---
agent: agent
description: Fill remaining template placeholders after init-project.sh apply
tools: [edit/editFiles]
---

You are an expert project architect completing the setup of an existing project that has just
been updated with the latest agent configuration from project-template.

The `init-project.sh apply` script has already:
- Updated `AGENTS.md`, `.vscode/settings.json`, `global.instructions.md`
- Copied any missing instruction files and scaffolding files
- Applied mechanical substitutions (project name, stack, commands)

Your job: fill every remaining `{{PLACEHOLDER}}` with **real, specific content** that reflects
this project's actual state. Do not invent features or decisions the user has not confirmed.
Do **not** regenerate or overwrite files that already have real content.

---

## Step 1 — Read the project context

Read these files to understand the project before writing anything:
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/global.instructions.md`
- `.github/instructions/frontend.instructions.md` (if exists)
- `.github/instructions/backend.instructions.md` (if exists)

---

## Step 2 — Find remaining placeholders

Run:
```
grep -rn '{{' . --include='*.md' --exclude-dir=node_modules --exclude-dir=prompts --exclude='README.md'
```

If the output is empty, all placeholders are already filled — confirm this to the user and stop.

---

## Step 3 — Ask for missing context (only what you cannot infer)

Before writing, ask only for information that is not already in the project files.
Keep this to 2 questions maximum. Examples of what to ask:
- What is the current development phase?
- Is the app deployed anywhere (live URL)?

Do not ask about the stack, project name, or anything already visible in the files.

---

## Step 4 — Fill placeholders only

For each file containing `{{...}}`:

### `HANDOFF.md`
- `{{LIVE_URL}}` — deployment URL, or "not yet deployed"
- `{{CURRENT_PHASE}}` — the current phase number, inferred from what's actually implemented
  (check git history and code state) cross-referenced against `PROJECT.md`'s Roadmap section.
  `PROJECT.md` itself is the static plan and doesn't track live status — `HANDOFF.md` is the
  only place that does, so this is the value to keep current every session, not `PROJECT.md`.
- `{{LAST_SESSION_*}}` — what was actually done in the most recent work session (infer from git log or recent file dates if unclear)
- `{{CURRENT_STATE_*}}` — factual description of what is working now
- `{{CONSTRAINT_*}}` — any active constraints not already listed
- `{{NEXT_TASK}}` — the single most important next action

### `.github/copilot-instructions.md` (only if freshly copied — has `{{PHASE_MAX_PLUS_ONE}}`)
- `{{PHASE_MAX_PLUS_ONE}}` — the number of the current/next phase not yet started, based on
  `PROJECT.md`'s Roadmap section. Same value also fills `{{PHASE_MAX_PLUS_ONE}}` in `HANDOFF.md`.

### `PROJECT.md` (only if freshly copied — has `{{PROJECT_PURPOSE}}` etc.)
- `{{PROJECT_PURPOSE}}` — overview specific to the domain (not generic)
- `{{CURRENT_DIRECTION}}` — the strategic bet (target user, priorities, why this approach), not
  a status update — current status belongs in `HANDOFF.md`
- `{{PRINCIPLE_*}}`, `{{DATA_MODEL_DESCRIPTION}}`, `{{WORKFLOW_DESCRIPTION}}` — same as for a
  fresh project (see init.prompt.md's Architecture guidance) but reflecting what's actually
  already built
- `{{PHASE_*}}` — same as for a fresh project, but reflecting the actual current roadmap
- `{{PROJECT_CONSTRAINT_*}}` — permanent/structural constraints only; current/situational ones
  belong in `HANDOFF.md`'s Active Constraints instead

### `Decisions.md`
- Replace the example ADR block with 2–3 **real** architectural decisions already reflected in the codebase
- Format: **Decision**, **Context**, **Alternatives considered**, **Consequences**
- Base decisions on what is actually in the code — do not invent decisions

### `.github/instructions/*.instructions.md`
- Fill any remaining `{{...}}` in the instruction files with project-specific values
- Do not rewrite content that is already filled in

---

## Step 5 — Verify

Run again:
```
grep -rn '{{' . --include='*.md' --exclude-dir=node_modules --exclude-dir=prompts --exclude='README.md'
```

If placeholders remain, either fill them or mark them as intentionally deferred with a
`<!-- deferred: reason -->` comment on the same line.

---

## Constraints

- Do **not** modify `AGENTS.md` — it is template-managed
- Do **not** modify `global.instructions.md` — it is template-managed
- Do **not** regenerate `PROJECT.md` or any file that already has real content
- All generated content must be in English
