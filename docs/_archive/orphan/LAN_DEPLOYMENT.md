---
title: LAN Deployment — Internal Network Access (port-direct only, subdomain DEPRECATED)
owner: conductor
tier: internal
last-updated: 2026-05-12
related-pr: "#69 (subdomain — DEPRECATED), Cycle 9 #355 (bind-mount 도입), Cycle 10 #380 (image 영구 흡수 + LAN reachability KPI)"
related-root-cause: "#369 (Lobby login hosts 의존 root cause 확정)"
status: ACTIVE
confluence-page-id: 3833626839
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833626839/Deployment
---

# EBS LAN 배포 가이드 — port-direct 단일 방식 (Cycle 10 정리)

## TL;DR — Cycle 10 갱신 (모바일 KPI)

**모바일 / iPad / 태블릿 = 방식 ① (포트 직접) 만 사용. hosts 매핑 의존 금지.**

호스트 머신 1대에서 다음 한 줄:

```powershell
.\scripts\lan-deploy.ps1
```

LAN IP 자동 감지 + `docker compose --profile web up -d` + nginx /api proxy 검증 + **LAN IP reachability KPI 검증 (3중 probe)** + 접속 URL 출력 + 모바일 가이드 모두 자동.

| URL | 서비스 | 디바이스 | hosts 매핑 |
|-----|--------|----------|:----------:|
| `http://<LAN_IP>:3000/` | Lobby (운영자 대시보드) | PC / 모바일 / iPad / Android | 불필요 |
| `http://<LAN_IP>:3001/` | Command Center | PC / 태블릿 | 불필요 |
| `http://<LAN_IP>:8000/docs` | Backend OpenAPI (Swagger) | PC 만 (디버그) | 불필요 |

### Cycle 9 vs Cycle 10 변화

