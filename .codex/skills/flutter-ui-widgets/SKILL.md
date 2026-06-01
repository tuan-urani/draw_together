---
name: Flutter UI Widgets
description: Principles for maintainable UI components and project-specific widget standards.
---

# UI & Widgets

## **Priority: P1**

- **Design Tokens (STRICT)**:
  - Typography: 1–1 mapping from Figma. Use `AppStyles`; `height = lineHeight / fontSize`. Bundle exact font-family/weight.
  - Colors: Use `AppColors`; no hex/raw colors.
  - Spacing: Use `int_extensions` and `AppDimensions`; no free-form numbers.
  - Radius: Preserve Figma values; do not coerce to presets.
  - Icon: Sizes must follow Figma numeric tokens. Common 24×24; container per Figma (e.g., 40×40, 44×44). Do not assume fixed size. Reference via `AppAssets`.
  - Shadows: Normalize `BoxShadow` close to CSS box-shadow.
  - Backgrounds: Use `DecorationImage` + appropriate `BoxFit` (cover/contain).

## Quality & Safety
- **Async Gaps**: After `await`, check `if (context.mounted)` before using `BuildContext`.
- **Optimization**: Prefer `ColoredBox`/`Padding`/`DecoratedBox` over `Container` when only color/background/padding is needed.
- **Layout Tips**: Avoid `IntrinsicWidth/Height`; use `Stack` + `FractionallySizedBox` for overlays; `Flex` + int extensions (`n.height`/`n.width`) for spacing.
- **Large Lists**: Use `AppListView` for large lists.
- **SVG Color**: Do not use `colorFilter` if the SVG already matches Figma; only apply when design requires and the icon is flattened stroke→fill (see Assets Skill).

## Examples

### Async Gaps
```dart
onPressed: () async {
  await Future.delayed(const Duration(milliseconds: 100));
  if (!context.mounted) return;
  Navigator.pop(context);
}
```

### ColoredBox vs Container
```dart
// GOOD: only color + padding
ColoredBox(
  color: AppColors.white,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Content', style: AppStyles.bodyLarge()),
  ),
);
```

### Spacing with int extensions
```dart
Column(
  children: [
    Text('Title', style: AppStyles.h3),
    12.height, // vertical space
    Row(
      children: [
        Text('Left'),
        8.width, // horizontal space
        Text('Right'),
      ],
    ),
  ],
);
```

### SVG Color Handling
```dart
// No recolor (SVG already has Figma color)
SvgPicture.asset(AppAssets.iconsCalendarSvg);

// Recolor only for mono icons prepared with fill
SvgPicture.asset(AppAssets.iconsChevronSolidSvg, color: AppColors.primary);
```

### Overlay Layout
```dart
Stack(
  children: [
    Image.asset(AppAssets.bgContainerPng, fit: BoxFit.cover),
    const FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: 0.25,
      child: AppCardSection(child: Text('Bottom Sheet')),
    ),
  ],
);
```

## Customization & Defaults
- Every `App*` widget must provide parameters to override tokens per Figma: `size`, `radius`, `padding/margin`, `backgroundColor`, `textStyle`, `iconSize`, `constraints`.
- Defaults are fallbacks and must use tokens (`AppStyles`, `AppColors`, `AppDimensions`). Do not hardcode display values.
- Example: `AppButtonBar(size: 40, radius: 14, iconSize: 24, backgroundColor: AppColors.white)`; if Figma differs, pass matching parameters.
- When overriding numeric tokens, preserve Figma values; do not round or force presets.

- **Naming Convention**:
  - Shared widgets in `lib/src/ui/widgets` MUST use the `App` prefix (e.g., `AppInput`, `AppButton`, `AppCardSection`).
  - Use these pre-built `App*` widgets instead of raw Material/Cupertino widgets to ensure consistency.
- **Styling (Colors & Typography)**:
  - **Source of Truth**: Always use `AppColors` and `AppStyles` from `lib/src/utils/`.
  - **Forbidden**: Do NOT hardcode colors (e.g., `Colors.red`, `Color(0xFF...)`) or text styles.
  - **Usage**: `AppColors.primary`, `AppStyles.bodyMedium`.
- **State**: 
  - Use `StatelessWidget` by default.
  - Use `StatefulWidget` for self-contained UI logic (e.g., `AppInput` handling focus/password visibility internally) to keep parent Pages clean.
- **Composition**: Extract UI into small, atomic `const` widgets.
- **Theming**: Use `Theme.of(context)` where applicable, but prefer `AppColors`/`AppStyles` for specific design system tokens.
- **Layout**: Use `Flex` + int extensions (`n.height`/`n.width`).
- **Specialized**:
  - `SelectionArea`: For multi-widget text selection.
  - `InteractiveViewer`: For zoom/pan.
  - `ListWheelScrollView`: For pickers.
  - `IntrinsicWidth/Height`: Avoid unless strictly required.
- **Large Lists**: Always use `ListView.builder` (or `AppListView` if available).

## **Common System Widgets**

Refer to `lib/src/ui/widgets/` for the source of truth. Common examples:

- **Inputs**: `AppInput` (handles focus, labels, password visibility).
- **Buttons**: `AppButtonBar` (standard back button; container/radius/icon size per Figma, e.g., 40×40, radius 14, icon 24), `AppButton` (primary actions).
- **Text**: `AppTextGradient` (gradient text).
- **Containers**: `AppCardSection`, `AppContainerExpand`.

```dart
// Example of using project-standard widgets and styles
class WorkDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Use AppColors
      appBar: AppBar(
        leading: AppButtonBar(), // Standard back button
        title: AppTextGradient(  // Standard styled text
          text: 'Detail',
          gradient: AppColors.primaryTextGradient(),
        ),
      ),
      body: Column(
        children: [
          Text('Welcome', style: AppStyles.h3), // Use AppStyles
          AppInput(label: 'Email'), 
          AppInput(label: 'Password', isPassword: true),
        ],
      ),
    );
  }
}
```

## Related Topics

performance | testing
