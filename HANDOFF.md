# project-template — AI Session Handoff

_Last updated: 2026-06-01_

> Use this file to brief a new AI session on the current project state.
> Update before ending a session. Paste the contents as your first message.

---

## Project Summary

project-template は、GitHub Copilot エージェントを使った開発を始めるための zsh ベースのプロジェクトスキャフォールディングツール。
Stack: zsh, (Phase 2A〜) Node.js. Live: N/A（CLI ツール）

## Current Phase

Phase 2A — npx 対応 (Mac/Linux)。詳細は `Roadmap.md` を参照。

## What Was Done Last Session

- `--new` モードで `.git` が複製されるバグを修正（`cp -r` → `rsync --exclude=.git`）
- `--install` コマンド追加（`~/.local/bin/project-new` へのシンボリックリンク作成）
- 全プロンプトにデフォルト値を追加（Enter 連打で通過可能）
- `copilot/improvetemplate-generality` リモートブランチを削除（マージ済み）

## Current State

- `main` ブランチは安定・動作確認済み
- Phase 2A のブランチはまだ未作成（次のタスク）

## Active Constraints

- Phase 2B（Windows 対応）は Phase 2A の実績を見てから判断する
- `init-project.sh` の zsh スクリプトは引き続き Mac のメインパスとして維持する

## Next Priority

`feat/npx-cli` ブランチを切り、Phase 2A（Node.js ラッパー + package.json の bin エントリ）を実装する。

## Key Files to Read First

- `AGENTS.md` — agent behavior rules
- `Roadmap.md` — current phase and open items
- `init-project.sh` — メインの CLI スクリプト
