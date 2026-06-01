import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";

type ScoreResult = {
  score: number;
  confidence: number;
  rationale: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const promptVersion = "slow_similarity_v2_mode_palette";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return jsonResponse({}, 200);
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  let roundId: string | undefined;

  try {
    const authorization = req.headers.get("Authorization") ?? "";
    const jwt = authorization.replace("Bearer ", "").trim();
    if (!jwt) return jsonResponse({ error: "Missing bearer token." }, 401);

    const { data: userData, error: userError } = await supabase.auth.getUser(
      jwt,
    );
    if (userError || !userData.user) {
      return jsonResponse({ error: "Invalid bearer token." }, 401);
    }

    const body = await req.json();
    roundId = body.roundId;
    if (!roundId || typeof roundId !== "string") {
      return jsonResponse({ error: "roundId is required." }, 400);
    }

    const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini";
    const round = await fetchRound(supabase, roundId);
    const room = await fetchRoom(supabase, round.room_id);
    await assertRoomAccess(supabase, room, userData.user.id);

    const existingScores = await fetchExistingScores(supabase, round.id);
    if (existingScores.length > 0) {
      return jsonResponse({
        status: "scored",
        mode: round.mode,
        scores: existingScores,
        score: existingScores[0],
      });
    }

    const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiApiKey) {
      await insertFailedJudgement(
        supabase,
        roundId,
        "OPENAI_API_KEY is not configured.",
      );
      return jsonResponse(
        { error: "OPENAI_API_KEY is not configured." },
        500,
      );
    }

    const target = await fetchTarget(supabase, round.target_image_id);
    const targetDataUrl = await downloadAsDataUrl(
      supabase,
      "targets",
      target.storage_path,
      target.mime_type ?? "image/png",
    );

    await supabase
      .from("rounds")
      .update({ status: "scoring" })
      .eq("id", round.id);
    await supabase
      .from("rooms")
      .update({ status: "scoring" })
      .eq("id", room.id);

    if (round.mode === "versus") {
      const result = await scoreVersusRound({
        supabase,
        round,
        model,
        openAiApiKey,
        targetDataUrl,
      });

      return jsonResponse(result);
    }

    const result = await scoreCoopRound({
      supabase,
      round,
      room,
      model,
      openAiApiKey,
      targetDataUrl,
    });

    return jsonResponse(result);
  } catch (error) {
    if (roundId) {
      await safeInsertFailedJudgement(supabase, roundId, errorMessage(error));
      await markRoundFailed(supabase, roundId);
    }

    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});

async function markRoundFailed(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
) {
  const { data: round } = await supabase
    .from("rounds")
    .select("id, room_id")
    .eq("id", roundId)
    .maybeSingle();

  await supabase
    .from("rounds")
    .update({ status: "failed" })
    .eq("id", roundId);

  if (round?.room_id) {
    await supabase
      .from("rooms")
      .update({ status: "finished" })
      .eq("id", round.room_id);
  }
}

async function scoreCoopRound({
  supabase,
  round,
  room,
  model,
  openAiApiKey,
  targetDataUrl,
}: {
  supabase: ReturnType<typeof createClient>;
  round: Record<string, string>;
  room: Record<string, string>;
  model: string;
  openAiApiKey: string;
  targetDataUrl: string;
}) {
  const submission = await fetchTeamSubmission(supabase, round.id);
  const submissionDataUrl = await downloadAsDataUrl(
    supabase,
    "submissions",
    submission.image_path,
    "image/png",
  );

  const scoreResult = await scoreWithOpenAi({
    apiKey: openAiApiKey,
    model,
    mode: "coop",
    targetDataUrl,
    submissionDataUrl,
  });

  const { data: judgement, error: judgementError } = await supabase
    .from("ai_judgements")
    .insert({
      round_id: round.id,
      model,
      prompt_version: promptVersion,
      status: "succeeded",
      raw_response: scoreResult,
    })
    .select()
    .single();
  if (judgementError) throw judgementError;

  const { data: score, error: scoreError } = await supabase
    .from("scores")
    .insert({
      round_id: round.id,
      submission_id: submission.id,
      user_id: null,
      team_score: scoreResult.score,
      similarity_score: scoreResult.score,
      winner: false,
    })
    .select()
    .single();
  if (scoreError) throw scoreError;

  await markRoundScored(supabase, round.id, room.id);

  return {
    status: "scored",
    mode: "coop",
    judgement,
    score,
    scores: [score],
  };
}

