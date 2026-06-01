# project-template — Development Roadmap

_Last updated: 2026-06-01_

---

## Phase 1 — Mac-only CLI (current)

### Goal

zsh スクリプトとして Mac 上で動作する完成度の高いテンプレートツールを作る。

### Scope

- `init-project.sh` による新規プロジェクト作成・既存プロジェクトへの適用
- `--install` でグローバルコマンド化（`~/.local/bin/project-new`）
- デフォルト値・Enter 連打対応
- `.git` 除外コピー（rsync）
- `--check` / `--apply` / `--version` フラグ

---

## Phase 2 — npx 対応（クロスプラットフォーム）

### Goal

`npx github:ken2san/project-template my-app` の1行で他の人も使えるようにする。
Node.js があれば OS を問わず動作することを目標とする。

### Scope

- **Phase 2A**: Mac/Linux 向け npx 対応（Node.js ラッパー → zsh スクリプトを呼ぶ）
  - `package.json` に `bin` エントリ追加
  - `bin/create-project.js` 作成
  - README に使い方を記載
- **Phase 2B**: Windows 対応（完全 JS 移植 or PowerShell ラッパー）
  - 工数大のため Phase 2A の実績を見てから判断

---

## Current Status

Active phase: Phase 2A

| Phase | Name | Status |
| ----- | ---- | ------ |
| 1 | Mac-only CLI | `done` |
| 2A | npx 対応 (Mac/Linux) | `in-progress` |
| 2B | Windows 対応 | `pending` |