| 항목 | Cycle 9 (PR #360) | Cycle 10 (PR #380) |
|------|-------------------|--------------------|
| nginx /api proxy 적용 위치 | docker-compose `volumes:` bind-mount | image 내부 `team{1,4}/docker/{lobby,cc}-web/nginx.conf` SSOT |
| image rebuild 안전성 | bind-mount 의존 (제거 시 silent drift) | image 자체 정합 (bind-mount 제거 가능) |
| 모바일 reachability 검증 | localhost:3000 만 | localhost + LAN IP healthz + LAN IP /api/ 3중 |
| PR #369 root cause | 우회 (bind-mount 임시 fix) | 영구 해소 (image SSOT same-origin) |

### 방식 ② — 서브도메인 (DEPRECATED, PR #69)

> **DEPRECATED 2026-05-12 Cycle 10**: hosts file 의존 → 모바일/iPad 편집 불가 → 본 가이드 권장 시나리오에서 제외. 인프라(`ebs-proxy` :80) 자체는 PC-만-LAN 환경 위해 유지하지만, **신규 배포 / 모바일 시연 / 외부 시연에서는 사용 금지**.

PC-만-LAN 환경 (모바일 시연 없음 + 사용자 모두 hosts 편집 가능) 의 보조 도구로만 활용. 모든 새 자동화 도구는 방식 ① 만 검증한다.

| 도메인 | 서비스 | 상태 |
|--------|--------|------|
| `http://lobby.ebs.local/`  | team1 lobby | DEPRECATED — `http://<LAN_IP>:3000/` 사용 |
| `http://cc.ebs.local/`     | team4 CC | DEPRECATED — `http://<LAN_IP>:3001/` 사용 |
| `http://ebs.local/`        | default lobby | DEPRECATED |
| `http://api.ebs.local/`    | team2 BO REST + WS | DEPRECATED — `<LAN_IP>:3000` 의 nginx /api 사용 |
| `http://engine.ebs.local/` | team3 engine | DEPRECATED |

### 비교 (Cycle 10)

| 항목 | 방식 ① (port-direct) — **권장** | 방식 ② (subdomain) — DEPRECATED |
|------|:-------------------------------:|:---------------------------------:|
| hosts file 등록 | 불필요 | 필요 (모든 디바이스) |
| 모바일 / iPad / Android | OK | 제한 (편집 불가) |
| 모바일 시연 시나리오 | ✓ | ✗ |
| nginx config 위치 | image 내부 SSOT | 별도 proxy 컨테이너 |
| image rebuild 안전 | 자체 정합 | proxy config drift 위험 |
| 새 자동화 도구 검증 | ✓ | ✗ |
| PR 추적 | #355 → #380 (image fold) | #69 (frozen) |

---



## 사전 요구

- **호스트 머신**: Docker Desktop (Windows) 또는 docker engine (Linux/macOS) + docker-compose v2+
- **호스트 LAN IP**: 고정 IP 권장 (DHCP reservation 또는 static). IP 변경 시 LAN 클라이언트 재설정 필요
- **방화벽 인바운드 허용**:
  - 방식 ①: TCP 3000 (lobby), 3001 (cc), 선택 8000 (bo 직접)
  - 방식 ②: TCP 80 (proxy)
  - Windows 방화벽은 docker compose up 시 자동 등록 (PowerShell 관리자 권한)
- **LAN 클라이언트**: 방식 ② 사용 시 hosts file 수정 권한 (Admin/sudo). 방식 ① 은 권한 불필요.

## 방식 ① — 포트 직접 접근 (간단, NEW Cycle 9)

### 한 번에 — `scripts/lan-deploy.ps1`

```powershell
cd C:\claude\ebs
.\scripts\lan-deploy.ps1
```

스크립트가 자동 수행:
1. LAN IPv4 감지 (docker bridge / VPN 가상 NIC 제외, `192.168.x.x` → `10.x.x.x` 우선)
2. `EBS_EXTERNAL_HOST` 환경변수 주입 (BO 의 `ws_url/rest_url` 생성에 사용)
3. `docker compose --profile web build` + `up -d`
4. 모든 컨테이너 healthy 대기 (최대 60초)
5. nginx `/api/` proxy 검증 (`POST localhost:3000/api/v1/auth/login` → 200/401/422 OK, 405 FAIL)
6. 접속 URL 출력 + 모바일 가이드

옵션:
- `-DryRun` — 실제 기동 없이 IP 감지 + URL 출력만
- `-Down` — `docker compose --profile web down`
- `-EbsHost 10.10.0.5` — IP 수동 지정
- `-SkipBuild` — 이미지 재사용 (build 생략)

### 수동 실행 (스크립트 없이)

```powershell
# 1. LAN IP 확인
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" }

# 2. 환경변수 주입 + 기동
$env:EBS_EXTERNAL_HOST = "10.10.100.115"   # 위에서 확인한 IP
$env:CORS_ORIGINS = '["*"]'
docker compose --profile web up -d

# 3. 검증
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/auth/login" -Method POST `
  -ContentType "application/json" -Body '{"username":"a","password":"b"}' `
  -UseBasicParsing -SkipHttpErrorCheck | Select-Object StatusCode
# StatusCode: 401 (또는 422) — 405 가 아니면 nginx /api proxy 정상
```

### 모바일 / iPad / 노트북 접속

1. 동일 LAN (Wi-Fi SSID 일치)
2. 브라우저에 `http://<HOST_LAN_IP>:3000/` 직접 입력 — hosts 등록 불필요
3. F12 / Safari 개발자도구 Network 탭에서 `/api/v1/*` 호출이 200 응답 확인

### 동작 원리

```
모바일 브라우저                  호스트 머신 (LAN IP)
  http://10.10.100.115:3000/ ─→  ebs-lobby-web (nginx, port 3000)
                                  │
                                  ├─ /                   → SPA (index.html)
                                  ├─ /api/v1/auth/login  → bo:8000/api/...
                                  └─ /ws/lobby           → bo:8000/ws/...  (Upgrade)
```

nginx 가 동일 origin 으로 reverse proxy 하므로 브라우저는 CORS preflight 를 발생시키지 않음.
이는 모바일 Safari 의 third-party origin 제약을 우회.

### nginx /api proxy 컨테이너 검증 (Cycle 10 갱신)

```powershell
docker exec ebs-lobby-web sh -c "cat /etc/nginx/conf.d/default.conf" | Select-String "/api/|/ws/"
# location /api/ {
# proxy_pass http://bo:8000/api/;
# location /ws/ {
# proxy_pass http://bo:8000/ws/;
```

Cycle 10 이후 image 내부 SSOT (`team1-frontend/docker/lobby-web/nginx.conf` + `team4-cc/docker/cc-web/nginx.conf`) 가 default. bind-mount 가 docker-compose 에 여전히 남아있어도 image config 와 동일 내용이라 silent drift 발생 안 함.

출력이 없으면:
1. 컨테이너가 cycle 10 image 로 rebuild 되었는지 확인 — `docker images | grep ebs/lobby-web` 의 created 시각
2. bind-mount 가 의도적으로 제거된 후 image rebuild 누락 → `docker compose --profile web build lobby-web`

### LAN IP reachability KPI (모바일 시연 사전 검증)

```powershell
# 호스트 PC 에서 자기 LAN IP 로 self-reach -> 모바일에서 보는 것과 동일한 origin
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" } |
       Select-Object -First 1).IPAddress
Invoke-WebRequest -Uri "http://${ip}:3000/healthz" -UseBasicParsing | Select-Object StatusCode
# StatusCode: 200 -> 모바일/태블릿이 hosts 매핑 없이 접속 가능
```

`scripts/lan-deploy.ps1` 가 본 KPI 를 자동 수행 (localhost /api + LAN IP /healthz + LAN IP /api 3중 probe). 200 이 아니면:
- Windows firewall 인바운드 3000/3001 차단 → 방화벽 인바운드 규칙 수동 추가
- LAN IP 변경 (DHCP) → 라우터 DHCP reservation 권장
- lobby-web 비정상 → `docker compose ps` healthy 확인 후 `docker compose logs lobby-web`

---

---

> **⚠️ DEPRECATED 2026-05-12 (Cycle 10) — 다음 섹션 (방식 ②) 은 PC-only LAN 환경의 보조 절차**: hosts file 의존 — 모바일/iPad/태블릿 편집 불가. 새 모바일 시연 / 신규 배포에서는 방식 ① 만 사용. 인프라(`ebs-proxy` :80) 자체는 호환성을 위해 유지하지만 active 권장 경로 아님.

## 방식 ② — Step 1: hosts file 등록 (호스트 머신)

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

## 방식 ② — Step 2: Docker stack 빌드 + 기동

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

## 방식 ② — Step 3: 호스트 머신 검증

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

## 방식 ② — Step 4: LAN 내 다른 기기에서 접근

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

### 방식 ① — 진화 chain
- PR #355 (Cycle 9 issue) — root cause 진단 + 방식 ① 도입 결정
- PR #360 (Cycle 9) — bind-mount 우회로 image stale config 덮어쓰기 (임시 해소)
- PR #369 (Cycle 9 QA, MERGED) — 6 screenshot e2e evidence + Lobby login hosts 의존 root cause 확정
- PR #380 (Cycle 10) — image 내부 `team{1,4}/docker/{lobby,cc}-web/nginx.conf` 영구 흡수 + LAN reachability KPI 자동 검증 + 본 docs 갱신

### 방식 ① — 자산 위치 (Cycle 10 이후)

| 자산 | 위치 | 역할 |
|------|------|------|
| Lobby nginx SSOT | `team1-frontend/docker/lobby-web/nginx.conf` | image 내부 SSOT (Cycle 10 흡수) |
| CC nginx SSOT | `team4-cc/docker/cc-web/nginx.conf` | image 내부 SSOT (Cycle 10 흡수) |
| bind-mount fallback | `infra/web/{lobby,cc}-web.nginx.conf` | `docker-compose.yml volumes:` 안전 fallback (Cycle 11 에서 제거 검토) |
| LAN one-shot deploy | `scripts/lan-deploy.ps1` | LAN IP 자동 감지 + 3중 reachability 검증 |

### 방식 ② — frozen (PR #69)
- `infra/proxy/nginx.conf` — reverse proxy (port 80, subdomain routing) — DEPRECATED
- `tools/setup_lan_access.{ps1,sh}` — 자동 hosts 등록 / 제거 — DEPRECATED
- `team1-frontend/production.example.json` — lobby 빌드 시 API host (subdomain) — Cycle 10 same-origin 도입 후 deprecated
- `team4-cc/docker/cc-web/Dockerfile` — cc 빌드 시 API host (inline JSON) — 동일 deprecated

### 공통
- 인프라 SSOT: `docs/4. Operations/Docker_Runtime.md`
- 검증 스크립트: `scripts/lan-deploy.ps1` (3중 probe), `team1-frontend/scripts/verify_harness.py`, `team1-frontend/tools/verify_team1_e2e.py`
