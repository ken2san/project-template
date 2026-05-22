---
description: Global agent rules for {{PROJECT_NAME}} — applies to all roles
---

# Global Agent

_Last updated: {{DATE}}_

<!--
Usage (developer note, not for AI):
- Rules in AGENTS.md are universal and take precedence in all environments.
- Add only project-specific exceptions, clarifications, or operational examples here.
- Do not duplicate or restate AGENTS.md rules.
-->

## Verification Commands

| Purpose | Command |
| ------- | ------- |
| Start dev server | `{{DEV_COMMAND}}` → `{{DEV_URL}}` |
| Run tests | `{{TEST_COMMAND}}` |
| Build | `{{BUILD_COMMAND}}` |

The self-healing loop must use these commands for verification steps. If a command is not yet defined, state that explicitly rather than skipping verification.

## Project-Specific Overrides

_None yet — add exceptions here as the project evolves._
