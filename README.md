# project-template

New project bootstrap template for Copilot Agent projects.

> **Template version:** see `VERSION` file. Check current version with `./init-project.sh --version`.

---

## File Structure

```
project-template/
├── README.md
├── AGENTS.md                          ← Universal AI agent rules (self-contained)
├── Roadmap.md                         ← Phase management and scope boundaries
├── Protocol.md                        ← Project protocol / system rules
├── Decisions.md                       ← Architecture decision records (ADR)
├── HANDOFF.md                         ← AI session handoff template
├── .gitignore
├── init-project.sh                    ← Bootstrap script (--new flag supported)
├── VERSION                            ← Template semantic version (e.g. 1.0.0)
├── .vscode/
│   └── settings.json                  ← VS Code workspace settings
└── .github/
    ├── copilot-instructions.md
    ├── PULL_REQUEST_TEMPLATE.md
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   ├── feature_request.md
    │   └── config.yml
    ├── instructions/
    │   ├── global.instructions.md         ← Template-managed global rules (overwritten by --apply)
    │   ├── global.custom.instructions.md  ← Project-owned overrides (never overwritten)
    │   ├── frontend.instructions.md
    │   ├── backend.instructions.md
    │   └── infra.instructions.md
    └── prompts/
        ├── init.prompt.md             ← AI content generation prompt
        └── apply.prompt.md            ← Placeholder fill prompt for --apply mode
```

---

## Setup

**Two-step process: bash handles structure, AI handles content.**

### Primary environments

- VS Code + GitHub Copilot Chat (recommended)
- GitHub Copilot CLI (`copilot`)

This template is optimized for these two workflows. Instruction files in `AGENTS.md`, `.github/copilot-instructions.md`, and `.github/instructions/*.instructions.md` are intended to be consumed by Copilot agents.

### Step 1 — Bootstrap (bash)

**Option A — New project (recommended):**

```
git clone https://github.com/YOUR_USERNAME/project-template
cd project-template
./init-project.sh --new
```

Prompts for project folder name, project type, name, description, stack, phase boundary, and dev/test commands. Copies template, replaces basic placeholders, runs `git init`.

### Step 2 — AI content generation (Copilot Agent)

Open the new project in VS Code, then run:

```
> Copilot: Run Prompt > init
```

The agent reads your project context, asks 2–3 targeted questions, then writes real content into `Roadmap.md`, `Protocol.md`, `Decisions.md`, `HANDOFF.md`, and all agent files. No `{{PLACEHOLDER}}` tokens remain after this step.

> The prompt file is at `.github/prompts/init.prompt.md`.

If you use GitHub Copilot CLI, start an interactive session with `copilot` in the project root, then ask it to execute the instructions in `.github/prompts/init.prompt.md`.

---

## Applying to an existing project

**Option B — Apply to existing project:**

```
./init-project.sh --apply ~/path/to/existing-project
```

Copies only agent files into an existing project. Skips files that already exist. Then run in VS Code:

```
> Copilot: Run Prompt > apply
```

If you use GitHub Copilot CLI, run `copilot` in the target project root and ask it to execute `.github/prompts/apply.prompt.md`.

## Supported project types

- `webapp` — frontend-focused project with an optional backend agent path.
- `game` — client-only project type that removes backend agent instructions.
- `api` — backend-first project type that removes frontend agent instructions.

## Template variable reference

