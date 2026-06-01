---
name: Flutter Assets Management
description: Standards for asset naming, organization, and synchronization with design tools.
---

# Assets Management

## **Priority: P1 (HIGH)**

Strict conventions for asset filenames to ensure traceability between Design (Figma) and Code.

## Naming Convention

### **CRITICAL RULE: Figma Matching**
- **Filenames MUST match the layer/export name in Figma.**
- **Format**: `snake_case` (lowercase with underscores).
- **Prohibited**: Random strings, UUIDs, or generic names (e.g., `image_1.png`, `552ecefb...png`).

### **Temporary Naming for Per-Screen Icons**
- **Rule**: If a name already exists, append an incrementing numeric suffix: `_2`, `_3`, ...
- **Examples**:
  - `visit_record_calendar.svg` → `visit_record_calendar_2.svg` (if already present)
  - `customer_detail_back.svg` → `customer_detail_back_2.svg` (if already present)
- **AppAssets**: Constant should match the filename; e.g. `iconsVisitRecordCalendar2Svg` → `'assets/images/icons/visit_record_calendar_2.svg'`.
- **Note**: Do not overwrite existing files; always create the next numeric suffix.

### **Examples**
| Bad (Reject) | Good (Accept) |
| :--- | :--- |
| `552ecefb-d09c.png` | `user_avatar_placeholder.png` |
| `Group 123.svg` | `ic_notification_badge.svg` |
| `IMG_2024.jpg` | `onboarding_background.jpg` |

## Organization

```text
assets/
├── images/ # Illustrations, photos, backgrounds
├── icons/ # Vector icons (SVG)
└── fonts/ # Custom font files
```

## Workflow
1.  **Rename in Figma**: Before exporting, rename the layer in Figma to a valid `snake_case` name.
2.  **Export**: Export the asset with the correct name.
3.  **Import**: Place in the corresponding `assets/` subdirectory.
4.  **Verification**: Do not commit random filenames.

## Icon Consistency & Deduplication
- **Goal**: Avoid cross-screen reuse during the current phase; keep icons per-screen only.
- **Rule**:
  - **Single Source**: Each icon has one SVG file and one constant in `AppAssets`.
  - **No Duplicates**: Do not add different filenames with identical graphics/content.
- **Dedup Workflow**:
  1. Normalize SVG: remove metadata, pretty-print, sort attributes, flatten stroke→fill, remove masks/filters if unnecessary.
  2. Compute a content hash (SHA-256) after normalization; compare within `assets/images/icons/`.
  3. If hashes match, consolidate to a single file and update all code references to the shared `AppAssets` constant.
  4. Variants (color/size/outline vs solid) must be clearly named and treated as different when geometry or semantics differ (e.g., `icons_chevron_solid.svg` vs `icons_chevron_outline.svg`).
- **CI/Pre-commit (Recommended)**:
  - Add a duplicate check step: normalize + hash for `assets/images/icons/`.
  - Fail build on duplicates; print a list of files to consolidate.
- **Usage Policy**:
  - Always use `SvgPicture.asset(AppAssets.some_icon)`; do not reference raw paths.
  - For recolor, use a fill/tint-friendly version (stroke flattened to fill).

## Temporary Policy: Per-Screen Icons Only
- **Scope**: Current phase.
- **Rule**: Each screen adds its own icons only; do not reuse icons across other screens.
- **Naming Suggestion**: Name by screen context (e.g., `customer_detail_back.svg`, `visit_record_calendar.svg`) to avoid confusion.
- **Note**: When moving to project-wide reuse, we will consolidate using the dedup policy above.

## SVG Color Handling
- **Default**: Do not apply `color`/`colorFilter` if the SVG already has the correct Figma colors.
- **Allowed**: Only use `color`/`colorFilter` when explicit recolor is required (e.g., active/inactive states) and the icon is prepared with fill (no stroke).
- **Prohibited**: Avoid applying `colorFilter` broadly on multi-color SVGs; this causes color deviations unless explicitly specified by design.
## Related Topics

idiomatic-flutter | feature-based-clean-architecture
