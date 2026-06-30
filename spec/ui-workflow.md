# UI Workflow

## Home

**Path**: `lib/src/ui/home`

### 1. Description

Goal: provide the shortest route to create or join a slow drawing room.

### 2. UI Structure

- Profile summary with editable display name.
- Header action for Settings.
- Compact `Create Co-op Room`, `Create Versus Room`, and `Join Room` actions.
- `Recent Games` card backed by the three newest scored rounds.
- Empty gallery state when the player has no scored history.
- Tappable history items, plus header and `View All` navigation.
- The previous duplicate guest information and empty room-history sections are not displayed.

### 3. User Flow & Logic

1. Player loads an anonymous profile.
2. Player optionally edits their display name.
3. Player opens Settings from the header action.
4. Home loads up to three newest matches from `HistoryRepository`.
5. Player opens a recent match to view its History Detail.
6. Player opens the full History from the section header or `View All`.
7. Player creates a mode-specific room or enters a room code to join.
8. Recent Games reloads when the room or match navigation flow returns to Home.

### 4. Key Dependencies

- `HomeBloc` coordinates profile, room actions, and recent history state.
- `HistoryRepository` supplies newest-first scored rounds with an optional limit.

## Settings

**Path**: `lib/src/ui/settings`

### 1. Description

Goal: let the player customize app audio and language, and access account/support actions.

### 2. UI Structure

- Screen: `SettingsPage`
- Components: settings section card, toggle row, language dropdown row, link row, delete account card, delete confirmation dialog.
- Route: `AppPages.settings`

### 3. User Flow & Logic

1. Player taps the Settings icon on Home.
2. Settings opens with a back button, title, and subtitle.
3. Player toggles Background Music; the choice is saved and the current music starts or stops.
4. Player toggles Sound Effects; the choice is saved and future tap sounds respect it.
5. Player selects English, Japanese, or Vietnamese; the app updates immediately and saves the choice for future launches.
6. On the first launch without a saved choice, the app uses the device language for English, Japanese, or Vietnamese and falls back to English for every other language.
7. Player opens Privacy Policy or Terms of Use in the in-app web view.
8. Player taps Delete Account and confirms the destructive action.
9. The app invokes the `delete-account` Edge Function, signs out locally, and returns to Splash.
10. Splash prepares a fresh anonymous session and profile for the next account.

### 4. Key Dependencies

- `AppAudioManager`
- `AppShared`
- `AuthRepository`
- `TranslationManager`
- Supabase Edge Function `delete-account`

## Room Lobby

**Path**: `lib/src/ui/room`

### 1. Description

Goal: let two players assemble quickly before starting a round.

### 2. UI Structure

- Compact room-code row with copy action.
- Single-row mode and status summary.
- Two compact player slots and start/readiness actions.

### 3. User Flow & Logic

1. Host shares the code; guest joins it from Home.
2. Presence and ready state appear in the two player slots.
3. Host starts the round when both players are ready.

## Drawing Board

**Path**: `lib/src/ui/drawing`

### 1. Description

Goal: let players draw during an active round, using a shared canvas for co-op and separate local canvases for versus.

Features:

- loads the latest round for the room,
- shows target image, timer, realtime connection status, and player color,
- uses a compact target/timer strip and prioritizes canvas area while drawing,
- lets the user draw while the round timer is active,
- visually degrades fast strokes by lowering opacity, reducing width, and skipping severe fast points,
- broadcasts stroke segments through Supabase Realtime Broadcast in co-op,
- renders remote player stroke segments on the shared co-op canvas,
- keeps versus strokes local so players cannot see each other's drawing during the round,
- selects only target images matching the room mode; co-op uses black/red assigned lines and versus uses black lines,
- lets the host export and submit the final team canvas after the timer ends,
- lets each versus player export and submit their own final canvas after the timer ends,
- invokes server-side AI scoring and shows either the team score or versus scores and winner.

### 2. UI Structure

- Screen: `DrawingBoardPage`
- Binding: `DrawingBoardBinding`
- Bloc: `DrawingBoardBloc`
- Component: `SlowDrawingCanvas`
- Route: `AppPages.drawingBoard`
- Active drawing layout: fixed, non-scrolling canvas-first view without an instructional tip card or unused tool palette.

### 3. User Flow & Logic

1. Player starts a round from the room lobby.
2. Lobby shows the active target and an `Enter Drawing` action.
3. Player enters the drawing board with `roomId`.
4. Drawing board fetches room, players, latest round, and target metadata.
5. Drawing board connects to `room:{roomId}` Realtime channel.
6. In co-op, local strokes are batched into `stroke_segment` messages.
7. In co-op, remote `stroke_segment` messages are deduplicated and appended to the canvas.
8. In versus, local strokes remain private to the current player canvas.
9. The local countdown is calculated from `started_at + duration_ms`.
10. When time reaches zero, the canvas locks.
11. In co-op, host exports the canvas as PNG and uploads one team submission.
12. In versus, each player exports and uploads their own player submission.
13. App broadcasts `player_submitted` after each upload.
14. In co-op, host invokes the `score-round` Edge Function after the team submission.
15. In versus, host invokes `score-round` after both player submissions exist.
16. Edge Function stores `ai_judgements` and `scores`.
17. Host broadcasts `result_ready`.
18. Both clients show the team score or versus winner.

### 4. Key Dependencies

- `RoomRepository`
- `TargetRepository`
- Supabase Realtime Broadcast
- `target_images` metadata and public `targets` storage URLs
- Supabase Storage bucket `submissions`
- `submissions` table
- Supabase Edge Function `score-round`
- `ai_judgements` and `scores` tables

### 5. Notes & Known Issues

- Reconnect currently recovers round/timer state, but not missed stroke history.
- `target_images` must contain active rows for the requested room mode before a real round can be started.
- Co-op targets must use black/red assigned lines matching player stroke colors; Versus targets and both private canvases use black lines.
- Only host can submit the co-op team canvas in the current MVP because host has RLS permission to move the round to `submitting`.
- In versus, both players can submit their own canvas; host is responsible for triggering scoring once both submissions exist.
- Scoring requires `OPENAI_API_KEY` to be configured as a Supabase Edge Function secret.
