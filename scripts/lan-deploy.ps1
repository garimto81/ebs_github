# scripts/lan-deploy.ps1 — EBS LAN one-shot deploy (Windows host).
#
# 목적
#   호스트 머신의 LAN IPv4 자동 감지 + EBS_EXTERNAL_HOST 주입 + docker compose 기동 +
#   접속 URL 출력. 모바일 디바이스 / iPad / 노트북에서 별도 hosts file 등록 없이
#   http://<LAN_IP>:3000/ (Lobby) 와 http://<LAN_IP>:3001/ (CC) 직접 접근 가능.
#
# 사용법
#   .\scripts\lan-deploy.ps1                # 기본 — auto IP + compose up
#   .\scripts\lan-deploy.ps1 -DryRun        # 변경 없이 IP 감지 + URL 출력
#   .\scripts\lan-deploy.ps1 -Down          # docker compose --profile web down
#   .\scripts\lan-deploy.ps1 -EbsHost 10.10.0.5  # IP 수동 지정
#   .\scripts\lan-deploy.ps1 -SkipBuild     # 빌드 생략 (이미지 재사용)
#
# 정합
#   S11 SSOT: docs/4. Operations/Docker_Runtime.md
#   LAN 가이드: docs/4. Operations/LAN_DEPLOYMENT.md
#   본 cycle: GitHub issue #355 (S11 Cycle 9 — bind-mount 우회 도입),
#             issue #380 (S11 Cycle 10 — image 영구 흡수 + LAN IP reachability 추가)

[CmdletBinding()]
param(
    [string]$EbsHost = "",
    [switch]$DryRun,
    [switch]$Down,
    [switch]$SkipBuild,
    [switch]$VerboseLog
)

$ErrorActionPreference = "Stop"

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor Cyan
}

function Write-Step([string]$Msg) {
    Write-Host "[+] $Msg" -ForegroundColor Green
}

function Write-Warn([string]$Msg) {
    Write-Host "[!] $Msg" -ForegroundColor Yellow
}

function Write-Err([string]$Msg) {
    Write-Host "[X] $Msg" -ForegroundColor Red
}

# repo root 자동 이동 (scripts/ 에서 호출하면 상위로)
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repoRoot "docker-compose.yml"))) {
    Write-Err "docker-compose.yml not found at $repoRoot"
    exit 1
}
Set-Location $repoRoot

# -Down: 정리만
if ($Down) {
    Write-Section "EBS LAN - docker compose down"
    docker compose --profile web down
    exit $LASTEXITCODE
}

# LAN IPv4 자동 감지
function Get-LanIPv4 {
    # Docker bridge (172.17~172.31), WSL, VPN 가상 NIC 제외
    $candidates = Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp,Manual -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.IPAddress -notlike "172.1[6-9].*" -and
            $_.IPAddress -notlike "172.2[0-9].*" -and
            $_.IPAddress -notlike "172.3[0-1].*" -and
            $_.IPAddress -notlike "192.168.65.*" -and
            $_.IPAddress -notlike "10.0.75.*"
        } |
        Sort-Object -Property InterfaceMetric, IPAddress

    if (-not $candidates) { return $null }

    # 우선순위: 192.168.x.x > 10.x.x.x > 그 외
    $preferred = $candidates | Where-Object { $_.IPAddress -like "192.168.*" } | Select-Object -First 1
    if (-not $preferred) {
        $preferred = $candidates | Where-Object { $_.IPAddress -like "10.*" } | Select-Object -First 1
    }
    if (-not $preferred) {
        $preferred = $candidates | Select-Object -First 1
    }

    return @{
        IPAddress = $preferred.IPAddress
        Interface = (Get-NetAdapter -InterfaceIndex $preferred.InterfaceIndex).Name
        Metric    = $preferred.InterfaceMetric
    }
}

Write-Section "EBS LAN Deploy - Cycle 10 (image fold + LAN reachability)"

if (-not $EbsHost) {
    Write-Step "LAN IPv4 자동 감지 중..."
    $lan = Get-LanIPv4
    if (-not $lan) {
        Write-Err "LAN IPv4 감지 실패. -EbsHost <IP> 로 명시 지정하세요."
        exit 1
    }
    $EbsHost = $lan.IPAddress
    Write-Host "    -> Interface: $($lan.Interface)" -ForegroundColor Gray
    Write-Host "    -> Metric:    $($lan.Metric)" -ForegroundColor Gray
    Write-Host "    -> IPv4:      $EbsHost" -ForegroundColor White
} else {
    Write-Step "사용자 지정 IP: $EbsHost"
}

