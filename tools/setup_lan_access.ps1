# EBS LAN Access Setup — Windows PowerShell
#
# 2026-04-29 (PR #69, LAN domain deployment).
#
# Action:
#   (1) LAN IP 자동 감지
#   (2) hosts file 에 ebs.local 매핑 등록 (Administrator 권한 필요)
#   (3) 다른 LAN 기기 등록 가이드 출력
#
# 사용:
#   PowerShell (관리자 권한) → cd C:\claude\ebs → .\tools\setup_lan_access.ps1
#
# 옵션:
#   -Hostname <name>   기본 ebs.local. 다른 도메인 사용 시 명시
#   -RemoveOnly        등록 제거 (cleanup)
#   -DryRun            변경 미리보기만 (hosts file 수정 안 함)

param(
  [string]$Hostname = "ebs.local",
  [switch]$RemoveOnly,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ── Admin check ──────────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
              [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
  Write-Host "❌ Administrator 권한 필요 (hosts file 수정)." -ForegroundColor Red
  Write-Host "   PowerShell 을 '관리자 권한으로 실행' 하거나 -DryRun 옵션 사용." -ForegroundColor Yellow
  exit 1
}

# ── LAN IP 자동 감지 ─────────────────────────────────────────────────────
function Get-LanIPv4 {
  $candidates = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
      $_.IPAddress -notlike "127.*"        -and
      $_.IPAddress -notlike "169.254.*"    -and
      $_.IPAddress -notlike "172.17.*"     -and  # docker default bridge
      $_.IPAddress -notlike "172.18.*"     -and  # docker compose default
      $_.IPAddress -notlike "172.19.*"     -and
      $_.IPAddress -notlike "172.20.*"     -and
      $_.IPAddress -notlike "172.21.*"     -and
      $_.IPAddress -notlike "172.22.*"     -and
      $_.IPAddress -notlike "172.23.*"     -and
      $_.IPAddress -notlike "172.24.*"     -and
      $_.IPAddress -notlike "172.25.*"     -and
      $_.IPAddress -notlike "172.26.*"     -and
      $_.IPAddress -notlike "172.27.*"     -and
      $_.IPAddress -notlike "172.28.*"     -and
      $_.IPAddress -notlike "172.29.*"     -and
      $_.IPAddress -notlike "172.30.*"     -and
      $_.IPAddress -notlike "172.31.*"     -and
      $_.PrefixOrigin -ne "WellKnown"
    } |
    Sort-Object PrefixLength -Descending  # /24 같은 작은 subnet 우선

  if (-not $candidates) {
    Write-Host "❌ LAN IPv4 주소를 찾을 수 없습니다." -ForegroundColor Red
    exit 2
  }
  return $candidates[0].IPAddress
}

$lanIp = Get-LanIPv4
$subdomains = @("ebs.local", "lobby.ebs.local", "cc.ebs.local",
                "api.ebs.local", "engine.ebs.local")

Write-Host ""
Write-Host "═══ EBS LAN Access Setup ═══" -ForegroundColor Cyan
Write-Host " 호스트 머신 LAN IP: $lanIp"
Write-Host " 등록할 도메인     : $($subdomains -join ', ')"
Write-Host ""

# ── hosts file 위치 ──────────────────────────────────────────────────────
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$marker = "# EBS LAN Access (managed by setup_lan_access.ps1)"

# ── 기존 EBS block 제거 (idempotent) ─────────────────────────────────────
$hostsContent = Get-Content $hostsPath -Raw -Encoding UTF8
$pattern = "(?ms)^# EBS LAN Access \(managed by setup_lan_access\.ps1\).*?(?=^#|^\s*$|\z)"
$cleaned = [regex]::Replace($hostsContent, $pattern, "").TrimEnd() + "`r`n"

if ($RemoveOnly) {
  Write-Host "🗑️  cleanup 모드 — 기존 EBS hosts 등록 제거" -ForegroundColor Yellow
  if ($DryRun) {
    Write-Host "[dry-run] 다음 hosts file 로 변경:" -ForegroundColor Gray
    Write-Host $cleaned -ForegroundColor DarkGray
  } else {
    Set-Content -Path $hostsPath -Value $cleaned -Encoding UTF8 -NoNewline
    Write-Host "✓ hosts file 정리 완료." -ForegroundColor Green
  }
  exit 0
}

# ── 새 EBS block 작성 ────────────────────────────────────────────────────
$newBlock = @($marker, "$lanIp $($subdomains -join ' ')") -join "`r`n"
$newContent = $cleaned + $newBlock + "`r`n"

if ($DryRun) {
  Write-Host "[dry-run] 다음을 hosts file 끝에 추가:" -ForegroundColor Gray
  Write-Host ""
  Write-Host $newBlock -ForegroundColor White
  Write-Host ""
} else {
  Set-Content -Path $hostsPath -Value $newContent -Encoding UTF8 -NoNewline
  Write-Host "✓ hosts file 업데이트 완료:" -ForegroundColor Green
  Write-Host "    $hostsPath"
  Write-Host ""
  Write-Host "  추가된 라인:"
  Write-Host "    $marker" -ForegroundColor DarkGray
  Write-Host "    $lanIp $($subdomains -join ' ')" -ForegroundColor White
  Write-Host ""
}

# ── DNS 캐시 flush ──────────────────────────────────────────────────────
if (-not $DryRun) {
  ipconfig /flushdns | Out-Null
  Write-Host "✓ DNS 캐시 flush 완료." -ForegroundColor Green
  Write-Host ""
}

# ── 다른 LAN 기기 등록 가이드 ─────────────────────────────────────────────
Write-Host "═══ 다른 LAN 기기 등록 ═══" -ForegroundColor Cyan
Write-Host ""
Write-Host "각 기기에 다음을 hosts file 에 추가하세요:"
Write-Host ""
Write-Host "  $lanIp $($subdomains -join ' ')" -ForegroundColor White
Write-Host ""
Write-Host "📁 hosts file 위치:"
Write-Host "  Windows : C:\Windows\System32\drivers\etc\hosts"
Write-Host "  macOS   : /etc/hosts"
Write-Host "  Linux   : /etc/hosts"
Write-Host "  iOS     : (jailbreak 필요 — DNS 우회 앱 권장)"
Write-Host "  Android : (root 필요 — DNS 우회 앱 권장)"
Write-Host ""
Write-Host "또는 라우터 DNS 에 wildcard *.ebs.local → $lanIp 등록 (모든 LAN 기기 자동)"
Write-Host ""

Write-Host "═══ 다음 단계 ═══" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Docker 컨테이너 빌드:"
Write-Host "     docker compose --profile web build" -ForegroundColor White
Write-Host ""
Write-Host "2. 전체 stack 기동:"
Write-Host "     docker compose --profile web up -d" -ForegroundColor White
Write-Host ""
Write-Host "3. 검증 (호스트 머신):"
Write-Host "     curl http://lobby.ebs.local/healthz" -ForegroundColor White
Write-Host "     start http://lobby.ebs.local" -ForegroundColor White
Write-Host ""
Write-Host "📖 자세히: docs\4. Operations\LAN_DEPLOYMENT.md"
Write-Host ""
