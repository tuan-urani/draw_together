# Gameplay Design

## Core Rule

Players copy a target image while keeping stroke speed below a threshold.

When speed is too high, the canvas engine degrades the stroke. The AI judge does not need a separate speed score because the final drawing already includes the consequence of drawing too quickly.

```text
fast hand movement -> broken/faint stroke -> lower image similarity -> lower score
```

## Co-op Slow Drawing

### Round Flow

1. Player A creates a room.
2. Player B joins the room.
3. Both players ready up.
4. Game selects a Co-op target image containing black and red assigned line segments.
5. Countdown starts.
6. Both players draw on the same canvas.
7. Timer ends.
8. A final team canvas is exported.
9. AI scores the team canvas against the target.
10. Result screen shows the target, team drawing, and score.

### Score

```text
team_score = ai_similarity_score
```

No individual score is shown in co-op. Per-player stroke metrics may be collected for tuning, but they should not be part of the user-facing result in MVP.

For target matching, Player A draws black lines (`#1F2937`) and Player B draws red lines (`#EF4056`). The target image includes both colors as the intended combined result.

## Versus Slow Drawing

### Round Flow

1. Two players join the same room.
2. Both players ready up.
3. Game selects one Versus target image rendered with black lines only.
4. Countdown starts.
5. Each player draws on their own local canvas.
6. Timer ends.
7. Both players upload final canvas images.
8. Host triggers AI scoring after both player submissions exist.
9. AI scores each canvas against the same target.
10. Result UI shows each player's score and winner.

### Score

```text
player_score = ai_similarity_score
winner = player with higher score
```

The current implementation scores each submitted canvas against the target and compares the normalized similarity scores. A later optimization can batch both player canvases into one AI request if cost or latency requires it.

Both Versus canvases use black lines (`#1F2937`) so player identity does not affect target similarity.

## Target Images

MVP target images should be simple and readable.

Canonical source format:

```text
1024x1024 PNG
square canvas
white or transparent background
```

AI scoring input may be resized server-side to:

```text
512x512 or 768x768
```

Target images should use:

- white or transparent background,
- one main object,
- minimal texture,
- few small details,
- consistent square framing,
- line-art or icon-like style.

Good examples:

- house
- rocket
- fish
- cactus
- robot
- umbrella
- cup

Avoid early:

- real photos,
- complex landscapes,
- multiple objects,
- highly detailed characters,
- text-heavy images.

See [Target Assets](target-assets.md) for local folder, Supabase Storage, and database conventions.

## Slow Drawing Mechanic

The canvas engine should calculate speed between points:

```text
speed = distance(previousPoint, currentPoint) / deltaTime
```

If speed is within limit:

- draw normally.

If speed is slightly above limit:

- lower alpha,
- reduce width,
- or create small gaps.

If speed is far above limit:

- skip part of the stroke,
- or draw only sparse points.

The player should understand the rule through visual feedback on the line itself.
