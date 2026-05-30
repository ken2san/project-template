# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/).

---

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
