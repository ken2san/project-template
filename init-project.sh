#!/usr/bin/env zsh
# init-project.sh — Initialize a new project from template
# Usage (install globally):          ./init-project.sh --install   → adds `project-new` to /usr/local/bin
# Usage (new project, sibling):      project-new --new
# Usage (new project, custom dir):   project-new --new ~/Desktop
# Usage (apply to existing project): project-new --apply ~/path/to/project
# Usage (check for unresolved):      project-new --check [dir]

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
SANDBOX_DIR="$(dirname "$TEMPLATE_DIR")"
TEMPLATE_VERSION="$(cat "$TEMPLATE_DIR/VERSION" 2>/dev/null || echo 'unknown')"

# --- Version flag ---
if [[ "$1" == "--version" ]]; then
  echo "project-template v${TEMPLATE_VERSION}"
  exit 0
fi

# --- Install flag: symlink this script for global access ---
if [[ "$1" == "--install" ]]; then
  LINK_PATH="${2:-$HOME/.local/bin/project-new}"
  LINK_PATH="${LINK_PATH/#\~/$HOME}"
  mkdir -p "$(dirname "$LINK_PATH")"
  ln -sf "$TEMPLATE_DIR/init-project.sh" "$LINK_PATH"
  echo "Installed: $LINK_PATH -> $TEMPLATE_DIR/init-project.sh"
  # Warn if the target dir is not in PATH
  if [[ ":$PATH:" != *":$(dirname $LINK_PATH):"* ]]; then
    echo ""
    echo "Note: $(dirname $LINK_PATH) is not in your PATH."
    echo "Add this to ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
  echo "\nUsage: project-new --new [dest]"
  exit 0
fi

# --- Check flag: read-only scan for unresolved {{...}} tokens ---
if [[ "$1" == "--check" ]]; then
  CHECK_DIR="${2:-.}"
  CHECK_DIR="${CHECK_DIR/#\~/$HOME}"
  if [[ ! -d "$CHECK_DIR" ]]; then
    echo "Error: $CHECK_DIR does not exist." >&2
    exit 1
  fi
  FOUND=0
  while IFS= read -r match; do
    echo "$match"
    FOUND=1
  done < <(grep -rn '{{[^}]*}}' "$CHECK_DIR" \
    --include='*.md' --include='*.json' \
    --exclude-dir='.git' \
    --exclude-dir='node_modules' \
    2>/dev/null || true)
  if [[ "$FOUND" -eq 0 ]]; then
    echo "No placeholder tokens found."
    exit 0
  else
    exit 1
  fi
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
  # Files always overwritten (pure template rules, no project-specific content)
  FORCE_FILES=(
    "AGENTS.md"
    ".vscode/settings.json"
    ".github/instructions/global.instructions.md"
  )

  # Files copied only if not present (contain project-specific or placeholder content)
  SKIP_IF_EXISTS_FILES=(
    "Decisions.md"
    "HANDOFF.md"
    "Protocol.md"
    "Roadmap.md"
    ".github/copilot-instructions.md"
    ".github/instructions/frontend.instructions.md"
    ".github/instructions/backend.instructions.md"
    ".github/instructions/infra.instructions.md"
  )

  # global.custom.instructions.md: project-owned — only create if absent, never overwrite
  SKIP_IF_EXISTS_FILES+=(".github/instructions/global.custom.instructions.md")

  # prompts: utilities — copy if absent, allow project to customize
  SKIP_IF_EXISTS_FILES+=(".github/prompts/init.prompt.md")
  SKIP_IF_EXISTS_FILES+=(".github/prompts/apply.prompt.md")

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
  if [[ -z "$PROJECT_SLUG" ]]; then
    read "PROJECT_SLUG?Value required, please try again: "
    if [[ -z "$PROJECT_SLUG" ]]; then
      echo "Error: project folder name is required." >&2
      exit 1
    fi
  fi
  DEST="$DEST_PARENT/$PROJECT_SLUG"

  if [[ -d "$DEST" ]]; then
    echo "Error: $DEST already exists." >&2
    exit 1
  fi

  rsync -a --exclude='.git' --exclude='bin/' --exclude='package.json' --exclude='node_modules/' "$TEMPLATE_DIR/" "$DEST/"
  echo "Copied template to: $DEST (excluding .git)\n"
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
      rm -f .github/instructions/backend.instructions.md
      echo "  removed: backend.instructions.md (game project)"
      ;;
    3)
      rm -f .github/instructions/frontend.instructions.md
      echo "  removed: frontend.instructions.md (api project)"
      ;;
  esac
