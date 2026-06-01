---
name: Flutter Error Handling
description: Typed error handling with Result<T> and Failure models using Dio. Invoke when implementing repository error flow, mapping API errors, or handling exceptions in BLoC.
---

# Error Handling

## **Priority: P1 (HIGH)**

Standardized typed error handling using `Result<T>` and `Failure` models. The project uses **Dio** for networking, not `http`.

## Implementation Guidelines

- **Networking**: Use `Dio` (configured in `lib/src/api/api.dart`).
- **Result Pattern**: Return `Result<T>` from repositories. No exceptions in UI/BLoC.
- **Failures**: Define domain-specific failures as plain immutable classes.
- **Error Mapping**:
  - `Api` class (in `lib/src/api/api.dart`) handles low-level `DioException`.
  - It extracts error messages from server response (e.g., `response.data['errors']` or `response.data['message']`).
  - It handles UI feedback (e.g., `showErrorToast`) automatically for API errors.
  - Repositories should catch exceptions rethrown by `Api` and map them to `Failure`.

## Reference & Examples

For Failure definitions and API error mapping:
See [references/REFERENCE.md](references/REFERENCE.md).

## Related Topics

layer-based-clean-architecture | bloc-state-management
