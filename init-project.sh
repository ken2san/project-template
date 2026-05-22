#!/usr/bin/env zsh
# init-project.sh — Initialize a new project from template
# Usage (in-place init):             ./init-project.sh
# Usage (new project, sibling):      ./init-project.sh --new
# Usage (new project, custom dir):   ./init-project.sh --new ~/Desktop
# Usage (apply to existing project): ./init-project.sh --apply ~/path/to/project

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
SANDBOX_DIR="$(dirname "$TEMPLATE_DIR")"
TEMPLATE_VERSION="$(cat "$TEMPLATE_DIR/VERSION" 2>/dev/null || echo 'unknown')"

# --- Version flag ---
if [[ "$1" == "--version" ]]; then
  echo "project-template v${TEMPLATE_VERSION}"
  exit 0
fi

echo "=== Copilot Agent Project Init (v${TEMPLATE_VERSION}) ===\n"

# --- Apply mode: copy agent files only into an existing project ---
if [[ "$1" == "--apply" ]]; then
  TARGET="${2:-.}"
  TARGET="${TARGET/#\~/$HOME}"

  if [[ ! -d "$TARGET" ]]; then
    echo "Error: $TARGET does not exist." >&2
    exit 1
  fi

  echo "Applying agent files to: $TARGET\n"

  # DESIGN NOTE (for maintainers and AI agents):
  # Two categories of files exist for --apply:
  #
  #   FORCE_FILES        — overwritten on every --apply run.
  #                        Use for pure-template content with no project-specific data.
  #                        Template improvements are automatically propagated.
  #
  #   SKIP_IF_EXISTS     — copied only if absent; never overwritten.
  #                        Use for files that accumulate project-specific content.
  #                        Once present in the workspace, they are owned by the project.
  #
  # *.agent.md role files (global, frontend, backend, infra) are currently in
  # SKIP_IF_EXISTS because they contain placeholder content that projects may have
  # customised. Ideal design would move them to FORCE_FILES and reserve
  # global.custom.agent.md as the sole project-owned customisation point.
  # Changing this requires ensuring projects have migrated custom edits out first.

  # Files always overwritten (pure template rules, no project-specific content)
  FORCE_FILES=(
    "AGENTS.md"
    ".vscode/settings.json"
  )

  # Files copied only if not present (contain project-specific or placeholder content)
  SKIP_IF_EXISTS_FILES=(
    "Decisions.md"
    "HANDOFF.md"
    ".github/copilot-instructions.md"
    ".github/agents/global.agent.md"
    ".github/agents/frontend.agent.md"
    ".github/agents/backend.agent.md"
    ".github/agents/infra.agent.md"
  )

  # global.custom.agent.md: project-owned — only create if absent, never overwrite
  SKIP_IF_EXISTS_FILES+=(".github/agents/global.custom.agent.md")

  for f in "${FORCE_FILES[@]}"; do
    dest="$TARGET/$f"
    destdir="$(dirname "$dest")"
    mkdir -p "$destdir"
    cp "$TEMPLATE_DIR/$f" "$dest"
    echo "  updated: $f"
  done

  for f in "${SKIP_IF_EXISTS_FILES[@]}"; do
    dest="$TARGET/$f"
    destdir="$(dirname "$dest")"
    mkdir -p "$destdir"
    if [[ -f "$dest" ]]; then
      echo "  skip (exists): $f"
    else
      cp "$TEMPLATE_DIR/$f" "$dest"
      echo "  copied: $f"
    fi
  done

  echo "$TEMPLATE_VERSION" > "$TARGET/.template-version"
  echo "  wrote: .template-version ($TEMPLATE_VERSION)"

  echo "\nRunning placeholder replacement in: $TARGET"
  cd "$TARGET"
  # Fall through to collect inputs and replace placeholders below
fi

