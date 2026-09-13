# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/).

---

## [1.7.0] — 2026-09-13

### Changed

- Restructured all shipped content under `modules/<name>/`, each mirroring the file tree it
  produces inside a generated project. There is no separate "core" tier: `base` (AGENTS.md,
  Roadmap/Protocol/Decisions/HANDOFF, README, CHANGELOG, copilot/Claude config, issue/PR
  templates) is just the one module every project type always includes; `frontend`/`backend`/
  `infra` are the modules a project type selects between. A project type is now literally a
  preset list of modules (see the updated "Supported project types" table in README.md).
- `init-project.sh --new`: replaced "copy everything, then delete the unwanted role file" with
  "copy only the selected modules" — no more `rm -f` of files that were copied just to be
  discarded a moment later.
- `init-project.sh --apply`: file lists now source from `modules/<name>/...` via a small
  `dest_rel_path()` helper instead of assuming source and destination paths are identical;
  external behavior (which files are forced vs. skip-if-exists) is unchanged.
- Dropped the `README.project.md` / `CHANGELOG.project.md` naming workaround — now that they live
  in their own `modules/base/` directory, they no longer collide with project-template's own
  root `README.md` / `CHANGELOG.md` and can just be named normally.
- `package.json`: `files` list collapsed from ~14 explicit entries to `modules/`, `bin/`,
  `init-project.sh`, `.gitignore`, `VERSION` — adding a module no longer means updating this list.
- `test/smoke-test.sh`: added assertions that each project type includes/excludes the right
  modules (webapp: all three; game: frontend+infra, no backend; api: backend+infra, no frontend).

---

## [1.6.0] — 2026-09-13

### Added

- Claude Code support alongside Copilot: `.claude/commands/template/{init,apply}.md` launch the
  same `.github/prompts/*.prompt.md` workflows via `/template:init` / `/template:apply`
  (namespaced under `template/` so they don't collide with Claude Code's built-in `/init`)
- `AGENTS.md`: note that Copilot auto-applies `.github/instructions/*.instructions.md` by path,
  but other agents don't auto-apply path-scoped files and should read the matching one themselves
- `init-project.sh --uninstall`: removes the `project-new` symlink; refuses to delete the target
  if it isn't a symlink, so it can't remove an unrelated file at that path
- `test/smoke-test.sh` and `.github/workflows/test.yml`: end-to-end test of `--new`, `--apply`,
  `--install`, and `--uninstall` against a temp directory, run in CI on both `ubuntu-latest`
  (GNU sed) and `macos-latest` (BSD sed) on every push/PR

### Fixed

- `init-project.sh --new`: exclude `test/` and `.github/workflows/` from the rsync copy — like
  `README.md`/`CHANGELOG.md`, these describe and validate project-template itself and have no
  meaning inside a generated project

---

## [1.5.1] — 2026-09-13

### Fixed

- `init-project.sh`: `sed -i ''` (BSD-only syntax) replaced with the portable `sed -i.bak` + cleanup form — the placeholder-fill step was aborting immediately on Linux/WSL2 with GNU sed
- `init-project.sh --apply`: `.vscode/settings.json` moved from `FORCE_FILES` to `SKIP_IF_EXISTS_FILES` — it was being silently overwritten with `{}` on every `--apply` run, destroying any existing VS Code workspace settings
- `init-project.sh --new`: generated projects no longer inherit project-template's own `README.md` and `CHANGELOG.md` verbatim; new `README.project.md` / `CHANGELOG.project.md` are copied in as project-specific `README.md` / `CHANGELOG.md` instead
- `.github/ISSUE_TEMPLATE/bug_report.md`, `feature_request.md`: reworded "the project template" → "this project" so copied issue templates make sense in generated projects
- `bin/create-project.js`: missing `zsh` now prints an actionable error (with a WSL2 pointer) instead of exiting silently with no output
- `package.json`: `version` was out of sync with `VERSION` (1.3.1 vs 1.5.0); both now track together

---

## [1.5.0] — 2026-06-01

### Added

- `--new` completion: next-step checklist printed (`cd`, `code .`, Copilot Chat prompt)
- `--new` completion: bootstrap prompt auto-copied to clipboard (`pbcopy` on macOS, `xclip`/`xsel` on Linux; printed as fallback)
- README: Platform requirements table with macOS / Linux / Windows (WSL2) support status

---

## [1.4.0] — 2026-06-01

### Added

