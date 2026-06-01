# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/).

---

## [1.4.0] — 2026-06-01

### Added
- `npx github:ken2san/project-template --new .` で clone 不要で実行できる npx サポートを追加
- `bin/create-project.js` — Node.js ラッパー（Mac/Linux 対応）
- `package.json` — npx エントリポイント
- `--install` フラグ追加：`~/.local/bin/project-new` にシンボリックリンクを作成し、グローバルコマンドとして使えるようにする
- 全プロンプトにデフォルト値を追加（Enter 連打で通過可能）
- `PROJECT_NAME` のデフォルトをフォルダ名スラッグから自動導出

### Fixed
- `--new` モードで `cp -r` を `rsync --exclude=.git` に変更し、テンプレートの `.git` が新規プロジェクトに混入するバグを修正
- `bin/` と `package.json` を `--new` コピー対象から除外

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
