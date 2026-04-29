---
title: LAN Deployment — Internal Network Domain Access
owner: conductor
tier: internal
last-updated: 2026-04-29
related-pr: "#69 (LAN domain deployment)"
status: ACTIVE
---

# EBS LAN 배포 가이드 — 내부 네트워크 도메인 접근

## TL;DR

호스트 머신 1대에서 `docker compose --profile web up -d` 실행 후 LAN 내 모든 기기에서 다음 도메인으로 접근:

| 도메인 | 서비스 | 용도 |
|--------|--------|------|
| `http://lobby.ebs.local/` | team1 lobby | 운영자 대시보드 (Series/Event/Flight/Table) |
| `http://cc.ebs.local/`    | team4 command center | 테이블별 실시간 액션 트래킹 |
| `http://ebs.local/`       | (default → lobby) | 짧은 진입점 |
| `http://api.ebs.local/`   | team2 BO REST + WS | 직접 API 호출 (디버깅) |
| `http://engine.ebs.local/`| team3 game engine | harness UI |

도메인 매핑은 단일 nginx reverse proxy (port 80) + LAN 클라이언트 hosts file 등록.

---

## 사전 요구

- **호스트 머신**: Docker Desktop (Windows) 또는 docker engine (Linux/macOS) + docker-compose v2+
- **호스트 LAN IP**: 고정 IP 권장 (DHCP reservation 또는 static). IP 변경 시 LAN 클라이언트 hosts 갱신 필요
- **포트 80 공개**: 호스트 firewall 에서 80 inbound 허용 (Windows 방화벽 자동 또는 수동)
- **LAN 클라이언트**: hosts file 수정 권한 (Admin/sudo)

## Step 1 — hosts file 등록 (호스트 머신)

자동 스크립트 실행:

### Windows (PowerShell, 관리자 권한)

```powershell
cd C:\claude\ebs
.\tools\setup_lan_access.ps1
```

### Linux / macOS

```bash
cd /path/to/ebs
sudo bash tools/setup_lan_access.sh
```

스크립트는:
1. LAN IPv4 자동 감지 (Docker bridge 172.17~172.31 제외)
2. `hosts` file 에 `<IP> ebs.local lobby.ebs.local cc.ebs.local api.ebs.local engine.ebs.local` 추가
3. DNS 캐시 flush
4. 다른 LAN 기기 등록 가이드 출력

옵션:
- `-DryRun` / `--dry-run` → 변경 미리보기만 (실제 수정 안 함)
- `-RemoveOnly` / `--remove-only` → 등록 제거 (cleanup)

## Step 2 — Docker stack 빌드 + 기동

```bash
# 1. 빌드 (lobby/cc Flutter web rebuild — production.json 의 api.ebs.local 반영)
docker compose --profile web build

# 2. 기동
docker compose --profile web up -d

# 3. 모든 컨테이너 healthy 확인 (15-30초 후)
docker ps --filter "name=ebs-" --format "table {{.Names}}\t{{.Status}}"
```

기대 결과:

```
NAMES           STATUS
ebs-proxy       Up X seconds (healthy)
ebs-lobby-web   Up X seconds (healthy)
ebs-cc-web      Up X seconds (healthy)
ebs-bo          Up X seconds (healthy)
ebs-engine      Up X seconds (healthy)
ebs-redis       Up X seconds (healthy)
```

## Step 3 — 호스트 머신 검증

```bash
# 도메인 resolve 확인
ping -n 1 lobby.ebs.local       # Windows
ping -c 1 lobby.ebs.local       # Linux/macOS

# proxy healthcheck
curl http://lobby.ebs.local/healthz  # → "ok"
curl http://api.ebs.local/healthz    # → "ok"

# 브라우저 접속
start http://lobby.ebs.local         # Windows
open http://lobby.ebs.local          # macOS
xdg-open http://lobby.ebs.local      # Linux
```

## Step 4 — LAN 내 다른 기기에서 접근

각 기기 (개발자/운영자 노트북, 태블릿 등) 에 hosts file 등록 필요. 두 가지 방법 중 택일:

### 방법 A — 각 기기 hosts file 수동 등록 (간단)

각 기기에 다음 라인 추가:

```
<HOST_LAN_IP> ebs.local lobby.ebs.local cc.ebs.local api.ebs.local engine.ebs.local
```

`<HOST_LAN_IP>` 는 Step 1 에서 출력된 호스트 LAN IP (예: `10.10.100.115`).

| OS | hosts file 위치 |
|----|-----------------|
| Windows | `C:\Windows\System32\drivers\etc\hosts` (관리자 권한) |
| macOS | `/etc/hosts` (sudo) |
| Linux | `/etc/hosts` (sudo) |
| iOS / Android | hosts 직접 편집 불가 (jailbreak/root 필요). 방법 B 권장. |

### 방법 B — 라우터 DNS 등록 (모든 LAN 기기 자동)

LAN 라우터의 DNS / DHCP 설정에서:
- A record: `lobby.ebs.local` → `<HOST_LAN_IP>`
- A record: `cc.ebs.local`    → `<HOST_LAN_IP>`
- A record: `api.ebs.local`   → `<HOST_LAN_IP>`
- A record: `engine.ebs.local`→ `<HOST_LAN_IP>`
- A record: `ebs.local`       → `<HOST_LAN_IP>`

