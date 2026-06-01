# Supabase Architecture

## When to Choose Supabase

Supabase is a good option if the project values:

- Postgres and SQL,
- Row Level Security,
- relational room/match/history queries,
- Edge Functions for AI scoring,
- one backend platform for database, auth, realtime, storage, and functions.

## Realtime Model

Supabase Realtime is not a realtime JSON database.

Supabase Realtime Broadcast:

```text
channel: room:ABC123
event: stroke_segment
payload: {...}
```

Broadcast messages are live events. They are not a durable JSON tree and should not be treated as persistent storage. Durable room, round, submission, and score state belongs in Postgres.

## Services

### Supabase Auth

Use anonymous or lightweight auth for MVP if available in the chosen auth setup. Otherwise use email/social login later and a local guest identity for early prototypes.

### Supabase Postgres

Use for durable data:

- rooms,
- room players,
- rounds,
- submissions,
- AI judgements,
- target images,
- leaderboards.

### Supabase Realtime Broadcast

Use for live game events:

- `round_started`,
- `stroke_segment`,
- `cursor_moved`,
- `round_ended`,
- `player_submitted`.

Do not insert every stroke segment into Postgres just to trigger realtime changes.

### Supabase Presence

Use to track:

- player online/offline,
- ready state,
- active participants in a room.

### Supabase Storage

Use for:

- target images,
- final canvas submissions.

### Supabase Edge Functions

Use for AI scoring if using OpenAI, Gemini REST APIs, or any provider requiring a private API key.

Edge Function responsibilities:

- validate user/session,
- fetch target and submission images,
- call AI provider,
- parse structured result,
- write score to Postgres.

## Co-op Reconnect Strategy

Because Broadcast does not replay missed messages, choose one:

1. Accept simple MVP reconnect where a disconnected client may miss strokes.
2. Periodically store a canvas snapshot and restore from latest snapshot.
3. Store stroke segments temporarily in Postgres or object storage, with cleanup.
4. Let host resend current canvas state when a player reconnects.

For MVP, option 1 or 2 is usually enough.

## Recommended Supabase Flow

1. Create room row in Postgres.
2. Both clients subscribe to `room:{roomId}` channel.
3. Presence tracks connected players.
4. Host inserts round row with `started_at` and `duration_ms`.
5. Host broadcasts `round_started`.
6. Co-op mode broadcasts `stroke_segment` events.
7. Clients export final images at round end.
8. Images upload to Storage.
9. Edge Function scores the round.
10. Score is saved to Postgres.
