#!/usr/bin/env zsh
# init-project.sh — Initialize a new project from template
# Usage (install globally):          ./init-project.sh install    → adds `ptpl` to ~/.local/bin
# Usage (uninstall):                 ptpl uninstall                → removes the `ptpl` symlink
# Usage (new project, sibling):      ptpl new
# Usage (new project, custom dir):   ptpl new ~/Desktop
# Usage (apply to existing project): ptpl apply ~/path/to/project
# Usage (check for unresolved):      ptpl check [dir]

set -e

# ${0:A:h} (zsh-only) resolves symlinks before taking the dirname, unlike
# `dirname "$0"` — needed because `install` runs this script via a symlink
# (e.g. ~/.local/bin/ptpl), and a plain dirname would resolve to the
# symlink's own directory instead of the real project-template checkout.
TEMPLATE_DIR="${0:A:h}"
SANDBOX_DIR="$(dirname "$TEMPLATE_DIR")"
TEMPLATE_VERSION="$(cat "$TEMPLATE_DIR/VERSION" 2>/dev/null || echo 'unknown')"

# Shared by `new` (called early, before project-type/module selection — see
# note at the call site for why) and `apply` (called from the "Collect
# inputs" tail, since apply has no earlier point to call it from).
collect_identity_inputs() {
  # Derive default project name from slug (`new` mode) or fall back to generic
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
}

# --- Unknown/missing command: print usage and exit, rather than silently
# falling through into the shared "collect inputs" tail below with no
# TARGET/DEST set (that used to happen for any typo'd or unrecognized flag).
case "$1" in
  new|apply|check|install|uninstall|version) ;;
  *)
    echo "Usage: ptpl <command> [args]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  new [dest]         Create a new project from this template" >&2
    echo "  apply [dir]        Apply/update agent files in an existing project" >&2
    echo "  check [dir]        Scan for unresolved {{...}} placeholder tokens" >&2
    echo "  install [path]     Install this script globally as 'ptpl' (default: ~/.local/bin/ptpl)" >&2
    echo "  uninstall [path]   Remove the globally installed 'ptpl' symlink" >&2
    echo "  version            Print the template version" >&2
    exit 1
    ;;
esac

# --- Version command ---
if [[ "$1" == "version" ]]; then
  echo "project-template v${TEMPLATE_VERSION}"
  exit 0
fi

# --- Install command: symlink this script for global access ---
if [[ "$1" == "install" ]]; then
  LINK_PATH="${2:-$HOME/.local/bin/ptpl}"
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
  echo "\nUsage: ptpl new [dest]"
  exit 0
fi

