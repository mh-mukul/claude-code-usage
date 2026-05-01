#!/usr/bin/env bash
# uninstall.sh — remove claude-code-usage. Pass --purge to also delete ~/.claude/usage.db.

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/claude-code-usage"
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --purge|-p) PURGE=1 ;;
    -h|--help)
      cat <<EOF
Usage: bash uninstall.sh [--purge]

  --purge   Also delete ~/.claude/usage.db (the local database). Default: keep it.
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  echo "Removed $TARGET"
else
  echo "Not installed at $TARGET"
fi

if [ "$PURGE" -eq 1 ]; then
  DB="$HOME/.claude/usage.db"
  if [ -f "$DB" ]; then
    rm -f "$DB"
    echo "Purged $DB"
  fi
fi

echo "Done."
