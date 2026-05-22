# {{PROJECT_NAME}} — GitHub Copilot Workspace Instructions

_Last updated: {{DATE}}_

---

## Project

{{PROJECT_NAME}} is {{PROJECT_DESCRIPTION}}.
Stack: {{STACK}}. Entry: `{{ENTRY_POINT}}`. State: {{STATE_LOCATION}}.

## Before Any Task

- Read `Roadmap.md` to understand current phase, target user, and scope boundaries.
- Do not implement Phase {{PHASE_MAX_PLUS_ONE}} or later features (see `Roadmap.md`) without explicit user instruction.

## Project-Specific Code Rules

- {{CODE_RULE_1}}
- {{CODE_RULE_2}}
- {{CODE_RULE_3}}

## Agent Files

Role-specific rules are in `.github/agents/`:
- `global.agent.md` — project-wide overrides to `AGENTS.md`
- `frontend.agent.md` — UI/component rules
- `backend.agent.md` — API/data rules
- `infra.agent.md` — deployment/infrastructure rules

## Key Reference Files

- `Decisions.md` — architectural decisions; do not reverse without explicit instruction
- `HANDOFF.md` — AI session handoff context; update before ending a session
