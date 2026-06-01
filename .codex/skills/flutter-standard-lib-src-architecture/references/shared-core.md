# Core vs Shared UI

Use this rule to decide where code should live in a standard `lib/src` codebase.

## Core (`lib/src/core/`)

Put code here when it is:
- Cross-cutting infrastructure (router, theme, localization, networking base, logging)
- App-wide and not tied to any specific page
- Safe to be imported by any page module

## Shared UI (`lib/src/ui/widgets/`)

Put code here when it is:
- UI building blocks reused by multiple pages (buttons, form fields, empty states)
- Design system widgets (app button, app text, skeletons)
- Not “infrastructure”, but still reusable UI

## Page-local (`lib/src/ui/<page>/...`)

Default choice. Keep code inside the feature when it is:
- Only used by one page (UI components, interactor logic, page validators/helpers)
- Tightly coupled to that page flow

## Rule of Thumb

- If only one page uses it → keep it in that page.
- If many pages use it and it’s infrastructure-like → `core/`.
- If many pages use it and it’s UI → `ui/widgets/`.
