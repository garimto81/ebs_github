# QA-LOBBY-03: 기획 문서 Gap 리포트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | 구현 과정에서 발견된 기획 문서 누락 항목 |
| 2026-04-09 | GAP-L-001/002 기획 문서 보강 완료 | API-06 §2.1 토큰 생명주기 추가, BS-01 A-20/A-21 추가, BS-02 §세션 보존 가드 조건 추가, API-05 §1.3 WS JWT 인증 방식 추가 |
| 2026-04-10 | GAP-L-009 RESOLVED (예정) | UI-01 §0.1~0.3 Login 확장(2FA/Forgot/Session restore Dialog) + §9.6 Session restore 거동 작성 완료. BS-01 `lastContext` 필드 스키마 row 및 `POST /auth/verify-2fa` API-06 row 만 후속 CCR 대기 |
| 2026-04-13 | GAP-L-014~017 추가 | Google OAuth 에러 코드, "Only updated series" 필터 기준, 북마크 API, Event DataTable 확장 컬럼 |

---

## 개요

이 문서는 Lobby 구현 과정에서 발견된 **기획 문서(BS/API/DATA)의 누락 또는 모호한 항목**을 기록한다. 구현자가 임의 판단으로 코드를 작성한 결과 버그가 발생한 사례와 함께, 기획 문서에 보강이 필요한 항목을 명시한다.

### 목적

- 기획 문서의 빈틈을 체계적으로 추적
- 동일 누락으로 인한 반복 버그 방지
- 기획 문서 보강 우선순위 결정 근거 제공

### 프로세스

```
구현 중 기획 문서에 없는 판단 필요
  │
  ├─ 임의 구현 금지
  │
  ├─ 이 문서에 Gap 항목 추가 (아래 형식)
  │
  ├─ 구현자의 판단으로 임시 구현 (workaround 명시)
  │
  └─ 기획자 확인 후:
       ├─ 기획 문서 보강 → 해당 BS/API/DATA 문서 업데이트
       └─ 이 문서의 Status를 "RESOLVED"로 변경
```

---

## Gap 항목

### GAP-L-001: 앱 시작 시 토큰 유효성 검증 흐름 누락

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Critical** |
| **관련 문서** | API-06 §2 (로그인 API), BS-02 §세션 상태 보존 |
| **Status** | **RESOLVED** — 기획 문서 보강 완료 (2026-04-09) |

**누락 내용:**

API-06은 Login → Token 발급 → API 호출 시 Bearer 사용까지만 기술한다. 다음 시나리오가 기획 문서에 없다:

1. **앱 초기화 시 기존 토큰 검증**: 사용자가 브라우저를 닫았다가 다시 열 때, localStorage에 남아있는 토큰이 유효한지 서버에 확인하는 흐름
2. **토큰 만료 시 로그인 리다이렉트**: Access Token이 만료되었을 때 자동으로 로그인 화면으로 전환하는 조건
3. **Refresh Token 만료 시 강제 로그아웃**: Refresh Token까지 만료되었을 때의 처리

**발생한 버그:**

구현자가 `localStorage.getItem('access_token')` 존재 여부만으로 인증 상태를 판단 → 만료된 토큰으로도 로비에 진입 → API 호출 시 401 에러 연쇄 발생. `/login` 페이지 접속 시에도 localStorage에 (만료된) 토큰이 있으면 즉시 `/series`로 리다이렉트되어 로그인 불가.

**임시 구현 (workaround):**

```
ProtectedRoute 진입 시:
  1. accessToken 존재 확인
  2. GET /auth/session 호출 (서버 검증)
  3. 성공 → user 설정 → 보호된 페이지 표시
  4. 실패 → logout() → /login 리다이렉트

LoginPage:
  - localStorage 기반 자동 리다이렉트 제거
  - 로그인 성공 후에만 /series 이동
```

**기획 문서 보강 요청:**

