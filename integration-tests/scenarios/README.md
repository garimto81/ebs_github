# Integration Test Scenarios

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | CCR-010~036 계약 검증 시나리오 카탈로그 |

---

## 파일명 체계

```
{그룹번호}-{주제}.http
```

| 그룹 | 범위 | 커버 CCR |
|:----:|------|----------|
| **10~19** | Auth / Idempotency / Saga / WS Replay | 010, 019, 020, 021, 018 |
| **20~29** | Graphic Editor (API-07) + DATA-07 + skin_updated | 011, 012, 013, 014, 015 |
| **30~39** | CC Launch / BO Recovery / WriteGameInfo / Statistics | 027, 029, 031, 024 |
| **40~49** | Overlay / Security Delay / Color sync | 025, 033, 034, 036 |
| **50~59** | RFID / Deck Register | 022, 026 |
| **60~69** | team1 WSOP Parity (Event/Flight/Table/RBAC) | 016, 017 |

## 실행 환경

- **VSCode REST Client** 또는 **httpyac** 확장
- Backend BO 서비스(`http://localhost:8000`) 실행 중이어야 함
- 일부 WebSocket 시나리오는 별도 `wscat`/`websocat` CLI 필요

## 공통 설정

`_env.http` 참조 — host, 인증 토큰, 테스트 ID 정의.

환경 변수(`.env`)로 token 주입:
```
ADMIN_JWT=eyJhbGc...
OPERATOR_JWT=eyJhbGc...
VIEWER_JWT=eyJhbGc...
```

## CCR 추적

각 시나리오 파일 상단에 커버하는 CCR 번호를 명시한다. 예: `### CCR-013 §1 POST /skins — Upload`.

---

## 작성 완료 (16개)

| 파일 | 커버 CCR | 상태 |
|------|----------|:----:|
| `10-auth-login-profile.http` | CCR-010 | ✓ |
| `11-idempotency-key.http` | CCR-019 | ✓ |
| `12-table-rebalance-saga.http` | CCR-020 | ✓ |
| `13-ws-event-seq-replay.http` | CCR-021 | ✓ |
| `20-ge-upload-download.http` | CCR-013 §1, §3, CCR-012 | ✓ |
| `21-ge-patch-metadata-etag.http` | CCR-013 §4, §5 | ✓ |
| `22-ge-activate-broadcast.http` | CCR-013 §6, CCR-015 | ✓ |
| `23-ge-rbac-denied.http` | CCR-013 RBAC, BS-08-04 | ✓ |
| `30-cc-launch-flow.http` | CCR-029 | ✓ |
| `31-cc-bo-reconnect-replay.http` | CCR-031 (W2) | ✓ |
| `32-cc-write-game-info.http` | CCR-024 | ✓ |
| `40-overlay-security-delay.http` | CCR-036 | ✓ |
| `50-rfid-deck-register.http` | CCR-026 | ✓ |
| `60-event-flight-status-enum.http` | CCR-017 §1 | ✓ |
| `61-table-is-pause-constraint.http` | CCR-017 §2 | ✓ |
| `62-rbac-bit-flag.http` | CCR-017 §5 | ✓ |

## 작성 필요 (API 검증 가능)

| 파일 | 커버 CCR | 우선순위 | 메모 |
|------|----------|:--------:|------|
| `14-data-idempotency-audit.http` | CCR-018 | Low | DATA-04 `idempotency_keys`/`audit_events` 테이블 쓰기/조회 검증. 대부분 11번에서 간접 커버됨. |
| `24-ge-delete-active.http` | CCR-013 §8 | Medium | active skin 삭제 차단(409), 비활성 skin 정상 삭제(204) |
| `25-gfskin-zip-validation.http` | CCR-012 | Medium | ZIP 구조 오류(`skin.json` 누락, `skin.riv` 누락)에 대한 검증 fixture 필요 |
| `33-cc-action-on-response.http` | CCR-031 (W9, W15) | High | ActionOnResponse 없으면 액션 버튼 비활성. Straddle + BB Check 충돌 규칙 |
| `34-cc-statistics-push.http` | CCR-027 | Low | AT-04 Statistics 화면의 GFX Push 트리거 |
| `35-cc-game-settings-modal.http` | CCR-028 | Low | AT-06 Game Settings PATCH 엔드포인트 검증 |
| `36-cc-player-edit-modal.http` | CCR-028 | Low | AT-07 Player Edit PATCH + Sitting Out 즉시/지연 |
| `41-overlay-messagepack.http` | CCR-023 | Medium | WebSocket `format=msgpack` 연결 후 MessagePack 바이너리 송수신 |
| `42-overlay-color-override.http` | CCR-025 | Low | Table별 `overlay_colors` PATCH + CC·Overlay 동일 override 수신 |
| `63-blind-detail-type.http` | CCR-017 §3 | Low | BlindDetailType enum + Late Reg 계산식 |

## 수동 검증만 가능 (HAL / UI / 시각 / OS 레벨)

