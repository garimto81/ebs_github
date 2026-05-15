---
title: Network Configuration Contract
owner: conductor
tier: contract
last-updated: 2026-04-17
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "네트워크 구성 계약 (tier=contract, 3KB)"
confluence-page-id: 3819209219
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209219/EBS+Network+Configuration+Contract
related-spec:
  - ../2.1 Frontend/Lobby/Overview.md
  - ../2.2 Backend/Back_Office/Overview.md
  - ../2.3 Game Engine/Rules/Multi_Hand_v03.md
  - ../2.4 Command Center/Command_Center_UI/Overview.md
mirror: none
---
# Network Configuration Contract

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-17 | 신규 작성 | 포트 할당, 환경 변수 규칙, 서비스 디스커버리, CORS, WS 계약 |

---

## 포트 할당 SSOT

| 서비스 | 포트 | 프로토콜 | 소유 팀 |
|--------|:----:|:--------:|---------|
| Back Office (BO) | 8000 | HTTP + WS | team2 |
| Game Engine | 8080 | HTTP | team3 |
| Redis | 6379 | TCP | team2 (내부) |
| CC Web (Nginx) | 3100 | HTTP | team4 |
| Lobby Dev Server | 9000 | HTTP | team1 |

> 포트 변경은 **이 문서를 먼저 수정**한 후 각 팀에서 반영. 이 테이블이 SSOT.

---

## 환경 변수 네이밍 규칙

| 규칙 | 예시 |
|------|------|
| `EBS_` prefix 필수 | `EBS_BO_HOST`, `EBS_ENGINE_PORT` |
| UPPER_SNAKE_CASE | `EBS_EXTERNAL_HOST` (O) / `ebs-external-host` (X) |
| 컴포넌트별 prefix 권장 | `EBS_BO_*`, `EBS_ENGINE_*`, `EBS_CC_*` |
| 비밀값은 `_SECRET` suffix | `JWT_SECRET`, `EBS_API_SECRET` |
| URL은 `_URL` suffix | `REDIS_URL`, `DATABASE_URL` |

팀별 자체 변수(내부 전용)는 `EBS_` prefix 없이 사용 가능. 팀 간 공유 변수는 반드시 `EBS_` prefix.

---

## 서비스 디스커버리

### Phase 1 (현재): IP 직접 지정

모든 컴포넌트는 환경변수 또는 CLI 인자로 서버 IP를 직접 지정한다.

```
CC  → --bo_base_url=http://192.168.1.100:8000
CC  → --engine_url=http://192.168.1.100:8080
Lobby → VITE_API_BASE_URL=http://192.168.1.100:8000/api/v1
```

### Phase 2 (예정): mDNS `.local`

| 서비스 | mDNS 이름 | 해석 |
|--------|-----------|------|
| BO | `ebs-bo.local` | `{LAN_IP}:8000` |
| Engine | `ebs-engine.local` | `{LAN_IP}:8080` |

mDNS 도입 시 기존 IP 직접 지정도 fallback으로 유지한다.

---

## CORS 정책

| 환경 | 값 | 변경 주체 |
|------|-----|-----------|
| dev | `["*"]` | team2 (BO 설정) |
| lan | `["http://192.168.*"]` | team2 |
| prod | 명시적 Origin 목록 | conductor 승인 후 team2 반영 |

CORS 정책 변경 시 이 문서의 테이블을 먼저 갱신하고, BO `CORS_ORIGINS` 환경변수에 반영.

---

## WebSocket 엔드포인트 계약

### `/ws/lobby`

| 항목 | 값 |
|------|----|
| URL | `ws://{host}:8000/ws/lobby` |
| 인증 | Query param `?token={JWT}` |
| 방향 | **서버 → 클라이언트** (모니터링 전용, write 명령 없음) |
| 소유 | team2 (publisher), team1 (consumer) |

### `/ws/cc`

| 항목 | 값 |
|------|----|
| URL | `ws://{host}:8000/ws/cc` |
| 인증 | Query param `?token={JWT}` |
| 추가 params | `?table_id={N}&cc_instance_id={UUID}` |
| 방향 | **양방향** (CC ↔ BO) |
| 소유 | team2 (publisher), team4 (consumer) |

> 엔드포인트 추가/변경 시 이 문서와 `Backend/APIs/WebSocket_Events.md`를 동시 갱신.