| 보강 대상 | 추가할 내용 |
|----------|-----------|
| API-06 §2 뒤 | "§2.1 토큰 생명주기" 섹션: 앱 시작 → 토큰 확인 → 유효/무효 분기 플로우차트 |
| BS-02 §세션 상태 보존 | "세션 복원 전 토큰 유효성 검증 필수" 가드 조건 추가 |
| BS-01 §로그인 | "로그인 페이지 진입 조건: 유효한 세션이 없을 때만" 명시 |

---

### GAP-L-002: WebSocket 엔드포인트 구조 (CC vs Lobby 분리)

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Critical** |
| **관련 문서** | API-05 §1.1 |
| **Status** | **RESOLVED** — 구현 수정 완료 |

**누락 내용:**

API-05 §1.1이 CC와 Lobby의 WebSocket 엔드포인트를 분리 명시하지만, 각 엔드포인트의 **인증 방식**과 **연결 실패 시 재시도 정책**이 기술되지 않았다.

**발생한 버그:**

구현자가 `/ws/{room}` 단일 엔드포인트로 구현 → CC와 Lobby 연결 구분 불가 → 테이블 스코프 이벤트 라우팅 불가능.

**해결:**

`/ws/cc?table_id=N` + `/ws/lobby` 2-endpoint 구조로 수정 완료.

**기획 문서 보강 요청:**

| 보강 대상 | 추가할 내용 |
|----------|-----------|
| API-05 §1.1 | WS 연결 시 JWT 토큰 전달 방식 (query param? first message?) |
| API-05 §6 | 연결 실패/끊김 시 재시도 간격, 최대 재시도 횟수 |

---

### GAP-L-003: Login 응답 구조 (2FA 분기)

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Medium** |
| **관련 문서** | API-06 §2, §7 |
| **Status** | **RESOLVED** — API-06 문서 수정 + 구현 완료 |

**누락 내용:**

API-06 §2의 로그인 응답에 2FA 분기가 없었다. §7에 2FA 엔드포인트가 있지만, 로그인 시 `requires_2fa: true`를 반환하고 `temp_token`을 발급하는 흐름이 §2에 통합되어 있지 않았다.

**해결:**

API-06 §2에 2FA 분기 응답 추가. `requires_2fa: true` 시 `temp_token` 반환, `/auth/verify-2fa`로 최종 인증 완료 흐름 명시.

---

### GAP-L-004: `username` vs `email` 필드명 불일치

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Medium** |
| **관련 문서** | API-06 §1.2, §2 vs DATA-04 §4 (users 테이블) |
| **Status** | **RESOLVED** — API-06 `email`로 통일 |

**누락 내용:**

API-06은 JWT claims와 로그인 요청에 `username` 필드를 사용. DATA-04의 User 모델에는 `username` 필드가 존재하지 않고 `email`만 존재. 두 문서 간 필드명 불일치.

**해결:**

API-06을 DATA-04 기준(`email`)으로 수정. 구현도 `email` 사용.

---

### GAP-L-005: Session 응답 구조 (플랫 vs 중첩)

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Medium** |
| **관련 문서** | API-06 §4 |
| **Status** | **RESOLVED** — 구현 수정 완료 |

**누락 내용:**

API-06 §4의 Session 응답이 `{user: {...}, session: {...}}` 중첩 구조를 명시하지만, 각 필드의 정확한 타입 정의와 `table_ids`의 조회 방법(어떤 테이블에서? join 조건?)이 기술되지 않았다.

**발생한 버그:**

구현자가 플랫 구조로 구현 → Lobby Frontend에서 user/session 분리 처리 불가.

**해결:**

`SessionUser` + `SessionNavigation` 중첩 구조로 수정. `table_ids`는 Operator 할당 테이블 조회 기능이 구현될 때 보강 예정.

---

### GAP-L-006: FastAPI 버전별 HTTPBearer 응답 코드 차이

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Low** |
| **관련 문서** | API-06 §5 (에러 코드), IMPL-01 §4 (기술 스택) |
| **Status** | **RESOLVED** — 테스트 수정 |

**누락 내용:**

IMPL-01이 FastAPI 0.115+ 명시. API-06이 인증 실패 시 401 반환을 명시. 그러나 FastAPI 0.115.0의 `HTTPBearer`는 토큰 미제공 시 403을 반환하고, 0.128.0은 401을 반환한다. 버전별 동작 차이가 문서화되지 않음.

