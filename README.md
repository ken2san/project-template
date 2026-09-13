# project-template

New project bootstrap template for Copilot Agent projects.

> **Template version:** see `VERSION` file. Check current version with `./init-project.sh --version`.

---

## File Structure

Shipped content lives entirely under `modules/<name>/`, each mirroring the file tree it produces
inside a generated project (e.g. `modules/base/AGENTS.md` → `AGENTS.md`). There is no separate
"core" tier — `base` is simply the one module every project type always includes, because a
project generated without it (no `AGENTS.md`, no `Roadmap.md`/`Protocol.md`/`Decisions.md`, no
README) wouldn't have a reason to use this template. `frontend`/`backend`/`infra` are the optional
modules a project type selects between. Adding a new module later means adding a new
`modules/<name>/` directory and referencing it from a preset — nothing else in the mechanism
changes. Everything outside `modules/` is either about maintaining project-template itself
(`README.md`, `CHANGELOG.md`, `test/`, `.github/workflows/`) or plumbing the bootstrap script
needs at runtime (`VERSION`, `.gitignore`, `init-project.sh` itself — copied as-is, not through the
module mechanism, since they aren't content).

```
project-template/
├── README.md                          ← About project-template itself; not copied to new projects
├── CHANGELOG.md                       ← project-template's own changelog; not copied
├── init-project.sh                    ← Bootstrap script (also copied as-is into generated projects)
├── VERSION                            ← Template semantic version (plumbing, copied as-is)
├── .gitignore                         ← Plumbing, copied as-is into generated projects
├── test/
│   └── smoke-test.sh                  ← End-to-end test for --new/--apply (see Testing section)
├── package.json                       ← npx entry point
├── bin/
│   └── create-project.js             ← Node.js wrapper for npx
├── .github/
│   └── workflows/
│       └── test.yml                   ← Runs test/smoke-test.sh on ubuntu-latest + macos-latest
└── modules/
    ├── base/                          ← Always included, every project type
    │   ├── AGENTS.md
    │   ├── Roadmap.md
    │   ├── Protocol.md
    │   ├── Decisions.md
    │   ├── HANDOFF.md
    │   ├── README.md                  ← Becomes the new project's README.md
    │   ├── CHANGELOG.md               ← Becomes the new project's CHANGELOG.md
    │   ├── .vscode/settings.json
    │   ├── .claude/commands/template/
    │   │   ├── init.md                ← Claude Code /template:init → .github/prompts/init.prompt.md
    │   │   └── apply.md               ← Claude Code /template:apply → .github/prompts/apply.prompt.md
    │   └── .github/
    │       ├── copilot-instructions.md
    │       ├── PULL_REQUEST_TEMPLATE.md
    │       ├── ISSUE_TEMPLATE/
    │       │   ├── bug_report.md
    │       │   ├── feature_request.md
    │       │   └── config.yml
    │       ├── instructions/
    │       │   ├── global.instructions.md         ← Template-managed (overwritten by --apply)
    │       │   └── global.custom.instructions.md  ← Project-owned (never overwritten)
    │       └── prompts/
    │           ├── init.prompt.md     ← AI content generation prompt
    │           └── apply.prompt.md    ← Placeholder fill prompt for --apply mode
    ├── frontend/.github/instructions/frontend.instructions.md   ← Included by webapp, game
    ├── backend/.github/instructions/backend.instructions.md     ← Included by webapp, api
    └── infra/.github/instructions/infra.instructions.md         ← Included by webapp, game, api
```

---

## Setup

**Two-step process: bash handles structure, AI handles content.**

### Platform requirements

| Platform | Support     | Notes                                                      |
| -------- | ----------- | ---------------------------------------------------------- |
| macOS    | ✓ Full      | `zsh` built-in                                             |
| Linux    | ✓ Full      | `zsh` required (`apt install zsh` / `brew install zsh`)    |
| Windows  | ⚠ WSL2 only | Run inside WSL2 Ubuntu; native PowerShell is not supported |

> **Windows note:** The bootstrap script requires `zsh`. On Windows, install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and run all commands inside the WSL2 terminal. Native PowerShell / Command Prompt support is planned for a future release.

### Primary environments

- VS Code + GitHub Copilot Chat (recommended)
- GitHub Copilot CLI (`copilot`)
- Claude Code (CLI or IDE extension)
- Codex CLI (`codex`)

`AGENTS.md` is the single source of truth for agent behavior and is read automatically by all
four. Copilot additionally auto-applies `.github/copilot-instructions.md` and the path-scoped
`.github/instructions/*.instructions.md` files by itself; other agents don't auto-apply path-scoped
files, so AGENTS.md tells them to read the relevant one before frontend/backend/infra work.

### Step 1 — Bootstrap (bash)

**Option A — New project via npx (recommended, no clone required):**

```bash
npx github:ken2san/project-template --new ~/path/to/parent
```

Requires Node.js 18+. No install step — runs directly from GitHub.

**Option A' — New project from local clone:**

```
git clone https://github.com/ken2san/project-template
cd project-template
./init-project.sh --new
```

**Global install (optional, Mac/Linux):**

```bash
# Run once to install the project-new command globally
./init-project.sh --install
# Add to ~/.zshrc if prompted:
# export PATH="$HOME/.local/bin:$PATH"

# Then from anywhere:
project-new --new ~/path/to/parent
```

**Uninstall:**

```bash
project-new --uninstall
```

Removes the `project-new` symlink. Refuses to run if the path isn't a symlink, so it never deletes an unrelated file.

Prompts for project folder name, project type, name, description, stack, phase boundary, and dev/test commands. All prompts have defaults — press Enter to accept. Copies template, replaces basic placeholders, runs `git init`.

### Step 2 — AI content generation (Copilot Agent)

When `--new` completes, the script prints a checklist and **automatically copies a bootstrap prompt to your clipboard** (`pbcopy` on macOS, `clip.exe` on WSL2, `xclip`/`xsel` on Linux). If none of those tools are available, the prompt is printed to the terminal instead.

Open the new project in VS Code, paste the clipboard content into Copilot Chat, then also run:

```
> Copilot: Run Prompt > init
```

The agent reads your project context, asks 2–3 targeted questions, then writes real content into `Roadmap.md`, `Protocol.md`, `Decisions.md`, `HANDOFF.md`, and all agent files. No `{{PLACEHOLDER}}` tokens remain after this step.

> The prompt file is at `.github/prompts/init.prompt.md`.

If you use GitHub Copilot CLI, start an interactive session with `copilot` in the project root, then ask it to execute the instructions in `.github/prompts/init.prompt.md`.

If you use Claude Code, run `/template:init` in the project root — it launches the same `.github/prompts/init.prompt.md` workflow. (Namespaced to avoid colliding with Claude Code's built-in `/init`.)

If you use Codex CLI, start `codex` in the project root and ask it to execute the instructions in `.github/prompts/init.prompt.md`. (Codex's own custom-prompt files live outside the repo in `~/.codex/prompts/`, so they can't be shipped here the way `/template:init` is for Claude Code — pointing Codex at the prompt file directly works the same way it does for Copilot CLI.)

---

## Applying to an existing project

**Option B — Apply to existing project:**

```bash
npx github:ken2san/project-template --apply ~/path/to/existing-project
```

Or from local clone:

```bash
./init-project.sh --apply ~/path/to/existing-project
```

Copies only agent files into an existing project. Skips files that already exist. Then run in VS Code:

```
> Copilot: Run Prompt > apply
```

If you use GitHub Copilot CLI, run `copilot` in the target project root and ask it to execute `.github/prompts/apply.prompt.md`.

If you use Claude Code, run `/template:apply` in the target project root.

If you use Codex CLI, run `codex` in the target project root and ask it to execute `.github/prompts/apply.prompt.md`.

## Supported project types

A project type is just a preset list of `modules/` to include (`base` is always one of them):

| Type     | Modules included              |
| -------- | ------------------------------ |
| `webapp` | `base`, `frontend`, `backend`, `infra` |
| `game`   | `base`, `frontend`, `infra` (no backend) |
| `api`    | `base`, `backend`, `infra` (no frontend) |

## Template variable reference

| Variable                     | Description                                                 |
| ---------------------------- | ----------------------------------------------------------- |
| `{{PROJECT_NAME}}`           | Human-readable project name used across template documents. |
| `{{DATE}}`                   | Last-updated date stamp for generated template files.       |
| `{{PROJECT_DESCRIPTION}}`    | One-line summary describing the project.                    |
| `{{STACK}}`                  | Primary technology stack summary for project context.       |
| `{{PHASE_MAX_PLUS_ONE}}`     | First blocked phase number for scope control rules.         |
| `{{DEV_COMMAND}}`            | Command used to start the development environment.          |
| `{{DEV_URL}}`                | URL where the development environment is reachable.         |
| `{{TEST_COMMAND}}`           | Command used to run the project test suite.                 |
| `{{BUILD_COMMAND}}`          | Command used to build production-ready artifacts.           |
| `{{PHASE_1_NAME}}`           | Name of the first delivery phase.                           |
| `{{PHASE_1_GOAL}}`           | Goal statement for phase 1.                                 |
| `{{PHASE_1_SCOPE_1}}`        | First scoped item for phase 1.                              |
| `{{PHASE_1_SCOPE_2}}`        | Second scoped item for phase 1.                             |
| `{{PHASE_2_NAME}}`           | Name of the second delivery phase.                          |
| `{{PHASE_2_GOAL}}`           | Goal statement for phase 2.                                 |
| `{{PHASE_2_SCOPE_1}}`        | First scoped item for phase 2.                              |
| `{{PHASE_2_SCOPE_2}}`        | Second scoped item for phase 2.                             |
| `{{CURRENT_PHASE}}`          | Current active phase indicator used in status docs.         |
| `{{LIVE_URL}}`               | Current live deployment URL or deployment status note.      |
| `{{LAST_SESSION_1}}`         | First key outcome from the previous working session.        |
| `{{LAST_SESSION_2}}`         | Second key outcome from the previous working session.       |
| `{{LAST_SESSION_3}}`         | Third key outcome from the previous working session.        |
| `{{CURRENT_STATE_1}}`        | First current-state checkpoint for handoff context.         |
| `{{CURRENT_STATE_2}}`        | Second current-state checkpoint for handoff context.        |
| `{{CONSTRAINT_1}}`           | Additional project-specific delivery constraint.            |
| `{{NEXT_TASK}}`              | Highest-priority next action for the incoming session.      |
| `{{PROTOCOL_OVERVIEW}}`      | Overview paragraph describing project operating rules.      |
| `{{PRINCIPLE_1}}`            | First guiding principle in the protocol file.               |
| `{{PRINCIPLE_2}}`            | Second guiding principle in the protocol file.              |
| `{{PRINCIPLE_3}}`            | Third guiding principle in the protocol file.               |
| `{{DATA_MODEL_DESCRIPTION}}` | Summary of the project data model or state shape.           |
| `{{WORKFLOW_DESCRIPTION}}`   | Summary of the core project workflow.                       |
| `{{DECISION_SUMMARY}}`       | One-line architecture decision statement.                   |
| `{{DECISION_CONTEXT}}`       | Context that motivated the architecture decision.           |
| `{{ALTERNATIVE_1}}`          | First alternative considered during decision-making.        |
| `{{REASON_1}}`               | Reason the first alternative was rejected.                  |
| `{{ALTERNATIVE_2}}`          | Second alternative considered during decision-making.       |
| `{{REASON_2}}`               | Reason the second alternative was rejected.                 |
| `{{DECISION_CONSEQUENCES}}`  | Expected consequences of the chosen architecture decision.  |
| `{{ENTRY_POINT}}`            | Main application entry file or execution boundary.          |
| `{{STATE_LOCATION}}`         | Location where application state is managed or stored.      |
| `{{CODE_RULE_1}}`            | First project-specific coding rule for agents.              |
| `{{CODE_RULE_2}}`            | Second project-specific coding rule for agents.             |
| `{{CODE_RULE_3}}`            | Third project-specific coding rule for agents.              |
| `{{INFRA_STACK}}`            | Infrastructure stack summary used by infra guidance.        |
| `{{INFRA_RULE_1}}`           | First infrastructure-specific implementation rule.          |
| `{{INFRA_RULE_2}}`           | Second infrastructure-specific implementation rule.         |
| `{{STATE_LIBRARY}}`          | State management library expected in frontend work.         |
| `{{MODAL_RULE}}`             | Rule governing modal or overlay behavior patterns.          |
| `{{DIRECTORY_RULE}}`         | Rule describing directory structure conventions.            |
| `{{BACKEND_STATUS}}`         | Current backend implementation status summary.              |
| `{{BACKEND_PHASE}}`          | Phase number when backend implementation is expected.       |
| `{{BACKEND_STACK_1}}`        | First planned backend stack component.                      |
| `{{BACKEND_STACK_2}}`        | Second planned backend stack component.                     |
| `{{BACKEND_STACK_3}}`        | Third planned backend stack component.                      |
| `{{MOCK_DATA_LOCATION}}`     | Path or location for backend mock data.                     |

---

## Testing

`test/smoke-test.sh` runs `init-project.sh --new` and `--apply` end-to-end against a temp
directory and asserts on regressions found during template review (e.g. generated projects
must not inherit project-template's own README/CHANGELOG, `--apply` must not overwrite an
existing `.vscode/settings.json`, the placeholder-fill step must not leave `.bak` files behind).

```bash
./test/smoke-test.sh
```

CI (`.github/workflows/test.yml`) runs it on both `ubuntu-latest` and `macos-latest` on every
push/PR to catch shell differences (e.g. GNU sed vs. BSD sed) that don't show up when only
tested on one platform.

---

## Template Versioning

This template is versioned with Git and semantic versioning (`VERSION` file).

**Check current version:**

```bash
npx github:ken2san/project-template --version
# or from local clone:
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
