#!/usr/bin/env bash
# install.sh — one-line installer for claude-usage.
#
#   curl -fsSL <repo-raw>/install.sh | bash
#
# Env overrides:
#   VERSION=v0.1.0   # pin to a tagged release (default: main)
#   REPO_URL=...     # base URL of the repo (https://github.com/<u>/<r> or
#                    # https://gitlab.com/<u>/<r>); auto-derives the raw URL
#   INSTALL_DIR=...  # override install location (default: ~/.local/bin)
#   DRY_RUN=1        # print actions, do not execute

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
REPO_URL="${REPO_URL:-https://github.com/mhmukul/claude-code-usage}"
VERSION="${VERSION:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
SCRIPT_NAME="claude-usage"
DRY_RUN="${DRY_RUN:-}"

# Derive raw URL from REPO_URL host.
case "$REPO_URL" in
  https://github.com/*)
    RAW_URL="${REPO_URL/github.com/raw.githubusercontent.com}/${VERSION}/claude-usage.py"
    ;;
  https://gitlab.*)
    RAW_URL="${REPO_URL}/-/raw/${VERSION}/claude-usage.py"
    ;;
  *)
    echo "Unrecognized REPO_URL host. Set RAW_URL=... explicitly." >&2
    exit 1
    ;;
esac
RAW_URL="${RAW_URL_OVERRIDE:-$RAW_URL}"

# ── Output helpers ──────────────────────────────────────────────────────────
say()  { printf '  %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run()  { if [ -n "$DRY_RUN" ]; then echo "+ $*"; else eval "$@"; fi; }

# ── 1. Detect Python 3.9+ ───────────────────────────────────────────────────
PYTHON=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1; then
    if "$cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then
      PYTHON="$cand"
      break
    fi
  fi
done

if [ -z "$PYTHON" ]; then
  die "Python 3.9+ required. Install via:
    Ubuntu/Debian: sudo apt install python3
    Fedora/RHEL:   sudo dnf install python3
    macOS:         brew install python
  Then re-run this installer."
fi

PYVER=$("$PYTHON" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
say "Found Python $PYVER ($PYTHON)"

# ── 2. Ensure install dir + PATH ────────────────────────────────────────────
run mkdir -p "$INSTALL_DIR"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) warn "$INSTALL_DIR is not on PATH. Add this to your shell rc:
    export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac

# ── 3. Download claude-usage.py ─────────────────────────────────────────────
DEST="$INSTALL_DIR/$SCRIPT_NAME"
say "Downloading $RAW_URL"
say "→ $DEST"

if [ -n "$DRY_RUN" ]; then
  echo "+ curl -fsSL '$RAW_URL' -o '$DEST'"
  echo "+ chmod +x '$DEST'"
else
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT
  if ! curl -fsSL "$RAW_URL" -o "$TMP"; then
    die "Download failed. Check REPO_URL / VERSION and your network."
  fi
  # Sanity: must start with shebang.
  if ! head -n 1 "$TMP" | grep -q '^#!'; then
    die "Downloaded file does not look like a Python script. Aborting."
  fi
  mv "$TMP" "$DEST"
  chmod +x "$DEST"
  trap - EXIT
fi

# ── 4. Verify ────────────────────────────────────────────────────────────────
if [ -z "$DRY_RUN" ] && command -v "$SCRIPT_NAME" >/dev/null 2>&1; then
  INSTALLED_VER=$("$SCRIPT_NAME" --version 2>/dev/null || echo "unknown")
  say "Installed: $INSTALLED_VER"
fi

# ── 5. Hint ─────────────────────────────────────────────────────────────────
cat <<EOF

claude-usage installed.

Next steps:
  $SCRIPT_NAME dashboard         # scan + open browser
  $SCRIPT_NAME today             # terminal table
  $SCRIPT_NAME --help

Data lives in ~/.claude/usage.db (deleted by 'uninstall.sh --purge').
Uninstall: bash uninstall.sh
EOF
