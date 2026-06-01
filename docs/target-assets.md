# Target Assets

This document defines how target images are prepared, stored, and referenced.

## Canonical Format

Use one standard file format for both modes:

```text
1024x1024 px
PNG
square aspect ratio
white or transparent background
```

Reasoning:

- square targets simplify canvas layout,
- 1024px is sharp enough for mobile display,
- PNG preserves clean line art,
- consistent dimensions make AI scoring and export easier.

When sending images to AI, the Edge Function may resize to:

```text
512x512 or 768x768
```

This reduces latency and AI input cost while keeping enough detail for simple line-art targets.

## Mode Variants

Every target belongs to exactly one gameplay mode.

### Co-op Target

The target is a single combined reference image containing two line colors:

```text
seat 1: #1F2937 (black)
seat 2: #EF4056 (red)
```

Each color should represent a meaningful subset of the same object, so both players contribute to the shared final canvas. Both players see the combined reference, and the team canvas is compared to that combined image.

### Versus Target

The target uses one line color:

```text
#1F2937 (black)
```

Both players use that same black stroke color on their private canvas so scoring is based on shape rather than arbitrary player color.

## Visual Requirements

Target images should be:

- one main object,
- centered,
- readable as a silhouette,
- low-detail,
- no text,
- no complex background,
- no photo-realistic texture.

Good target examples:

- house,
- rocket,
- fish,
- robot,
- cactus,
- umbrella,
- cup.

Avoid for MVP:

- real photos,
- landscapes,
- groups of objects,
- detailed characters,
- text or logos,
- heavy gradients or shading.

## Local Folder

Place source target images here:

```text
assets/targets/{mode}/{difficulty}/{target_id}.png
```

Example:

```text
assets/targets/coop/easy/house_duo_001.png
assets/targets/versus/easy/house_001.png
assets/targets/versus/medium/robot_001.png
```

The repo does not need target images committed immediately, but this folder structure should be used when assets are added.

## Supabase Storage

Use this bucket:

```text
targets
```

The bucket is public. The app should load target images through public URLs derived from `storage_path`; it should not depend on listing objects in the bucket.

Storage path convention:

```text
{mode}/{difficulty}/{target_id}.png
```

Example:

```text
coop/easy/house_duo_001.png
versus/easy/house_001.png
versus/medium/robot_001.png
```

Do not store the bucket name inside `storage_path`.

Correct:

```text
versus/easy/rocket_001.png
```

Incorrect:

```text
targets/versus/easy/rocket_001.png
```

## Database Metadata

Each uploaded target should have one `target_images` row.

Example:

```json
{
  "id": "rocket_001",
  "storage_path": "versus/easy/rocket_001.png",
  "title": "Rocket",
  "mode": "versus",
  "difficulty": "easy",
  "width": 1024,
  "height": 1024,
  "mime_type": "image/png",
  "active": true
}
```

Co-op example:

```json
{
  "id": "house_duo_001",
  "storage_path": "coop/easy/house_duo_001.png",
  "title": "House",
  "mode": "coop",
  "difficulty": "easy",
  "width": 1024,
  "height": 1024,
  "mime_type": "image/png",
  "active": true
}
```

Optional fields:

- `checksum` for duplicate detection,
- `tags` for later target filtering,
- `sort_order` for curated target sequences.

## Target Selection

MVP can select targets randomly from active rows:

```text
active = true
mode = current room mode
difficulty = selected difficulty
```

Do not use AI-generated target images during gameplay for MVP. Curated assets make scoring behavior easier to test.

## Import Workflow

Recommended workflow:

1. Put source PNGs in `assets/targets/{mode}/{difficulty}/`.
2. Validate size is `1024x1024`.
3. Validate palette: black/red for `coop`, black only for `versus`.
4. Upload to Supabase Storage bucket `targets`.
5. Insert/update `target_images` rows.
6. Test a few rounds against each new target.

## MVP Seed Assets

The repo currently includes four legacy-path single-color targets for Versus MVP testing:

- `assets/targets/easy/cat_001.png`
- `assets/targets/easy/house_001.png`
- `assets/targets/easy/rocket_001.png`
- `assets/targets/medium/robot_001.png`

The repo also includes one two-color Co-op target:

- `assets/targets/coop/easy/house_duo_001.png`

Upload them with:

```bash
./scripts/seed_targets.sh
```

The matching metadata SQL is stored in:

```text
supabase/seed_target_images.sql
```

These existing seed objects may keep their legacy paths (`easy/...`, `medium/...`) while their database `mode` is `versus`. New imports should use the mode-prefixed folder convention above.

`house_duo_001` is the initial active Co-op target and uses the mode-prefixed storage path `coop/easy/house_duo_001.png`.
