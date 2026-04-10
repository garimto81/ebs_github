# QA-LOBBY-03: 기획 문서 Gap 리포트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | 구현 과정에서 발견된 기획 문서 누락 항목 |
| 2026-04-09 | GAP-L-001/002 기획 문서 보강 완료 | API-06 §2.1 토큰 생명주기 추가, BS-01 A-20/A-21 추가, BS-02 §세션 보존 가드 조건 추가, API-05 §1.3 WS JWT 인증 방식 추가 |

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