fi

# --- Collect inputs (essential only — edit other files directly after) ---
# Derive default project name from slug (--new mode) or fall back to generic
if [[ -n "$PROJECT_SLUG" ]]; then
  _default_name="$(echo "$PROJECT_SLUG" | sed 's/^project-//' | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
else
  _default_name="MyApp"
fi

read "PROJECT_NAME?Project name [${_default_name}]: "
PROJECT_NAME="${PROJECT_NAME:-$_default_name}"

read "PROJECT_DESCRIPTION?One-line description [TBD]: "
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-TBD}"

read "STACK?Tech stack [React 18, Vite, TailwindCSS]: "
STACK="${STACK:-React 18, Vite, TailwindCSS}"

read "PHASE_MAX_PLUS_ONE?First phase to block [3]: "
PHASE_MAX_PLUS_ONE="${PHASE_MAX_PLUS_ONE:-3}"

read "DEV_COMMAND?Dev server command [npm run dev]: "
DEV_COMMAND="${DEV_COMMAND:-npm run dev}"

read "DEV_URL?Dev server URL [http://localhost:5173]: "
DEV_URL="${DEV_URL:-http://localhost:5173}"

read "TEST_COMMAND?Test command [npm test]: "
TEST_COMMAND="${TEST_COMMAND:-npm test}"

read "BUILD_COMMAND?Build command [npm run build]: "
BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"

DATE=$(date +%Y-%m-%d)

echo "\n--- Applying replacements to all .md and .json files ---"

find . \( -name "*.md" -o -name "settings.json" \) \
  -not -path '*/.git/*' \
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
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=prompts \
  --exclude='README.md' \
  2>/dev/null || true)
if [[ -z "$REMAINING" ]]; then
  echo "  ✓ No placeholders remaining."
else
  echo "$REMAINING"
  if [[ "$1" == "--apply" ]]; then
    echo "\n  → Run 'Copilot: Run Prompt > apply' in VS Code to fill these with AI-generated content."
  else
    echo "\n  → Run 'Copilot: Run Prompt > init' in VS Code to fill these with AI-generated content."
  fi
fi

echo "\n=== Done. ==="
if [[ "$1" == "--new" ]]; then
  echo "Project created at: $(pwd)"
  echo "\nNext steps:"
  echo "  1. cd $DEST"
  echo "  2. code ."
  echo "  3. Paste the bootstrap prompt into Copilot Chat (see below)"
  echo "  4. Copilot: Run Prompt > init"

  BOOT_PROMPT="Read AGENTS.md and all files in .github/instructions/ to understand this project's context and rules. Then run the 'init' prompt to fill in all placeholder tokens and set up the project."

  if command -v pbcopy &>/dev/null; then
    echo "$BOOT_PROMPT" | pbcopy
    echo "\n✓ Bootstrap prompt copied to clipboard — paste into Copilot Chat."
  elif command -v clip.exe &>/dev/null; then
    # WSL2: pipe to Windows-side clipboard via clip.exe
    echo "$BOOT_PROMPT" | clip.exe
    echo "\n✓ Bootstrap prompt copied to clipboard — paste into Copilot Chat."
  elif command -v xclip &>/dev/null; then
    echo "$BOOT_PROMPT" | xclip -selection clipboard
    echo "\n✓ Bootstrap prompt copied to clipboard — paste into Copilot Chat."
  elif command -v xsel &>/dev/null; then
    echo "$BOOT_PROMPT" | xsel --clipboard --input
    echo "\n✓ Bootstrap prompt copied to clipboard — paste into Copilot Chat."
  else
    echo "\n→ First prompt (paste into Copilot Chat manually):"
    echo "  $BOOT_PROMPT"
  fi
fi
