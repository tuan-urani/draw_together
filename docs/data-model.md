# Data Model

This document defines durable data. Live stroke data should not be stored permanently unless needed for replay/debugging.

## Logical Entities

## users

Represents a player identity.

Fields:

- `id`
- `display_name`
- `auth_provider`
- `created_at`

## rooms

Represents a 2-player room.

Fields:

- `id`
- `code`
- `mode`
- `host_user_id`
- `status`
- `created_at`
- `expires_at`

Valid modes:

- `coop`
- `versus`

Valid statuses:

- `waiting`
- `ready`
- `drawing`
- `submitting`
- `scoring`
- `finished`
- `expired`

## room_players

Represents room membership.

Fields:

- `room_id`
- `user_id`
- `seat`
- `joined_at`
- `left_at`

## target_images

Represents the target image catalog.

Fields:

- `id`
- `storage_path`
- `title`
- `mode`: `coop` or `versus`
- `difficulty`
- `width`
- `height`
- `mime_type`
- `checksum`
- `active`
- `created_at`

Conventions:

- source image should be `1024x1024` PNG,
- `storage_path` is relative to the `targets` bucket,
- new `storage_path` should be mode-prefixed, for example `versus/easy/rocket_001.png`,
- `coop` targets contain black (`#1F2937`) and red (`#EF4056`) assigned stroke lines,
- `versus` targets contain only black (`#1F2937`) stroke lines.

## rounds

Represents one playable round.

Fields:

- `id`
- `room_id`
- `mode`
- `target_image_id`
- `status`
- `started_at`
- `duration_ms`
- `ended_at`
- `created_at`

## submissions

Represents an uploaded final canvas.

For co-op, use one team submission.

For versus, use one submission per player.

Fields:

- `id`
- `round_id`
- `user_id`
- `submitted_by`
- `is_team_submission`
- `image_path`
- `width`
- `height`
- `created_at`

Notes:

- `user_id` is nullable for co-op team submissions.
- `submitted_by` records which authenticated user uploaded the image.
- `image_path` is relative to the `submissions` bucket.

## ai_judgements

Represents AI scoring output.

Fields:

- `id`
- `round_id`
- `model`
- `prompt_version`
- `status`
- `raw_response`
- `created_at`

## scores

Represents normalized game result.

Fields:

- `id`
- `round_id`
- `submission_id`
- `user_id`
- `team_score`
- `similarity_score`
- `winner`
- `created_at`

For co-op:

- `user_id` can be null,
- `team_score` is set,
- `winner` is null.

For versus:

- each player submission has a score,
- one score row can be marked winner.
