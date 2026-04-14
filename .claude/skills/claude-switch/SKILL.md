---
name: cc
version: 1.0.0
description: Claude Code 다중 계정 전환 관리
triggers:
  keywords:
    - cc
    - claude switch
    - 프로필 전환
    - 계정 전환
    - account switch
  patterns:
    - "cc (list|add|use|login|status|next|auto|config|env|run|remove)"
    - "프로필 (목록|추가|전환|삭제)"
---

# Claude Code Switch (/cc)

Claude Code 다중 계정 관리 및 자동 전환 시스템.

## 핵심 기능

| 명령 | 설명 |
|------|------|
| `cc list` | 프로필 목록 조회 |
| `cc add <name>` | 새 프로필 추가 |
| `cc use <name>` | 프로필 전환 |
| `cc login <name>` | 프로필 로그인 |
| `cc next` | 다음 프로필로 순환 |
| `cc auto on/off` | 자동 전환 설정 |

## 실행 지시

### 사용자가 프로필 목록 요청 시

```bash
python C:\claude\login_claudecode\cli.py list
```

### 사용자가 프로필 추가 요청 시

```bash
python C:\claude\login_claudecode\cli.py add <name> --email <email> --login
```

### 사용자가 프로필 전환 요청 시

```bash
python C:\claude\login_claudecode\cli.py use <name>
```

**전환 후 안내:**
새 터미널에서 환경변수를 설정해야 합니다:
```powershell
$env:CLAUDE_CONFIG_DIR = "$HOME\.claude-profiles\profiles\<name>"
```

### 사용자가 로그인 요청 시

```bash
python C:\claude\login_claudecode\cli.py login <name>
```

### 사용자가 자동 전환 활성화 요청 시

```bash
python C:\claude\login_claudecode\cli.py auto on
```

### 사용자가 상태 확인 요청 시

```bash
python C:\claude\login_claudecode\cli.py status
```

## 상태 아이콘

| 아이콘 | 의미 |
|--------|------|
| `[*]` | 활성 + 로그인됨 |
| `[!]` | 활성 + 로그인 필요 |
| `[ ]` | 비활성 + 로그인됨 |
| `[x]` | 비활성 + 로그인 필요 |

## 전환 전략

| 전략 | 설명 |
|------|------|
| `round_robin` | 순차적으로 다음 프로필 |
| `least_recently_used` | 가장 오래 미사용 프로필 |

설정 변경:
```bash
python C:\claude\login_claudecode\cli.py config --strategy least_recently_used
```

## 환경변수

`CLAUDE_CONFIG_DIR` 환경변수로 프로필 디렉토리를 지정합니다.

```powershell
# PowerShell
$env:CLAUDE_CONFIG_DIR = "$HOME\.claude-profiles\profiles\personal"
claude

# 또는 cc env 명령으로 출력
python C:\claude\login_claudecode\cli.py env personal --shell powershell
```

## 자동 전환 훅

`cc auto on` 활성화 시, rate limit 감지 시 자동으로 다음 프로필로 전환됩니다.

훅 설정 예시는 `C:\claude\login_claudecode\hooks\settings_example.json` 참조.

## 관련 파일

| 경로 | 용도 |
|------|------|
| `~/.claude-profiles/config.json` | 프로필 메타데이터 |
| `~/.claude-profiles/profiles/` | 프로필별 설정 디렉토리 |
| `C:\claude\login_claudecode\cli.py` | CLI 진입점 |