**해결:**

테스트에서 `assert status_code in (401, 403)` 허용. requirements.txt에 버전 고정(0.115.0)으로 Docker 환경 통일.

**기획 문서 보강 요청:**

| 보강 대상 | 추가할 내용 |
|----------|-----------|
| IMPL-01 §4 | FastAPI 버전 고정 사유 + HTTPBearer 동작 차이 주의 사항 |

---

### GAP-L-007: Series 생성 폼 필수 필드 누락

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Medium** |
| **관련 문서** | BS-02 §화면 1 수동 Series 생성 (라인 361-377) |
| **Status** | **RESOLVED** — 구현 보강 완료 (2026-04-09) |

**누락 내용:**

BS-02 §화면 1은 Series 생성 폼에 9개 필드를 명시하지만, `ebs_lobby/src/pages/SeriesListPage.tsx`는 5개 필드만 구현한다.

| 필드 | 필수 | 구현 현황 |
|------|:----:|:--------:|
| Competition | O | ✅ |
| Series Name | O | ✅ |
| Start Date (begin_at) | O | ✅ |
| End Date (end_at) | O | ✅ |
| Year | — | ✅ |
| **Time Zone** | **O** | ❌ 누락 |
| **Country Code** | **O** | ❌ 누락 |
| Series Image | — | ❌ 누락 |
| Is Displayed | — | ❌ 누락 |
| Is Demo | — | ❌ 누락 |

**발생한 버그:**

Time Zone, Country Code 없이 저장 → 서버 측에서 기본값(UTC, null) 적용. 실제 운영 시 타임존 기준 날짜 오류 발생 가능.

**임시 구현 (workaround):**

현재 5개 필드만으로 저장 중. Time Zone은 서버 기본값 UTC 적용.

**기획 문서 보강 요청:**

없음 — BS-02 §화면 1 명세는 완전함. 구현 보강 필요.

---

### GAP-L-008: Event 생성 폼 핵심 기능 누락

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | **Critical** |
| **관련 문서** | BS-02 §화면 2 수동 Event 생성 (라인 407-515) |
| **Status** | **RESOLVED** — 구현 보강 완료 (2026-04-09) |

**누락 내용:**

BS-02 §화면 2는 Event 생성 폼에 13개 필드 + BlindStructure 인라인 설정 + Days/Flight 설정을 명시하지만, `ebs_lobby/src/pages/EventListPage.tsx`는 5개 필드만 구현한다.

