# S-11 automation orchestrator — Windows PowerShell.
#
# Flags:
#   -SkipSeed  : skip seeder
#   -SkipUi    : skip flutter_driver step (CI friendly)
#   -Only api|ui : run a single step

param(
  [switch]$SkipSeed,
  [switch]$SkipUi,
  [ValidateSet('', 'api', 'ui')]
  [string]$Only = ''
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\..\..\..\..')).Path

if (-not $env:BACKEND_HTTP_URL) { $env:BACKEND_HTTP_URL = 'http://localhost:8000' }
if (-not $env:BACKEND_WS_URL)   { $env:BACKEND_WS_URL   = 'ws://localhost:8000/ws/lobby' }

Write-Host "[S-11] repo root: $RepoRoot"
Write-Host "[S-11] backend: $($env:BACKEND_HTTP_URL)"

# Step 1: seed
if (-not $SkipSeed -and $Only -eq '') {
  Write-Host '[S-11] step 1 - seed (stub)'
  $seeder = Join-Path $ScriptDir 'scripts\seed_s11.py'
  if (Test-Path $seeder) {
    try { python $seeder } catch { Write-Warning "[S-11] seed failed (non-blocking)" }
  } else {
    Write-Host '[S-11] seeder stub not present yet — skipping'
  }
}

# Step 2: Playwright
if ($Only -ne 'ui') {
  Write-Host '[S-11] step 2 - Playwright API+WS'
  Push-Location (Join-Path $ScriptDir 'playwright')
  try {
    if (-not (Test-Path 'node_modules')) {
      npm install --no-audit --no-fund
      npx playwright install chromium
    }
    npx playwright test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  } finally { Pop-Location }
}

# Step 3: flutter_driver
if (-not $SkipUi -and $Only -ne 'api') {
  Write-Host '[S-11] step 3 - flutter_driver (Lobby)'
  $team1 = Join-Path $RepoRoot 'team1-frontend'
  $target = Join-Path $team1 'integration_test\s11_lobby_test.dart'
  if (-not (Test-Path $team1)) {
    Write-Host '[S-11] team1-frontend not found - skipping UI step'
  } elseif (-not (Test-Path $target)) {
    Write-Host '[S-11] target not copied to team1 yet (team1 ownership)'
  } else {
    Push-Location $team1
    try {
      flutter drive `
        --driver=test_driver/integration_test.dart `
        --target=integration_test/s11_lobby_test.dart `
        --dart-define=BACKEND_HTTP_URL=$env:BACKEND_HTTP_URL
    } finally { Pop-Location }
  }
}

Write-Host '[S-11] done.'
