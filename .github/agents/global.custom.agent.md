---
description: Project-specific customizations for {{PROJECT_NAME}} — safe from template upgrades
---

# Custom Agent Rules

_Last updated: {{DATE}}_

<!--
DESIGN PATTERN — read this before editing (applies to AI agents too):

There are two global agent files. Their roles are deliberately separate:

  global.agent.md        — MANAGED BY TEMPLATE
                           Overwritten when `init-project.sh --apply` is run.
                           Contains universal rules sourced from project-template.
                           Do NOT add project-specific content here — it will be lost on the next template upgrade.

  global.custom.agent.md — OWNED BY THIS PROJECT (this file)
                           Never touched by `init-project.sh --apply`.
                           Add all project-specific rules, exceptions, and context HERE.
                           This is the only file safe to accumulate project knowledge in.

If you are an AI agent deciding where to add a rule:
  - Generic / reusable rule → belongs upstream in project-template, not here.
  - Project-specific exception or context → add it in this file.
-->

## Project-Specific Overrides

_None yet — add exceptions to AGENTS.md rules here as the project evolves._