- npx support: `npx github:ken2san/project-template --new .` runs directly from GitHub without cloning
- `bin/create-project.js` — Node.js wrapper that delegates to `init-project.sh` (Mac/Linux)
- `package.json` — npx entry point with `bin` field and `files` allowlist
- `--install` flag: creates a symlink at `~/.local/bin/project-new` for global CLI access
- Default values for all interactive prompts — press Enter to accept and move on
- `PROJECT_NAME` default auto-derived from the project folder slug

### Fixed

- `--new` mode: replaced `cp -r` with `rsync --exclude=.git` to prevent template `.git` from being copied into new projects
- `--new` mode: excluded `bin/` and `package.json` from the template copy so they don't appear in generated projects

---

## [1.3.1] — 2026-05-30

### Changed

- README: clarified primary support targets as VS Code + GitHub Copilot Chat and GitHub Copilot CLI
- README: added explicit Copilot CLI flow for running `.github/prompts/init.prompt.md` and `.github/prompts/apply.prompt.md`

## [1.3.0] — 2026-05-30

### Fixed

- `init-project.sh`: `find` sed loop now excludes `.git/` (prevents corrupting git internals)
- `init-project.sh`: remaining-placeholder `grep` now excludes `.git/` (matches `--check` behavior)
- `init-project.sh`: `Protocol.md` and `Roadmap.md` added to `SKIP_IF_EXISTS_FILES` so `--apply` seeds them when absent
- `init.prompt.md`: Step 5 verify `grep` now excludes `prompts/` and `README.md` (matches Step 2 and `apply.prompt.md`)
- `init.prompt.md`: Step 1 removed false claim that `AGENTS.md` contains project name/stack
- `init.prompt.md`: Step 2 `grep` now excludes `prompts/` and `README.md` (prevents AI filling docs examples)
- `init.prompt.md`: Step 4 now includes `infra.instructions.md` fill guidance
- `apply.prompt.md`: Step 1 now reads `global.instructions.md` for consistency with `init.prompt.md`
- `HANDOFF.md`: "game/system rules" → "project operating rules" (template is stack-agnostic)
- `copilot-instructions.md`: `Protocol.md` added to Key Reference Files
- `PULL_REQUEST_TEMPLATE.md`: replaced template-repo-specific checklist item with generic one
- `config.yml`: hardcoded `ken2san` contact URL replaced with commented-out placeholder
- `README.md`: `config.yml` added to file structure tree
- `README.md`: `settings.json` description corrected (`{}` not "Copilot instruction file references")
- `README.md`: dangling "3. Fill in remaining placeholders" step removed
- `README.md`: Option B (`--apply`) moved to its own section; Step 2 now correctly references `apply.prompt.md`
- `README.md`: version upgrade example generalized to `<new-version>`

## [1.2.0] — 2026-05-30

### Fixed

- `--check` flag no longer produces false positives from `init-project.sh` itself (removed `--include='*.sh'` from scan)

### Changed

- README: removed duplicate placeholder table from Setup section (canonical reference is now "Template variable reference")
- README: updated file structure tree to include `PULL_REQUEST_TEMPLATE.md` and `ISSUE_TEMPLATE/`

### Added

- `.github/ISSUE_TEMPLATE/config.yml` to enable GitHub issue template selection UI

---

## [1.1.0] — 2026-05-30

### Added

- `.github/PULL_REQUEST_TEMPLATE.md` — stack-agnostic PR checklist aligned to AGENTS.md verification policy
- `.github/ISSUE_TEMPLATE/bug_report.md` — standard bug report form
- `.github/ISSUE_TEMPLATE/feature_request.md` — standard feature request form
- `init-project.sh --check [dir]` — read-only scan for unresolved `{{...}}` tokens; exits 0 if clean, 1 if tokens found
- Required-input retry logic for `--new` and in-place modes (re-prompts once on empty input, then exits with error)
- README: "Supported project types" section documenting `webapp`, `game`, and `api`
- README: "Template variable reference" table listing all unique placeholder tokens

---

## [1.0.0] — 2026-05-27

### Added

- Initial release of project-template bootstrap scaffold
- `init-project.sh` with `--new`, `--apply`, and `--version` modes
- `AGENTS.md` — universal AI agent rules (self-healing loop, scope policy, git policy)
- `.github/copilot-instructions.md` — project-level Copilot workspace instructions
- `.github/instructions/` — role-scoped instruction files (global, frontend, backend, infra)
- `.github/prompts/init.prompt.md` and `apply.prompt.md` — AI content generation prompts
- `Roadmap.md`, `Protocol.md`, `Decisions.md`, `HANDOFF.md` — placeholder template documents
- `VERSION` file and `.template-version` tracking for bootstrapped projects
