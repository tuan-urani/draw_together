# Supabase Implementation Plan

This is the concrete implementation plan for the Flutter + Supabase MVP.

## Target Stack

```text
Mobile:
  Flutter

Backend:
  Supabase Auth
  Supabase Postgres
  Supabase Realtime Broadcast
  Supabase Realtime Presence
  Supabase Storage
  Supabase Edge Functions

AI:
  Edge Function -> vision model API
```

## Implementation Principles

- Postgres stores durable game records.
- Realtime Broadcast sends live game events and co-op stroke segments.
- Presence tracks who is in the room and ready.
- Storage stores target images and final canvas submissions.
- Edge Functions protect AI provider keys and write authoritative scores.
- Do not use Postgres as a high-frequency stroke event bus.
- Do not stream full canvas images during drawing.

## Phase 1: Supabase Project Setup

Tasks:

- create Supabase project,
- create local `.env` values for Flutter,
- install Flutter Supabase client,
- configure Auth,
- create Storage buckets,
- create initial database schema,
- enable RLS on app tables,
- create minimal RLS policies.

Storage buckets:

```text
targets
submissions
```

Recommended access:

- `targets`: public read, admin write.
- `submissions`: authenticated write, authenticated read for MVP result screens.

Target image convention:

```text
source size: 1024x1024
source format: PNG
local folder: assets/targets/{mode}/{difficulty}/{target_id}.png
storage path: {mode}/{difficulty}/{target_id}.png
mode: coop (black/red lines) or versus (black lines only)
```

Submission image convention:

```text
bucket: submissions
storage path: {user_id}/{round_id}/{submission_id}.png
```

The first path segment must match the authenticated user id for client uploads.

Exit criteria:

- Flutter can connect to Supabase.
- A signed-in user can read target metadata.
- A signed-in user can create a room row.

## Phase 2: Auth and Player Identity

Tasks:

- implement sign-in flow,
- use anonymous/guest-like identity if supported by chosen Supabase auth setup,
- enable Anonymous Sign-Ins in Supabase Auth Providers,
- otherwise create a temporary profile after lightweight auth,
- create `profiles` row for each user,
- store display name locally and in Postgres.

Tables:

```text
profiles
```

Exit criteria:

- every app session has a stable `user.id`,
- user can set a display name,
- room ownership can be enforced by RLS.

## Phase 3: Database Schema

Create durable tables:

```text
profiles
rooms
room_players
target_images
rounds
submissions
ai_judgements
scores
```

Recommended enums:

```text
room_mode: coop, versus
room_status: waiting, ready, drawing, submitting, scoring, finished, expired
round_status: pending, drawing, submitting, scoring, scored, failed
target_mode: coop, versus
```

Implementation notes:

- generate room codes server-side if possible, or client-side with uniqueness check for MVP;
- keep `started_at` and `duration_ms` in `rounds`;
- keep AI raw response in `ai_judgements`;
- keep normalized score fields in `scores`.
- filter active `target_images` by the room's mode before creating a round.

Exit criteria:

- rooms can be created and joined,
- rounds can be inserted,
- submissions and scores can be queried for a result screen.

## Phase 4: Room Lifecycle

Tasks:

- create room,
- join room by code,
- enforce max 2 players,
- leave room,
- expire stale rooms,
- show room lobby.

Database writes:

```text
rooms
room_players
```

Realtime:

```text
channel: room:{roomId}
presence: each joined player
```

Exit criteria:

- two devices can join the same room,
- both devices see room members,
- a third device cannot join a full room.

## Phase 5: Realtime Presence

Tasks:

- subscribe to `room:{roomId}`,
- track presence with user id, display name, seat, and ready state,
- display online/ready state,
- handle disconnect and reconnect.

Presence payload:

```json
{
  "userId": "uuid",
  "displayName": "An",
  "seat": 1,
  "ready": true
}
```

Exit criteria:

- both players see each other online,
- ready state updates without refreshing,
- room can start only when both players are ready.

