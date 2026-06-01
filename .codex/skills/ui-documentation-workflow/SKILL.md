---
name: "UI Documentation Workflow"
description: "Generates and maintains spec/ui-workflow.md for UI flows. Invoke when creating/modifying features or when asked to update documentation."
---

# AI Documentation Workflow (UI)

## Goal
Automatically generate and maintain `spec/ui-workflow.md` describing business logic and user flows, so devs/AI can understand features quickly.

## Trigger (When to Invoke)
- A new UI feature is created
- An existing UI feature is significantly modified
- User explicitly requests to update documentation

## Workflow
1) Analyze the Feature
- Read for EACH feature:
  - `*_page.dart`: UI elements and interactions
  - `interactor/*_bloc.dart` (or Controller): logic, state changes, API calls
  - `binding/*_binding.dart`: dependencies
  - `locale_key.dart`: terminology

2) Write Documentation
- Append or update a section in `spec/ui-workflow.md` with:
```
## [Feature Name]
**Path**: lib/src/ui/<feature>

### 1. Description
Goal: ...
Features:
- ...

### 2. UI Structure
- Screen: <Page>
- Components: ...

### 3. User Flow & Logic
1) ...
2) ...

### 4. Key Dependencies
- ...

### 5. Notes & Known Issues (Optional)
- Tech Debt: ...
- UX Issues: ...
- Todo: ...
```

3) Verification
- Ensure documented flow matches code
- Keep “User Flow” business-friendly; avoid low-level jargon
- Note raw strings, complex logic, or potential issues
