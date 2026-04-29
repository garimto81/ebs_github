#!/usr/bin/env bash
# EBS LAN Access Setup — Linux/macOS bash
#
# 2026-04-29 (PR #69, LAN domain deployment).
#
# Action:
#   (1) LAN IP 자동 감지
#   (2) /etc/hosts 에 ebs.local 매핑 등록 (sudo 필요)
#   (3) 다른 LAN 기기 등록 가이드 출력
#
# 사용:
#   sudo bash tools/setup_lan_access.sh                # 등록
#   sudo bash tools/setup_lan_access.sh --remove-only  # 제거
#        bash tools/setup_lan_access.sh --dry-run      # 미리보기

set -euo pipefail

HOSTNAME="${HOSTNAME_OVERRIDE:-ebs.local}"
SUBDOMAINS="ebs.local lobby.ebs.local cc.ebs.local api.ebs.local engine.ebs.local"
HOSTS="/etc/hosts"
MARKER="# EBS LAN Access (managed by setup_lan_access.sh)"

REMOVE_ONLY=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --remove-only) REMOVE_ONLY=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
  esac
done

# ── root check ──────────────────────────────────────────────────────────
if [ $DRY_RUN -eq 0 ] && [ "$(id -u)" -ne 0 ]; then
  echo "❌ root 권한 필요 (/etc/hosts 수정). sudo 사용." >&2
  exit 1
fi

# ── LAN IP 자동 감지 ─────────────────────────────────────────────────────
detect_lan_ip() {
  # macOS: ifconfig | grep inet
  # Linux: ip addr show
  local ip
  if command -v ip >/dev/null 2>&1; then
    ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')"
  elif command -v ifconfig >/dev/null 2>&1; then
    # macOS or older Linux
    ip="$(ifconfig | awk '/inet / && $2 != "127.0.0.1" && $2 !~ /^172\.(17|18|19|2[0-9]|3[01])\./ {print $2; exit}')"
  fi
  if [ -z "${ip:-}" ]; then
    echo "❌ LAN IPv4 주소 자동 감지 실패." >&2
    exit 2
  fi
  echo "$ip"
}

LAN_IP="$(detect_lan_ip)"

echo ""
echo "═══ EBS LAN Access Setup ═══"
echo " 호스트 머신 LAN IP: $LAN_IP"
echo " 등록할 도메인     : $SUBDOMAINS"
echo ""

# ── 기존 EBS block 제거 (idempotent) ─────────────────────────────────────
TMP_HOSTS="$(mktemp)"
trap "rm -f '$TMP_HOSTS'" EXIT

# remove existing EBS block (marker line + next non-empty line)
awk -v marker="$MARKER" '
  $0 == marker { in_ebs = 1; next }
  in_ebs && /^[[:space:]]*$/ { in_ebs = 0; print; next }
  in_ebs && /^#/ { in_ebs = 0; print; next }
  in_ebs { next }
  { print }
' "$HOSTS" > "$TMP_HOSTS"

if [ $REMOVE_ONLY -eq 1 ]; then
  echo "🗑️  cleanup 모드 — 기존 EBS hosts 등록 제거"
  if [ $DRY_RUN -eq 1 ]; then
    echo "[dry-run] 다음 /etc/hosts 로 변경:"
    cat "$TMP_HOSTS"
  else
    cat "$TMP_HOSTS" > "$HOSTS"
    echo "✓ /etc/hosts 정리 완료."
  fi
  exit 0
fi

# ── 새 EBS block 추가 ────────────────────────────────────────────────────
{
  cat "$TMP_HOSTS"
  echo ""
  echo "$MARKER"
  echo "$LAN_IP $SUBDOMAINS"
} > "$TMP_HOSTS.new"

if [ $DRY_RUN -eq 1 ]; then
  echo "[dry-run] 다음을 /etc/hosts 끝에 추가:"
  echo ""
  echo "$MARKER"
  echo "$LAN_IP $SUBDOMAINS"
  echo ""
else
  cat "$TMP_HOSTS.new" > "$HOSTS"
  rm -f "$TMP_HOSTS.new"
  echo "✓ /etc/hosts 업데이트 완료:"
  echo ""
  echo "    $MARKER"
  echo "    $LAN_IP $SUBDOMAINS"
  echo ""
fi

# ── DNS 캐시 flush (best-effort) ────────────────────────────────────────
if [ $DRY_RUN -eq 0 ]; then
  if command -v dscacheutil >/dev/null 2>&1; then
    dscacheutil -flushcache 2>/dev/null || true
    killall -HUP mDNSResponder 2>/dev/null || true
    echo "✓ macOS DNS 캐시 flush 완료."
  elif command -v systemd-resolve >/dev/null 2>&1; then
    systemd-resolve --flush-caches 2>/dev/null || true
    echo "✓ systemd-resolved 캐시 flush 완료."
  elif command -v resolvectl >/dev/null 2>&1; then
    resolvectl flush-caches 2>/dev/null || true
    echo "✓ resolvectl 캐시 flush 완료."
  fi
  echo ""
fi

# ── 다른 LAN 기기 등록 가이드 ─────────────────────────────────────────────
echo "═══ 다른 LAN 기기 등록 ═══"
echo ""
echo "각 기기에 다음을 hosts file 에 추가하세요:"
echo ""
echo "    $LAN_IP $SUBDOMAINS"
echo ""
echo "📁 hosts file 위치:"
echo "  Windows : C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "  macOS   : /etc/hosts"
echo "  Linux   : /etc/hosts"
echo ""
echo "또는 라우터 DNS 에 wildcard *.ebs.local → $LAN_IP 등록 (모든 LAN 기기 자동)"
echo ""

echo "═══ 다음 단계 ═══"
echo ""
echo "1. Docker 컨테이너 빌드:"
echo "     docker compose --profile web build"
echo ""
echo "2. 전체 stack 기동:"
echo "     docker compose --profile web up -d"
echo ""
echo "3. 검증 (호스트 머신):"
echo "     curl http://lobby.ebs.local/healthz"
echo "     xdg-open http://lobby.ebs.local  # Linux"
echo "     open http://lobby.ebs.local      # macOS"
echo ""
echo "📖 자세히: docs/4. Operations/LAN_DEPLOYMENT.md"
echo ""
