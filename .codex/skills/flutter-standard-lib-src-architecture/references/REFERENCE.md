# Standard lib/src Architecture Reference

Detailed examples for organizing Flutter apps using the standard `lib/src` structure.

## References

- [**Standard Folder Structure**](folder-structure.md) - Deep dive into `lib/src` directory nesting.
- [**Core vs Shared UI**](shared-core.md) - When to put code in `core`, `ui/widgets`, or keep it page-local.
- [**Modular Injection**](modular-injection.md) - How to wire dependencies per page module + global DI.

## **Quick Implementation Rule**

- Page-local code stays page-local:
  - Do not import `lib/src/ui/<page>/components/` from other pages.
  - Do not import `lib/src/ui/<page>/binding/` from other pages.
- If something is reused by multiple pages, move it to:
  - `lib/src/ui/widgets/` (UI)
  - `lib/src/core/` (infrastructure)
  - `lib/src/utils/` (constants/styles)
