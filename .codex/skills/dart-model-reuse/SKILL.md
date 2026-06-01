---
name: "Dart Model Reuse & Evolution"
description: "Guides model reuse/composition and safe extension. Invoke when adding/updating UI/domain models or preventing duplicate screen-specific models."
---

# Dart Model Reuse & Evolution

## Goal
Prevent duplicate models across features and keep UI data strongly typed. Reuse existing models where possible; evolve them safely when needed.

## Where Models Live
- Request: `lib/src/core/model/request/`
- Response: `lib/src/core/model/response/`
- UI/Domain: `lib/src/core/model/`
- Demo/Mock Data: `lib/src/utils/app_demo_data.dart` (only)

## Reuse-first Policy
- Before adding a new model:
  - Check the Model Registry: `spec/model-registry.md` for existing shared models and their purposes.
  - Also check `lib/src/core/model/` for an existing model with overlapping fields.
  - Prefer reuse if ≥70% fields overlap and semantics match.
  - If needed, add optional fields to the existing model (keep backward compatibility).
  - If semantics differ, compose: nest existing model rather than duplicating fields.

## Evolution Rules
- Additive changes only on active branches (append fields, keep constructors compatible).
- Use optional fields (`Type?`) and sensible defaults to avoid breaking code.
- Keep `fromJson`/`toJson` aligned when applicable.

## Naming & Ownership
- Names must reflect domain, not screens (`CustomerProjectInfo`, not `CustomerProjectListItem`).
- Shared models are owned at `lib/src/core/model/`; screens cannot fork them.

## Checklist (Mandatory)
- Reuse considered?
- Composition preferred over duplication?
- Demo data added to `app_demo_data.dart`, not UI?
- Request/Response models separated?
