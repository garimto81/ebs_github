# setup_drive_scheduler.ps1 -- EBS Drive 자동 동기화 스케줄러 등록
# 실행: PowerShell에서 .\setup_drive_scheduler.ps1

$pythonExe = (Get-Command python).Source
$scriptPath = "C:\claude\ebs\sync_ebs_drive.py"
$logDir = "C:\claude\ebs\logs"

# 로그 디렉토리 생성
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "로그 디렉토리 생성: $logDir"
}

# Task Scheduler 등록 (매일 09:00)
# 로그 파일은 날짜별로 생성됨
$taskAction = New-ScheduledTaskAction `
    -Execute $pythonExe `
    -Argument "$scriptPath" `
    -WorkingDirectory "C:\claude"

$taskTrigger = New-ScheduledTaskTrigger -Daily -At "09:00"

$taskSettings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "EBS-Drive-Sync" `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Settings $taskSettings `
    -Description "EBS Google Drive 단방향 동기화 (로컬 -> Drive)" `
    -Force

Write-Host "스케줄러 등록 완료: EBS-Drive-Sync (매일 09:00)"
Write-Host "로그 위치: $logDir\sync-YYYY-MM-DD.log"
Write-Host ""
Write-Host "수동 실행 확인:"
Write-Host "  cd C:\claude && python ebs\sync_ebs_drive.py --dry-run"
