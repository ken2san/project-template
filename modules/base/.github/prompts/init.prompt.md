---
agent: agent
description: Fill all remaining template placeholders with AI-generated project content
tools: [edit/editFiles]
---

You are an expert project architect finishing the initialization of a new software project.

The bash script has already handled: file structure, git init, and basic substitutions
(project name, date, stack, dev/test commands).

Your job: replace every remaining `{{PLACEHOLDER}}` with **real, specific, intelligent content**
tailored to this project. Do not use generic filler like "Feature 1" or "Rule 1".

---

## Step 1 — Read the project context

Read these files to understand the project:
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/global.instructions.md`

---

## Step 2 — Identify remaining placeholders

Run:
```
grep -rn '{{' . --include='*.md' --exclude-dir=node_modules --exclude-dir=prompts --exclude='README.md'
```

---

## Step 3 — Ask for any missing context (only what you need)

Before generating, ask the user for any information that cannot be inferred from the project name/description/stack:
- What is the core domain or problem this project solves?
- Any known constraints (solo dev, deadline, specific integrations)?
- Are there any decisions already made (auth strategy, DB choice, etc.)?

Do not ask for information that is already in the files. Keep this to 2–3 targeted questions maximum.

---

## Step 4 — Generate and write content

### `PROJECT.md`
- Purpose: write an overview specific to the domain (not generic)
- Current Direction: the strategic bet — target user, priorities, why this approach. Not
  a status update; if there's nothing strategic to say yet, a short "no pivots yet, building
  toward Phase 1" is fine
- Architecture > Principles: write 3–5 core principles that are actually relevant (e.g. "All AI
  responses must be validated against source data before display")
- Architecture > Data Model: include a data model sketch if applicable
- Architecture > Workflow: include a workflow description
- Roadmap: write 2–3 concrete phases with realistic names, goals, and 3–5 scope items each
  - Phase 1 should be the smallest shippable slice (not "setup")
  - Phase scope must reflect the actual stack and domain
  - `{{PHASE_MAX_PLUS_ONE}}` (in `.github/copilot-instructions.md` and `HANDOFF.md`) — set this to
    the number of the first phase you wrote that hasn't started yet (usually `2`, or `1` if even
    Phase 1 is still just planned). This can't be decided until the phases above are written, which
    is why it isn't filled by the bash script.
- Constraints: permanent/structural constraints only (e.g. "no new dependencies without
  approval"). Do not put current/situational constraints here — those belong in `HANDOFF.md`'s
  Active Constraints instead.

### `Decisions.md`
- Write 2–3 initial ADRs for the tech choices already made
- Format: **Decision**, **Why**, **Trade-offs accepted**
- Decisions must be specific (e.g. "Use Zustand over Redux: lower boilerplate for solo dev, acceptable for <10 stores")

### `HANDOFF.md`
- Fill in current state: Phase 1 not started, no sessions yet
- `{{CURRENT_PHASE}}` = `1` — this is the only place that tracks current phase; `PROJECT.md`'s
  Roadmap section is the static plan and is never updated with live status, so keep this field
  (not PROJECT.md) current every session
- `{{NEXT_TASK}}` = the single most important first task to start

### `.github/copilot-instructions.md`
- Fill in `{{CODE_RULE_*}}` with 3 project-specific rules (not generic)
- Fill in `{{ENTRY_POINT}}` and `{{STATE_LOCATION}}` based on the stack

### `.github/instructions/frontend.instructions.md` (if exists)
- Fill in `{{MODAL_RULE}}` and `{{DIRECTORY_RULE}}` based on the project structure

### `.github/instructions/backend.instructions.md` (if exists)
- Fill in `{{BACKEND_STATUS}}`, `{{BACKEND_PHASE}}`, `{{BACKEND_STACK_*}}`, `{{MOCK_DATA_LOCATION}}`

### `.github/instructions/infra.instructions.md` (if exists)
- Fill in `{{INFRA_STACK}}` with the planned infrastructure (hosting, CI, CDN, etc.)
- Fill in `{{INFRA_RULE_1}}` and `{{INFRA_RULE_2}}` with deployment constraints specific to this project

### `.github/instructions/testing.instructions.md` (if exists)
- Fill in `{{TESTING_APPROACH}}` with the actual testing strategy (unit/integration/e2e split, coverage expectations)
- Fill in `{{TESTING_RULE_1}}` with one project-specific testing rule (e.g. required test types for new endpoints, snapshot policy)

---

## Step 5 — Verify

After writing all files, run:
```
grep -rn '{{' . --include='*.md' --exclude-dir=node_modules --exclude-dir=prompts --exclude='README.md'
```

If any placeholders remain, either fill them in or explicitly flag them as "intentionally deferred" with a comment.

---

## Constraints

- All generated content must be in English
- Do not invent features or decisions the user has not confirmed
- Do not modify `AGENTS.md` — it is already complete
- Do not modify `.github/instructions/global.instructions.md` — verification commands already filled in by init script
- Keep file structure intact; only replace placeholder content
