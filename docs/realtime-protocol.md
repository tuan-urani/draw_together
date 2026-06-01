# Realtime Protocol

## Goals

The realtime protocol must support:

- 2-player rooms,
- ready state,
- round start/end,
- co-op shared canvas strokes,
- versus state sync,
- reconnect handling,
- low payload size.

## General Rules

- Use normalized coordinates from `0.0` to `1.0`.
- Batch points into segments.
- Do not stream full canvas images during drawing.
- Do not send every pointer event as its own network message.
- Use server timestamps for round start when possible.

## Stroke Segment

```json
{
  "type": "stroke_segment",
  "roomId": "ABC123",
  "roundId": "round_001",
  "playerId": "uid_a",
  "strokeId": "stroke_123",
  "seq": 4,
  "color": "#2F80ED",
  "width": 4,
  "points": [
    [0.122, 0.431, 0],
    [0.126, 0.437, 18],
    [0.130, 0.444, 36]
  ]
}
```

Point format:

```text
[x, y, dtMs]
```

Where:

- `x` is normalized horizontal position,
- `y` is normalized vertical position,
- `dtMs` is milliseconds since the start of the stroke or segment.

## Room State

```json
{
  "type": "room_state",
  "roomId": "ABC123",
  "mode": "coop",
  "status": "waiting",
  "players": ["uid_a", "uid_b"]
}
```

Valid statuses:

- `waiting`
- `ready`
- `drawing`
- `submitting`
- `scoring`
- `finished`
- `expired`

## Round Started

```json
{
  "type": "round_started",
  "roundId": "round_001",
  "mode": "coop",
  "targetId": "rocket_01",
  "startedAt": 1779415200000,
  "durationMs": 60000
}
```

Clients calculate:

```text
endsAt = startedAt + durationMs
remainingMs = endsAt - estimatedServerNow
```

## Player Submitted

```json
{
  "type": "player_submitted",
  "roundId": "round_001",
  "playerId": "uid_a",
  "submissionId": "submission_001"
}
```

## Result Ready

```json
{
  "type": "result_ready",
  "roundId": "round_001",
  "resultId": "result_001"
}
```

## Batching Guidance

Initial tuning values:

```text
send segment every 30-80ms
or every 5-15 points
```

Use a shorter interval if the remote drawing feels delayed. Use a longer interval if bandwidth/cost becomes a concern.

