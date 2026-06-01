---
alwaysApply: false
---
# API Integration Rules & Workflow

## 1. Goal
Standardize how to integrate backend APIs into this project using the current architecture:
- Transport: `lib/src/api/api.dart`
- Endpoint mapping: `lib/src/api/api_url.dart`
- Flavor config: `lib/src/utils/app_api_config.dart`
- Persistence/token: `lib/src/utils/app_shared.dart`
- State/UI: `lib/src/ui/**` with `Bloc + PageState`

The rule is designed to prevent common violations: hardcoded URLs, mixed model layers, missing flavor handling, and inconsistent error behavior.

## 1.1 Skill References (Required)
When executing this rule, apply these skills together:
- Architecture: [flutter-standard-lib-src-architecture](../skills/flutter-standard-lib-src-architecture/SKILL.md)
- Dependency flow: [flutter-standard-lib-src-architecture-dependency-rules](../skills/flutter-standard-lib-src-architecture-dependency-rules/SKILL.md)
- State management: [flutter-bloc-state-management](../skills/flutter-bloc-state-management/SKILL.md)
- DI: [flutter-dependency-injection-injectable](../skills/flutter-dependency-injection-injectable/SKILL.md)
- Error handling: [flutter-error-handling](../skills/flutter-error-handling/SKILL.md)
- Localization: [getx-localization-standard](../skills/getx-localization-standard/SKILL.md)
- Model reuse: [dart-model-reuse](../skills/dart-model-reuse/SKILL.md)

## 2. Definition of Ready (P1 - Required Before Coding)
API integration must not start until all items are clear:
- Feature scope (function flow) is explicit.
- API contract is explicit: method, path, request body/query, response schema, error schema.
- Database-side behavior is understood from backend contract (field semantics, nullable rules, pagination/sort semantics).
- Target flavor is explicit for testing (`staging` or `prod`).

If any item is missing, stop implementation and request contract clarification first.

## 3. Project Conventions (Current Repo)

### A. Endpoint Source of Truth
- Base URL must come from `AppApiConfig.baseApiUrl`.
- Endpoint paths must be defined in `api_url.dart` interfaces (`IAuthApiUrl`, future groups).
- Do not hardcode endpoint strings inside bloc/page/widget.

### B. Transport Layer
- Reuse `Api.request()` in `lib/src/api/api.dart`.
- Use `useIDToken: true` by default for authenticated APIs.
- Use `useIDToken: false` only for anonymous APIs (login/register/...).
- Do not duplicate Dio setup in feature code.

### C. Model Layer Separation
- Request models: `lib/src/core/model/request/`
- Response models: `lib/src/core/model/response/`
- UI/domain-only models: `lib/src/core/model/`
- Never pass raw `Map<String, dynamic>` across UI layers for non-trivial APIs.
- Reuse-first: check existing models before creating new ones.
- Required API fields must not silently fallback to fake defaults in `fromJson`.
- Nullable/non-nullable and enum values must match backend contract explicitly.
- Date/number parsing must be guarded (safe parse/cast), not optimistic cast.

### D. Repository Boundary
- All remote calls must be wrapped by repository classes in `lib/src/core/repository/`.
- Bloc/Controller must call repository methods, not `Api.request()` directly.
- Repository owns request/response mapping and token persistence side effects when needed.
- New repository methods should prefer `Result<T, E>` style returns for predictable error flow.

### E. State/Error Handling
- Use `PageState` (`initial/loading/failure/success`) for request lifecycle.
- User-facing messages must be localized via `LocaleKey.*.tr` (no hardcoded text in bloc).
- Network/server errors should be normalized in repository before bubbling to UI state.
- Token invalid flow should be handled consistently with existing dialog flow (`showDialogErrorToken`).
- Do not throw raw exceptions into UI layer for new integrations; map to typed error/result first.

## 4. Standard Workflow for New API Integration

### Step 1: Confirm Contract + Flavor
- Confirm endpoint contract and sample payloads.
- Confirm test flavor command:
  - `fvm flutter run --flavor staging --dart-define=FLAVOR=staging`
  - `fvm flutter run --flavor prod --dart-define=FLAVOR=prod`