async function scoreVersusRound({
  supabase,
  round,
  model,
  openAiApiKey,
  targetDataUrl,
}: {
  supabase: ReturnType<typeof createClient>;
  round: Record<string, string>;
  model: string;
  openAiApiKey: string;
  targetDataUrl: string;
}) {
  const submissions = await fetchPlayerSubmissions(supabase, round.id);
  if (submissions.length < 2) {
    throw new Error("Two player submissions are required.");
  }

  const scoredSubmissions = [];
  for (const submission of submissions) {
    const submissionDataUrl = await downloadAsDataUrl(
      supabase,
      "submissions",
      submission.image_path,
      "image/png",
    );
    const result = await scoreWithOpenAi({
      apiKey: openAiApiKey,
      model,
      mode: "versus",
      targetDataUrl,
      submissionDataUrl,
    });

    scoredSubmissions.push({ submission, result });
  }

  const maxScore = Math.max(
    ...scoredSubmissions.map((entry) => entry.result.score),
  );
  const winnerCount = scoredSubmissions.filter(
    (entry) => entry.result.score === maxScore,
  ).length;

  const { data: judgement, error: judgementError } = await supabase
    .from("ai_judgements")
    .insert({
      round_id: round.id,
      model,
      prompt_version: `${promptVersion}_versus`,
      status: "succeeded",
      raw_response: scoredSubmissions.map((entry) => ({
        submissionId: entry.submission.id,
        userId: entry.submission.user_id,
        ...entry.result,
      })),
    })
    .select()
    .single();
  if (judgementError) throw judgementError;

  const scoreRows = scoredSubmissions.map((entry) => ({
    round_id: round.id,
    submission_id: entry.submission.id,
    user_id: entry.submission.user_id,
    team_score: null,
    similarity_score: entry.result.score,
    winner: winnerCount === 1 && entry.result.score === maxScore,
  }));

  const { data: scores, error: scoreError } = await supabase
    .from("scores")
    .insert(scoreRows)
    .select();
  if (scoreError) throw scoreError;

  await markRoundScored(supabase, round.id, round.room_id);

  return {
    status: "scored",
    mode: "versus",
    judgement,
    scores,
  };
}

async function markRoundScored(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
  roomId: string,
) {
  await supabase
    .from("rounds")
    .update({ status: "scored" })
    .eq("id", roundId);
  await supabase
    .from("rooms")
    .update({ status: "finished" })
    .eq("id", roomId);
}

async function fetchRound(supabase: ReturnType<typeof createClient>, id: string) {
  const { data, error } = await supabase
    .from("rounds")
    .select()
    .eq("id", id)
    .single();
  if (error) throw error;
  return data;
}

async function fetchRoom(supabase: ReturnType<typeof createClient>, id: string) {
  const { data, error } = await supabase
    .from("rooms")
    .select()
    .eq("id", id)
    .single();
  if (error) throw error;
  return data;
}

async function assertRoomAccess(
  supabase: ReturnType<typeof createClient>,
  room: { id: string; host_user_id: string },
  userId: string,
) {
  if (room.host_user_id === userId) return;

  const { data, error } = await supabase
    .from("room_players")
    .select("room_id")
    .eq("room_id", room.id)
    .eq("user_id", userId)
    .is("left_at", null)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new Error("User is not a member of this room.");
}

async function fetchTarget(
  supabase: ReturnType<typeof createClient>,
  id: string,
) {
  const { data, error } = await supabase
    .from("target_images")
    .select()
    .eq("id", id)
    .single();
  if (error) throw error;
  return data;
}

async function fetchTeamSubmission(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
) {
  const { data, error } = await supabase
    .from("submissions")
    .select()
    .eq("round_id", roundId)
    .eq("is_team_submission", true)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();
  if (error) throw error;
  return data;
}