# --- Uninstall command: remove the ptpl symlink ---
if [[ "$1" == "uninstall" ]]; then
  LINK_PATH="${2:-$HOME/.local/bin/ptpl}"
  LINK_PATH="${LINK_PATH/#\~/$HOME}"

  if [[ ! -e "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
    echo "Nothing to uninstall: $LINK_PATH does not exist."
    exit 0
  fi

  if [[ ! -L "$LINK_PATH" ]]; then
    echo "Error: $LINK_PATH exists but is not a symlink (not something 'install' created). Refusing to delete it." >&2
    exit 1
  fi

  rm "$LINK_PATH"
  echo "Uninstalled: removed $LINK_PATH"
  exit 0
fi

# --- Check command: read-only scan for unresolved {{...}} tokens ---
if [[ "$1" == "check" ]]; then
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
if [[ "$1" == "apply" ]]; then
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
  # Two categories of files exist for `apply`. The dividing line is not
  # "does it currently have project-specific content" — it's "could a
  # project legitimately want to customize this file." FORCE_FILES gets
  # silently clobbered on every apply, so it must be reserved for files the
  # template owns outright, where a project is never expected to edit them
  # directly (AGENTS.md/global.instructions.md both say so in their own
  # header, with global.custom.instructions.md as the sanctioned place for
  # project-specific additions instead). Anything a project could plausibly
  # customize — instructions, agents, hooks, not just docs that accumulate
  # prose — goes in SKIP_IF_EXISTS, even at the cost of template fixes not
  # auto-propagating to existing projects; a diff shown to an AI session
  # covers that case when it actually matters. skeptic.md and
  # pre-commit-verify.sh were originally FORCE_FILES on the reasoning that
  # nobody would want to customize a reviewer persona or a verification
  # script — wrong, by the same logic .vscode/settings.json was once
  # force-overwritten and destroyed real project settings before that got
  # fixed too (see CHANGELOG). Don't repeat that mistake for a new file
  # without a specific, checked reason it doesn't apply.
  #
  #   FORCE_FILES        — overwritten on every `apply` run.
  #                        Only for files the template owns outright; a project
  #                        is never expected to edit them (see note above).
  #
  #   SKIP_IF_EXISTS     — copied only if absent; never overwritten.
  #                        Everything a project could plausibly customize,
  #                        docs and instructions/agents/hooks alike. Once
  #                        present in the workspace, they are owned by the
  #                        project.
  #
  # Files always overwritten (template-owned, not meant to be project-edited)
  FORCE_FILES=(
    "modules/base/AGENTS.md"
    "modules/base/CLAUDE.md"
    "modules/base/.github/instructions/global.instructions.md"
  )

  # Files copied only if not present (project-owned once created, including
  # anything a project could plausibly customize — see note above).
  # `apply` doesn't prompt for a project type, so it includes every module —
  # unlike `new`, an existing project's stack isn't being chosen here, only augmented.
  SKIP_IF_EXISTS_FILES=(
    "modules/base/Decisions.md"
    "modules/base/HANDOFF.md"
    "modules/base/PROJECT.md"
    "modules/base/.vscode/settings.json"
    "modules/base/.claude/settings.json"
    "modules/base/.claude/agents/skeptic.md"
    "modules/base/.claude/hooks/pre-commit-verify.sh"
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
if [[ "$1" == "new" ]]; then
  # Under npx/npm, TEMPLATE_DIR is an ephemeral cache path, not a real
  # checkout — "default to the directory next to TEMPLATE_DIR" has no
  # sensible meaning there, so require an explicit destination instead of
  # silently writing into npm's cache (see PTPL_VIA_NPX in bin/create-project.js).
  if [[ -n "$PTPL_VIA_NPX" && -z "$2" ]]; then
    echo "Error: destination directory is required when running via npx." >&2
    echo "Usage: npx github:ken2san/project-template new <dest>" >&2
    exit 1
  fi

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

  # Asked here — before project type/module selection — rather than down in
  # the shared "Collect inputs" tail with the rest: knowing the stack first
  # reads more naturally than picking a project type blind, then only
  # learning the stack afterward.
  collect_identity_inputs

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
  # project (`check`/`version` there) — not content, so not a module.
  cp "$TEMPLATE_DIR/VERSION" "$DEST/VERSION"
  cp "$TEMPLATE_DIR/init-project.sh" "$DEST/init-project.sh"

  # Written inline rather than `cp`'d from this repo's own .gitignore: when
  # installed via `npx github:...`, pacote's git-fetcher unconditionally
  # renames the top-level .gitignore to .npmignore (clobbering it even if
  # one already exists), so the source file is simply gone by the time this
  # script runs from an npx-managed checkout. Keep this in sync with the
  # project-template repo's own .gitignore by hand.
  cat > "$DEST/.gitignore" <<'GITIGNORE_EOF'
# Dependencies
node_modules/

# Build artifacts
dist/
build/
.next/
out/

# Environment & secrets
.env
.env.*
*.pem
*.key
*.p12
*.pfx
secrets/

# Logs
*.log
logs/

# sed -i.bak backups (init-project.sh removes these itself; ignored as a safety net)
*.bak

# OS
.DS_Store

# IDE
.vscode/*
!.vscode/settings.json
GITIGNORE_EOF

  echo "  wrote: VERSION, .gitignore, init-project.sh"

  cd "$DEST"

  echo "$TEMPLATE_VERSION" > .template-version
  echo "  wrote: .template-version ($TEMPLATE_VERSION)"
fi

# --- Collect inputs (essential only — edit other files directly after) ---
# `new` already asked name/description/stack earlier (before project-type
# selection); `apply` has no earlier point to ask from, so it asks here.
if [[ "$1" != "new" ]]; then
  collect_identity_inputs
fi

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
    -e "s|{{DEV_COMMAND}}|${DEV_COMMAND}|g" \
    -e "s|{{DEV_URL}}|${DEV_URL}|g" \
    -e "s|{{TEST_COMMAND}}|${TEST_COMMAND}|g" \
    -e "s|{{BUILD_COMMAND}}|${BUILD_COMMAND}|g" \
    "$file" && rm -f "$file.bak"
  echo "  updated: $file"
done

# --- Git init (new projects only) ---
if [[ "$1" != "apply" && ! -d ".git" ]]; then
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
  if [[ "$1" == "apply" ]]; then
    echo "\n  → Run 'Copilot: Run Prompt > apply' in VS Code to fill these with AI-generated content."
  else
    echo "\n  → Run 'Copilot: Run Prompt > init' in VS Code to fill these with AI-generated content."
  fi
fi

echo "\n=== Done. ==="
if [[ "$1" == "new" ]]; then
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
