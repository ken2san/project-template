#!/usr/bin/env bash
# Smoke test for init-project.sh — exercises new and apply end-to-end and
# asserts on the regressions found and fixed during template review:
#   - sed -i '' is BSD-only and breaks the placeholder-fill step under GNU sed
#   - apply used to force-overwrite an existing .vscode/settings.json
#   - generated projects used to inherit project-template's own README/CHANGELOG
# Run manually with: ./test/smoke-test.sh
# Run in CI via: .github/workflows/test.yml (matrix: ubuntu-latest, macos-latest)
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# init-project.sh runs `git init && git commit` for new. Give the child
# processes a git identity via env vars (not `git config --global`) so the
# test is self-contained on a machine/CI runner with no git identity
# configured, without touching the caller's own global git config.
export GIT_AUTHOR_NAME="Smoke Test" GIT_AUTHOR_EMAIL="smoke-test@example.com"
export GIT_COMMITTER_NAME="Smoke Test" GIT_COMMITTER_EMAIL="smoke-test@example.com"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

cd "$TEMPLATE_DIR"

echo "=== new: produces a working, project-specific scaffold ==="

NEW_LOG="$WORKDIR/new.log"
printf "smoketest\nSmoke Test\nA smoke-tested project\nReact 18, Vite\n1\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh new "$WORKDIR" >"$NEW_LOG" 2>&1 \
  || { cat "$NEW_LOG"; fail "new exited non-zero (see log above — this is how the BSD-only 'sed -i ''' regression showed up on Linux)"; }

PROJECT="$WORKDIR/smoketest"
[[ -d "$PROJECT" ]] || fail "project directory was not created"
pass "new completed successfully"

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

[[ -f "$PROJECT/VERSION" ]] || fail "VERSION is missing (the copied init-project.sh reads it for version/check)"
pass "VERSION is present"

[[ -f "$PROJECT/.claude/commands/template/init.md" ]] || fail ".claude/commands/template/init.md is missing"
[[ -f "$PROJECT/.claude/commands/template/apply.md" ]] || fail ".claude/commands/template/apply.md is missing"
pass "Claude Code launcher commands are present"

[[ -d "$PROJECT/.git" ]] || fail "git repository was not initialized"
pass "git repository was initialized"

[[ -e "$PROJECT/test" ]] && fail "test/ (project-template's own test suite) leaked into the generated project"
[[ -e "$PROJECT/.github/workflows" ]] && fail ".github/workflows/ (project-template's own CI) leaked into the generated project"
pass "project-template's own test/CI files were not copied into the generated project"

echo "=== new: module selection matches project type (base is always included) ==="

[[ -f "$PROJECT/.github/instructions/frontend.instructions.md" ]] || fail "webapp (type 1) should include the frontend module"
[[ -f "$PROJECT/.github/instructions/backend.instructions.md" ]] || fail "webapp (type 1) should include the backend module"
[[ -f "$PROJECT/.github/instructions/infra.instructions.md" ]] || fail "webapp (type 1) should include the infra module"
pass "webapp (type 1) included frontend + backend + infra"

GAME_LOG="$WORKDIR/game.log"
printf "gametest\nGame Test\nA smoke-tested game\nUnity\n2\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh new "$WORKDIR" >"$GAME_LOG" 2>&1 \
  || { cat "$GAME_LOG"; fail "new (game) exited non-zero"; }
GAME_PROJECT="$WORKDIR/gametest"
[[ -f "$GAME_PROJECT/.github/instructions/frontend.instructions.md" ]] || fail "game (type 2) should include the frontend module"
[[ -f "$GAME_PROJECT/.github/instructions/backend.instructions.md" ]] && fail "game (type 2) should NOT include the backend module"
[[ -f "$GAME_PROJECT/.github/instructions/infra.instructions.md" ]] || fail "game (type 2) should include the infra module"
[[ -f "$GAME_PROJECT/AGENTS.md" ]] || fail "game (type 2) should still include the base module (AGENTS.md)"
pass "game (type 2) included frontend + infra + base, excluded backend"

API_LOG="$WORKDIR/api.log"
printf "apitest\nAPI Test\nA smoke-tested api\nFastAPI\n3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh new "$WORKDIR" >"$API_LOG" 2>&1 \
  || { cat "$API_LOG"; fail "new (api) exited non-zero"; }
API_PROJECT="$WORKDIR/apitest"
[[ -f "$API_PROJECT/.github/instructions/backend.instructions.md" ]] || fail "api (type 3) should include the backend module"
[[ -f "$API_PROJECT/.github/instructions/frontend.instructions.md" ]] && fail "api (type 3) should NOT include the frontend module"
[[ -f "$API_PROJECT/.github/instructions/infra.instructions.md" ]] || fail "api (type 3) should include the infra module"
pass "api (type 3) included backend + infra + base, excluded frontend"

echo "=== new: custom mode reaches a module no preset includes ==="

