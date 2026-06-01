---
alwaysApply: false
---
# CI/CD Rule - Commit, Push, Pull Request Gate

## 1. Trigger
Apply this rule after completing any feature that follows:
- `ui.md`
- `integration-api.md`

This is the required "done" flow before feature handoff.

## 2. Required Flow
1. Verify quality gates:
   - `fvm flutter analyze`
   - Run related tests for the changed scope (unit/widget/integration when available).
2. Ensure spec/docs are updated if behavior changed.
3. Ask user explicitly: `Do you want me to commit now? (yes/no)`
4. If answer is `yes`, create commit with clear scope and summary.
5. Ask user explicitly: `Do you want me to push now? (yes/no)`
6. If answer is `yes`, push branch to remote.
7. Ask user explicitly: `Do you want me to create PR now? (yes/no)`
8. If answer is `yes`, create PR with mandatory template sections.
9. If answer is `no` at any step, stop at that step and return current status.

If any step is skipped, feature is not considered complete.

## 3. Git Commands (Reference)
```bash
git checkout -b feat/<feature-name>
git add -A
git commit -m "feat(<scope>): <short summary>"
git push -u origin HEAD
```

## 4. PR Body Policy (Mandatory)
PR must follow `.github/pull_request_template.md` and include all sections:
- Issue/Explanation (with `Feature` and `UI` lines).
- Checklist (all required items checked `[x]`).
- Notes for reviewer.
- Screenshots section (`No UI` or actual screenshots/evidence).
- Paired with.

## 5. Merge Gate
- CI workflow `PR Template Gate` validates PR body.
- If required section/checklist is missing, CI fails.
- Branch protection must require this check before merge.

## 6. Agent Behavior
- After finishing UI/API tasks, agent must ask in order: commit -> push -> create PR.
- Agent executes only steps explicitly confirmed by user (`yes`).
- If user confirms all steps, agent returns PR URL as final output.
- If user declines at any step, agent stops and returns repository status.
