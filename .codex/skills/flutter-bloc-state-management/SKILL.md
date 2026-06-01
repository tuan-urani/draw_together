---
name: Flutter BLoC State Management
description: Standards for predictable state management using flutter_bloc and equatable. Invoke when implementing BLoCs/Cubits, Events, States, or refactoring page widgets into components.
---

# BLoC State Management

## **Priority: P0 (CRITICAL)**

Predictable state management separating business logic from UI using `flutter_bloc` and `equatable`.

## Structure

```text
presentation/blocs/
├── auth/
│   ├── auth_bloc.dart
│   ├── auth_event.dart # (Equatable)
│   └── auth_state.dart # (Equatable)
```

## Implementation Guidelines

- **States & Events**: Use `equatable` for value equality (stable rebuilds, reliable tests).
- **State Strategy**:
  - **Phase-based State**: Use a `Status` enum (idle/loading/success/failure) for exclusive UI phases.
  - **Property-based State**: Use explicit properties (e.g. `isSubmitting`, `errorMessage`, `data`) for forms and complex screens.
- **Copy/Update**: Provide `copyWith` manually when needed (keep it small and explicit).
- **Error Handling**: Use `Failure` objects; avoid throwing exceptions.
- **Async Data**: Use `emit.forEach` or `emit.onEach` for streams.
- **Concurrency**: Use `transformer` (restartable, droppable) for event debouncing.
- **Testing**: Use `blocTest` for state transition verification.
- **Injection**: Register BLoCs as `@injectable` (Factory).

## Anti-Patterns

- **No Manual Emit**: Do not call `emit()` inside `Future.then`; always use `await` or `emit.forEach`.
- **No UI Logic**: Do not perform calculations or data formatting inside `BlocBuilder`.
- **No Cross-Bloc Reference**: Do not pass a BLoC instance into another BLoC; use streams or the UI layer to coordinate.

## Reference & Examples

For full BLoC/Cubit implementations and concurrency patterns:
See [references/REFERENCE.md](references/REFERENCE.md).

## Related Topics

feature-based-clean-architecture | dependency-injection