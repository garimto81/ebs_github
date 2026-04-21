#!/usr/bin/env bash
# S-11 automation orchestrator — Linux/macOS/Git Bash.
#
# Phases:
#   1) seed  : team2 BO seeder (accounts + events/tables/hands fixtures)
#   2) api   : Playwright API+RBAC+WS tests
#   3) ui    : flutter_driver s11_lobby_test.dart (team1 Lobby)
#
# Flags:
#   --skip-seed   : skip step 1 (assume BO already seeded)
#   --skip-ui     : skip step 3 (CI often not able to run Flutter Desktop)
#   --api-only    : run step 2 only
#   --ui-only     : run step 3 only

set -euo pipefail

SKIP_SEED=0
SKIP_UI=0
ONLY=""

for arg in "$@"; do
  case "$arg" in
    --skip-seed) SKIP_SEED=1 ;;
    --skip-ui)   SKIP_UI=1 ;;
    --api-only)  ONLY="api" ;;
    --ui-only)   ONLY="ui" ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"

export BACKEND_HTTP_URL="${BACKEND_HTTP_URL:-http://localhost:8000}"
export BACKEND_WS_URL="${BACKEND_WS_URL:-ws://localhost:8000/ws/lobby}"

echo "[S-11] repo root: $REPO_ROOT"
echo "[S-11] backend: $BACKEND_HTTP_URL"

# -----------------------------------------------------------------------------
# Step 1: seed (team2 BO) — stub for now, team2 provides actual seeder later
# -----------------------------------------------------------------------------
if [[ "$SKIP_SEED" -eq 0 && "$ONLY" != "api" && "$ONLY" != "ui" ]]; then
  echo "[S-11] step 1 — seed (stub)"
  if command -v python >/dev/null 2>&1; then
    python "$SCRIPT_DIR/scripts/seed_s11.py" || {
      echo "[S-11] seed failed (non-blocking for template run)"
    }
  else
    echo "[S-11] python not found — skipping seed"
  fi
fi

# -----------------------------------------------------------------------------
# Step 2: Playwright API+WS
# -----------------------------------------------------------------------------
if [[ "$ONLY" != "ui" ]]; then
  echo "[S-11] step 2 — Playwright API+WS"
  pushd "$SCRIPT_DIR/playwright" >/dev/null
  if [[ ! -d node_modules ]]; then
    npm install --no-audit --no-fund
    npx playwright install chromium
  fi
  npx playwright test || exit $?
  popd >/dev/null
fi

# -----------------------------------------------------------------------------
# Step 3: flutter_driver (team1 Lobby)
# -----------------------------------------------------------------------------
if [[ "$SKIP_UI" -eq 0 && "$ONLY" != "api" ]]; then
  echo "[S-11] step 3 — flutter_driver (Lobby)"
  TEAM1_FRONTEND="$REPO_ROOT/team1-frontend"
  if [[ ! -d "$TEAM1_FRONTEND" ]]; then
    echo "[S-11] team1-frontend/ not found — skipping UI step"
  elif [[ ! -f "$TEAM1_FRONTEND/integration_test/s11_lobby_test.dart" ]]; then
    echo "[S-11] s11_lobby_test.dart not copied to team1-frontend/integration_test/ yet"
    echo "[S-11] (team1 ownership — see flutter_driver/README inside this directory)"
  else
    pushd "$TEAM1_FRONTEND" >/dev/null
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/s11_lobby_test.dart \
      --dart-define=BACKEND_HTTP_URL="$BACKEND_HTTP_URL"
    popd >/dev/null
  fi
fi

echo "[S-11] done."