# 환경변수 export (현재 PowerShell session 한정)
$env:EBS_EXTERNAL_HOST = $EbsHost
$env:CORS_ORIGINS      = '["*"]'
$env:BO_URL            = "http://bo:8000"
$env:ENGINE_URL        = "http://engine:8080"
$env:LOBBY_URL         = "http://lobby-web:3000"
$env:CC_URL            = "http://cc-web:3001"

Write-Host ""
Write-Step "환경변수 주입"
Write-Host "    EBS_EXTERNAL_HOST = $env:EBS_EXTERNAL_HOST" -ForegroundColor Gray
Write-Host "    CORS_ORIGINS      = $env:CORS_ORIGINS" -ForegroundColor Gray

if ($DryRun) {
    Write-Section "DRY RUN - 실제 실행 생략"
    Write-Host "Lobby: http://${EbsHost}:3000/" -ForegroundColor White
    Write-Host "CC:    http://${EbsHost}:3001/" -ForegroundColor White
    Write-Host "BO:    http://${EbsHost}:8000/  (REST API 직접 - 디버그용)" -ForegroundColor Gray
    exit 0
}

# docker compose build (선택) + up
if (-not $SkipBuild) {
    Write-Section "docker compose --profile web build"
    docker compose --profile web build
    if ($LASTEXITCODE -ne 0) {
        Write-Err "build 실패 (exit code $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}

Write-Section "docker compose --profile web up -d"
docker compose --profile web up -d
if ($LASTEXITCODE -ne 0) {
    Write-Err "up -d 실패 (exit code $LASTEXITCODE)"
    exit $LASTEXITCODE
}

# healthy 대기 (최대 60초)
Write-Section "Healthcheck 대기 (최대 60초)"
$services = @("ebs-bo", "ebs-redis", "ebs-engine", "ebs-lobby-web", "ebs-cc-web")
$deadline = (Get-Date).AddSeconds(60)
$allHealthy = $false

while ((Get-Date) -lt $deadline) {
    $allHealthy = $true
    foreach ($svc in $services) {
        $status = docker inspect --format '{{.State.Health.Status}}' $svc 2>$null
        if ($status -ne "healthy") {
            $allHealthy = $false
            if ($VerboseLog) { Write-Host "    $svc : $status" -ForegroundColor Gray }
            break
        }
    }
    if ($allHealthy) { break }
    Start-Sleep -Seconds 3
}

if (-not $allHealthy) {
    Write-Warn "일부 컨테이너가 60초 내 healthy 도달 못 함. 'docker compose ps' 로 확인."
    docker compose --profile web ps
} else {
    Write-Step "모든 컨테이너 healthy OK"
}

# Probe helper — PowerShell 5.1 + 7 호환 (SkipHttpErrorCheck 는 PS7 전용이라 try-catch fallback)
function Invoke-EbsProbe {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [string]$Body = $null,
        [int]$TimeoutSec = 5
    )
    try {
        $params = @{
            Uri              = $Uri
            Method           = $Method
            UseBasicParsing  = $true
            TimeoutSec       = $TimeoutSec
            ErrorAction      = "Stop"
        }
        if ($Body) {
            $params["ContentType"] = "application/json"
            $params["Body"]        = $Body
        }
        $resp = Invoke-WebRequest @params
        return [pscustomobject]@{ Status = $resp.StatusCode; Ok = $true; Err = $null }
    } catch [System.Net.WebException] {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        return [pscustomobject]@{ Status = $code; Ok = $false; Err = $_.Exception.Message }
    } catch {
        return [pscustomobject]@{ Status = 0; Ok = $false; Err = "$_" }
    }
}

# nginx /api proxy 검증 (localhost — host PC 시점)
Write-Section "nginx /api proxy 검증 (localhost)"
$probe1 = Invoke-EbsProbe -Uri "http://localhost:3000/api/v1/auth/login" -Method POST `
    -Body '{"username":"_probe","password":"_probe"}'
if ($probe1.Status -eq 405) {
    Write-Err "FAIL: HTTP 405 - nginx 가 /api/ 를 proxy 하지 못함 (SPA fallback). image rebuild 후 재실행 필요."
} elseif ($probe1.Status -ge 200 -and $probe1.Status -lt 500) {
    Write-Step "PASS: HTTP $($probe1.Status) - /api/ proxy 활성 (401/422 정상, 405 만 FAIL)"
} elseif ($probe1.Status -eq 0) {
    Write-Warn "probe 요청 자체 실패: $($probe1.Err)"
} else {
    Write-Warn "HTTP $($probe1.Status) - BO 측 5xx 가능. 'docker logs ebs-bo' 확인."
}

# LAN IP reachability 검증 (KPI — hosts 매핑 없이 모바일/태블릿 접속 가능?)
# 외부 디바이스가 보는 것과 동일한 호스트 시점 (호스트 자기 LAN IP 로 self-reach)
Write-Section "LAN IP reachability 검증 (hosts 매핑 없이 작동 KPI)"
$probe2 = Invoke-EbsProbe -Uri "http://${EbsHost}:3000/healthz"
if ($probe2.Ok -and $probe2.Status -eq 200) {
    Write-Step "PASS: http://${EbsHost}:3000/healthz -> 200. 모바일/태블릿이 hosts 없이 도달 가능 예상."
} else {
    Write-Warn "FAIL: http://${EbsHost}:3000/healthz status=$($probe2.Status) err=$($probe2.Err)"
    Write-Warn "원인 후보: (a) Windows firewall 인바운드 3000 차단, (b) LAN IP 변경, (c) lobby-web 비정상."
}

$probe3 = Invoke-EbsProbe -Uri "http://${EbsHost}:3001/healthz"
if ($probe3.Ok -and $probe3.Status -eq 200) {
    Write-Step "PASS: http://${EbsHost}:3001/healthz -> 200 (CC 도 LAN 도달 가능)."
} else {
    Write-Warn "FAIL: http://${EbsHost}:3001/healthz status=$($probe3.Status) err=$($probe3.Err)"
}

$probe4 = Invoke-EbsProbe -Uri "http://${EbsHost}:3000/api/v1/auth/login" -Method POST `
    -Body '{"username":"_probe","password":"_probe"}'
if ($probe4.Status -ge 200 -and $probe4.Status -lt 500 -and $probe4.Status -ne 405) {
    Write-Step "PASS: LAN IP /api/ proxy 도 정상 (HTTP $($probe4.Status), BO 도달)."
} else {
    Write-Warn "LAN IP /api/ proxy 결과 비정상: status=$($probe4.Status) err=$($probe4.Err)"
}

# 접속 URL 출력
Write-Section "접속 URL (LAN 내 모든 디바이스)"
Write-Host ""
Write-Host "  Lobby (운영자 대시보드)" -ForegroundColor White
Write-Host "      http://${EbsHost}:3000/" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Command Center (테이블 운영)" -ForegroundColor White
Write-Host "      http://${EbsHost}:3001/" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Backend (REST 직접 - 디버그용)" -ForegroundColor Gray
Write-Host "      http://${EbsHost}:8000/docs   (OpenAPI Swagger)" -ForegroundColor Gray
Write-Host ""
Write-Host "  [DEPRECATED] subdomain 방식 (port 80, hosts file 의존)" -ForegroundColor DarkGray
Write-Host "      http://lobby.ebs.local/  (PR #69, 모바일/태블릿 hosts 편집 불가 -> 비권장)" -ForegroundColor DarkGray
Write-Host ""

Write-Section "모바일 / iPad / 노트북 접속 가이드"
Write-Host "1. 동일 LAN 에 연결 (Wi-Fi SSID 일치 확인)"
Write-Host "2. 호스트 머신 firewall 인바운드 3000/3001 허용 (Windows 방화벽 자동)"
Write-Host "3. 모바일 브라우저에서 http://${EbsHost}:3000/ 직접 입력 (hosts 매핑 불필요)"
Write-Host "4. 로그인 화면 도달 -> /api/v1/auth/login 정상 작동 확인"
Write-Host "5. F12 (또는 Safari 개발자 도구) Network 탭에서 /api/ 호출이 200 응답 확인"
Write-Host ""
Write-Host "문제 시 트러블슈팅: docs/4. Operations/LAN_DEPLOYMENT.md"
Write-Host ""
Write-Step "Cycle 10 LAN deploy 완료. 정리: .\scripts\lan-deploy.ps1 -Down"
