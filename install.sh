#!/usr/bin/env bash
# Install the Claude Code Companion layer on top of Superpowers.
#
# This script:
#   1. Verifies Superpowers is installed (refuses to install otherwise)
#   2. Backs up your existing ~/.claude/ to ~/.claude.bak-<timestamp>
#   3. Copies CLAUDE.md, hooks, skills, rules, agents, commands
#   4. Marks hook scripts executable
#
# It does NOT touch your settings.json — review settings.template.json
# and merge by hand.

set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Verify Superpowers is installed
# ---------------------------------------------------------------------------

echo "==> Checking for Superpowers..."

# Superpowers installs into plugin dirs that vary by harness. Check the
# common locations.
superpowers_found=false
for candidate in \
  "$CLAUDE_HOME/plugins/superpowers" \
  "$CLAUDE_HOME/marketplaces/claude-plugins-official/superpowers" \
  "$CLAUDE_HOME/marketplaces/superpowers-marketplace/superpowers"
do
  if [ -d "$candidate" ]; then
    echo "    Found Superpowers at: $candidate"
    superpowers_found=true
    break
  fi
done

if [ "$superpowers_found" = false ]; then
  echo ""
  echo "ERROR: Superpowers does not appear to be installed."
  echo ""
  echo "This companion repo layers on top of Superpowers and assumes it's"
  echo "present. Install Superpowers first:"
  echo ""
  echo "  In Claude Code, run:"
  echo "    /plugin install superpowers@claude-plugins-official"
  echo ""
  echo "Then re-run this script."
  echo ""
  echo "(If you've installed Superpowers in a non-standard location, set"
  echo " CLAUDE_HOME=/path/to/your/.claude and re-run.)"
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Back up existing config
# ---------------------------------------------------------------------------

if [ -d "$CLAUDE_HOME" ]; then
  backup_dir="${CLAUDE_HOME}.bak-$(date +%Y%m%d-%H%M%S)"
  echo "==> Backing up $CLAUDE_HOME -> $backup_dir"
  cp -R "$CLAUDE_HOME" "$backup_dir"
else
  mkdir -p "$CLAUDE_HOME"
fi

# ---------------------------------------------------------------------------
# 3. Copy companion files
# ---------------------------------------------------------------------------

echo "==> Installing CLAUDE.md"
cp "$REPO_ROOT/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

for dir in hooks skills rules agents commands; do
  if [ -d "$REPO_ROOT/$dir" ]; then
    echo "==> Installing $dir/"
    mkdir -p "$CLAUDE_HOME/$dir"
    cp -R "$REPO_ROOT/$dir/." "$CLAUDE_HOME/$dir/"
  fi
done

# ---------------------------------------------------------------------------
# 4. Mark hooks executable
# ---------------------------------------------------------------------------

if [ -d "$CLAUDE_HOME/hooks/scripts" ]; then
  echo "==> Marking hook scripts executable"
  chmod +x "$CLAUDE_HOME/hooks/scripts/"*.sh 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Review settings.template.json and merge any pieces you want into"
echo "     $CLAUDE_HOME/settings.json by hand."
echo "  2. Customize bash-guard.sh and write-guard.sh patterns for your"
echo "     threat model (they ship with generic categories, not exact regex)."
echo "  3. Restart Claude Code so it re-reads CLAUDE.md and hooks."
