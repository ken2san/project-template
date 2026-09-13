#!/usr/bin/env zsh
# init-project.sh — Initialize a new project from template
# Usage (install globally):          ./init-project.sh --install   → adds `project-new` to /usr/local/bin
# Usage (uninstall):                 project-new --uninstall       → removes the `project-new` symlink
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

# --- Uninstall flag: remove the project-new symlink ---
if [[ "$1" == "--uninstall" ]]; then
  LINK_PATH="${2:-$HOME/.local/bin/project-new}"
  LINK_PATH="${LINK_PATH/#\~/$HOME}"

  if [[ ! -e "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
    echo "Nothing to uninstall: $LINK_PATH does not exist."
    exit 0
  fi

  if [[ ! -L "$LINK_PATH" ]]; then
    echo "Error: $LINK_PATH exists but is not a symlink (not something --install created). Refusing to delete it." >&2
    exit 1
  fi

  rm "$LINK_PATH"
  echo "Uninstalled: removed $LINK_PATH"
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
  # All shipped content lives under modules/<name>/, mirroring the destination
  # project's own file tree (e.g. modules/base/AGENTS.md -> AGENTS.md,
  # modules/frontend/.github/instructions/frontend.instructions.md ->
  # .github/instructions/frontend.instructions.md). There is no separate
  # "core" tier — `base` is just the one module every preset always includes.
  # dest_rel_path() strips the "modules/<name>/" prefix to get that dest path.
  #
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
    "modules/base/AGENTS.md"
    "modules/base/.github/instructions/global.instructions.md"
  )

  # Files copied only if not present (contain project-specific or placeholder content).
  # --apply doesn't prompt for a project type, so it includes every module —
  # unlike --new, an existing project's stack isn't being chosen here, only augmented.
  SKIP_IF_EXISTS_FILES=(
    "modules/base/Decisions.md"
    "modules/base/HANDOFF.md"
    "modules/base/Protocol.md"
    "modules/base/Roadmap.md"
    "modules/base/.vscode/settings.json"
    "modules/base/.github/copilot-instructions.md"
    "modules/base/.github/instructions/global.custom.instructions.md"
    "modules/base/.github/prompts/init.prompt.md"
    "modules/base/.github/prompts/apply.prompt.md"
    "modules/base/.claude/commands/template/init.md"
    "modules/base/.claude/commands/template/apply.md"
  )

  # Every non-base module's files, discovered dynamically so adding a new
  # modules/<name>/ directory needs no change here.
  for d in "$TEMPLATE_DIR"/modules/*/; do
    m="$(basename "$d")"
    [[ "$m" == "base" ]] && continue
    for filepath in $(find "$d" -type f); do
      SKIP_IF_EXISTS_FILES+=("modules/$m/${filepath#$d}")
    done
  done

  dest_rel_path() {
    echo "${1#modules/*/}"
  }

  for f in "${FORCE_FILES[@]}"; do
    rel="$(dest_rel_path "$f")"
    dest="$TARGET/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$TEMPLATE_DIR/$f" "$dest"
    echo "  updated: $rel"
  done

  for f in "${SKIP_IF_EXISTS_FILES[@]}"; do
    rel="$(dest_rel_path "$f")"
    dest="$TARGET/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
      echo "  skip (exists): $rel"
    else
      cp "$TEMPLATE_DIR/$f" "$dest"
      echo "  copied: $rel"
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

  mkdir -p "$DEST"

  # Project type is really just a preset list of modules. `base` (AGENTS.md,
  # Roadmap/Protocol/Decisions/HANDOFF, README, CHANGELOG, copilot/Claude
  # config, issue/PR templates, ...) is not a special "core" tier — it's a
  # normal module every preset happens to always include, because a project
  # generated without it wouldn't have a reason to use this template at all.
  #
  # Presets are just a shortcut over the same primitive "custom" exposes:
  # picking modules individually. AVAILABLE_MODULES is discovered from the
  # modules/ directory itself, so a newly added module (e.g. modules/testing/)
  # is automatically selectable via "custom" without touching this script.
  AVAILABLE_MODULES=()
  for d in "$TEMPLATE_DIR"/modules/*/; do
    m="$(basename "$d")"
    [[ "$m" == "base" ]] && continue
    AVAILABLE_MODULES+=("$m")
  done

  echo "Project type:"
  echo "  1) webapp   (frontend + backend + infra)"
  echo "  2) game     (frontend + infra, no backend)"
  echo "  3) api      (backend + infra, no frontend)"
  echo "  4) custom   (choose modules individually: ${AVAILABLE_MODULES[*]})"
  read "PROJECT_TYPE_NUM?Select (1/2/3/4, default=1): "
  PROJECT_TYPE=${PROJECT_TYPE_NUM:-1}

  case "$PROJECT_TYPE" in
    2) SELECTED_MODULES=(base frontend infra) ;;
    3) SELECTED_MODULES=(base backend infra) ;;
    4)
      SELECTED_MODULES=(base)
      for m in "${AVAILABLE_MODULES[@]}"; do
        read "INCLUDE_MODULE?Include '$m' module? (y/n) [y]: "
        INCLUDE_MODULE="${INCLUDE_MODULE:-y}"
        if [[ "$INCLUDE_MODULE" == "y" || "$INCLUDE_MODULE" == "Y" ]]; then
          SELECTED_MODULES+=("$m")
        fi
      done
      ;;
    *) SELECTED_MODULES=(base frontend backend infra) ;;
  esac

  for m in "${SELECTED_MODULES[@]}"; do
    rsync -a "$TEMPLATE_DIR/modules/$m/" "$DEST/"
    echo "  added module: $m"
  done

  # Plumbing needed for the tool itself to keep working inside the generated
  # project (--check/--version there) — not content, so not a module.
  cp "$TEMPLATE_DIR/VERSION" "$DEST/VERSION"
  cp "$TEMPLATE_DIR/.gitignore" "$DEST/.gitignore"
  cp "$TEMPLATE_DIR/init-project.sh" "$DEST/init-project.sh"
  echo "  wrote: VERSION, .gitignore, init-project.sh"

  cd "$DEST"

  echo "$TEMPLATE_VERSION" > .template-version
  echo "  wrote: .template-version ($TEMPLATE_VERSION)"
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
  # -i.bak (with an explicit suffix) is the portable form: BSD sed (macOS) and
  # GNU sed (Linux/WSL2) parse a bare `-i ''` differently, and GNU sed treats
  # the empty string as a file operand and errors out. The backup is removed
  # immediately after.
  sed -i.bak \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{DATE}}|${DATE}|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
    -e "s|{{STACK}}|${STACK}|g" \
    -e "s|{{PHASE_MAX_PLUS_ONE}}|${PHASE_MAX_PLUS_ONE}|g" \
    -e "s|{{DEV_COMMAND}}|${DEV_COMMAND}|g" \
    -e "s|{{DEV_URL}}|${DEV_URL}|g" \
    -e "s|{{TEST_COMMAND}}|${TEST_COMMAND}|g" \
    -e "s|{{BUILD_COMMAND}}|${BUILD_COMMAND}|g" \
    "$file" && rm -f "$file.bak"
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