async function fetchExistingScores(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
) {
  const { data, error } = await supabase
    .from("scores")
    .select()
    .eq("round_id", roundId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

async function fetchPlayerSubmissions(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
) {
  const { data, error } = await supabase
    .from("submissions")
    .select()
    .eq("round_id", roundId)
    .eq("is_team_submission", false)
    .not("user_id", "is", null)
    .order("created_at", { ascending: true });
  if (error) throw error;

  const latestByUser = new Map<string, Record<string, string>>();
  for (const submission of data ?? []) {
    if (submission.user_id) latestByUser.set(submission.user_id, submission);
  }

  return Array.from(latestByUser.values());
}

async function downloadAsDataUrl(
  supabase: ReturnType<typeof createClient>,
  bucket: string,
  path: string,
  contentType: string,
) {
  const { data, error } = await supabase.storage.from(bucket).download(path);
  if (error) throw error;

  const bytes = new Uint8Array(await data.arrayBuffer());
  return `data:${contentType};base64,${base64FromBytes(bytes)}`;
}

async function scoreWithOpenAi({
  apiKey,
  model,
  mode,
  targetDataUrl,
  submissionDataUrl,
}: {
  apiKey: string;
  model: string;
  mode: "coop" | "versus";
  targetDataUrl: string;
  submissionDataUrl: string;
}): Promise<ScoreResult> {
  const paletteInstruction = mode === "coop"
    ? "For co-op, black and red target lines assign each player's contribution. Penalize important target segments that are missing or drawn in the wrong assigned color."
    : "For versus, target and submission should use the same black line color; compare structure and completeness.";
  const submissionLabel = mode === "coop"
    ? "the combined team drawing"
    : "one player's drawing";

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      instructions:
        `You are a judge for a slow drawing game. Compare the drawing to the target image. Score visual similarity from 0 to 100. Evaluate object identity, silhouette, major parts, proportions, placement, and important target details. ${paletteInstruction} Do not reward artistic style. Ignore canvas background differences. Return JSON only.`,
      input: [
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text:
                `Image 1 is the target. Image 2 is ${submissionLabel}. Return the similarity score, confidence, and a short rationale.`,
            },
            { type: "input_image", image_url: targetDataUrl },
            { type: "input_image", image_url: submissionDataUrl },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "slow_drawing_score",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              score: { type: "integer", minimum: 0, maximum: 100 },
              confidence: { type: "number", minimum: 0, maximum: 1 },
              rationale: { type: "string" },
            },
            required: ["score", "confidence", "rationale"],
          },
        },
      },
      max_output_tokens: 300,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.error?.message ?? "OpenAI scoring failed.");
  }

  const outputText = extractOutputText(payload);
  const parsed = JSON.parse(outputText) as ScoreResult;
  if (!Number.isInteger(parsed.score) || parsed.score < 0 || parsed.score > 100) {
    throw new Error("OpenAI returned an invalid score.");
  }

  return {
    score: parsed.score,
    confidence: Number(parsed.confidence),
    rationale: String(parsed.rationale),
  };
}

function extractOutputText(payload: Record<string, unknown>): string {
  if (typeof payload.output_text === "string") return payload.output_text;

  const output = Array.isArray(payload.output) ? payload.output : [];
  for (const item of output) {
    const content = (item as { content?: unknown }).content;
    if (!Array.isArray(content)) continue;

    for (const part of content) {
      const text = (part as { text?: unknown }).text;
      if (typeof text === "string") return text;
    }
  }

  throw new Error("OpenAI response did not contain output text.");
}

async function insertFailedJudgement(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
  message: string,
) {
  await supabase.from("ai_judgements").insert({
    round_id: roundId,
    model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini",
    prompt_version: promptVersion,
    status: "failed",
    raw_response: {},
    error_message: message,
  });
}

async function safeInsertFailedJudgement(
  supabase: ReturnType<typeof createClient>,
  roundId: string,
  message: string,
) {
  try {
    await insertFailedJudgement(supabase, roundId, message);
  } catch (error) {
    console.error("Could not insert failed judgement", error);
  }
}

function base64FromBytes(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  let binary = "";
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
