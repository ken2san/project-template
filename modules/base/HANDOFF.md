# {{PROJECT_NAME}} — AI Session Handoff

_Last updated: {{DATE}}_

> Use this file to brief a new AI session on the current project state.
> Update before ending a session. Paste the contents as your first message.
>
> This file is the volatile record: what happened last, what's broken now, what's next.
> For what this project is and why (permanent reference), see `PROJECT.md` instead —
> never duplicate that here.

---

## Current Position

_A recovering agent reads this first and verifies every line against the repository before acting
on it — see `AGENTS.md` > Context Loss Recovery / Handoff. Write `none`/`unknown` rather than
leaving a guess._

- **Active owner / scope**: {{ACTIVE_OWNER}} — {{ACTIVE_SCOPE}}
- **Last verified**: {{LAST_VERIFIED}} at commit {{LAST_VERIFIED_COMMIT}}
- **Approved**: {{APPROVED_SCOPE}}
- **Explicitly forbidden**: {{FORBIDDEN_SCOPE}}
- **Next action**: see Next Priority below
- **How to confirm it is done**: {{NEXT_VERIFICATION}}
- **Known uncertainty**: {{UNCERTAINTY}}

## Current Phase

Phase {{CURRENT_PHASE}} — see `PROJECT.md`'s Roadmap for full scope and open items.

## What Was Done Last Session

- {{LAST_SESSION_1}}
- {{LAST_SESSION_2}}
- {{LAST_SESSION_3}}

## Current State

- {{CURRENT_STATE_1}}
- {{CURRENT_STATE_2}}
- Live: {{LIVE_URL}}

## Active Constraints

_Current/situational only — permanent constraints live in `PROJECT.md` instead._

_A blocker is written with its scope, never as a bare impossibility: which operation is
blocked, which subjects it applies to, how a reader tests one subject for themselves, and
which operations it does **not** cover. "X does not work" that silently meant "X does not
work via Y" is how an agent comes to report a working path as impossible._

- Do not implement Phase {{PHASE_MAX_PLUS_ONE}} or later without explicit instruction.
- {{CONSTRAINT_1}}

## Next Priority

{{NEXT_TASK}}

## Key Files to Read First

- `AGENTS.md` — agent behavior rules
- `PROJECT.md` — purpose, direction, architecture, roadmap, constraints
- `Decisions.md` — architectural decisions (do not reverse without instruction)
