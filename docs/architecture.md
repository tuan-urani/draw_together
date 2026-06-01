# Architecture Overview

## Recommended MVP Architecture

The recommended implementation is Supabase-first because it gives the project one backend platform for Postgres, Auth, Storage, Realtime, and Edge Functions.

```text
Flutter app
  |
  |-- Supabase Auth
  |-- Supabase Postgres
  |     - rooms
  |     - rounds
  |     - submissions
  |     - scores
  |
  |-- Supabase Realtime
  |     - Broadcast for stroke/game events
  |     - Presence for online/ready state
  |
  |-- Supabase Storage
  |     - target images
  |     - final canvas images
  |
  |-- Supabase Edge Functions
        - AI scoring with private provider keys
```

## Realtime Tradeoff

Supabase Realtime Broadcast is an event channel, not a durable room-state database.

It is good for live stroke events, but it does not automatically preserve room state or replay missed stroke history. Durable state must be stored in Postgres, and co-op reconnect behavior must be designed explicitly.

## Source of Truth

### During an Active Round

The realtime layer is the live source of truth:

- current room state,
- ready state,
- active round state,
- co-op stroke segments,
- online presence.

### After a Round Ends

The persistent database is the source of truth:

- room metadata,
- round metadata,
- final image paths,
- AI score,
- winner,
- timestamps.

## AI Key Safety

AI provider keys must not be hardcoded in the Flutter app unless the provider offers a client-safe product specifically designed for mobile usage.

Safe options:

- Supabase Edge Function with OpenAI, Gemini, or another provider key stored as a secret.
- Backend endpoint through Cloud Functions, Cloud Run, or another server.

Unsafe option:

- Calling OpenAI or Gemini REST APIs directly from Flutter with a private API key bundled in the app.
