# AI Scoring

## Goal

AI scoring compares the target image with the final canvas image and returns a visual similarity score.

The score should measure recognizability and structural similarity, not artistic beauty.

## Why No Separate Steadiness Score

The slow drawing mechanic modifies the actual stroke output. If a player draws too fast, the final canvas becomes worse.

Therefore:

```text
score = AI visual similarity score
```

This keeps scoring simple and makes the consequence of fast drawing visible.

## Co-op Input

- two-color target image with black/red assigned line segments
- team final canvas using the same player-assigned colors

Expected output:

```json
{
  "score": 78,
  "confidence": 0.84
}
```

## Versus Input

- single-color black target image
- Player A final canvas
- Player B final canvas

Expected output:

```json
{
  "playerA": {
    "score": 81
  },
  "playerB": {
    "score": 67
  },
  "winner": "playerA",
  "confidence": 0.88
}
```

Versus should be scored in one request so both drawings are judged with the same context.

## Suggested Rubric

```text
You are a judge for a slow drawing game.

Compare the player's drawing to the target image.
Score only visual similarity from 0 to 100.

Evaluate:
- main object identity and silhouette
- presence of major parts
- relative proportions and placement
- important target details
- for Co-op only: whether required black/red assigned segments are present in the matching color

Do not reward artistic style.
Do not penalize rough hand-drawn lines unless they make the target less recognizable.
Ignore canvas background differences.

Return JSON only.
```

## Scoring Runtime

Use Supabase Edge Functions for scoring.

The Flutter app should not call AI providers directly with private API keys. The app uploads final canvas images to Supabase Storage, then invokes an Edge Function that performs scoring server-side.

Implemented function:

```text
score-round
```

Required Supabase secret:

```text
OPENAI_API_KEY
```

Optional Supabase secret:

```text
OPENAI_MODEL
```

Default model:

```text
gpt-4.1-mini
```

Edge Function responsibilities:

- validate the authenticated user,
- verify the user belongs to the room,
- load the target image and submission image paths,
- download target and submission images from Supabase Storage,
- call OpenAI Responses API with image inputs,
- apply mode-specific palette judging: color assignment matters for Co-op and is uniform for Versus,
- parse structured JSON from a JSON schema response,
- write `ai_judgements` and `scores`,
- update round status.

Function input:

```json
{
  "roundId": "round_uuid"
}
```

Function success output:

```json
{
  "status": "scored",
  "score": {
    "team_score": 78,
    "similarity_score": 78
  }
}
```

## Image Preparation

Before scoring:

- export square canvas,
- use white or transparent background consistently,
- keep source target images at `1024x1024` PNG,
- resize to `512x512` or `768x768` for cost control,
- compress to PNG or WebP,
- avoid sending huge images.

## Data to Save

Save:

- score,
- model name,
- prompt version,
- raw response,
- image paths,
- timestamp.

This allows later debugging when users disagree with the score or the prompt changes.