| Variable | Description |
| --- | --- |
| `{{PROJECT_NAME}}` | Human-readable project name used across template documents. |
| `{{DATE}}` | Last-updated date stamp for generated template files. |
| `{{PROJECT_DESCRIPTION}}` | One-line summary describing the project. |
| `{{STACK}}` | Primary technology stack summary for project context. |
| `{{PHASE_MAX_PLUS_ONE}}` | First blocked phase number for scope control rules. |
| `{{DEV_COMMAND}}` | Command used to start the development environment. |
| `{{DEV_URL}}` | URL where the development environment is reachable. |
| `{{TEST_COMMAND}}` | Command used to run the project test suite. |
| `{{BUILD_COMMAND}}` | Command used to build production-ready artifacts. |
| `{{PHASE_1_NAME}}` | Name of the first delivery phase. |
| `{{PHASE_1_GOAL}}` | Goal statement for phase 1. |
| `{{PHASE_1_SCOPE_1}}` | First scoped item for phase 1. |
| `{{PHASE_1_SCOPE_2}}` | Second scoped item for phase 1. |
| `{{PHASE_2_NAME}}` | Name of the second delivery phase. |
| `{{PHASE_2_GOAL}}` | Goal statement for phase 2. |
| `{{PHASE_2_SCOPE_1}}` | First scoped item for phase 2. |
| `{{PHASE_2_SCOPE_2}}` | Second scoped item for phase 2. |
| `{{CURRENT_PHASE}}` | Current active phase indicator used in status docs. |
| `{{LIVE_URL}}` | Current live deployment URL or deployment status note. |
| `{{LAST_SESSION_1}}` | First key outcome from the previous working session. |
| `{{LAST_SESSION_2}}` | Second key outcome from the previous working session. |
| `{{LAST_SESSION_3}}` | Third key outcome from the previous working session. |
| `{{CURRENT_STATE_1}}` | First current-state checkpoint for handoff context. |
| `{{CURRENT_STATE_2}}` | Second current-state checkpoint for handoff context. |
| `{{CONSTRAINT_1}}` | Additional project-specific delivery constraint. |
| `{{NEXT_TASK}}` | Highest-priority next action for the incoming session. |
| `{{PROTOCOL_OVERVIEW}}` | Overview paragraph describing project operating rules. |
| `{{PRINCIPLE_1}}` | First guiding principle in the protocol file. |
| `{{PRINCIPLE_2}}` | Second guiding principle in the protocol file. |
| `{{PRINCIPLE_3}}` | Third guiding principle in the protocol file. |
| `{{DATA_MODEL_DESCRIPTION}}` | Summary of the project data model or state shape. |
| `{{WORKFLOW_DESCRIPTION}}` | Summary of the core project workflow. |
| `{{DECISION_SUMMARY}}` | One-line architecture decision statement. |
| `{{DECISION_CONTEXT}}` | Context that motivated the architecture decision. |
| `{{ALTERNATIVE_1}}` | First alternative considered during decision-making. |
| `{{REASON_1}}` | Reason the first alternative was rejected. |
| `{{ALTERNATIVE_2}}` | Second alternative considered during decision-making. |
| `{{REASON_2}}` | Reason the second alternative was rejected. |
| `{{DECISION_CONSEQUENCES}}` | Expected consequences of the chosen architecture decision. |
| `{{ENTRY_POINT}}` | Main application entry file or execution boundary. |
| `{{STATE_LOCATION}}` | Location where application state is managed or stored. |
| `{{CODE_RULE_1}}` | First project-specific coding rule for agents. |
| `{{CODE_RULE_2}}` | Second project-specific coding rule for agents. |
| `{{CODE_RULE_3}}` | Third project-specific coding rule for agents. |
| `{{INFRA_STACK}}` | Infrastructure stack summary used by infra guidance. |
| `{{INFRA_RULE_1}}` | First infrastructure-specific implementation rule. |
| `{{INFRA_RULE_2}}` | Second infrastructure-specific implementation rule. |
| `{{STATE_LIBRARY}}` | State management library expected in frontend work. |
| `{{MODAL_RULE}}` | Rule governing modal or overlay behavior patterns. |
| `{{DIRECTORY_RULE}}` | Rule describing directory structure conventions. |
| `{{BACKEND_STATUS}}` | Current backend implementation status summary. |
| `{{BACKEND_PHASE}}` | Phase number when backend implementation is expected. |
| `{{BACKEND_STACK_1}}` | First planned backend stack component. |
| `{{BACKEND_STACK_2}}` | Second planned backend stack component. |
| `{{BACKEND_STACK_3}}` | Third planned backend stack component. |
| `{{MOCK_DATA_LOCATION}}` | Path or location for backend mock data. |

---

## Template Versioning

This template is versioned with Git and semantic versioning (`VERSION` file).

**Check current version:**

```
./init-project.sh --version
```

**Upgrade the template** (add new features, fix agent rules, etc.):

```bash
# 1. Edit files in this template directory
# 2. Commit the change
git add .
git commit -m "feat: add mobile agent template"

# 3. Bump VERSION and tag
echo "<new-version>" > VERSION
git add VERSION && git commit -m "chore: bump version to <new-version>"
git tag v<new-version>
```

**Each generated project tracks its origin** via `.template-version` (written by `init-project.sh`).
To see which version a project was bootstrapped from:

```
cat .template-version
```

> Note: `.template-version` in generated projects is informational only — there is no automatic upgrade mechanism. To pull in new agent rules, use `--apply` mode.
