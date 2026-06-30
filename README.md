# Draw Together

Draw Together is a 2-player mobile drawing game built around one core rule:

> Copy the target image, but draw slowly. If you draw too fast, the stroke quality breaks down and the final image becomes harder for AI to score well.

The app is planned for Flutter. The initial product focuses on two modes:

- **Co-op Slow Drawing**: two players draw on one shared canvas and receive one team score.
- **Versus Slow Drawing**: two players draw the same target on separate canvases and compare AI similarity scores.

## Documentation

- [Product Scope](docs/product-scope.md)
- [Gameplay Design](docs/gameplay-design.md)
- [Architecture Overview](docs/architecture.md)
- [Supabase Architecture](docs/supabase-architecture.md)
- [Supabase Implementation Plan](docs/supabase-implementation-plan.md)
- [Target Assets](docs/target-assets.md)
- [UI Reference](docs/ui-reference.md)
- [Realtime Protocol](docs/realtime-protocol.md)
- [Data Model](docs/data-model.md)
- [AI Scoring](docs/ai-scoring.md)
- [Implementation Roadmap](docs/roadmap.md)

## Recommended MVP Direction

The planned MVP direction is Supabase-first:

- Flutter app
- Supabase Auth for player identity
- Supabase Postgres for rooms, rounds, submissions, scores, and target metadata
- Supabase Realtime Broadcast for live co-op strokes and game events
- Supabase Realtime Presence for online/ready state
- Supabase Storage for target and result images
- Supabase Edge Functions for AI scoring with private API keys

Supabase Realtime Broadcast is an event channel rather than a realtime JSON database. Co-op reconnect and stroke replay must therefore be handled explicitly, either by accepting simple reconnect behavior in MVP or by adding periodic canvas snapshots.

## MVP Seed Data

Seed target image assets with:

```bash
./scripts/seed_targets.sh
```

Target metadata seed SQL lives at `supabase/seed_target_images.sql`.

## Development Commands

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run --flavor prod -d <device_id>
```

Build Android APK:

```bash
flutter build apk --release --flavor prod
```

Build Android App Bundle for Play Store:

```bash
flutter build appbundle --release --flavor prod
```

Build iOS release:

```bash
flutter build ios --release --flavor prod
```