# Custom mode asks y/n per available module, in the order backend, frontend,
# infra, testing (alphabetical, matches modules/*/ glob order). Answer n/n/n/y
# to prove `testing` — a module no preset references — is reachable, and that
# declining the others actually excludes them (composition works both ways).
CUSTOM_LOG="$WORKDIR/custom.log"
printf "customtest\nCustom Test\nA smoke-tested custom project\nNode\n4\nn\nn\nn\ny\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh new "$WORKDIR" >"$CUSTOM_LOG" 2>&1 \
  || { cat "$CUSTOM_LOG"; fail "new (custom) exited non-zero"; }
CUSTOM_PROJECT="$WORKDIR/customtest"
[[ -f "$CUSTOM_PROJECT/AGENTS.md" ]] || fail "custom mode should still include the base module (AGENTS.md)"
[[ -f "$CUSTOM_PROJECT/.github/instructions/testing.instructions.md" ]] || fail "custom mode should include testing when answered y (no preset includes it)"
[[ -f "$CUSTOM_PROJECT/.github/instructions/backend.instructions.md" ]] && fail "custom mode should exclude backend when answered n"
[[ -f "$CUSTOM_PROJECT/.github/instructions/frontend.instructions.md" ]] && fail "custom mode should exclude frontend when answered n"
[[ -f "$CUSTOM_PROJECT/.github/instructions/infra.instructions.md" ]] && fail "custom mode should exclude infra when answered n"
pass "custom mode included base + testing only, excluded frontend/backend/infra"

echo "=== apply: does not clobber an existing .vscode/settings.json ==="

APPLY_DIR="$WORKDIR/existing-project"
mkdir -p "$APPLY_DIR/.vscode"
echo '{"my.custom.setting": "keep-me"}' > "$APPLY_DIR/.vscode/settings.json"

APPLY_LOG="$WORKDIR/apply.log"
printf "Existing App\nAn existing app\nVue 3\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh ./init-project.sh apply "$APPLY_DIR" >"$APPLY_LOG" 2>&1 \
  || { cat "$APPLY_LOG"; fail "apply exited non-zero"; }

grep -q "keep-me" "$APPLY_DIR/.vscode/settings.json" \
  || fail "apply overwrote an existing .vscode/settings.json (should be skip-if-exists)"
pass "apply preserved the existing .vscode/settings.json"

[[ -f "$APPLY_DIR/AGENTS.md" ]] || fail "apply did not write AGENTS.md"
pass "apply wrote AGENTS.md"

[[ -f "$APPLY_DIR/CLAUDE.md" ]] || fail "apply did not write CLAUDE.md"
grep -q "@AGENTS.md" "$APPLY_DIR/CLAUDE.md" || fail "CLAUDE.md should import AGENTS.md via @AGENTS.md"
pass "apply wrote CLAUDE.md importing AGENTS.md"

[[ -f "$APPLY_DIR/.github/instructions/testing.instructions.md" ]] \
  || fail "apply should discover and copy every non-base module dynamically, including testing"
pass "apply dynamically included the testing module without any script change for it"

echo "=== install / uninstall: symlink lifecycle ==="

LINK_PATH="$WORKDIR/bin/ptpl"
./init-project.sh install "$LINK_PATH" >/dev/null
[[ -L "$LINK_PATH" ]] || fail "install did not create a symlink at $LINK_PATH"
pass "install created the symlink"

# Regression check: TEMPLATE_DIR must resolve the symlink to the real
# checkout, not just take dirname() of the symlink's own path (that bug
# made every install'd invocation fail with "no matches found: .../modules/*/").
SYMLINK_LOG="$WORKDIR/symlink-new.log"
printf "symlinktest\nSymlink Test\ndesc\nNode\n1\nnpm run dev\nhttp://localhost:5173\nnpm test\nnpm run build\n" \
  | zsh "$LINK_PATH" new "$WORKDIR" >"$SYMLINK_LOG" 2>&1 \
  || { cat "$SYMLINK_LOG"; fail "new via the installed symlink exited non-zero"; }
[[ -f "$WORKDIR/symlinktest/AGENTS.md" ]] || fail "new via the installed symlink did not produce AGENTS.md"
[[ -f "$WORKDIR/symlinktest/CLAUDE.md" ]] || fail "new via the installed symlink did not produce CLAUDE.md"
pass "new via the installed symlink resolves TEMPLATE_DIR correctly"

./init-project.sh uninstall "$LINK_PATH" >/dev/null
[[ -e "$LINK_PATH" || -L "$LINK_PATH" ]] && fail "uninstall did not remove the symlink"
pass "uninstall removed the symlink"

echo "not a symlink" > "$LINK_PATH"
if ./init-project.sh uninstall "$LINK_PATH" >/dev/null 2>&1; then
  fail "uninstall must refuse to delete a non-symlink file"
fi
pass "uninstall refused to delete a non-symlink file"

echo "=== unknown command: prints usage instead of silently falling through ==="

UNKNOWN_LOG="$WORKDIR/unknown.log"
if ./init-project.sh --new "$WORKDIR" >"$UNKNOWN_LOG" 2>&1; then
  fail "an unrecognized command (old-style --new flag) should exit non-zero, not silently proceed"
fi
grep -q "Usage: ptpl" "$UNKNOWN_LOG" || fail "unrecognized command should print usage"
pass "unrecognized command prints usage and exits non-zero"

echo "=== All smoke tests passed ==="
