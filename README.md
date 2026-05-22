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
    └── agents/
        ├── global.agent.md            ← Project-specific overrides to AGENTS.md
        ├── frontend.agent.md
        ├── backend.agent.md
        └── infra.agent.md
```

---

## Setup (new project)

**Option A — Bootstrap from scratch (recommended):**

```
cd ~/Library/CloudStorage/Dropbox/Sandbox/project-template

# Create in Dropbox/sandbox/ (default):
./init-project.sh --new

# Create anywhere (e.g. Desktop):
./init-project.sh --new ~/Desktop
```

Prompts for project folder name, then copies the template and initializes it automatically.

**Option B — Manual copy:**

1. Copy this folder to `Dropbox/Sandbox/project-{name}/`
2. Run the init script:

   ```
   cd ~/Library/CloudStorage/Dropbox/Sandbox/project-{name}
   ./init-project.sh
   ```

   Prompts: **Project type (webapp/game/api) / Project name / One-line description / Tech stack / First phase to block**

**Option C — Apply to existing project:**

```
./init-project.sh --apply ~/path/to/existing-project
```

Copies only agent files (AGENTS.md, .github/agents/, .vscode/settings.json, etc.) into an existing project. Skips files that already exist. Then runs placeholder replacement.

3. Fill in remaining placeholders:
   ```
   grep -rn '{{' . --include='*.md'
   ```

| Placeholder                                                | Set by | Files                                                  |
| ---------------------------------------------------------- | ------ | ------------------------------------------------------ |
| `{{PROJECT_NAME}}`                                         | script | all                                                    |
| `{{DATE}}`                                                 | script | all                                                    |
| `{{PROJECT_DESCRIPTION}}`                                  | script | copilot-instructions.md, HANDOFF.md                    |
| `{{STACK}}`                                                | script | copilot-instructions.md, frontend.agent.md, HANDOFF.md |
| `{{PHASE_MAX_PLUS_ONE}}`                                   | script | AGENTS.md, copilot-instructions.md, HANDOFF.md         |
| `{{ENTRY_POINT}}` `{{STATE_LOCATION}}` `{{STATE_LIBRARY}}` | manual | copilot-instructions.md, frontend.agent.md             |
| `{{CODE_RULE_*}}`                                          | manual | copilot-instructions.md                                |
| `{{PHASE_*}}` `{{CURRENT_PHASE}}`                          | manual | Roadmap.md, HANDOFF.md                                 |
| `{{BACKEND_*}}` `{{MOCK_DATA_LOCATION}}`                   | manual | backend.agent.md                                       |
| `{{INFRA_*}}`                                              | manual | infra.agent.md                                         |
| `{{PROTOCOL_OVERVIEW}}` `{{PRINCIPLE_*}}` etc.             | manual | Protocol.md                                            |
| `{{DECISION_*}}`                                           | manual | Decisions.md                                           |
| `{{LAST_SESSION_*}}` `{{CURRENT_STATE_*}}` etc.            | manual | HANDOFF.md (update each session)                       |
| `{{LIVE_URL}}`                                             | manual | HANDOFF.md                                             |
| `{{DEV_COMMAND}}` `{{DEV_URL}}`                            | manual | global.agent.md                                        |
| `{{TEST_COMMAND}}` `{{BUILD_COMMAND}}`                     | manual | global.agent.md                                        |

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
