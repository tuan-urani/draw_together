# Implementation Roadmap

This roadmap assumes the Supabase-first architecture described in [Supabase Implementation Plan](supabase-implementation-plan.md).

## Phase 0: Prototype Canvas

Goal: prove the slow drawing mechanic.

Tasks:

- build Flutter drawing canvas,
- calculate stroke speed,
- degrade strokes when speed is too high,
- export final canvas as image,
- test target images locally.

Exit criteria:

- drawing feels responsive,
- fast strokes visibly degrade,
- exported image matches what the player sees.

## Phase 1: Local Game Loop

Goal: play one full round on one device.

Tasks:

- show target image,
- start countdown,
- lock drawing when timer ends,
- export final image,
- show result screen placeholder.

Exit criteria:

- a full round can be played locally without backend.

## Phase 2: Room and Auth

Goal: two devices can join a room.

Tasks:

- add Supabase Auth,
- create `profiles`,
- create room,
- join room by code,
- show both players,
- ready state through Supabase Presence.

Exit criteria:

- two devices can enter the same room and see each other's ready state.

## Phase 3: Co-op Realtime Drawing

Goal: shared canvas works.

Tasks:

- subscribe to `room:{roomId}` Supabase Realtime channel,
- send stroke segments through Broadcast,
- receive and render remote Broadcast strokes,
- batch points,
- handle disconnect/reconnect minimally,
- prevent drawing after timer ends.

Exit criteria:

- both players can draw on one canvas and see each other's strokes live.

## Phase 4: Final Image and Storage

Goal: save round output.

Tasks:

- export co-op canvas,
- upload final image,
- save round/submission metadata,
- show saved result screen.

Exit criteria:

- each completed co-op round has a saved final image and metadata.

## Phase 5: AI Scoring

Goal: score the final image.

Tasks:

- implement Supabase Edge Function `score-round`,
- store AI provider key as a Supabase secret,
- define prompt version,
- parse structured JSON,
- save `ai_judgements` and `scores`,
- display score.

Exit criteria:

- target and final canvas produce a stable score for simple test images.

## Phase 6: Versus Mode

Goal: separate canvases and winner.

Tasks:

- create versus room mode,
- draw locally per player,
- upload both player canvases,
- score both canvases in one AI request,
- show target, both drawings, scores, and winner.

Exit criteria:

- two players can complete a versus round and get a winner.

## Phase 7: Hardening

Goal: make MVP testable with real users.

Tasks:

- improve security rules/RLS,
- add room expiry cleanup,
- add scoring timeouts,
- add retry and error states,
- collect basic analytics,
- tune stroke speed threshold.

Exit criteria:

- app can survive casual playtests without manual database cleanup every session.
