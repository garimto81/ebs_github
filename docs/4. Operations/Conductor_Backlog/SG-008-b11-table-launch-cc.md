---
id: SG-008-b11
title: "POST /api/v1/tables/{table_id}/launch-cc 필요성 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2, team4]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.4 Command Center/
  - docs/2. Development/2.1 Frontend/Lobby/
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
---

# SG-008-b11 — `POST /api/v1/tables/{table_id}/launch-cc` 필요성

## 배경

SG-008 §"b분류" 에서 승격. CC 앱을 원격으로 launch 하는 endpoint. 기획은 Lobby UI 에서 Operator 가 직접 CC 데스크톱 앱을 실행하는 패턴 (deep-link) 가정. 백엔드 endpoint 필요성 재검토 필요.

## 대상 endpoint (code-only)

- `POST /api/v1/tables/{table_id}/launch-cc` — CC 앱 원격 launch signal

## 논점

1. CC launch 메커니즘 — OS deep-link(`ebs-cc://table/{id}?token=...`) vs WebSocket push (`LaunchCCRequested` 이벤트) vs 본 REST endpoint
2. 누가 발행? — Lobby UI 의 "Launch CC" 버튼? Admin 이 원격으로? 자동화(CI) ?
3. 보안 — launch 시 access token 전달 방식 (query param 노출 위험)
4. 현재 코드가 실제로 무엇을 하는지 — DB 기록? Push notification? 실제 launch 는 CC side 에서 polling?

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Deep-link 방식 전환, 본 endpoint 삭제 | OS native, token 은 short-lived 로 URL fragment 전달. 백엔드 로직 zero | Lobby 와 CC 가 같은 OS user session 필수 |
| 2. WebSocket push 로 전환 — `POST` 대신 BO 가 CC 채널에 `LaunchCCRequested` 이벤트 발행 | CC 가 이미 WebSocket 연결 중이면 즉시 반응. 원격 launch 가능 | CC 앱이 먼저 실행되어 있어야 (해결 순환) |
| 3. 본 endpoint 유지 — RBAC + 명확한 semantics 문서화 | 기존 코드 활용 | 실제 "launch" 는 CC side 구현 필요 (현재 stub?) |

## Default 제안

**옵션 1 (Deep-link 전환, 코드 삭제)**. 이유:
- WSOP LIVE `Staff App §Launch` 는 deep-link (`wsop-staff://table/{id}`) 패턴
- Lobby 웹 + CC 데스크톱 앱은 동일 Operator 장비에서 운용 — deep-link 가 UX 자연스러움
- "원격 launch" 요구사항이 기획 본문에 없음 (Foundation.md / BS-02-lobby.md)
- deep-link 는 브라우저 표준 지원, 백엔드 코드 불필요
- 만약 향후 "원격 launch" (예: TD 가 Operator PC 에 원격으로 CC 실행) 요구 발생 시 옵션 2 로 재설계

**스펙 제안 초안 (옵션 1 채택 시)**:
- team2 코드 삭제: `POST /api/v1/tables/{table_id}/launch-cc` router 제거
- Lobby Frontend: "Launch CC" 버튼 클릭 시 `window.location = ebs-cc://table/${id}?token=${short_lived_token}`
- CC 앱: OS protocol handler 등록 (Flutter `app_links` 패키지)
- Backend_HTTP.md §Explicit Non-Goals 에 기록
- decision_owners_notified: team1 (Lobby button 구현), team4 (CC deep-link handler)

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: team2 코드 삭제 + Lobby/CC deep-link 구현 (team1/team4 Backlog 추가)
- [ ] 옵션 2: WebSocket 이벤트 스펙 정의 (WebSocket_Events.md §5 에 추가) + team2 구현 조정
- [ ] 옵션 3: Backend_HTTP.md 섹션 작성 + CC side 구현 확인 (team4 Backlog)


## Resolution

**2026-04-20: 옵션 1 채택** — deep-link 전환, POST /launch-cc 삭제.

**2026-05-03 v1.2 — Web variant 복원** (Conductor Mode A 자율, E2E 검증 cascade):

Phase 1 Korea soft-launch 가 **Docker Web 배포** (lobby-web :3000 + cc-web :3001) 로 결정됨에 따라
브라우저에서 OS deep-link (`ebs-cc://`) 미작동 → 옵션 1 단독 적용 시 Lobby → CC 호출 chain
break. 옵션 1 + 4 hybrid 채택:

| 옵션 | 채택 | 처리 |
|:---:|:----:|------|
| 1 (deep-link) | ✅ 보존 | Desktop 배포 시 활성화 (response.deep_link) |
| 4 (Web URL endpoint) ⭐ NEW | ✅ 추가 | Browser 배포 활성화 (response.cc_url) |

**Endpoint 복원**: `POST /api/v1/tables/{table_id}/launch-cc`

Response shape (V9.5 P26+):
```json
{
  "data": {
    "table_id": 1,
    "status": "live",
    "cc_instance_id": "uuid-v4",
    "launch_token": "JWT (5min)",
    "ws_url": "ws://bo:8000/ws/cc?table_id=1",
    "cc_url": "http://<EBS_EXTERNAL_HOST>:3001/?table_id=1&token=...&cc_instance_id=...",
    "deep_link": "ebs-cc://table/1?token=...&cc_instance_id=...",
    "launched_at": "2026-05-03T14:21:10Z"
  }
}
```

**Client launch logic**:
- Web (browser): `window.location = response.cc_url`
- Desktop (Flutter): try `deep_link` → fallback `cc_url`

**Env vars (BO)**:
- `EBS_EXTERNAL_HOST` — browser-facing host (default `localhost`)
- `CC_EXTERNAL_URL` — direct override (proxy/HTTPS 환경)

**E2E evidence (2026-05-03)**:
- `tools/e2e_lobby_to_cc_ws.py` 9/9 PASS
  - login → series → events → flights → tables → launch-cc → WS connect

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드: `team2-backend/src/routers/tables.py:api_launch_cc()` 복원

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: deep-link 전환, POST /launch-cc 삭제 | team2 session |
| 2026-05-03 | v1.2 | Web variant 복원 — endpoint 재도입 + dual response (cc_url + deep_link). E2E 9/9 PASS | Conductor Mode A 자율 |
