# UI Reference

This document records the current visual direction for the Flutter app.

## Reference Asset

Local reference:

```text
target_vibe_ui/target_vibe.png
```

Image size:

```text
1080x2400 px
```

## Observed Direction

The reference suggests:

- playful hand-drawn drawing-game identity,
- light cyan/sky-blue background,
- white text,
- large centered title,
- rounded cyan CTA buttons,
- simple top navigation labels,
- cat illustration as a friendly brand element,
- bottom gallery strip with user drawing thumbnails,
- soft, low-pressure casual game mood.

## UI Principles

Use the reference as vibe, not as a strict layout spec.

Keep:

- playful drawing-game feel,
- simple mobile-first screens,
- clear large actions,
- target/canvas as the main focus,
- gallery/result thumbnails where useful.

Avoid:

- cluttered menus,
- heavy dark UI,
- realistic/serious art-tool styling,
- dense dashboard layout,
- excessive gradients or decorative effects.

## Screen Implications

### Home

Should include:

- app title,
- player display name,
- create/start action,
- join friend/room action,
- gallery entry or recent drawings strip.

### Lobby

Should include:

- room code,
- two player slots,
- ready states,
- mode selector,
- start button for host.

### Drawing Round

Should prioritize:

- target image,
- canvas,
- timer,
- player cursors/colors,
- minimal controls.

### Result

Should show:

- target image,
- final drawing,
- AI score,
- winner for versus,
- next round action.

## Color Direction

Initial palette should stay close to the reference:

```text
background: light cyan / sky blue
primary action: saturated cyan
text: white or high-contrast dark where needed
accent: hand-drawn art colors from target/gallery assets
```

Keep accessibility in mind. White text on light cyan can be low contrast, so production screens may need darker text or stronger overlays in smaller labels.

