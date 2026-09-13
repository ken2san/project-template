#!/usr/bin/env bash
# Smoke test for init-project.sh — exercises --new and --apply end-to-end and
# asserts on the regressions found and fixed during template review:
#   - sed -i '' is BSD-only and breaks the placeholder-fill step under GNU sed
#   - --apply used to force-overwrite an existing .vscode/settings.json
#   - generated projects used to inherit project-template's own README/CHANGELOG
# Run manually with: ./test/smoke-test.sh
# Run in CI via: .github/workflows/test.yml (matrix: ubuntu-latest, macos-latest)
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

cd "$TEMPLATE_DIR"

echo "=== --new: produces a working, project-specific scaffold ==="

NEW_LOG="$WORKDIR/new.log"
printf "smoketest\n1\nSmoke Test\nA smoke-tested project\nReact 18, Vite\n3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh --new "$WORKDIR" >"$NEW_LOG" 2>&1 \
  || { cat "$NEW_LOG"; fail "--new exited non-zero (see log above — this is how the BSD-only 'sed -i ''' regression showed up on Linux)"; }

PROJECT="$WORKDIR/smoketest"
[[ -d "$PROJECT" ]] || fail "project directory was not created"
pass "--new completed successfully"

grep -q "New project bootstrap template for Copilot Agent projects" "$PROJECT/README.md" \
  && fail "README.md still contains project-template's own description"
pass "README.md is project-specific, not project-template's own README"

grep -q "Smoke Test" "$PROJECT/README.md" || fail "README.md is missing the filled-in PROJECT_NAME"
pass "README.md placeholders were filled in"

[[ -f "$PROJECT/CHANGELOG.md" ]] || fail "CHANGELOG.md is missing"
grep -Eq '^## \[1\.[0-9]+\.[0-9]+\]' "$PROJECT/CHANGELOG.md" \
  && fail "CHANGELOG.md still contains project-template's own release history"
pass "CHANGELOG.md is project-specific, not project-template's own changelog"

if find "$PROJECT" -name "*.bak" | grep -q .; then
  fail "leftover .bak files from the sed -i.bak cleanup step"
fi
pass "no leftover .bak files"

[[ -f "$PROJECT/VERSION" ]] || fail "VERSION is missing (the copied init-project.sh reads it for --version/--check)"
pass "VERSION is present"

[[ -f "$PROJECT/.claude/commands/template/init.md" ]] || fail ".claude/commands/template/init.md is missing"
[[ -f "$PROJECT/.claude/commands/template/apply.md" ]] || fail ".claude/commands/template/apply.md is missing"
pass "Claude Code launcher commands are present"

[[ -d "$PROJECT/.git" ]] || fail "git repository was not initialized"
pass "git repository was initialized"

[[ -e "$PROJECT/test" ]] && fail "test/ (project-template's own test suite) leaked into the generated project"
[[ -e "$PROJECT/.github/workflows" ]] && fail ".github/workflows/ (project-template's own CI) leaked into the generated project"
pass "project-template's own test/CI files were not copied into the generated project"

echo "=== --new: module selection matches project type (base is always included) ==="

[[ -f "$PROJECT/.github/instructions/frontend.instructions.md" ]] || fail "webapp (type 1) should include the frontend module"
[[ -f "$PROJECT/.github/instructions/backend.instructions.md" ]] || fail "webapp (type 1) should include the backend module"
[[ -f "$PROJECT/.github/instructions/infra.instructions.md" ]] || fail "webapp (type 1) should include the infra module"
pass "webapp (type 1) included frontend + backend + infra"

GAME_LOG="$WORKDIR/game.log"
printf "gametest\n2\nGame Test\nA smoke-tested game\nUnity\n3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh --new "$WORKDIR" >"$GAME_LOG" 2>&1 \
  || { cat "$GAME_LOG"; fail "--new (game) exited non-zero"; }
GAME_PROJECT="$WORKDIR/gametest"
[[ -f "$GAME_PROJECT/.github/instructions/frontend.instructions.md" ]] || fail "game (type 2) should include the frontend module"
[[ -f "$GAME_PROJECT/.github/instructions/backend.instructions.md" ]] && fail "game (type 2) should NOT include the backend module"
[[ -f "$GAME_PROJECT/.github/instructions/infra.instructions.md" ]] || fail "game (type 2) should include the infra module"
[[ -f "$GAME_PROJECT/AGENTS.md" ]] || fail "game (type 2) should still include the base module (AGENTS.md)"
pass "game (type 2) included frontend + infra + base, excluded backend"

API_LOG="$WORKDIR/api.log"
printf "apitest\n3\nAPI Test\nA smoke-tested api\nFastAPI\n3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh --new "$WORKDIR" >"$API_LOG" 2>&1 \
  || { cat "$API_LOG"; fail "--new (api) exited non-zero"; }
API_PROJECT="$WORKDIR/apitest"
[[ -f "$API_PROJECT/.github/instructions/backend.instructions.md" ]] || fail "api (type 3) should include the backend module"
[[ -f "$API_PROJECT/.github/instructions/frontend.instructions.md" ]] && fail "api (type 3) should NOT include the frontend module"
[[ -f "$API_PROJECT/.github/instructions/infra.instructions.md" ]] || fail "api (type 3) should include the infra module"
pass "api (type 3) included backend + infra + base, excluded frontend"

echo "=== --apply: does not clobber an existing .vscode/settings.json ==="

APPLY_DIR="$WORKDIR/existing-project"
mkdir -p "$APPLY_DIR/.vscode"
echo '{"my.custom.setting": "keep-me"}' > "$APPLY_DIR/.vscode/settings.json"

APPLY_LOG="$WORKDIR/apply.log"
printf "Existing App\nAn existing app\nVue 3\n3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh --apply "$APPLY_DIR" >"$APPLY_LOG" 2>&1 \
  || { cat "$APPLY_LOG"; fail "--apply exited non-zero"; }

grep -q "keep-me" "$APPLY_DIR/.vscode/settings.json" \
  || fail "--apply overwrote an existing .vscode/settings.json (should be skip-if-exists)"
pass "--apply preserved the existing .vscode/settings.json"

[[ -f "$APPLY_DIR/AGENTS.md" ]] || fail "--apply did not write AGENTS.md"
pass "--apply wrote AGENTS.md"

echo "=== install / uninstall: symlink lifecycle ==="

LINK_PATH="$WORKDIR/bin/project-new"
./init-project.sh --install "$LINK_PATH" >/dev/null
[[ -L "$LINK_PATH" ]] || fail "--install did not create a symlink at $LINK_PATH"
pass "--install created the symlink"

./init-project.sh --uninstall "$LINK_PATH" >/dev/null
[[ -e "$LINK_PATH" || -L "$LINK_PATH" ]] && fail "--uninstall did not remove the symlink"
pass "--uninstall removed the symlink"

echo "not a symlink" > "$LINK_PATH"
if ./init-project.sh --uninstall "$LINK_PATH" >/dev/null 2>&1; then
  fail "--uninstall must refuse to delete a non-symlink file"
fi
pass "--uninstall refused to delete a non-symlink file"

echo "=== All smoke tests passed ==="
