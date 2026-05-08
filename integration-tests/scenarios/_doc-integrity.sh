#!/usr/bin/env bash
# integration-tests/scenarios/_doc-integrity.sh
#
# 문서 정합성 자동 검증 (S6 책임 — Layer 경계 등 grep 기반).
# Prototype_Build_Plan.md §4.3 / §6.1 Cascade 정합 게이트 일부.
#
# 검증 대상 (CCR 매핑):
#   CCR-014: GE Metadata 25 필드 (GEM-01 ~ GEM-25) 존재
#   CCR-016: Lobby 기술 스택 = Flutter (Foundation v4.5 결정)
#   CCR-025: Settings Graphics §6 Active Skin 섹션 존재
#   CCR-035: Layer Boundary 정본 파일 존재 + 참조
#
# Exit code:
#   0 = 모든 검증 PASS
#   N = N개 항목 FAIL (N > 0)
#
# 실행:
#   bash integration-tests/scenarios/_doc-integrity.sh
#   (worktree root 에서 실행 가정)

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

PASS=0
FAIL=0
FAILED_CHECKS=()

ok() {
    echo "  [PASS] $1"
    PASS=$((PASS + 1))
}

ng() {
    echo "  [FAIL] $1"
    FAIL=$((FAIL + 1))
    FAILED_CHECKS+=("$1")
}

# ----------------------------------------------------------------------
echo "=== CCR-014: GE Metadata 25 필드 (GEM-01~GEM-25) ==="
GE_DIR="docs/2. Development/2.1 Frontend/Graphic_Editor"

if [ ! -d "$GE_DIR" ]; then
    ng "CCR-014: GE 디렉토리 없음 ($GE_DIR)"
else
    expected=25
    found=$(grep -hoE "GEM-(0[1-9]|1[0-9]|2[0-5])" "$GE_DIR"/UI.md "$GE_DIR"/Metadata_Editing.md "$GE_DIR"/Overview.md 2>/dev/null \
            | sort -u | wc -l)
    if [ "$found" -ge "$expected" ]; then
        ok "CCR-014: GEM-01~GEM-25 모두 발견 ($found/$expected)"
    else
        ng "CCR-014: GEM 필드 부족 ($found/$expected)"
    fi
fi

# ----------------------------------------------------------------------
echo "=== CCR-016: Lobby 기술 스택 = Flutter ==="
LOBBY_OVERVIEW="docs/2. Development/2.1 Frontend/Lobby/Overview.md"

if [ ! -f "$LOBBY_OVERVIEW" ]; then
    ng "CCR-016: Lobby Overview 파일 없음"
else
    if grep -qE "Flutter" "$LOBBY_OVERVIEW"; then
        ok "CCR-016: Lobby Overview 에 Flutter 명시"
    else
        ng "CCR-016: Lobby Overview 에 Flutter 명시 없음"
    fi

    # 추가: 구식 'Quasar Framework' 단독 잔존 검사 (Foundation v4.5 후 제거되어야 함)
    if grep -qE "^.*Quasar Framework" "$LOBBY_OVERVIEW" 2>/dev/null; then
        # Quasar 가 historical 컨텍스트로만 등장하면 OK. 확정 목적의 단독 명시는 drift.
        if grep -qE "기술 스택.*Quasar" "$LOBBY_OVERVIEW"; then
            ng "CCR-016: Lobby 기술 스택이 아직 Quasar 로 남음"
        fi
    fi
fi

# ----------------------------------------------------------------------
echo "=== CCR-025: Settings Graphics §6 Active Skin ==="
GFX_FILE="docs/2. Development/2.1 Frontend/Settings/Graphics.md"

if [ ! -f "$GFX_FILE" ]; then
    ng "CCR-025: Settings/Graphics.md 없음"
else
    if grep -qE "^#+\s+.*Active Skin" "$GFX_FILE"; then
        ok "CCR-025: Active Skin 섹션 존재"
    else
        ng "CCR-025: Active Skin 섹션 누락"
    fi
fi

# ----------------------------------------------------------------------
echo "=== CCR-035: Layer Boundary 정본 + 참조 ==="
LB_FILE="docs/2. Development/2.4 Command Center/Overlay/Layer_Boundary.md"
OVERLAY_OVERVIEW="docs/2. Development/2.4 Command Center/Overlay/Overview.md"

if [ ! -f "$LB_FILE" ]; then
    ng "CCR-035: Layer_Boundary.md 정본 없음"
else
    ok "CCR-035: Layer_Boundary.md 존재"
fi

if [ -f "$OVERLAY_OVERVIEW" ]; then
    if grep -qE "Layer.?Boundary|layer.boundary" "$OVERLAY_OVERVIEW"; then
        ok "CCR-035: Overlay Overview 에서 Layer Boundary 참조"
    else
        ng "CCR-035: Overlay Overview 에서 Layer Boundary 미참조"
    fi
else
    ng "CCR-035: Overlay Overview 파일 없음"
fi

# ----------------------------------------------------------------------
echo ""
echo "=== 결과 ==="
echo "PASS: $PASS / FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "FAILED checks:"
    for c in "${FAILED_CHECKS[@]}"; do
        echo "  - $c"
    done
fi

exit "$FAIL"
