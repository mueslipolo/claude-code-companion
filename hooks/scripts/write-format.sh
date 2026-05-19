#!/usr/bin/env bash
# write-format.sh — PostToolUse hook
#
# Runs after Write/Edit. Auto-formats the file Claude just touched, based
# on extension. Failures are non-fatal: a missing formatter or a syntax
# error in user content should not block Claude's turn.
#
# Wired in settings.json:
#   "PostToolUse": [
#     { "match": "Write", "command": "hooks/scripts/write-format.sh" },
#     { "match": "Edit",  "command": "hooks/scripts/write-format.sh" }
#   ]
#
# Inputs:
#   stdin: JSON event from Claude Code, including .tool_input.file_path
#
# Dependencies (all optional, hook skips silently if missing):
#   jq        - parse the event JSON (required)
#   mdformat  - format Markdown (install: pipx install mdformat && pipx inject mdformat mdformat-gfm mdformat-tables)
#   ruff      - format Python (install: pipx install ruff)
#   prettier  - format JS/TS/JSON/YAML/CSS (install: npm i -g prettier)

set -u  # but NOT -e: this hook must never break the session

# ---------------------------------------------------------------------------
# Parse the event
# ---------------------------------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  # No jq, no way to read the event. Bail quietly.
  exit 0
fi

event="$(cat)"
file_path="$(echo "$event" | jq -r '.tool_input.file_path // empty')"

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Dispatch by extension
# ---------------------------------------------------------------------------

case "$file_path" in
  # -- Markdown -----------------------------------------------------------
  #
  # mdformat with the GFM and tables plugins:
  #   - Aligns pipe tables
  #   - Normalizes structural markdown
  #   - Does NOT rewrap prose
  #   - Does NOT touch code fences
  #
  *.md|*.mdx|*.markdown)
    if command -v mdformat >/dev/null 2>&1; then
      mdformat "$file_path" >/dev/null 2>&1 || true
    fi
    ;;

  # -- JS / TS / JSON / YAML / CSS -----------------------------------------
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.yml|*.yaml|*.css|*.scss|*.html)
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$file_path" >/dev/null 2>&1 || true
    fi
    ;;

  # -- Python --------------------------------------------------------------
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file_path" >/dev/null 2>&1 || true
      ruff check --fix --quiet "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
