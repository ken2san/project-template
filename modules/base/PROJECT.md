# {{PROJECT_NAME}} — Project

_Last updated: {{DATE}}_

> This file is the permanent reference: what this project is, why, and how it's built.
> For what's happening right now (current phase, last session's work, what's broken,
> what's next), see `HANDOFF.md` instead — never duplicate that here.
>
> If this no longer matches the actual implementation, don't patch around it. Do a full
> rewrite so the whole document is internally consistent again, or mark it
> `> ⚠️ STALE as of {{DATE}}: <what changed>` at the top — never leave an old description
> sitting next to a new one that contradicts it for someone else to discover later.

---

## Purpose

{{PROJECT_PURPOSE}}

---

## Current Direction

{{CURRENT_DIRECTION}}

> This is the strategic bet — target user, priorities, why this approach — not "what
> phase we're on" or "what's currently broken." That belongs in `HANDOFF.md`.

---

## Architecture

### Principles

- {{PRINCIPLE_1}}
- {{PRINCIPLE_2}}
- {{PRINCIPLE_3}}

### Data Model

{{DATA_MODEL_DESCRIPTION}}

### Workflow

{{WORKFLOW_DESCRIPTION}}

---

## Roadmap

### Phase 1 — {{PHASE_1_NAME}}

**Goal:** {{PHASE_1_GOAL}}

**Scope:**
- {{PHASE_1_SCOPE_1}}
- {{PHASE_1_SCOPE_2}}

### Phase 2 — {{PHASE_2_NAME}}

**Goal:** {{PHASE_2_GOAL}}

**Scope:**
- {{PHASE_2_SCOPE_1}}
- {{PHASE_2_SCOPE_2}}

> This is the static plan — it isn't updated every session. For current phase and what's
> actually done, see `HANDOFF.md`, which is.

---

## Constraints

- {{PROJECT_CONSTRAINT_1}}
- {{PROJECT_CONSTRAINT_2}}

> Permanent/structural constraints only (e.g. "no new dependencies without approval").
> Current, situational constraints (e.g. "don't touch X until bug Y is fixed") belong in
> `HANDOFF.md`'s Active Constraints instead.
