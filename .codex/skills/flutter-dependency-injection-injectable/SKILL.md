---
name: Flutter Dependency Injection (GetX)
description: Standards for dependency injection using GetX Bindings and Service Locator.
---

# Dependency Injection (GetX)

## **Priority: P1 (HIGH)**

This project uses **GetX** for dependency injection.
Dependencies are managed via `Bindings` and the global `Get` service locator.

## Structure

```text
lib/src/
├── di/
│   ├── di_graph_setup.dart      # Global/Core dependencies (Singletons)
│   ├── register_core_module.dart
│   └── register_manager_module.dart
└── ui/
    └── <feature>/
        └── binding/
            └── <feature>_binding.dart # Feature-specific dependencies
```

## Implementation Guidelines

### 1. Global Dependencies (Singletons)
Register core services (API clients, storage, managers) in `lib/src/di/di_graph_setup.dart`.

```dart
// register_core_module.dart
Future<void> _registerCoreModule() async {
  Get.put(SharedPreferenceHelper(), permanent: true);
  Get.lazyPut(() => AuthRepository(Get.find(), Get.find()), fenix: true);
}
```

### 2. Feature Dependencies (Bindings)
Use `Bindings` to lazy-load controllers/BLoCs when a page is entered.

```dart
// lib/src/ui/auth/login/binding/login_binding.dart
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Register BLoC/Controller
    Get.lazyPut<LoginBloc>(() => LoginBloc());
  }
}
```

### 3. Injection Types
- **`Get.put()`**: Immediate initialization. Use for critical core services.
- **`Get.lazyPut()`**: Lazy initialization. Created only when used. Best for Repositories/BLoCs.
- **`Get.find<T>()`**: Inject a dependency.

### 4. Scoping
- Bindings attached to `GetPage` in `AppPages` are automatically disposed when the route is removed from the stack (unless `fenix: true` is used).

## Reference & Examples

See [references/modules.md](references/modules.md).
