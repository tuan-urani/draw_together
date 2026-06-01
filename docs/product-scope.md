# Product Scope

## Core Concept

Draw Together is a 2-player mobile game where players copy a target image under a slow-drawing constraint.

The game does not reward drawing fast. Fast strokes degrade visually:

- the line becomes faint,
- the line becomes broken,
- or parts of the stroke are skipped.

The final canvas is scored by AI against the target image. Because fast drawing directly damages the final drawing, the score can be based only on visual similarity.

## Target Platform

- Mobile app
- Flutter
- Realtime multiplayer for 2-player rooms

## MVP Modes

### Co-op Slow Drawing

Two players draw together on the same canvas.

- One shared two-color target image, assigning black lines to Player A and red lines to Player B
- One shared canvas
- Player A draws black lines and Player B draws red lines
- Final result is one team submission
- AI returns one team similarity score

### Versus Slow Drawing

Two players compete to copy the same target image.

- One shared single-color black target image
- Separate canvas per player
- Players do not need to see each other's strokes during the round
- AI compares each player canvas against the target
- Winner is the higher-scoring submission

## Out of Scope for MVP

- Public matchmaking
- Ranking or rewards
- Complex anti-cheat
- Stroke replay history
- Friend system
- In-app purchases
- Full account/profile system
- AI generation of target images during gameplay

## Success Criteria

The MVP is successful if:

- two players can join a room reliably,
- co-op drawing feels live enough to be fun,
- the slow-stroke penalty is understandable without extra explanation,
- AI scoring is consistent enough for casual play,
- players can complete multiple rounds without restarting the app.
