#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="${INSANE_SEARCH_PLUGIN_ROOT:-$DEFAULT_ROOT}"
VENV="${INSANE_SEARCH_VENV:-$ROOT/.venv}"
REQ="$ROOT/requirements-codex.txt"
MARKER="$VENV/.insane-search-ready"

if [ ! -d "$ROOT/skills/insane-search/engine" ]; then
  echo "insane-search setup error: plugin root not found at $ROOT" >&2
  exit 2
fi

pick_python() {
  if [ -n "${INSANE_SEARCH_PYTHON:-}" ]; then
    printf '%s\n' "$INSANE_SEARCH_PYTHON"
    return
  fi
  for candidate in python3.12 python3.11 python3.10 python3.13 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      "$candidate" - <<'PY' >/dev/null 2>&1 && { printf '%s\n' "$candidate"; return; }
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
    fi
  done
  return 1
}

PYTHON_BASE="$(pick_python || true)"
if [ -z "$PYTHON_BASE" ]; then
  echo "insane-search setup error: Python 3.10+ is required for curl_cffi>=0.15.0" >&2
  exit 2
fi

if [ -x "$VENV/bin/python" ]; then
  if ! "$VENV/bin/python" - <<'PY' >/dev/null 2>&1; then
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
    rm -rf "$VENV"
  fi
fi

if [ ! -x "$VENV/bin/python" ]; then
  "$PYTHON_BASE" -m venv "$VENV"
fi

if [ ! -f "$MARKER" ] || [ "$REQ" -nt "$MARKER" ]; then
  "$VENV/bin/python" -m pip install -U pip wheel >/dev/null
  "$VENV/bin/python" -m pip install -r "$REQ" >/dev/null
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$MARKER"
fi

if [ "${INSANE_SETUP_PLAYWRIGHT:-0}" = "1" ] && command -v npm >/dev/null 2>&1; then
  TEMPLATES="$ROOT/skills/insane-search/engine/templates"
  if [ -f "$TEMPLATES/package.json" ]; then
    (cd "$TEMPLATES" && npm install >/dev/null)
  fi
  if command -v npx >/dev/null 2>&1; then
    npx playwright install chrome >/dev/null 2>&1 || true
  fi
fi

echo "$VENV/bin/python"
