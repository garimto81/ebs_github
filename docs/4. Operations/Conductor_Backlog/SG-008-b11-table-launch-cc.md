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
reimplementability_notes: "v1.3 (2026-05-03) — same-window + URL query parsing cascade"
tier: internal
backlog-status: open
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

**2026-05-03 v1.3 — Same-window navigation + URL query parsing 정합**:

v1.2 적용 후 사용자 의도 재명시: "하나의 창 안에서 처리". 2 cascade 변경:

| 변경 | 위치 | 의도 |
|------|------|------|
| 1. Lobby Web `_blank` → `location.assign` | `team1-frontend/lib/foundation/launchers/cc_launcher_web.dart:14` | 동일 탭 navigation, browser back 으로 lobby 회귀 |
| 2. CC Web `Uri.base.queryParameters` 자동 파싱 | `team4-cc/src/lib/models/launch_config.dart:93` `tryFromQuery()` + `main.dart:31` fallback | URL query 자동 인식 → manual "Connect" 폼 미표시 |

**Browser launch flow (v1.3)**:

```
[Lobby :3000]                          [BO :8000]                  [CC :3001 same tab]
   |                                      |                                |
   |--POST /tables/1/launch-cc----------->|                                |
   |<--{cc_url, deep_link, token, ...}----|                                |
   |                                                                      |
   |--window.location.assign(cc_url)----------------------------(same tab)>|
   |                                       Uri.base.queryParameters       |
   |                                       → tryFromQuery() → LaunchConfig|
   |                                       → auto-connect (manual skip)   |
```

**검증 확인 사항 (v1.3 추가)**:
- 새 탭 차단 (popup blocker) 영향 0
- browser back 버튼 = lobby 회귀
- `Uri.base.queryParameters` = Flutter Web 표준 (dart:html 의존 0)
- demo fallback (`?demo=1`) 보존: query 일부만 있을 때 default 채움

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드: `team2-backend/src/routers/tables.py:api_launch_cc()` 복원

**2026-05-04 v1.4 — Iframe Embed + Password-Only Connect**:

v1.3 사용자 비판 후 critic-mode 분석 (`docs/4. Operations/Critic_Reports/SG-008-b11-v13-critic-2026-05-03.md`)
결과 3 critical gap 식별:

| 변경 | 위치 | 사용자 의도 |
|------|------|------------|
| 1. Lobby `location.assign` → **fullscreen Dialog + iframe** | `team1-frontend/lib/foundation/launchers/cc_iframe_view{.dart, _web.dart, _stub.dart}` + `table_detail_screen.dart:_handleLaunchCc` | "해당 로비에 해당 cc 를 선택해서 진행중이라는 상호작용" — lobby UI 보존 + CC active 시각 표현 |
| 2. CC stand-alone 4-field form → **password-only** | `team4-cc/src/lib/features/command_center/screens/at_00_login_screen.dart` 전면 재작성 | "connect 창은 오로지 비번 입력만 있어야 함 (lobby settings 에서 설정 가능)" |
| 3. CC localStorage 영속 — `ebs_cc_last_config` | `team4-cc/src/lib/foundation/cc_settings_storage{.dart, _web.dart, _stub.dart}` + `auth_provider.dart` save hook | URL launch / 비번 connect 시 last session 자동 저장 → 다음 stand-alone 진입은 비번만 |

**Browser launch flow (v1.4)**:

```
[Lobby :3000 — 보존됨]                                      [BO :8000]
   ┌──────────────────────────────┐                              │
   │ Table Detail [Enter CC]      │──POST /launch-cc────────────>│
   │                              │<──{cc_url, token, ...}───────┤
   │ ┌──────────────────────────┐ │                              │
   │ │ Dialog.fullscreen        │ │     (iframe loads CC)
   │ │ ┌──────────────────────┐ │ │                              │
   │ │ │ AppBar: Active CC -  │ │ │   [CC :3001 — iframe inside lobby]
   │ │ │ Table N        [X]   │ │ │   - Uri.base.queryParameters parse
   │ │ │                      │ │ │   - auto-auth → /main
   │ │ │   <iframe src=cc_url>│ │ │   - 비번 폼 미표시 (loading placeholder만)
   │ │ │     CC content       │ │ │   - localStorage save (next time)
   │ │ │                      │ │ │
   │ │ └──────────────────────┘ │ │
   │ └──────────────────────────┘ │
   └──────────────────────────────┘   (X 닫기 → lobby 회귀)
```

**Stand-alone 재진입 (CC :3001 직접 접속)**:

```
[CC :3001 — URL query 없음]
  ↓
  config = LaunchConfig.tryFromArgs([])  → null
  config = LaunchConfig.tryFromQuery(empty)  → null
  ↓
  CcSettingsStorage.loadLastSession() → CcLastSession{email, boBaseUrl, tableId, wsUrl}
  ↓
  at_00_login_screen 표시 (last session 카드 + 비번 1 field)
  ↓
  사용자 비번 입력 → POST /auth/login → token → CC 사용
```

**검증 (v1.4)**:

| # | 항목 | 도구 |
|:-:|------|------|
| 1 | backend chain 9/9 | `tools/e2e_lobby_to_cc_ws.py` |
| 2 | lobby 배포 JS 에 iframe HtmlElementView 포함 | `docker exec ebs-lobby-web grep ...` |
| 3 | cc 배포 JS 에 saveLastSession + 비밀번호 form 포함 | grep |
| 4 | flutter analyze 0 issue | both |
| 5 | (수동) browser screenshot — Dialog open + iframe CC | manual |

**v1.4 vs v1.3 매핑**:

| 항목 | v1.3 | v1.4 |
|------|------|------|
| Launch UX | location.assign (same-tab nav) | Dialog.fullscreen + iframe |
| Cross-origin | navigate (lose lobby state) | iframe (preserve lobby) |
| CC stand-alone form | 4 fields (tableId/token/wsUrl/boBaseUrl) | 1 field (password) + last session 카드 |
| localStorage 영속 | ❌ | ✅ `ebs_cc_last_config` |
| 첫 launch 후 재진입 | manual entry 필요 | 비번만 |

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: deep-link 전환, POST /launch-cc 삭제 | team2 session |
| 2026-05-03 | v1.2 | Web variant 복원 — endpoint 재도입 + dual response (cc_url + deep_link). E2E 9/9 PASS | Conductor Mode A 자율 |
| 2026-05-03 | v1.3 | Same-window navigation (location.assign) + CC URL query parsing (tryFromQuery) | Conductor Mode A 자율 |
| 2026-05-04 | v1.4 | Iframe embed (lobby 보존) + password-only stand-alone form + localStorage 영속 | Conductor Mode A 자율 (사용자 비판 cascade) |
