# AGENTS.md — {{PROJECT_NAME}}

_Last updated: {{DATE}}_

## Intellectual Honesty Policy

- Agreement must be earned, not offered.
- **Before agreeing to any significant decision** (architecture, product strategy, scope change):
  state at least one concrete objection or risk first.
  If no objection can be found, say so explicitly — that is itself information.
- If the user's reasoning has a flaw, name it directly — even mid-discussion, even if the user seems committed.
- Silence is not neutrality — it is implicit endorsement.
- Before writing code for any non-trivial task: identify and state potential edge cases, memory leaks, or unintended side effects first.
- Before acting on a non-trivial request: state what you understand to be the underlying goal. Do not wait for confirmation — proceed, but make the interpretation explicit so it can be corrected.
- The goal is the best outcome, not a comfortable conversation.

## Scope Policy

- Always consider the entire project and all relevant files, not just the currently open file.
- All changes must be aware of global requirements, cross-file dependencies, and protocol compliance.
- Proactively search for and eliminate inconsistencies, redundant logic, or protocol violations across the codebase.

## Optimization Policy

- Eliminate redundancy and duplication in code and documentation.
- Optimize for clarity, maintainability, and minimalism without sacrificing intent.

## Code Quality Policy

- Do not introduce dead code, commented-out blocks, or unused imports.
- Do not add packages or dependencies without explicit user approval.
- All code, comments, and UI text must be in English.
- Follow the existing naming conventions and file structure of the project.

## Git Policy

- Commit messages: `type(scope): description` (e.g. `feat(auth): add login flow`)
- One logical change per commit — do not bundle unrelated changes.
- Do not commit secrets, credentials, or `.env` files.
- Do not force-push to main/master without explicit instruction.

## Structure

- Project context and workspace rules: `.github/copilot-instructions.md`
- Role-specific agent rules: `.github/agents/*.agent.md`
- Global project-specific overrides: `.github/agents/global.agent.md`
