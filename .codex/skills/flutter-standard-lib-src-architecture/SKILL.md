---
name: Flutter Standard lib/src Architecture
description: Standard folder structure and component extraction rules for Flutter apps under lib/src/. Invoke when scaffolding a new page, feature module, or shared widget.
---

# Standard lib/src Architecture

## **Priority: P0 (CRITICAL)**

Standard folder architecture for Flutter apps organized under `lib/src/`.

## Structure

```text
lib/
└── src/
    ├── api/
    ├── core/
    │   ├── model/
    │   │   ├── request/   # API Request Bodies (DTOs)
    │   │   └── response/  # API Response Objects (DTOs)
    ├── di/
    ├── enums/
    ├── extensions/
    ├── helper/
    ├── locale/
    ├── ui/
    │   ├── <page_name>/
    │   │   ├── binding/
    │   │   ├── components/
    │   │   └── interactor/
    │   └── widgets/
    └── utils/
```

## Implementation Guidelines

- **Page Modules**: Each screen/flow is a module under `lib/src/ui/<page_name>/`.
- **Page Naming**: Page file MUST be named `<page_name>_page.dart` (e.g., `page_a_page.dart`).
- **Folder Roles**:
  - `ui/<page>/binding/`: routing + dependency wiring for that page module.
  - `ui/<page>/interactor/`: state + business logic for that page module.
  - `ui/<page>/components/`: page-specific UI blocks.
  - `ui/widgets/`: shared UI widgets reused across pages.
  - `di/`: global dependency registration (app-level modules).
  - `api/`: networking clients, repositories/services (no UI).
  - `core/model/`: **Data Transfer Objects (DTOs)**.
    - `request/`: Models sent TO the server (e.g., `LoginRequest`).
    - `response/`: Models received FROM the server (e.g., `LoginResponse`).
    - *Note*: Shared domain entities can sit directly in `core/model/`.
  - `core/`: cross-cutting infrastructure (router, theme, localization plumbing, error mapping, etc.).
  - `utils/`: app-wide constants/styles/helpers that are safe to import anywhere.

- **Dependency Rule**:
  - `components`/`widgets`/page UI → may depend on `interactor`.
  - `interactor` → may depend on `api`, `core`, and `utils`.
  - `api`/`core` → must not depend on `ui`.
  - `binding` is the only place inside a page module allowed to import `di`.

## UI: Component Extraction (P0)

Any **visually meaningful UI block** must be extracted into a component file.

### What counts as “visually meaningful”

- A block users can visually identify as a unit (Header, SearchBar, Card, Section, BottomSheet content).
- A repeated layout (e.g., list item / card appears 2+ times).
- A block with its own spacing/background/border/gradient.
- A block that would make the page widget harder to scan if kept inline.

### Folder convention

```text
lib/src/ui/<page_name>/
├── binding/
├── interactor/
├── components/
└── <page_name>_page.dart
```

Shared components live in:

```text
lib/src/ui/widgets/
```

## Reference & Examples

For page module blueprints and DI guidance:
See [references/REFERENCE.md](references/REFERENCE.md).

## Related Topics

dependency-injection | go-router-navigation | getx-localization | error-handling
