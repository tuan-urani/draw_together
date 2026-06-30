import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

type StorageEntry = {
  name: string;
  id?: string | null;
  metadata?: Record<string, unknown> | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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

  try {
    const authorization = req.headers.get("Authorization") ?? "";
    const jwt = authorization.replace("Bearer ", "").trim();
    if (!jwt) return jsonResponse({ error: "Missing bearer token." }, 401);

    const { data, error } = await supabase.auth.getUser(jwt);
    if (error || !data.user) {
      return jsonResponse({ error: "Invalid bearer token." }, 401);
    }

    await deleteSubmissionObjects(supabase, data.user.id);

    const { error: deleteError } = await supabase.auth.admin.deleteUser(
      data.user.id,
    );
    if (deleteError) throw deleteError;

    return jsonResponse({ status: "deleted" }, 200);
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});

async function deleteSubmissionObjects(
  supabase: SupabaseClient,
  userId: string,
) {
  const paths = await listStoragePaths(supabase, userId);
  if (paths.length === 0) return;

  for (const chunk of chunks(paths, 100)) {
    const { error } = await supabase.storage.from("submissions").remove(chunk);
    if (error) throw error;
  }
}

async function listStoragePaths(
  supabase: SupabaseClient,
  prefix: string,
): Promise<string[]> {
  const paths: string[] = [];
  const limit = 1000;
  let offset = 0;

  while (true) {
    const { data, error } = await supabase.storage
      .from("submissions")
      .list(prefix, {
        limit,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
    if (error) throw error;

    const entries = (data ?? []) as StorageEntry[];
    for (const entry of entries) {
      const path = `${prefix}/${entry.name}`;
      if (isStorageFile(entry)) {
        paths.push(path);
      } else {
        paths.push(...(await listStoragePaths(supabase, path)));
      }
    }

    if (entries.length < limit) break;
    offset += limit;
  }

  return paths;
}

function isStorageFile(entry: StorageEntry) {
  return Boolean(entry.id || entry.metadata);
}

function chunks<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }

  return result;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  if (typeof error === "string") return error;

  return "Unknown error.";
}
