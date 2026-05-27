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
│   └── settings.json                  ← Copilot instruction file references
└── .github/
    ├── copilot-instructions.md
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

## Setup (new project)

**Two-step process: bash handles structure, AI handles content.**

### Step 1 — Bootstrap (bash)

**Option A — New project (recommended):**

```
git clone https://github.com/YOUR_USERNAME/project-template
cd project-template
./init-project.sh --new
```

Prompts for project folder name, project type, name, description, stack, phase boundary, and dev/test commands. Copies template, replaces basic placeholders, runs `git init`.

**Option B — Apply to existing project:**

```
./init-project.sh --apply ~/path/to/existing-project
```

Copies only agent files into an existing project. Skips files that already exist.

### Step 2 — AI content generation (Copilot Agent)

Open the new project in VS Code, then run:

```
> Copilot: Run Prompt > init
```

The agent reads your project context, asks 2–3 targeted questions, then writes real content into `Roadmap.md`, `Protocol.md`, `Decisions.md`, `HANDOFF.md`, and all agent files. No `{{PLACEHOLDER}}` tokens remain after this step.

> The prompt file is at `.github/prompts/init.prompt.md`.

3. Fill in remaining placeholders:
   ```
   grep -rn '{{' . --include='*.md'
   ```

| Placeholder                                                | Set by | Files                                                         |
| ---------------------------------------------------------- | ------ | ------------------------------------------------------------- |
| `{{PROJECT_NAME}}`                                         | script | all                                                           |
| `{{DATE}}`                                                 | script | all                                                           |
| `{{PROJECT_DESCRIPTION}}`                                  | script | copilot-instructions.md, HANDOFF.md                           |
| `{{STACK}}`                                                | script | copilot-instructions.md, frontend.instructions.md, HANDOFF.md |
| `{{PHASE_MAX_PLUS_ONE}}`                                   | script | AGENTS.md, copilot-instructions.md, HANDOFF.md                |
| `{{ENTRY_POINT}}` `{{STATE_LOCATION}}` `{{STATE_LIBRARY}}` | manual | copilot-instructions.md, frontend.instructions.md             |
| `{{CODE_RULE_*}}`                                          | manual | copilot-instructions.md                                       |
| `{{PHASE_*}}` `{{CURRENT_PHASE}}`                          | manual | Roadmap.md, HANDOFF.md                                        |
| `{{BACKEND_*}}` `{{MOCK_DATA_LOCATION}}`                   | manual | backend.instructions.md                                       |
| `{{INFRA_*}}`                                              | manual | infra.instructions.md                                         |
| `{{PROTOCOL_OVERVIEW}}` `{{PRINCIPLE_*}}` etc.             | manual | Protocol.md                                                   |
| `{{DECISION_*}}`                                           | manual | Decisions.md                                                  |
| `{{LAST_SESSION_*}}` `{{CURRENT_STATE_*}}` etc.            | manual | HANDOFF.md (update each session)                              |
| `{{LIVE_URL}}`                                             | manual | HANDOFF.md                                                    |
| `{{DEV_COMMAND}}` `{{DEV_URL}}`                            | manual | global.instructions.md                                        |
| `{{TEST_COMMAND}}` `{{BUILD_COMMAND}}`                     | manual | global.instructions.md                                        |

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
echo "1.1.0" > VERSION
git add VERSION && git commit -m "chore: bump version to 1.1.0"
git tag v1.1.0
```

**Each generated project tracks its origin** via `.template-version` (written by `init-project.sh`).
To see which version a project was bootstrapped from:

```
cat .template-version
```

> Note: `.template-version` in generated projects is informational only — there is no automatic upgrade mechanism. To pull in new agent rules, use `--apply` mode.