## Phase 6: Local Drawing Engine

Tasks:

- implement Flutter canvas,
- capture pointer points,
- calculate speed,
- degrade fast strokes,
- render local strokes,
- export canvas to PNG/WebP.

Exit criteria:

- drawing feels responsive,
- fast strokes visibly degrade,
- exported image matches the visible canvas.

## Phase 7: Co-op Stroke Broadcast

Tasks:

- batch local points into stroke segments,
- broadcast `stroke_segment` events on `room:{roomId}`,
- receive remote segments,
- render remote strokes,
- assign stable player colors,
- deduplicate by `strokeId + seq`.

Event:

```json
{
  "type": "stroke_segment",
  "roundId": "round_001",
  "playerId": "uid_a",
  "strokeId": "stroke_123",
  "seq": 4,
  "points": [[0.12, 0.44, 0], [0.13, 0.45, 18]]
}
```

Initial batching:

```text
30-80ms per segment
or 5-15 points per segment
```

Exit criteria:

- both players can draw on one shared canvas,
- remote stroke latency is acceptable,
- network payload stays small.

## Phase 8: Round Timer

Tasks:

- host starts a round by inserting a `rounds` row,
- use database timestamp as `started_at`,
- broadcast `round_started`,
- clients calculate countdown locally,
- disable drawing when timer ends.

Round started event:

```json
{
  "type": "round_started",
  "roundId": "round_001",
  "targetId": "rocket_01",
  "startedAt": "2026-05-24T10:00:00Z",
  "durationMs": 60000
}
```

Reconnect behavior:

- fetch current round row from Postgres,
- compute remaining time from `started_at + duration_ms`.

Exit criteria:

- both devices start the round at nearly the same time,
- reconnecting device can recover timer state.

## Phase 9: Submission Upload

Tasks:

- export final canvas at round end,
- upload to `submissions` bucket,
- insert `submissions` row,
- broadcast `player_submitted`.

Co-op:

- host or selected finalizer uploads one team canvas.

Versus:

- each player uploads one canvas.

Exit criteria:

- final images are stored,
- result screen can load submitted images,
- round can move to `scoring`.

## Phase 10: AI Scoring Edge Function

Create Edge Function:

```text
score-round
```

Responsibilities:

- validate authenticated user,
- validate user belongs to the room,
- load round, target, and submissions,
- call AI provider,
- parse JSON score,
- insert `ai_judgements`,
- insert/update `scores`,
- set round status to `scored` or `failed`.

Co-op input:

```text
target image + team canvas
```

Versus input:

```text
target image + player A canvas + player B canvas
```

Exit criteria:

- score is generated server-side,
- AI provider key is never exposed to Flutter,
- both players see result after scoring.

## Phase 11: Versus Mode

Tasks:

- add room mode selection,
- each player draws locally,
- do not broadcast stroke segments during versus,
- upload both final images,
- score both images in one Edge Function call,
- display winner.

Exit criteria:

- two players complete a versus round,
- scores are comparable,
- winner is saved and displayed.

## Phase 12: MVP Hardening

Tasks:

- tighten RLS policies,
- add rate limits for room creation and scoring,
- add Edge Function timeout handling,
- add retry states for uploads and scoring,
- add room expiry cleanup,
- add target image admin workflow,
- add target image import/seed script,
- add basic telemetry for latency and scoring failures.

Exit criteria:

- app is stable enough for external playtest,
- failed scoring/upload states are recoverable,
- database does not collect unbounded stale live data.

## MVP Build Order

Recommended exact order:

1. Flutter local canvas with slow-stroke degradation.
2. Supabase Auth and profiles.
3. Postgres schema and RLS baseline.
4. Room create/join.
5. Realtime Presence.
6. Round start/timer.
7. Co-op Broadcast strokes.
8. Storage upload for final canvas.
9. Edge Function AI scoring.
10. Co-op result screen.
11. Versus local drawing.
12. Versus scoring/result screen.