| 필드/기능 | 필수 | 구현 현황 |
|----------|:----:|:--------:|
| Event No. | O | ✅ |
| Event Name | O | ✅ |
| Game Type | O | ✅ |
| Buy-In | — | ✅ |
| Table Size | O | ✅ |
| **Start Date** | **O** | ❌ 누락 |
| **Starting Chip** | **O** | ❌ 누락 |
| Display Buy-In | — | ❌ 누락 |
| **Game Mode** (Single/Fixed Rotation/Dealer's Choice) | **O** | ❌ 누락 |
| Allowed Games | — | ❌ 누락 (Mix 모드 필수) |
| Rotation Order | — | ❌ 누락 |
| Rotation Trigger | — | ❌ 누락 |
| Mix Preset | — | ❌ 누락 |
| **Blind Structure 인라인 설정** (레벨별 SB/BB/Ante/Duration) | **O** | ❌ 전체 누락 |
| **Days/Flight 설정** (Event 생성 시 자동 생성) | **O** | ❌ 전체 누락 |

**발생한 버그:**

- Game Mode 없이 저장 → Mix 게임 이벤트 생성 불가. 모든 이벤트가 Single 모드로 고정.
- Starting Chip 없음 → 게임 시작 시 칩 수량 미정의.
- Blind Structure 없음 → 레벨 타이머/블라인드 구조 없이 이벤트 생성됨.
- Days/Flight 미생성 → Event 생성 후 Flight를 별도로 수동 생성해야 함.

**임시 구현 (workaround):**

현재 5개 필드만으로 생성 중. Game Mode = Single 묵시적 적용. Blind Structure, Starting Chip, Flight는 생성 후 별도 조작 필요.

**기획 문서 보강 요청:**

없음 — BS-02 §화면 2 명세(라인 407-515)는 완전함. 구현 보강 필요.

---

## 요약 테이블

| ID | 제목 | 심각도 | Status | 관련 문서 |
|----|------|:------:|:------:|----------|
| GAP-L-001 | 앱 시작 시 토큰 검증 흐름 | Critical | RESOLVED | API-06 §2.1, BS-01 A-20/A-21, BS-02 §세션 보존 |
| GAP-L-002 | WS 엔드포인트 인증/재시도 | Critical | RESOLVED | API-05 |
| GAP-L-003 | Login 2FA 분기 응답 | Medium | RESOLVED | API-06 |
| GAP-L-004 | username vs email 불일치 | Medium | RESOLVED | API-06, DATA-04 |
| GAP-L-005 | Session 응답 중첩 구조 | Medium | RESOLVED | API-06 |
| GAP-L-006 | FastAPI HTTPBearer 버전 차이 | Low | RESOLVED | API-06, IMPL-01 |
| GAP-L-007 | Series 생성 폼 필수 필드 누락 | Medium | RESOLVED | BS-02 §화면 1 |
| GAP-L-008 | Event 생성 폼 핵심 기능 누락 | Critical | RESOLVED | BS-02 §화면 2 |
| GAP-L-009 | Session restore UX 미정의 | Medium | **RESOLVED (예정)** | BS-01, UI-01 §0.1~0.3 + §9.6 (2026-04-10) |
| GAP-L-010 | GE `background.image` 편집 흐름 — .gfskin 재패키징 필요 여부 미정의 | Low | OPEN | DATA-07 §3, BS-08-02, UI-04 §5.2 (2026-04-10) |
| GAP-L-011 | BS-08-00/02 가 `UI-08-graphic-editor.md` 참조하나 실파일은 `UI-04-graphic-editor.md` | Low | OPEN | BS-08-00, BS-08-02, UI-04 (2026-04-10) |
| GAP-L-012 | `POST /auth/verify-2fa` endpoint 가 API-06 엔드포인트 표에 row 누락 (BS-01 A-16 본문만) | Low | OPEN | BS-01 A-16, API-06, UI-01 §0.1 (2026-04-10) |
| GAP-L-013 | `lastContext` 필드가 BS-01 응답 스키마 섹션에 명시적으로 미정의 (A-20/A-22 서술만) | Low | OPEN | BS-01, UI-01 §0.3/§9.6 (2026-04-10) |
| GAP-L-014 | Google OAuth callback 에러 코드 | High | OPEN | API-06, BS-01 (2026-04-13) |
| GAP-L-015 | "Only updated series" 필터 기준 | Medium | OPEN | UI-01 §1 (2026-04-13) |
| GAP-L-016 | 북마크 API endpoint | Medium | OPEN | API-01 (2026-04-13) |
| GAP-L-017 | Event DataTable 확장 컬럼 API 필드 | Medium | OPEN | API-01 §5.5 (2026-04-13) |

---

## GAP-L-009 Session restore UX 미정의

| 항목 | 내용 |
|------|------|
| **발견일** | 2026-04-10 |
| **심각도** | Medium |
| **관련 문서** | BS-01-auth A-20/A-22~A-25, UI-01 §0.1~0.3 + §9.6 |
| **Status** | **RESOLVED (예정)** — UI-01 §0 확장 완료 (2026-04-10). 계약 확장 2건 후속 CCR 대기. |

### 발견 맥락

Team 1 dev-readiness critic (2026-04-10) 에서 발견. 기존 GAP-L-001 (토큰 검증 흐름) 해결 후에도 **"로그인 성공 시 이전 세션 컨텍스트를 어떻게 복원하는가"** 의 UX 가 정의되지 않았다. 특히:

- Operator 가 Flight 진행 중 실수로 브라우저를 닫았다 다시 로그인했을 때, 이전에 관제하던 Table 로 자동 이동할지?
- 24시간 전 세션도 복원할지, 신선한 세션만 복원할지?
- 복원 다이얼로그의 "Continue / Change" UX 는 어떻게 생겼는지?
- 2FA 활성 계정의 경우 복원 타이밍이 password 통과 직후인지 TOTP 통과 직후인지?
- Forgot Password 완료 후 재로그인 시 복원할지 차단할지?

### 영향

- 반복적인 "로그인 → Series → Event → Flight → Table" 4-5 step 네비게이션 부하
- 긴급 상황 복구 시 이전 작업 맥락 재탐색 비용
- Operator 재할당 상황(A-24) 처리 미정의로 "이전 테이블로 이동 시도 → 권한 없음 403" 에러 가능

### 해결 (UI-01 §0 확장, 2026-04-10)

Team 1 dev-readiness remediation 작업으로 UI-01-lobby.md 에 다음 섹션을 작성하여 해결:

| 섹션 | 내용 |
|------|------|
| **UI-01 §0.1** (L109-170) | 2FA TOTP 화면 — 1차 password 통과 후 `requires_2fa: true` 분기 처리. TOTP 통과 후 `lastContext` 검증으로 이동 |
| **UI-01 §0.2** (L171-273) | Forgot Password 3단계 wizard. 완료 후 Login 화면 복귀 (복원 없음 — 새 세션 시작) |
| **UI-01 §0.3** (L274-395) | Session Restore Dialog UI — q-dialog, 와이어프레임, 상태 전이 7단계, 복원 3조건(24시간/Running/할당 유효) |
| **UI-01 §9.6** (L912-993) | Session Restore 거동 — 서버 계약(`lastContext` 스키마), 부분 복원 ladder(table→flight→event→series), Operator 재할당 특수 처리(A-24), A-25 [Launch CC] 자동 표시 |

핵심 판단:
- **복원 타이밍**: 2FA 통과 후 최종 토큰 발급 시점에 `lastContext` 수신 → §0.3 다이얼로그 표시
- **24시간 조건**: 클라이언트에서 `now() - lastContext.timestamp < 24h` 판정
- **복원 실패 ladder**: table fail → flight 목록 / flight fail → event 목록 / event fail → series 목록 / series fail → `/series`
- **Operator 재할당**: "할당 변경" 화면 표시 후 새 테이블 목록 노출, 0개면 "미할당 — 관리자 문의" (A-24 Edge Case)

### 임시 구현 (workaround)

현재 Team 1 Quasar 프로젝트는 초기화 단계이므로 코드 구현 없음. UI-01 §0.3 + §9.6 에 설계 선반영 완료. 실제 Quasar 프로젝트 착수 시 `useAuthStore.tryRestoreSession()` 에서 `lastContext` 를 소비한다.

### 기획 문서 보강 요청 (후속 작업)

UI-01 §0.3 / §9.6 에 "계약 확장 필요" 주석으로 표시해둔 2건:

| 보강 대상 | 추가할 내용 | 우선순위 |
|----------|-----------|:-------:|
| **BS-01-auth §응답 스키마** | `POST /auth/login` / `POST /auth/verify-2fa` / `GET /auth/session` 응답 body 에 `lastContext: { seriesId, eventId, flightId, tableId, operatorId, timestamp }` 필드 명시 (현재는 A-20/A-22 본문 서술에만 근거 존재) | P1 |
| **API-06 Auth 엔드포인트 표** | `POST /auth/verify-2fa` row 추가 + `temp_token` 필드 명시 (현재는 BS-01 A-16 서술에만 존재) | P1 |
| **DATA-02-entities** | `OperatorSession` 엔티티에 last context 필드 추가 또는 별도 `SessionContext` 테이블 (서버 측 영속화 전략) | P2 |

위 3건은 CCR-DRAFT-team1-20260411-session-restore-contract.md 로 합쳐서 제출 예정.

### 완전한 RESOLVED 조건

- [x] UI 설계 완료 (UI-01 §0.1~0.3, §9.6) — 2026-04-10
- [ ] BS-01-auth 응답 스키마에 `lastContext` 필드 row 추가 (CCR)
- [ ] API-06 표에 `POST /auth/verify-2fa` row 추가 (CCR)
- [ ] DATA-02 OperatorSession 엔티티 확장 또는 SessionContext 테이블 설계
- [ ] Quasar 프로젝트 `useAuthStore.tryRestoreSession()` 구현

현재는 **1번만 완료**, 나머지 4건이 남아 "RESOLVED (예정)" 상태로 표시. 4건 완료 시 본 Gap 항목을 **RESOLVED** 로 최종 전환.

---

### GAP-L-014 Google OAuth callback 에러 코드
- **발견일**: 2026-04-13
- **심각도**: High
- **관련 문서**: contracts/api/API-06-auth-session.md, contracts/specs/BS-01-auth/BS-01-auth.md
- **누락 내용**: Google OAuth callback 실패 시 에러 코드 미정의 (AUTH_GOOGLE_NOT_LINKED, AUTH_GOOGLE_EMAIL_MISMATCH 등)
- **임시 구현**: 403 + generic 에러 메시지
- **기획 보강 요청**: API-06에 Google OAuth endpoint + 에러 코드 추가 (CCR draft 제출 예정)

### GAP-L-015 "Only updated series" 필터 기준
- **발견일**: 2026-04-13
- **심각도**: Medium
- **관련 문서**: team1-frontend/ui-design/UI-01-lobby.md §1
- **누락 내용**: "Only updated series" 필터의 "updated" 정의 미확정 (24h 이내? 서버 updated_at? WebSocket 이벤트?)
- **임시 구현**: `updated_at` 기준 24h 이내
- **기획 보강 요청**: BS-02-lobby에 Series 변경 감지 기준 명시

### GAP-L-016 북마크 API endpoint
- **발견일**: 2026-04-13
- **심각도**: Medium
- **관련 문서**: contracts/api/API-01-backend-endpoints.md
- **누락 내용**: Series 북마크 토글 API 미정의 (POST/DELETE /series/{id}/bookmark)
- **임시 구현**: localStorage 전용 (서버 동기화 없음)
- **기획 보강 요청**: API-01에 bookmark CRUD endpoint 추가

### GAP-L-017 Event DataTable 확장 컬럼 API 필드
- **발견일**: 2026-04-13
- **심각도**: Medium
- **관련 문서**: contracts/api/API-01-backend-endpoints.md §5.5 Events
- **누락 내용**: WSOP LIVE 동일 15컬럼 중 일부 (Tickets, Chip M, Alt Entries, Late Reg status) API 응답 필드 미정의
- **임시 구현**: 해당 컬럼 빈 값 표시 ("-")
- **기획 보강 요청**: API-01 Events 응답 스키마에 누락 필드 추가

---

## 기획 문서 보강 대기 목록 (OPEN 항목)

| 우선순위 | 대상 문서 | 보강 내용 |
|:--------:|----------|----------|
| **P0** | API-06 §2 | 토큰 생명주기 (앱 시작 → 검증 → 유효/무효 분기) |
| **P0** | BS-02 §세션 보존 | 토큰 유효성 검증 가드 조건 |
| **P0** | BS-01 §로그인 | 로그인 페이지 진입 조건 (유효 세션 없을 때만) |
| P1 | API-05 §1.1 | WS JWT 인증 전달 방식 |
| P1 | API-05 §6 | WS 재연결 정책 (간격, 최대 횟수) |
| P2 | IMPL-01 §4 | FastAPI 버전 고정 사유 |
| ~~P1~~ | ~~`ebs_lobby` SeriesListPage.tsx~~ | ~~Time Zone, Country Code, Is Displayed, Is Demo, Series Image 필드 추가~~ — **RESOLVED** (2026-04-09) |
| ~~P0~~ | ~~`ebs_lobby` EventListPage.tsx~~ | ~~Start Date, Starting Chip, Game Mode, Blind Structure, Days/Flight 구현~~ — **RESOLVED** (2026-04-09) |