또는 wildcard 지원 라우터 (e.g., dnsmasq, AdGuard Home, Pi-hole):
- `*.ebs.local` → `<HOST_LAN_IP>`

라우터 별 절차는 펌웨어 문서 참조.

### 검증 (다른 기기에서)

```
브라우저 → http://lobby.ebs.local
```

- ✓ Lobby 화면 정상 로드
- ✓ Network tab 에서 `api.ebs.local/api/v1/*` 호출 확인
- ✓ WebSocket: `ws://api.ebs.local/ws/lobby` 연결 확인 (auth gate 인 경우 401/403 정상)

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAN 클라이언트 (브라우저)                      │
│   hosts: <HOST_IP> *.ebs.local                                   │
└───────────────┬─────────────────────────────────────────────────┘
                │ HTTP/WS :80
                ▼
┌─────────────────────────────────────────────────────────────────┐
│              호스트 머신 (LAN IP, 포트 80 expose)                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ebs-proxy (nginx :80) — server_name 기반 routing            │ │
│  └─┬──────────┬──────────┬────────────┬─────────────────────┬─┘ │
│    │ lobby.   │ cc.      │ api.       │ engine.             │   │
│    │ ebs.     │ ebs.     │ ebs.       │ ebs.                │   │
│    │ local    │ local    │ local      │ local               │   │
│    ▼          ▼          ▼            ▼                     │   │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                    │   │
│  │lobby-│  │cc-web│  │  bo  │  │engine│                    │   │
│  │ web  │  │      │  │      │  │      │                    │   │
│  │:3000 │  │:3001 │  │:8000 │  │:8080 │                    │   │
│  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘                    │   │
│     │         │         │         │                         │   │
│     └─────────┴─────────┴─────────┘                         │   │
│              ebs-net (docker bridge)                         │   │
└─────────────────────────────────────────────────────────────────┘
```

## 트러블슈팅

### `lobby.ebs.local` resolve 안 됨

```
ping lobby.ebs.local
→ "Ping request could not find host"
```

**원인**: hosts file 미등록 또는 DNS 캐시 stale.

**해결**:
1. hosts file 확인: `cat /etc/hosts` 또는 `notepad C:\Windows\System32\drivers\etc\hosts`
2. EBS 블록 라인 존재 확인
3. DNS 캐시 flush:
   - Windows: `ipconfig /flushdns`
   - macOS: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
   - Linux: `sudo systemd-resolve --flush-caches` 또는 `sudo resolvectl flush-caches`

### 호스트 머신은 OK, 다른 기기는 안 됨

**원인 1**: 다른 기기 hosts file 미등록 → Step 4 방법 A 또는 B 실행

**원인 2**: 호스트 머신 firewall 80 inbound 차단:
- Windows: 방화벽 → 인바운드 규칙 → "EBS Proxy" → 80 TCP 허용
- macOS: System Preferences → Security & Privacy → Firewall → docker 허용
- Linux: `sudo ufw allow 80/tcp`

**원인 3**: 호스트 LAN IP 변경 (DHCP):
- 모든 클라이언트 hosts 재등록 필요. 또는 라우터에서 호스트 머신에 DHCP reservation 설정.

### 컨테이너가 healthy 안 됨

```bash
docker compose logs proxy lobby-web cc-web bo
```

자주 발생:
- `bo` 미기동 시 proxy 가 healthcheck 실패 — `bo` 먼저 healthy 확인
- `lobby-web` 빌드 시 `EBS_BO_HOST=api.ebs.local` 미적용 → `production.json` 확인

### CORS / WebSocket 차단

bo 의 `CORS_ORIGINS` default `["*"]` 이지만 prod 환경에서 좁히면 LAN 도메인 명시:

```yaml
# docker-compose.yml bo.environment
- CORS_ORIGINS=["http://lobby.ebs.local", "http://cc.ebs.local", "http://ebs.local"]
```

## 정리 / 롤백

```powershell
# Windows
.\tools\setup_lan_access.ps1 -RemoveOnly

# Linux/macOS
sudo bash tools/setup_lan_access.sh --remove-only

# Docker stack 중지
docker compose --profile web down
```

## 보안 고려

- **HTTP only** (HTTPS 미적용): LAN 내부 통신만 가정. 외부 노출 시 reverse proxy 에 TLS termination 추가 필요.
- **bo CORS_ORIGINS=["*"]**: dev 기본값. prod 환경 (외부 노출) 에서는 LAN 도메인 화이트리스트 명시 권장.
- **포트 80 공개**: 호스트 firewall 만 통과. 라우터 외부 노출 (port forwarding) 금지.

## 관련 PR / 문서

- **PR #69** — 본 LAN 배포 인프라 도입
- `infra/proxy/nginx.conf` — reverse proxy config
- `tools/setup_lan_access.{ps1,sh}` — 자동 hosts 등록
- `team1-frontend/production.example.json` — lobby 빌드 시 API host
- `team4-cc/docker/cc-web/Dockerfile` — cc 빌드 시 API host (inline JSON)
- 인프라 SSOT: `docs/4. Operations/Docker_Runtime.md`
- 검증 스크립트: `team1-frontend/scripts/verify_harness.py`, `team1-frontend/tools/verify_team1_e2e.py`