### RFID HAL (CCR-022)
- **UART 연결 FSM**: 물리 리더 연결/끊김 시뮬레이션 — HAL harness 별도 필요
- **안테나 튜닝 재시도**: 환경 변수(금속 테이블) 영향 측정 — 물리 테스트
- **펌웨어 버전 감지**: 실제 ST25R3911B 칩 플래싱 후 버전별 응답 확인
- **다중 리더 충돌**: Phase 2 요구사항, Phase 1 미지원
- **ST25R3916 마이그레이션**: Phase 2 별도 프로젝트

→ `team3-engine` 또는 별도 HAL test harness에서 수행 (integration-tests 범위 외)

### UI / 시각 검증

| CCR | 검증 내용 | 방법 |
|-----|----------|------|
| CCR-028 AT 화면 체계 | AT-00~07 진입 경로, 7 Zone 구조 | Flutter 앱 QA 수동 테스트 |
| CCR-030 Multi-Table 운영 | Pattern A/B/C 동작, 키보드 포커스 | OS 수준 수동 테스트 |
| CCR-032 시각 규격 | 포지션 마커 색상, action-glow 펄스 | Overlay 렌더 스크린샷 검증 |
| CCR-034 CC-Overlay 일관성 | CC와 Overlay의 같은 좌석 색상 | 동시 비교 스크린샷 |
| CCR-033 Audio Layer | 이벤트→사운드 매핑, 채널 정책 | 오디오 재생 수동 확인 |
| CCR-035 Layer 경계 | Layer 1 자동화, Layer 2 API 제공 | 문서 정합성 review |

→ `team4-cc/qa/` 체크리스트 + QA 세션 필요 (integration-tests 범위 외)

### 문서 정합성 (grep 기반 검증 가능)

| CCR | 검증 | 예 |
|-----|------|----|
| CCR-011 | BS-08 5파일 생성 + BS-00 GE row 수정 | `grep -l "Graphic Editor (GE)" contracts/specs/BS-00*` |
| CCR-014 | BS-00 §7.4 GEM-01~25 존재 | `grep -c "GEM-" contracts/specs/BS-00-definitions.md` |
| CCR-016 | BS-00 §1 Lobby row = Quasar | `grep "Quasar Framework" contracts/specs/BS-00*` |
| CCR-025 | BS-03-02-gfx §6~§8 섹션 | `grep "## 6. Active Skin" team1-frontend/specs/BS-03-settings/BS-03-02-gfx.md` |
| CCR-035 | BS-07-06 파일 존재 + BS-07-00 참조 | `test -f contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md` |

→ `integration-tests/scenarios/_doc-integrity.sh` 별도 스크립트 작성 권장 (TODO)

## Fixture 파일 필요

아래 fixture가 `integration-tests/fixtures/` 에 준비돼야 시나리오 실행 가능:

- `wsop-2026-test.gfskin` — 정상 ZIP (skin.json + skin.riv + cards/ + assets/)
- `invalid-colors.gfskin` — colors.badge_check 스키마 위반
- `huge-51mb.gfskin` — 50MB 초과
- `missing-skin-json.gfskin` — skin.json 누락
- `missing-skin-riv.gfskin` — skin.riv 누락
- `invalid-rive-magic.gfskin` — skin.riv가 Rive 포맷 아님

**작업**: Team 4 또는 Conductor가 샘플 .gfskin 파일 생성 후 fixture 폴더에 배치.

## 환경 설정 필요

### dev seed credentials (admin)

```bash
# bo 컨테이너에서 admin 생성 (default seed)
docker exec ebs-bo python tools/seed_admin.py \
  --email admin@local --password 'Admin!Local123' \
  --display-name 'Local Admin'
```

> v0.4.1 정정: 시나리오는 `admin@local` / `Admin!Local123` 을 default 로 사용 (이전 spec `admin@ebs.test` / `test-password-1234` 은 backend 기본 seed 와 불일치 — D5 drift, 시나리오 측 정정 완료).

### `.env` 파일 (integration-tests/.env, gitignore 대상)

```bash
ADMIN_JWT=eyJhbGc...      # POST /auth/login → response.data.accessToken
OPERATOR_JWT=eyJhbGc...   # operator 계정 JWT (별도 seed 필요)
VIEWER_JWT=eyJhbGc...     # viewer 계정 JWT (별도 seed 필요)
CC_SERVICE_JWT=eyJhbGc... # CC 서비스 계정 JWT
REFRESH_TOKEN=eyJhbGc...  # 10-auth 시나리오 refresh 테스트용 (response.data.refreshToken)
```

> v0.4.1 정정: `/auth/login` 응답은 envelope `{ data: { accessToken, refreshToken, ... }, error }` 구조 + camelCase (B-088 migration). 시나리오 reference 경로는 `response.body.data.accessToken` (D2+D3 drift 정정 완료).

## 실행 권장 순서

1. **Smoke test (10, 11, 20, 30)** — 가장 기본 계약 검증
2. **Auth/RBAC (23, 62)** — 권한 판정 검증
3. **State/FSM (60, 61)** — 상태 전이 제약
4. **Complex scenarios (22, 31, 32)** — 멀티 단계 플로우
5. **Edge cases (12, 21, 40, 50)** — 경계 조건 + 에러 처리

각 시나리오는 **독립적으로 실행** 가능하도록 작성되었으며, 일부는 이전 시나리오의 응답을 참조할 수 있다 (`@name` + `{{varName.response.body.field}}` 구문).