# --- New project mode: copy template first ---
if [[ "$1" == "--new" ]]; then
  DEST_PARENT="${2:-$SANDBOX_DIR}"
  DEST_PARENT="${DEST_PARENT/#\~/$HOME}"

  read "PROJECT_SLUG?Project folder name (e.g. project-myapp): "
  DEST="$DEST_PARENT/$PROJECT_SLUG"

  if [[ -d "$DEST" ]]; then
    echo "Error: $DEST already exists." >&2
    exit 1
  fi

  cp -r "$TEMPLATE_DIR" "$DEST"
  echo "Copied template to: $DEST\n"
  cd "$DEST"

  echo "$TEMPLATE_VERSION" > .template-version
  echo "  wrote: .template-version ($TEMPLATE_VERSION)"
fi

# --- Project type selection (skip in --apply mode to avoid deleting existing files) ---
if [[ "$1" != "--apply" ]]; then
  echo "Project type:"
  echo "  1) webapp   (frontend + optional backend)"
  echo "  2) game     (client-only, no backend agent)"
  echo "  3) api      (backend-first, no frontend agent)"
  read "PROJECT_TYPE_NUM?Select (1/2/3, default=1): "
  PROJECT_TYPE=${PROJECT_TYPE_NUM:-1}

  case "$PROJECT_TYPE" in
    2)
      rm -f .github/agents/backend.agent.md
      echo "  removed: backend.agent.md (game project)"
      ;;
    3)
      rm -f .github/agents/frontend.agent.md
      echo "  removed: frontend.agent.md (api project)"
      ;;
  esac
fi

# --- Collect inputs (essential only — edit other files directly after) ---
read "PROJECT_NAME?Project name (e.g. MyApp): "
read "PROJECT_DESCRIPTION?One-line description: "
read "STACK?Tech stack (e.g. React 18, Vite, TailwindCSS): "
read "PHASE_MAX_PLUS_ONE?First phase to block (e.g. 3): "
read "DEV_COMMAND?Dev server command (e.g. npm run dev): "
read "DEV_URL?Dev server URL (e.g. http://localhost:3000): "
read "TEST_COMMAND?Test command (e.g. npm test): "
read "BUILD_COMMAND?Build command (e.g. npm run build): "

DATE=$(date +%Y-%m-%d)

echo "\n--- Applying replacements to all .md and .json files ---"

find . \( -name "*.md" -o -name "settings.json" \) \
  -not -path '*/node_modules/*' | while read file; do
  sed -i '' \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{DATE}}|${DATE}|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
    -e "s|{{STACK}}|${STACK}|g" \
    -e "s|{{PHASE_MAX_PLUS_ONE}}|${PHASE_MAX_PLUS_ONE}|g" \
    -e "s|{{DEV_COMMAND}}|${DEV_COMMAND}|g" \
    -e "s|{{DEV_URL}}|${DEV_URL}|g" \
    -e "s|{{TEST_COMMAND}}|${TEST_COMMAND}|g" \
    -e "s|{{BUILD_COMMAND}}|${BUILD_COMMAND}|g" \
    "$file"
  echo "  updated: $file"
done

# --- Git init (new projects only) ---
if [[ "$1" != "--apply" && ! -d ".git" ]]; then
  echo "\n--- Initializing git repository ---"
  git init -q
  git add .
  git commit -q -m "init: bootstrap from project-template v${TEMPLATE_VERSION}"
  echo "  ✓ git init + initial commit done"
fi

echo "\n--- Remaining placeholders for Step 2 (AI prompt will fill these) ---"
# Exclude: README.md (placeholder table docs) and prompts/ (instructional {{...}} references)
REMAINING=$(grep -rn '{{' . --include='*.md' \
  --exclude-dir=node_modules \
  --exclude-dir=prompts \
  --exclude='README.md' \
  2>/dev/null || true)
if [[ -z "$REMAINING" ]]; then
  echo "  ✓ No placeholders remaining."
else
  echo "$REMAINING"
  echo "\n  → Run 'Copilot: Run Prompt > init' in VS Code to fill these with AI-generated content."
fi

echo "\n=== Done. ==="
if [[ "$1" == "--new" ]]; then
  echo "Project created at: $(pwd)"
  echo "\nNext: open this folder in VS Code, then run:"
  echo "  > Copilot: Run Prompt > init"
fi
