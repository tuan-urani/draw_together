# Modular Injection (Per Page Module)

This describes how to keep dependency wiring modular in the standard `lib/src` architecture.

## Goal

- Each page module owns its own bindings (wiring for that module).
- App composition wires global dependencies in `lib/src/di/`.

## Suggested Structure

```text
lib/src/
├── di/
│   ├── di.dart
│   └── modules/
└── ui/
    └── <page>/
        └── binding/
            └── <page>_binding.dart
```

## Rules

- Global DI registers shared services (clients, storage, repositories) in `di/modules/`.
- Page binding registers only page-scoped objects (interactors/controllers) for that page.
- UI code must not register dependencies outside `binding/` and `di/`.
