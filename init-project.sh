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

  # Files to copy (agent/AI config only — no README, Roadmap, Protocol)
  AGENT_FILES=(
    "AGENTS.md"
    "Decisions.md"
    "HANDOFF.md"
    ".vscode/settings.json"
    ".github/copilot-instructions.md"
    ".github/agents/global.agent.md"
    ".github/agents/frontend.agent.md"
    ".github/agents/backend.agent.md"
    ".github/agents/infra.agent.md"
  )

  for f in "${AGENT_FILES[@]}"; do
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

echo "\n--- Checking for remaining placeholders (fill in directly) ---"
REMAINING=$(grep -rn '{{' . --include='*.md' --exclude-dir=node_modules 2>/dev/null || true)
if [[ -z "$REMAINING" ]]; then
  echo "  ✓ No placeholders remaining."
else
  echo "$REMAINING"
fi

echo "\n=== Done. Edit remaining placeholders above directly in each file. ==="
if [[ "$1" == "--new" ]]; then
  echo "Project created at: $(pwd)"
fi