### Step 2: Add Endpoint Mapping
- Extend `api_url.dart` by feature group interface.
- Keep path builders centralized (no duplicated string fragments).
- Follow structure constraints from [flutter-standard-lib-src-architecture](../skills/flutter-standard-lib-src-architecture/SKILL.md).

### Step 3: Create Models
- Add request/response models in correct folders.
- Prefer typed fields and safe nullability.
- Add parser methods (`fromJson/toJson`) consistently.
- Apply reuse/evolution checklist from [dart-model-reuse](../skills/dart-model-reuse/SKILL.md).
- Validate model correctness against contract:
  - Required/optional fields match schema.
  - Enum/status values are constrained.
  - No hidden fallback defaults for required fields.
  - Update `spec/model-registry.md` for any model additions/changes.

### Step 4: Implement Repository Method
- Repository extends/reuses `Api`.
- Use endpoint from `apiUrl.<group>`.
- Map response to typed model.
- Handle auth token persistence/refresh responsibilities in repository only.
- Follow mapping strategy from [flutter-error-handling](../skills/flutter-error-handling/SKILL.md).

### Step 5: Wire DI
- Register repository through binding/module with `Get` injection.
- UI layer resolves repository through bloc/controller, not directly in widgets.
- Follow module boundaries from [flutter-dependency-injection-injectable](../skills/flutter-dependency-injection-injectable/SKILL.md).

### Step 6: Integrate into Bloc
- Add event(s): trigger API use case.
- Emit `PageState.loading` before call.
- On success: emit `PageState.success` with typed data.
- On failure: emit `PageState.failure` with localized error key/message.
- Keep event/state modeling aligned with [flutter-bloc-state-management](../skills/flutter-bloc-state-management/SKILL.md).

### Step 7: UI Consumption
- UI reads bloc state and renders loading/error/success.
- No API parsing logic in widget tree.
- All strings shown from API errors must pass localization policy in [getx-localization-standard](../skills/getx-localization-standard/SKILL.md).
- UI should consume repository-mapped typed models only (not raw response JSON/map).

## 5. Minimal Reference Pattern

```dart
class FeatureRepository extends Api {
  final IFeatureApiUrl _url;
  FeatureRepository(this._url);

  Future<FeatureResponse> fetchFeature(FeatureRequest req) async {
    final res = await request<Map<String, dynamic>>(
      _url.fetchFeature,
      Method.post,
      body: req.toJson(),
      useIDToken: true,
    );
    return FeatureResponse.fromJson(res.data ?? <String, dynamic>{});
  }
}
```

## 6. Anti-Patterns (Do Not)
- Do not call `Dio()` directly inside bloc/controller.
- Do not put endpoint string literals in UI layer.
- Do not mix request/response classes in one generic model file.
- Do not hardcode user-facing error strings.
- Do not bypass flavor config by using fixed base URL.

## 7. Verification Checklist Before PR
- [ ] Endpoint added in `api_url.dart` and consumed from repository only.
- [ ] Request/response models are separated and typed.
- [ ] Model correctness validated against API contract (required/nullable/enum/date/number).
- [ ] No hidden fallback defaults for required contract fields in `fromJson`.
- [ ] UI/Bloc consumes typed models only (no raw JSON/map parsing).
- [ ] Bloc uses `PageState` lifecycle correctly.
- [ ] All displayed text/error is localized via `LocaleKey`.
- [ ] Flavor run verified at least on staging command.
- [ ] `fvm flutter analyze` passes.
- [ ] Existing behavior (auth/token/toast/dialog flow) is not regressed.

## 8. Prompt Template for AI
Use this when asking AI to implement integration:

> Integrate API for `<feature>` using project rule `integration-api.md`.
> Contract: `<method/path/request/response/errors>`.
> Use `api_url.dart` + repository layer + typed models + bloc `PageState`.
> No hardcoded endpoint/message. Localize all user text.
> Validate with `analyze` and staging flavor run command.
