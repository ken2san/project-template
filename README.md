# project-template

New project bootstrap template for Copilot Agent projects.

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

| Placeholder                                                | Set by | Files                                      |
| ---------------------------------------------------------- | ------ | ------------------------------------------ |
| `{{PROJECT_NAME}}`                                         | script | all                                        |
| `{{DATE}}`                                                 | script | all                                        |
| `{{PROJECT_DESCRIPTION}}`                                  | script | copilot-instructions.md, HANDOFF.md        |
| `{{STACK}}`                                                | script | copilot-instructions.md, frontend.agent.md, HANDOFF.md |
| `{{PHASE_MAX_PLUS_ONE}}`                                   | script | AGENTS.md, copilot-instructions.md, HANDOFF.md |
| `{{ENTRY_POINT}}` `{{STATE_LOCATION}}` `{{STATE_LIBRARY}}` | manual | copilot-instructions.md, frontend.agent.md |
| `{{CODE_RULE_*}}`                                          | manual | copilot-instructions.md                    |
| `{{PHASE_*}}` `{{CURRENT_PHASE}}`                          | manual | Roadmap.md, HANDOFF.md                     |
| `{{BACKEND_*}}` `{{MOCK_DATA_LOCATION}}`                   | manual | backend.agent.md                           |
| `{{INFRA_*}}`                                              | manual | infra.agent.md                             |
| `{{PROTOCOL_OVERVIEW}}` `{{PRINCIPLE_*}}` etc.             | manual | Protocol.md                                |
| `{{DECISION_*}}`                                           | manual | Decisions.md                               |
| `{{LAST_SESSION_*}}` `{{CURRENT_STATE_*}}` etc.            | manual | HANDOFF.md (update each session)           |
| `{{LIVE_URL}}`                                             | manual | HANDOFF.md                                 |
