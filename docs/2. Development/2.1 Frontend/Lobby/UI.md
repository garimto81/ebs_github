---
title: UI
owner: team1
tier: internal
legacy-id: UI-01
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "UI-01 Lobby UI 스펙 (68KB) 정본"
---
# UI-01 Lobby — 화면 설계 (3계층 + 독립 레이어)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Login~Player 6화면 레이아웃, 데이터 바인딩, 네비게이션 |
| 2026-04-10 | critic revision | §9 WSOP LIVE Parity Notes 섹션 신규 추가 (EventFlightStatus matrix, isRegisterable, Restricted Day2+, Late Reg 계산식, Table 2축 분리, Bit Flag RBAC). Event+Flight accordion 단일 화면 원칙 재확인 |
| 2026-04-10 | CCR-017 APPLIED 반영 | §9 5개 "계약 반영 대기" 배너를 "CCR-017 APPLIED" 로 전환. §9.3/§9.5 본문의 "아직 존재하지 않는다/CCR 승격 후" 문구를 확정 참조로 교체. §9 header 에 Staff Page baseline(memory 근거) 명시. CCR footer 번호 정합화 (CCR-016→CCR-017 swap) 및 CCR-011/025 추가. Mix Game Late Reg 주석(G-02) 과 scheduled break vs in-hand pause 구분(G-04) 보강 |
| 2026-04-10 | dev-readiness 확장 | §0.1-0.3 Login 확장(2FA/Forgot/Session restore), §화면 4 Rebalance Saga UI(CCR-020), §9.0/9.5/9.6/9.7 WSOP gap 보강(G-01/03/05/07/08) |
| 2026-04-13 | WSOP LIVE 스크린샷 정렬 | §0 Google OAuth 추가, 공통 레이아웃(빨간 헤더+좌측 사이드바) 신설, §1 필터 3종 추가, §2 DataTable 15컬럼+상태탭+다중필터, §3 Flight→Day탭 통합, §4 카드→행 좌석그리드 전환, §6 RBAC 계정관리 신규, §10 Divergence 로그 |
| 2026-04-21 | Flutter Desktop 전환 1차 | Foundation §5.1 Lobby Flutter Desktop 단일 스택 결정 반영. 요소 표 열 헤더 "Quasar 컴포넌트" → "Flutter widget" 전환 완료. `**Quasar**:` 요약 블록 9개 `**Flutter**:` 로 재작성. 개별 q-* 셀 일부 남음 — Quasar↔Flutter 매핑표는 `docs/4. Operations/Plans/Lobby_Flutter_Stack_Doc_Migration_Plan_2026-04-21.md §3` 참조. 세부 컴포넌트 교체는 team1 후속 PR (Migration Plan Phase 3-A1 후반). |
| 2026-05-05 | EBS Lobby Design 누락 5개 보강 (P1/P2/P3) | §공통 레이아웃 §헤더 바: Show Context Cluster (SHOW/FLIGHT/LEVEL/NEXT) + Active CC pill 신규 (P1, shell.jsx:43-53 정합). §화면 1 Series 목록: Status Badge 5-color Legend + Year-grouped 그룹핑 정책 명시 (P2, screens.jsx:29 정합). Bookmark 검증 (P3, 이미 line 505/509 존재 — 디자인 자산과 정합 확인). AlertsScreen 폐기 (사용자 결정, EBS scope 외). |
| 2026-05-05 | mockup HTML 5건 redirect | 5개 화면 섹션 (0 Login / 1 Series / 2 Events / 3 Tables / 4 Players) 의 `> 목업 참조: docs/mockups/ebs-lobby-XX.html` 를 신 디자인 SSOT 표기로 교체 (`References/EBS_Lobby_Design/screens.jsx:N` + `visual/screenshots/ebs-lobby-XX.png`). Legacy mockup HTML 은 보존 (외부 링크 안전). 본문 ASCII 와이어프레임은 그대로 유지 (정본 source of truth = 코드). Hand History/Settings 본문은 `Overview.md §화면 6/§화면 7` 가 SSOT — 본 UI.md 는 mockup redirect 만 적용. |
| 2026-05-07 | v3 정체성 정합 | Lobby_PRD v3.0.0 cascade — 5분 게이트웨이 + WSOP LIVE 거울 정체성 framing 을 §개요 첫 단락에 추가. UI 본문 (3계층 + 독립 레이어 + 화면별 spec) 은 변경 0 — 정체성 박스만 additive. 외부 인계 PRD `docs/1. Product/Lobby_PRD.md` v3.0.0 narrative SSOT 정합. |

---

## 개요

> **정체성 (Lobby_PRD v3.0.0 cascade, 2026-05-07)**: Lobby = **5분 게이트웨이 + WSOP LIVE 거울**. 운영자가 머무는 화면이 아니라 거치는 화면이다. 4 진입 시점 (① 처음 진입 / ② 어긋났을 때 / ③ 게임 바뀔 때 / ④ 모든 것이 끝날 때) 에 5 화면 시퀀스 (Series → Events → Flights → Tables → Players) 를 통과한다. 본 UI 정본은 그 시퀀스 각 화면의 widget·필드·상태 spec 을 정의한다. 4 진입 시점 카탈로그는 `Overview.md §4 진입 시점 카탈로그` SSOT.

Lobby는 EBS의 **Flutter 앱**으로 구현되어 **Docker Web 으로 배포**되는 테이블 관리 화면이다 (2026-04-21 Foundation §5.1 결정: Quasar/Vue 폐기 → Flutter 프레임워크 통일; 2026-04-22 배포 형태 재정의: Docker Web 단독, 사용자는 브라우저 접속). **Series > Event(Day) > Table** 3계층 drill-down으로 Feature Table을 찾아 Command Center로 진입한다. Player는 3계층과 독립된 레이어로, 어디서든 상시 접근 가능하다. Staff Management(Admin)와 Settings(글로벌)도 독립 레이어이다.

> **UI 컴포넌트 매핑 가이드**: 본 문서에 잔존하는 `q-*` Quasar 컴포넌트 표기는 Flutter widget 으로 해석한다. 변환 규약: `docs/4. Operations/Plans/Lobby_Flutter_Stack_Doc_Migration_Plan_2026-04-21.md §3 Quasar↔Flutter 매핑표` (37 매핑). 세부 재작성은 team1 후속 PR.

> 참조: BS-02-lobby, BS-00 §1, Foundation Ch.5

---

## Breadcrumb 네비게이션

모든 화면(Login 제외)에 상단 Breadcrumb이 표시된다.

```
+-----------------------------------------------+
| EBS > Series Name > Event #1 > Day 1A > Tbl 3 |
+-----------------------------------------------+
```

| 요소 | 동작 |
|------|------|
| EBS (홈) | Series 목록으로 이동 |
| Series 이름 | 해당 Series의 Event 목록 |
| Event 이름 | 해당 Event의 Table 목록 (Day 탭) |
| Table 이름 | 해당 Table 상세 |

---

## Active CC 모니터링 패널

Lobby 헤더 우측에 활성 CC 드롭다운이 표시된다.

```
+---------------------------------------------+
| [EBS Logo]  Breadcrumb...   [CC v] [Set ⚙]  |
+---------------------------------------------+
         CC 드롭다운 펼침:
         +----------------------------------+
         | ● Table 1  Hand #42  NL Hold'em  |
         | ● Table 3  Hand #15  PLO4        |
         | ○ Table 5  IDLE                  |
         +----------------------------------+
```

| 상태 | 아이콘 | 클릭 동작 |
|------|:------:|---------|
| ● LIVE | 녹색 원 | 해당 CC로 전환 (Open) |
| ○ IDLE | 회색 원 | 해당 Table로 이동 |
| ⚠ ERROR | 빨간 삼각 | 해당 CC로 전환 + 경고 |

---

## 화면 0: Login

> 디자인 SSOT: `References/EBS_Lobby_Design/screens.jsx:443` (`LoginScreen`)
> Legacy mockup (deprecated 2026-05-05, 외부 링크 보존용): `docs/mockups/ebs-lobby-00-login.html`

```
+---------------------------------------------+
|                                             |
|              [EBS LOGO]                     |
|                                             |
|         +-------------------------+         |
|         |  Email                  |         |
|         +-------------------------+         |
|         |  Password          [👁] |         |
|         +-------------------------+         |
|         |  [ ] Remember me        |         |
|         +-------------------------+         |
|         |      [  LOGIN  ]        |         |
|         +-------------------------+         |
|         |  ────── or ──────       |         |
|         | [G] Sign in with Google |         |
|         +-------------------------+         |
|         |  Forgot password?       |         |
|         +-------------------------+         |
|                                             |
+---------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Email Address | TextField | `auth.email` |
| Password | TextField (masked) | `auth.password` |
| Remember me | Checkbox | `auth.remember` |
| LOGIN | Button (primary) | `POST /Auth/Login` |
| 구분선 | `Divider` + "or" label | — |
| Sign in with Google | `q-btn outline icon="img:google-logo.svg"` | `GET /Auth/Google` redirect |
| Forgot password? | Link | 비밀번호 재설정 페이지 |

### Google OAuth 플로우

1. 사용자 `[Sign in with Google]` 클릭
2. `GET /Auth/Google` → 서버가 Google OAuth consent URL redirect
3. Google 인증 완료 → callback `GET /Auth/Google/callback?code=...`
4. 서버: Google ID 토큰 검증 → EBS 계정의 email과 매칭 → JWT 발급
5. 응답은 일반 로그인과 동일: `{ access_token, refresh_token, user, lastContext }`
6. 2FA 활성 계정: Google 인증 후에도 TOTP 검증 필요 (`requires_2fa: true`)
7. EBS 계정과 매칭되지 않는 Google 계정: `AUTH_GOOGLE_NOT_LINKED` (403)

> **계약 확장 필요**: `GET /Auth/Google`, `GET /Auth/Google/Callback` endpoint는 현재 API-06에 미정의. CCR draft 제출: `docs/05-plans/ccr-inbox/CCR-DRAFT-team1-20260413-google-oauth.md`.

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| 로그인 성공 + 2FA 비활성 + 세션 없음 | 화면 1 (Series) |
| 로그인 성공 + 2FA 활성 | §0.1 2FA TOTP 화면 |
| 로그인 성공 + 세션 있음 | §0.3 Session Restore Dialog |
| "Forgot password?" 클릭 | §0.2 Forgot Password 흐름 |

---

### §0.1 2FA TOTP 화면

> 근거: BS-01-auth A-16 (계약 확정). `requires_2fa: true` 응답 수신 후 진입.

2FA 활성 계정이 1차 password 인증을 통과하면 본 화면으로 이동한다. 서버는 `temp_token` 과 함께 `requires_2fa: true` 를 반환하며, 이 화면에서 TOTP 6자리 코드를 검증해야 최종 access token 이 발급된다.

```
+---------------------------------------------+
|                                             |
|              [EBS LOGO]                     |
|                                             |
|           2단계 인증                        |
|                                             |
|   인증 앱의 6자리 코드를 입력하세요         |
|                                             |
|      [_][_][_]  [_][_][_]                   |
|                                             |
|         [   Verify   ]  [취소]              |
|                                             |
|   코드가 없으신가요?                        |
|   관리자에게 문의: admin@ebs.local          |
|                                             |
+---------------------------------------------+
```

#### 구성 요소

| 요소 | Flutter widget | 바인딩 |
|------|-----------------|--------|
| 6자리 TOTP 입력 | `TextField` × 6 (auto-advance) 또는 `mask="# # # # # #"` 단일 `TextField` | `twofa.code` |
| Verify | `ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary))` | `POST /Auth/Verify2FA` |
| 취소 | `TextButton` | `temp_token` 폐기 → Login 화면 |
| 관리자 문의 링크 | `q-btn type="a" flat` | `mailto:$t('login.adminEmail')` |
| 실패 카운터 | `MaterialBanner` | 3회 실패 시 30초 쿨다운 표시 |

i18n key: `$t('login.twofa.title')`, `$t('login.twofa.prompt')`, `$t('login.twofa.verify')`.

#### API 호출

- **요청**: `POST /Auth/Verify2FA`
  ```json
  { "tempToken": "tmp_...", "totp": "123456" }
  ```
- **응답 200**: 최종 access/refresh token + `lastContext` (있을 시 §0.3 로 이동)
- **응답 401** (`AUTH_2FA_INVALID`): 남은 시도 횟수 표시, 3회 실패 시 30초 disable
- **응답 410** (`AUTH_TEMP_TOKEN_EXPIRED`): "시간 초과. 다시 로그인하세요" → Login 화면 복귀

> **계약 확장 필요**: `POST /Auth/Verify2FA` endpoint 명과 `temp_token` 필드는 BS-01-auth A-16 본문 서술에는 존재하나 API-06 Auth 엔드포인트 표에 별도 row 가 보이지 않는다. 구현 전 API-06 에 row 추가 확인 필요.

#### 상태 전이

| 상태 | 트리거 | 다음 |
|------|--------|------|
| `idle` | 화면 진입 | 입력 대기 |
| `idle` → `verifying` | 6자리 완성 + Verify 클릭 | loading |
| `verifying` → `success` | 200 OK | `lastContext` 있으면 §0.3, 없으면 화면 1 |
| `verifying` → `error` | 401 | `idle` + 실패 카운트 +1 |
| `error` (3회) → `locked` | 3회 실패 | 30초 후 `idle` 복귀 |
| `verifying` → `expired` | 410 | Login 화면 리다이렉트 |

---

### §0.2 Forgot Password 흐름

> 근거: BS-01-auth A-26 ~ A-29 (계약 확정). 3단계 wizard.

Login 화면의 "Forgot password?" 링크 클릭 시 `showDialog()` 모달 또는 별도 route `/ForgotPassword` 로 이동한다. 3단계 `Stepper` 로 구성한다.

#### 단계 1 — 이메일 입력

```
+---------------------------------------------+
|  비밀번호 찾기              [X]             |
+---------------------------------------------+
|  [1. Email] [2. Code] [3. New Password]     |
+---------------------------------------------+
|                                             |
|   가입하신 이메일을 입력하세요              |
|                                             |
|   +-------------------------------------+   |
|   |  user@example.com                   |   |
|   +-------------------------------------+   |
|                                             |
|   [   재설정 링크 전송   ]  [취소]          |
|                                             |
|   ℹ 등록 여부와 무관하게 동일한            |
|      안내가 표시됩니다 (보안)               |
+---------------------------------------------+
```

- **Flutter**: `showDialog(barrierDismissible: false)` + `Stepper` + `TextField(keyboardType: TextInputType.emailAddress)` + `ElevatedButton`
- **API**: `POST /Auth/ForgotPassword { "email": "user@example.com" }`
- **응답**: 항상 200 (보안 — 계정 존재 여부 노출 방지, A-26 Edge Case)

#### 단계 2 — 인증 코드 입력

```
+---------------------------------------------+
|  비밀번호 찾기              [X]             |
+---------------------------------------------+
|  [✓ Email] [2. Code] [3. New Password]      |
+---------------------------------------------+
|                                             |
|   user@example.com 으로 전송된             |
|   6자리 인증 코드를 입력하세요              |
|                                             |
|      [_][_][_]  [_][_][_]                   |
|                                             |
|   [   확인   ]   [뒤로]                     |
|                                             |
|   ⏱ 남은 시간: 14:32                        |
|   코드 재전송                                |
+---------------------------------------------+
```

- **Flutter**: `TextField` + `mask_text_input_formatter` + `Timer.periodic` (수동 tick) + `TextButton(child: Text("재전송"))`
- **API**: `POST /Auth/VerifyResetCode { "email": "...", "code": "123456" }`
- **응답 200**: `{ "resetToken": "rst_..." }` → 단계 3
- **응답 401** (`AUTH_RESET_LINK_EXPIRED`): "코드가 만료되었습니다. 다시 요청하세요" → 단계 1 복귀
- **응답 401** (코드 불일치): "코드가 올바르지 않습니다"

#### 단계 3 — 새 비밀번호 설정

```
+---------------------------------------------+
|  비밀번호 찾기              [X]             |
+---------------------------------------------+
|  [✓ Email] [✓ Code] [3. New Password]       |
+---------------------------------------------+
|                                             |
|   새 비밀번호                                |
|   +-------------------------------------+   |
|   |  ●●●●●●●●                      [👁] |   |
|   +-------------------------------------+   |
|   새 비밀번호 확인                          |
|   +-------------------------------------+   |
|   |  ●●●●●●●●                      [👁] |   |
|   +-------------------------------------+   |
|                                             |
|   ✓ 8자 이상    ✓ 영문+숫자    ○ 특수문자   |
|                                             |
|   [   변경   ]   [취소]                     |
+---------------------------------------------+
```

- **Flutter**: `TextField(obscureText: true, decoration: InputDecoration(suffixIcon: IconButton(Icon(Icons.visibility))))` + `Chip` 강도 indicator
- **API**: `POST /Auth/ResetPassword { "resetToken": "rst_...", "newPassword": "..." }`
- **응답 200**: 완료 → "변경되었습니다. 로그인하세요" → Login 화면
- **응답 401** (`AUTH_RESET_LINK_USED`): "이미 사용된 링크입니다" → Login 화면
- **응답 400** (약한 비밀번호): 강도 경고 표시, 재입력

#### 단계별 상태 전이

| 단계 | 성공 | 실패 |
|------|------|------|
| 1 Email | → 단계 2 (항상) | 네트워크 오류만 표시 |
| 2 Code | → 단계 3 | 만료 → 단계 1 / 불일치 → 재입력 |
| 3 Password | → Login 화면 | 사용된 link → Login / 약한 PW → 재입력 |

> **A-28 반영**: 비밀번호 변경 완료 시 서버가 해당 사용자의 모든 Refresh Token 을 무효화한다. 기존 세션은 다음 refresh 시점에 강제 로그아웃된다 (Lobby 가 별도로 처리할 필요 없음).

i18n key: `$t('login.forgot.step1Title')`, `$t('login.forgot.sendLink')`, `$t('login.forgot.codePrompt')`, `$t('login.forgot.pwRules')`.

---

### §0.3 Session Restore Dialog

> 근거: BS-01-auth A-20, A-22 ~ A-25 (계약 확정). GAP-L-009 해결. 메모리 `feedback_staff_page_baseline.md`.

Login 성공 직후(또는 2FA 통과 직후), 서버 응답 `lastContext` 가 존재하면 Series 이동 전에 본 다이얼로그를 표시한다. Operator 가 Flight 진행 중 브라우저를 닫았다가 재진입한 시나리오가 주 대상이다.

```
+----------------------------------------------+
|  이전 세션 복원                              |
+----------------------------------------------+
|                                              |
|  마지막으로 작업한 내용:                     |
|                                              |
|  ▣ Series : WSOP Main 2026                   |
|  ▸ Event  : Main Event Day 2                 |
|  ♠ Flight : Day 2                            |
|  ⊞ Table  : #47 (9 players)                  |
|  ⏱ 2시간 전                                  |
|                                              |
|  [   Continue   ]   [ 새로 시작 ]            |
+----------------------------------------------+
```

#### 구성 요소

| 요소 | Flutter widget | 바인딩 |
|------|--------|--------|
| 다이얼로그 | `showDialog(barrierDismissible: false)` | `showSessionRestore` |
| 항목 리스트 | `ListView(shrinkWrap: true)` + `ListTile` | `lastContext.*` |
| 상대 시간 표시 | `Text(..., style: TextStyle(fontSize: 12))` (caption) | `formatRelative(lastContext.timestamp)` |
| Continue | `ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary))` | 해당 route 로 `router.push()` |
| 새로 시작 | `TextButton` | `/Series` 로 이동 |

i18n key: `$t('login.restoreTitle')`, `$t('login.restoreContinue')`, `$t('login.restoreFresh')`.

#### API 계약

`POST /Auth/Login` 및 `POST /Auth/Verify2FA` 응답 body 에 다음 필드를 포함한다 (BS-01 A-22 근거):

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": { "id": "u-1", "role": "operator" },
  "lastContext": {
    "seriesId": "sr-wsop2026",
    "eventId": "ev-main",
    "flightId": "fl-day2",
    "tableId": "tbl-47",
    "operatorId": "u-1",
    "timestamp": "2026-04-10T10:32:14Z"
  }
}
```

`lastContext == null` 이면 다이얼로그를 표시하지 않고 바로 `/Series` 로 이동한다.

> **계약 확장 필요**: `lastContext` 필드는 BS-01 A-20/A-22 서술에 근거가 있으나 응답 스키마(`BS-01-auth.md` §Response 예시)에는 아직 명시되지 않았다. 구현 전 BS-01 본문에 `lastContext` 필드 row 추가 필요.

#### 복원 판정 조건

다이얼로그 표시 자체는 `lastContext != null` 이면 되지만, Continue 클릭 후 실제 route 이동에는 다음 **3가지 조건이 모두** 충족되어야 한다:

| # | 조건 | 실패 시 |
|:-:|------|--------|
| 1 | `timestamp` 가 24시간 이내 | "세션이 너무 오래되었습니다" → `/Series` |
| 2 | 해당 `flightId`/`tableId` 가 여전히 `Running` 상태 | A-23 처리: "테이블이 삭제/종료되었습니다" → Event 화면 (Day 탭) |
| 3 | 현재 사용자가 여전히 해당 테이블 할당 권한 보유 | A-24 처리: 할당 목록 재표시 |

조건 1 은 클라이언트에서, 조건 2/3 은 Continue 클릭 후 해당 route 진입 시 서버 응답으로 판정한다.

#### 상태 전이

| 상태 | 트리거 | 다음 |
|------|--------|------|
| `hidden` | `lastContext == null` | `/Series` |
| `shown` | `lastContext != null` | 사용자 선택 대기 |
| `shown` → `restoring` | Continue 클릭 | 해당 route 이동 시도 |
| `restoring` → `restored` | 서버 검증 통과 | Table 화면 + [Enter CC] 자동 표시 (A-25) |
| `restoring` → `stale` | 조건 2 실패 | Event 화면 Day 탭 (A-23) |
| `restoring` → `reassigned` | 조건 3 실패 | 할당 테이블 목록 (A-24) |
| `shown` → `dismissed` | 새로 시작 | `/Series` |

#### 크로스 레퍼런스

- §9.6 Session restore 거동 — Operator 관점 상세 시나리오
- §화면 3 Table 관리 — A-25 의 "[Enter CC] 자동 표시" 는 Table 화면에서 구현

---

## 공통 레이아웃: 빨간 헤더 바 + 좌측 사이드바

> WSOP LIVE Staff Page 핵심 레이아웃 패턴 도입 (2026-04-13). Login 화면 제외 모든 화면에 적용.

```
+================================================================+
| [★ Admin]                  04/13/2026 07:02:14 UTC+2  Aiden Kim ● ⚙ |
+================================================================+
| ← 사이드바      | Breadcrumb: EBS > Series > Event             |
|                 |                                              |
| ■ Tournaments   | (메인 콘텐츠 영역)                           |
|   Create Tourn. |                                              |
|   Templates     |                                              |
|   Series Sett.  |                                              |
| ■ Staff         |                                              |
|   Staff List    |                                              |
| ■ Players       |                                              |
|   Create Player |                                              |
|   Player Verif. |                                              |
| ■ History       |                                              |
|   Staff Action  |                                              |
| ■ Hand History  |                                              |
|   Hand Browser  |                                              |
|   Hand Detail   |                                              |
|   Player Stats  |                                              |
+-----------------+----------------------------------------------+
```

### 헤더 바

| 요소 | 위치 | 바인딩 | 비고 |
|------|------|--------|------|
| 역할 라벨 | 좌측 | `[★ {user.role}]` | Admin/Operator/Viewer 표시 |
| 브랜드 마크 | 좌측 (역할 옆) | `EBS LOBBY` + 'E' 마크 | 클릭 시 Sidebar 토글 (디자인 정합, shell.jsx:39) |
| **Show Context Cluster** | 중앙 | `SHOW · FLIGHT · LEVEL · NEXT` 4 segment | 운영 컨텍스트 상시 표시 (디자인 보강, P1) |
| 현재 날짜/시간 | 우측 | `MM/DD/YYYY HH:mm:ss` | 1초 tick, UTC offset 표시 |
| Timezone | 시간 옆 | `UTC+{offset}` | Series 설정의 timezone 반영 |
| 사용자명 | 우측 | `{user.name}` | — |
| 온라인 상태 | 이름 옆 | `●` (녹색 원) | WebSocket 연결 상태 |
| **Active CC pill** | 우측 | `<button class="cc-pill">● Active CC · {n}</button>` | 펄스 애니메이션 + count, 클릭 시 Active CC 패널 (디자인 정합, P1) |
| Settings 기어 | 최우측 | `⚙` 아이콘 | Settings 페이지 이동 |

**Flutter**: `AppBar(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white, toolbarHeight: 56)`

**Login 화면에서는 헤더 바 숨김** (인증 전이므로).

#### Show Context Cluster (운영 컨텍스트, P1, 2026-05-05 신설)

> **출처**: `EBS_Lobby_Design/shell.jsx:43-51` — operator 가 현재 어느 SHOW/FLIGHT/LEVEL 에 있는지 항상 시각 인지하기 위함. EBS 의 라이브 방송 컨텍스트(여러 테이블 동시 운영)에서 필수.

```
+-----------------------------------------------------------------+
| SHOW             | FLIGHT  | LEVEL              | NEXT          |
| WPS · EU 2026    | Day2    | L17 · 6,000/12,000 | 22:48         |
+-----------------------------------------------------------------+
```

| Segment | 라벨 | 값 바인딩 | 데이터 소스 |
|---------|------|----------|------------|
| **SHOW** | `SHOW` | `series.code · series.name_short` (예: "WPS · EU 2026") | `GET /api/v1/series/{active}` |
| **FLIGHT** | `FLIGHT` | `flight.label` (예: "Day2", "Day1A") | `GET /api/v1/flights/{active}` |
| **LEVEL** | `LEVEL` | `L{n} · {sb}/{bb}` (예: "L17 · 6,000/12,000") | Game Engine `tournament.current_level` (API-04) |
| **NEXT** | `NEXT` | `mm:ss` 카운트다운 (다음 레벨까지) | Game Engine `tournament.next_level_at` (1초 tick) |

**상태 변이**:
- `series.active == null` (진입 직후 등) → 4 segment 모두 `—` 표시
- `flight.active == null` (이벤트 진입 전) → FLIGHT/LEVEL/NEXT `—`
- `tournament.paused == true` (브레이크) → NEXT 가 `Break · {mm:ss}` 로 전환

**RBAC**: 모든 role 노출 (Admin / Operator / Viewer 동일).

**Flutter**: `Row(children: [_segment("SHOW", ...), VerticalDivider(), _segment("FLIGHT", ...), ...])` — 각 segment 는 `Column(label, value)` 위젯, 폭은 max 200dp.

#### Active CC pill (P1, 2026-05-05 신설)

> **출처**: `EBS_Lobby_Design/shell.jsx:53` — 기존 `[CC ▼]` 드롭다운을 **pill 형태로 승격**. 펄스 애니메이션으로 active 상태를 시각 강조.

```
+------------------------+
|  ●  Active CC · 3      |  ← pulse animation (1.5s ease-in-out infinite)
+------------------------+
       (click)
       ↓
+------------------------+
|  Active CC List        |
| ┌──────────────────┐  |
| │ Table 1 · Op:JK  │  |
| │ Table 5 · Op:HM  │  |
| │ Table 7 · Op:JK  │  |
| └──────────────────┘  |
+------------------------+
```

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| 펄스 도트 | `cc.activeCount > 0` 조건 | active 0 이면 dot 회색 (애니메이션 OFF) |
| Active CC 라벨 | 고정 텍스트 | i18n key `lobby.cc_pill.label` |
| Count | `cc.activeCount` (`SELECT count(*) FROM cc_sessions WHERE status='active'`) | WebSocket `cc:session_changed` 으로 실시간 갱신 |
| 클릭 동작 | Dropdown 패널 (Active CC List) | Table 별 1행 — Table 번호 + Operator 이름 + 우측 [→ Open] 버튼 |

**RBAC**:
- Admin: 모든 Active CC 표시 + Open 가능
- Operator: 본인 할당 테이블만 표시 + Open 가능
- Viewer: pill 표시 (count 만), 드롭다운 클릭 시 토스트 "Viewer 권한으로 CC 진입 불가"

**WebSocket 이벤트**: `cc:session_changed` 발행 시 `cc.activeCount` 재계산 + 펄스 애니메이션 재시작.

**Flutter**: `OutlinedButton.icon(icon: AnimatedContainer(decoration: BoxDecoration(shape: circle), ...), label: Text("Active CC · $count"), onPressed: () => showMenu(...))`

### 좌측 사이드바

**Series 진입 후 표시.** Series 목록 화면에서는 사이드바 없음 (전체 화면 카드 그리드).

| 섹션 | 메뉴 항목 | EBS 대응 |
|------|----------|----------|
| **Tournaments** | Tournaments (목록) | Event 목록 (화면 2) |
| | Create Tournament | [+ New Event] 다이얼로그 |
| | Templates / Blind | Blind Structure 템플릿 |
| | Series Settings | Settings 페이지 링크 |
| **Staff** | Staff List | 사용자 관리 (§6, Admin only) |
| **Players** | Create Player | 플레이어 등록 |
| | Player Verification | 플레이어 검증 |
| **History** | Staff Action History | 감사 로그 뷰어 |
| **Hand History** | Hand Browser | `Hand_History.md` §2.1 (Event/Day/Table/Player/Date 필터) |
| | Hand Detail | `Hand_History.md` §2.2 (액션 timeline + hole card RBAC) |
| | Player Hand Stats | `Hand_History.md` §2.3 (당일 한정 VPIP/PFR/AGR/WTSD) |

> **Hand History 섹션 (2026-04-21 신설)**: SG-016 revised. EBS 고유 기능. WSOP LIVE Staff App 에는 없으나 EBS Core §1.2 (3입력→오버레이 결과물) 의 사후 조회 도구로 필수. `BS-02-HH Hand_History.md` 가 SSOT — 진입 경로/RBAC/데이터 바인딩/Overlay 경계 정의. (Migration Plan: `docs/4. Operations/Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md` Phase 2)

**WSOP에 있지만 EBS에서 제외하는 메뉴** (§10 Divergence 참조):
Cage, Cashier Page, Wallet Status, Payroll, Payout, Chip Master, Series Chips, Tournament Ticket, Player Rating (EBS Core 범위 외). Floor Staff, Edit Tournament Entries, Auto Sequences, Player Message, Invite New Staff, Staff Notes (Phase 2+ 검토).

**Flutter**: `NavigationRail` 또는 `Drawer` + `ListView` + `ExpansionTile` (섹션별). Desktop 권장 = `NavigationRail` extended

---

## 화면 1: Series 목록

> 디자인 SSOT: `References/EBS_Lobby_Design/screens.jsx:18` (`SeriesScreen`) + 시각 캡쳐 `visual/screenshots/ebs-lobby-01-series.png` (2026-05-05 신 디자인 정합)
> Legacy mockup (deprecated 2026-05-05): `docs/mockups/ebs-lobby-01-series.html`

```
+================================================================+
| [★ Admin] [E EBS LOBBY]    SHOW · FLIGHT · LEVEL · NEXT  ● Active CC · 3 |
+================================================================+
|                                                                |
| [Search Series...  ] [✓ Hide completed] [☆ Bookmarks] [↻ Reset]|
| Status: [● Running] [● Registering] [● Announced] [○ Completed]|
|                                                   [+ New Series] |
+----------------------------------------------------------------+
| ── 2026 ───────────────────────────────────────  3 series ──── |
| +------------------+ +------------------+ +------------------+ |
| | WPS · EU 2026 ★  | | WSOP LIVE 2026 ☆ | | WSOPC Tunica   ☆ | |
| | [venue photo]    | | [venue photo]    | | [venue photo]    | |
| | Mar 31 - Apr 12  | | Mar 24 - Apr 30  | | Apr 18 - Apr 27  | |
| | 15 events  ● Run | | 95 events  ● Run | | 12 events  ● Reg | |
| +------------------+ +------------------+ +------------------+ |
|                                                                |
| ── 2025 ───────────────────────────────────────  2 series ──── |
| +------------------+ +------------------+                       |
| | WPS · EU 2025  ☆ | | WSOPC Indy     ☆ |                      |
| | [venue photo]    | | [venue photo]    |                       |
| | Apr 03 - Apr 14  | | May 12 - May 21  |                       |
| | 14 events  ○ End | | 8 events   ○ End |                       |
| +------------------+ +------------------+                       |
+----------------------------------------------------------------+
```

> **사이드바 없음**: Series 목록은 전체 화면 카드 그리드. Series 진입 후부터 사이드바 표시.

#### 그룹핑 정책 (2026-05-05 명시)

> **출처**: `EBS_Lobby_Design/screens.jsx:29` — `g[s.year] = g[s.year] || []` (year 기준 1차 그룹). 디자인 자산이 명시적으로 year-grouped 채택.

| 1차 그룹 | 2차 정렬 | 표시 |
|---------|----------|------|
| **Year** (`series.start_date.year`) | 내림차순 (2026 → 2025 → 2024) | "── 2026 ──── N series ──" 밴드 헤더 |
| 카드 (year band 내부) | `start_date` 내림차순 | 최신 시작일이 좌상단 |

**Hide completed 동작** (디자인 정합):
- 체크 ON: `status == "completed"` 카드 숨김
- 체크 OFF (default): 모든 status 표시
- localStorage 영속: `ebs_lobby_filter_hide_completed` 키

> **이전 표기 정정 (2026-05-05)**: Overview.md line 326 의 "월별 그룹핑" 표현은 디자인 자산과 충돌. 본 §화면 1 의 **연도(Year)** 기준이 SSOT. Overview.md 도 동일 정책으로 정합.

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Search | `TextField(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true))` | `filter.search` — 시리즈명 실시간 필터 |
| Only updated | `Checkbox` (+ `Row` with `Text`) | `filter.onlyUpdated` — 최근 변경 시리즈만 (기준: 24h 이내 `updated_at`, GAP-L-015) |
| Show bookmarks | `Checkbox` (+ `Row` with `Text`) | `filter.bookmarked` — 북마크 시리즈만 |
| Reset | `IconButton(icon: Icon(Icons.refresh))` | 모든 필터 초기화 |
| + New Series | Button | 수동 생성 다이얼로그 |
| Series Card | Card | `GET /Series` |
| ☆ / ★ 북마크 | `q-btn flat icon="star_border/star"` | `POST/DELETE /Series/{id}/Bookmark` (GAP-L-016) |
| Series 이름 | Text (h3) | `series.name` |
| 기간 | Text (caption) | `series.start ~ end` |
| Venue 사진 | Card 배경 이미지 | `series.image_url` |
| Event 수 | Text (body) | `series.event_count` |
| Status | Badge | `series.status` |
| **Year band 헤더** | Section divider | `series.start_date.year` 기준 그룹 (P2, 2026-05-05) |
| **Status Legend** | Toolbar 우측 | 5-color 범례 (P2, 2026-05-05) |

#### Status Badge 5-color Legend (P2, 2026-05-05 신설)

> **출처**: `EBS_Lobby_Design/screens.jsx:5-14` — `STATUS_LABEL` enum 5개 + `screens.jsx:49-54` legend display + `styles.css §badge`.
> **DB 정합**: `team2-backend/src/db/enums.py EventFSM` 와 1:1 정합 (이미 8 series seed 검증 완료).

```
+--------------------------------------------------------------+
| ●  Running        ●  Registering      ●  Announced           |
| ─────────         ────────────        ──────────             |
| (green)           (yellow)            (blue)                 |
|                                                              |
| ○  Completed      ◌  Created                                 |
| ─────────         ───────                                    |
| (gray)            (slate, faded)                             |
+--------------------------------------------------------------+
```

| Status | Label | 색상 (token) | 의미 | 운영 사용 |
|--------|-------|-------------|------|----------|
| `running` | "Running" | `var(--success)` 녹색 | 진행 중 | 카드 클릭 → 즉시 운영 |
| `registering` | "Registering" | `var(--warning)` 황색 | 등록 중 | 카드 클릭 → 등록 관리 |
| `announced` | "Announced" | `var(--info)` 청색 | 공지 (등록 전) | 카드 클릭 → 공지 편집 |
| `completed` | "Completed" | `var(--muted)` 회색 | 종료 | Hide completed 시 숨김 |
| `created` | "Created" | `var(--slate-faded)` 슬레이트 | 생성 직후 (미공지) | Admin 만 표시 (option) |

**Legend 표시 위치**: Toolbar 우측 ([+ New Series] 버튼 좌측), 5개 도트 + 라벨 가로 배치. Operator/Viewer 도 표시 (학습 보조).

**Flutter**: `Wrap(children: STATUS.map((s) => _legendItem(s.color, s.label)).toList(), spacing: 12)`

#### Bookmark / Star 검증 (P3, 2026-05-05)

> **상태**: ✅ 이미 정의됨 (line 505 `Show bookmarks` 체크박스 + line 509 `☆/★ 북마크` + `POST/DELETE /Series/{id}/Bookmark` API). 본 검증은 `EBS_Lobby_Design/screens.jsx:70`, `data.jsx:8` (starred:true) 와의 정합 확인.

| 디자인 자산 | EBS 명세 | 정합 |
|------------|----------|:----:|
| `s.starred` (boolean per series) | `POST/DELETE /Series/{id}/Bookmark` | ✅ |
| Star icon: `screens.jsx:70` (`<Icon d={I.star} />`) | UI.md line 509 ☆/★ | ✅ |
| Toolbar Bookmarks 버튼 (`screens.jsx:45`) | UI.md line 505 `Show bookmarks` 체크박스 | ✅ (디자인은 버튼, EBS 는 체크박스 — UX 동등) |

**Bookmark 스코프 (정합 확정)**: **user-scoped** (`bookmarks` 테이블 — `user_id` × `series_id` UNIQUE). 디자인 자산의 `s.starred` 는 currentUser 관점의 derived field. RBAC 모든 role 동일 사용 가능.

**위치 호환**: 카드 banner 우상단 별 아이콘 (`screens.jsx:70` `scard-banner > .star`) — Flutter 에서 `Stack` + `Positioned(top:8, right:8, child: Icon(Icons.star))` 로 매핑.

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Series Card 클릭 | 화면 2 (Events) |

---

## 화면 2: Event 목록 (Management)

> 디자인 SSOT: `References/EBS_Lobby_Design/screens.jsx:92` (`EventsScreen`) + 시각 캡쳐 `visual/screenshots/ebs-lobby-02-events.png` + Flight accordion `visual/screenshots/ebs-lobby-03-flights.png`
> Legacy mockup (deprecated 2026-05-05): `docs/mockups/ebs-lobby-02-events.html`
> WSOP LIVE Staff Page "Management" 화면과 동일 구조 (2026-04-13 스크린샷 기반).

```
+================================================================+
| [★ Admin]                04/13/2026 07:02:14 UTC+2  Aiden Kim ⚙ |
+================================================================+
| ■ Tournaments  | EBS > 2026 WSOP Europe > Management           |
|   Create Tourn.|                                                |
|   Templates    | Management                                     |
|   Series Sett. |                                                |
| ■ Staff        | Event No [__] Name [________] Mix [v]          |
|   Staff List   | Game Type [v]  Tournament Type [v]             |
| ■ Players      |                       [🔍 Search] [↻ Reset]    |
|   Create Player|                                                |
| ■ History      | [All(80)] [Announced(5)] [Registering(2)]       |
|                | [Running(3)] [Completed(45)] [Cancelled(0)]     |
|                |                                                |
|                | [Today's Events]      [Create New Tournament ▶] |
|                |                                                |
|                | +----------------------------------------------+
|                | | Start  |No| Event Name   |Remain|Unique| Alt|
|                | | Time   |  | / Flights    |/Total|      |Ent |
|                | |--------|--|--------------|------|------|----|
|                | | 04/03  |#1| $10K NLHE    | 356  | 1200 | 130|
|                | | 12:00  |  |  └Day1A Day1B| /1330|      |    |
|                | |--------|--|--------------|------|------|----|
|                | | 04/04  |#2| $1,500 PLO   |  —   |  200 |  20|
|                | | 14:00  |  |              |  /220|      |    |
|                | +----------------------------------------------+
|                | | Status |Level| LateReg | Prize  |Guarantee|
|                | | Complt | 28 |   Off   | $12M   | $10M    |
|                | |--------|-----|---------|--------|---------|
|                | | Buy-In | Tickets | Registration | Chip M |
|                | | $10,000|   1,330 |      Off     |   On   |
|                | +----------------------------------------------+
|                | Showing 20 of 80        [< 1 2 3 4 ... >]     |
+----------------+------------------------------------------------+
```

### 다중 필터 바

| 요소 | Flutter widget | 바인딩 | 동작 |
|------|--------|--------|------|
| Event No | `TextField(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true))` | `filter.eventNo` | 이벤트 번호 정확 검색 |
| Tournament Name | `TextField(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true))` | `filter.name` | 이벤트명 부분 일치 |
| Mix | `DropdownButtonFormField(isDense: true, decoration: InputDecoration(border: OutlineInputBorder()))` | `filter.mix` | Mix/Single 필터 |
| Game Type | `DropdownButtonFormField(isDense: true, decoration: InputDecoration(border: OutlineInputBorder()))` | `filter.gameType` | 게임 유형 (HOLDEM, PLO4 등) |
| Tournament Type | `DropdownButtonFormField(isDense: true, decoration: InputDecoration(border: OutlineInputBorder()))` | `filter.tournType` | 토너먼트 유형 (Freezeout, Re-entry 등) |
| Search | `q-btn color="primary" icon="search"` | — | 필터 적용 |
| Reset | `IconButton(icon: Icon(Icons.refresh))` | — | 모든 필터 초기화 |

### 상태 탭 필터 (WSOP LIVE enum 정렬)

| 탭 | 필터 값 | 뱃지 색상 | 카운트 |
|----|---------|----------|--------|
| All | 전체 | — | `(totalCount)` |
| Announced | `status == 1` | 회색 | `(count)` |
| Registering | `status == 2` | 파랑 | `(count)` |
| Running | `status == 4` | 녹색 | `(count)` |
| Completed | `status == 5` | — | `(count)` |
| Cancelled | `status == 6` | 빨강 | `(count)` |

**Flutter**: `TabBar` + `Badge` (카운트). `TabController` 가 `statusFilter` state 바인딩

### Today's Events 버튼

당일 `start_at` 이벤트만 필터. `q-btn flat icon="today"`.

### DataTable 컬럼 (WSOP LIVE 동일 15개)

| 컬럼 | 바인딩 | 정렬 | 비고 |
|------|--------|:----:|------|
| Start Time | `event.start_at` | ✅ | 날짜 + 시간 |
| No. | `event.number` | ✅ | 이벤트 번호 |
| Event Name / Flights | `event.name` + 하위 Flight 서브행 | — | 펼침 가능 (accordion) |
| Remaining / Total | `event.remaining_players / total_players` | ✅ | — |
| Unique | `event.unique_entries` | ✅ | 고유 참가자 |
| Alt Entries | `event.alt_entries` | ✅ | 대체 엔트리 (GAP-L-017) |
| Status | `event.status` | ✅ | 뱃지 (EventFlightStatus enum) |
| Level | `event.current_level` | ✅ | 현재 블라인드 레벨 |
| Late Reg | `event.late_reg_status` | — | On/Off/Level N |
| Prize Pool | `event.prize_pool` | ✅ | 금액 포맷 |
| Guarantee | `event.guarantee` | ✅ | 보증 금액 |
| Buy-in Fee | `event.buyin` | ✅ | 바이인 금액 |
| Tickets | `event.ticket_count` | ✅ | 발급 티켓 수 (GAP-L-017) |
| Registration | `event.registration_status` | — | On/Off |
| Chip M | `event.chip_mode` | — | On/Off (GAP-L-017) |

### Flight 인라인 표시 (Event+Flight 통합 원칙 유지)

Event 행을 펼치면 하위 Flight가 인라인 서브행으로 표시된다.

```
| #1 | $10K NLHE Championship   | 356/1330 | ... |
|    |  └ Day 1A  25 tables  300 players  ● Running  |
|    |  └ Day 1B  20 tables  250 players  ○ Pending  |
|    |  └ Day 2   12 tables  150 players  ○ Pending  |
```

**Flutter**: `DataTable` 또는 `PaginatedDataTable` + `ExpansionPanelList` (확장 행)

### 구성 요소 (기존 + 확장)

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Create New Tournament | `q-btn color="red" label` | 수동 생성 다이얼로그 (우상단) |
| Event Table | `DataTable` in `ListView.builder` (virtualization) or `PaginatedDataTable` | `GET /Series/{id}/Events` |
| Pagination | `PaginatedDataTable` 내장 페이지네이션 | `DataTable` 내장 |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Event Flight 행 클릭 | 화면 3 (Tables, 해당 Day 탭 선택) |

---

## 화면 3: Table 관리

> 디자인 SSOT: `References/EBS_Lobby_Design/screens.jsx:233` (`TablesScreen`) + 시각 캡쳐 `visual/screenshots/ebs-lobby-04-tables.png` (KPI 5 + Levels strip + Grid/Floor Map/CC Focus seg + 좌석 그리드 + RFID/Deck/Out/Command Center/Action 컬럼 + Waiting List 사이드바)
> Legacy mockup (deprecated 2026-05-05): `docs/mockups/ebs-lobby-03-tables.html`
> **구조 변경 (2026-04-13)**: Flight 독립 화면 폐지 → Day 탭으로 통합. 카드 레이아웃 → WSOP LIVE 행 기반 좌석 그리드. RFID/Output은 Settings로 이동. Router: `/Events/:eventId/tables?day=N`.

```
+================================================================+
| [★ Admin]                04/13/2026 07:02:14 UTC+2  Aiden Kim ⚙ |
+================================================================+
| ■ Tournaments  | EBS > WSOP Europe > #5 Main Event > Day2      |
|   ...          |                                                |
|                | Players: 356/1,330     Waiting: 0              |
|                | Total Tables: 127      Seats: 1,016 (empty:28) |
|                |                                    [Save]       |
|                |                                                |
|                | [Day1] [Day2*] [Day3]                          |
|                |    356 Out | 127 Tables                       |
|                |                                                |
|                | [Table Action ▼] [Search Player...] [+ New Tbl]|
|                | [🔀 Rebalance]                                 |
|                |                                                |
|                | +----------------------------------------------+
|                | | Table #   | S1 | S2 | S3 | S4 | S5 | S6 |   |
|                | |   / Seat #| S7 | S8 | S9 |    |    |    |   |
|                | |-----------|----|----|----|----|----|----|   |
|                | | Tbl 1  ★  | ■  | ■  | ■  | ■  | ■  |    |   |
|                | |  (Feature)| ■  | ■  | ■  |    |    |    |   |
|                | |-----------|----|----|----|----|----|----|   |
|                | | Tbl 2     | ■  | ■  | ■  | ■  |    |    |   |
|                | |           | ■  | ■  | ■  | ■  | ■  |    |   |
|                | |-----------|----|----|----|----|----|----|   |
|                | | Tbl 3     | ■  |    | ■  | ■  |    |    |   |
|                | |           | ■  | ■  |    |    |    |    |   |
|                | +----------------------------------------------+
|                |                                                |
|                | ■ = 착석 (green)  □ = 빈좌석  ✕ = busted       |
+----------------+------------------------------------------------+
```

### Players 요약 바 (WSOP LIVE 동일)

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Players | `{remaining} / {total}` | 남은/전체 플레이어 |
| Waiting | `{waitingCount}` | 대기자 수 |
| Total Tables | `{tableCount}` | 테이블 수 |
| Seats | `{seatTotal} (empty: {emptySeat})` | 좌석 현황 |

### Day 탭 (Flight 통합)

Day1 / Day2 / Day3 탭 — 각 탭은 기존 Flight 1개에 대응. 클릭 시 해당 Day의 테이블만 표시.

| 요소 | Flutter widget | 바인딩 |
|------|--------|--------|
| Day 탭 | `TabBar` with `TabController` (selectedDay state) | `GET /Events/{id}/Flights` |
| 탭 라벨 | `Tab` | `{flight.name}` + `{outCount} Out | {tableCount} Tables` |
| [+ New Day] | `Tab(icon: Icon(Icons.add))` | 새 Flight 생성 다이얼로그 |

### 좌석 그리드 (행 기반 DataTable)

| 셀 상태 | 색상 | 표시 | 의미 |
|---------|------|------|------|
| 착석 | `bg-green-4` | `■` (player ID) | 플레이어 착석 |
| 빈좌석 | `bg-grey-2` | 빈 셀 | 배정 가능 |
| Busted | `bg-red-3` | `✕` | 탈락 |
| 미사용 | — | — | 좌석 수 초과분은 컬럼 없음 |

**Flutter**: `DataTable` 또는 `Table` (fixed layout). 각 행은 Table, 각 열은 Seat 1~N. 셀은 `Container(color:)` 로 색상 표시.

### Table Action 드롭다운

| 항목 | 동작 | 권한 |
|------|------|------|
| Edit Table | 수정 다이얼로그 | Admin + 할당 Operator |
| Delete Table | 확인 후 삭제 | Admin |
| Set as Feature | Feature Table 토글 (★) | Admin |
| Enter Command Center | CC 실행 | Admin + 할당 Operator |

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Table Grid | `DataTable` (행 기반) | `GET /Events/{id}/tables?day={N}` |
| Table 이름 | Text (h3) | `table.name` |
| ★ Feature | Badge | `table.is_feature` |
| Seat 셀 | `div` (색상 셀) | `seat.status` |
| [Table Action] | `PopupMenuButton` | 위 드롭다운 |
| Search Player | `q-input dense` | 플레이어 검색 |
| + New Table | `ElevatedButton` | 테이블 생성 다이얼로그 |

> **변경 근거**: WSOP LIVE 스크린샷에서 행 기반 좌석 그리드 확인. 127개 테이블의 좌석 현황을 한눈에 조망하는 데 카드보다 행 그리드가 효율적. RFID/Output 상태는 테이블 선택이 아닌 Settings(BS-03)에서 관리하므로 카드에서 제거.

### LOCK/CONFIRM/FREE (CC LIVE 상태)

CC가 LIVE일 때 Lobby에서의 설정 변경 가능 여부:

| 분류 | 변경 가능 | 예시 |
|:----:|:---------:|------|
| **LOCK** | 불가 (비활성) | Game Type, Max Players |
| **CONFIRM** | 확인 후 다음 핸드 적용 | Blinds, Output |
| **FREE** | 즉시 변경 | Overlay, Display |

### 4.1 Rebalance Saga UI (CCR-020 APPLIED)

> 근거: `contracts/api/API-01-backend-api.md` §`POST /Tables/Rebalance` (CCR-010/CCR-020). G-05 gap 해결.

Flight 진행 중 테이블 간 플레이어 재배치는 다단계 saga 연산이며, 부분 실패/보상/수동 개입 3가지 종료 상태가 존재한다. Lobby 는 각 상태를 운영자가 구분할 수 있게 시각화한다.

#### 트리거

Table 목록 상단 툴바에 `[🔀 Rebalance]` 버튼을 추가한다. 권한: `hasPermission('Table', Permission.Write) == true` 인 Admin/Operator 만 노출 (§9.5 bit flag 참조).

```
+-------------------------------------------------+
| [Search...  ] [Filter v] [+ New] [🔀 Rebalance] |
+-------------------------------------------------+
```

- **Flutter**: `ElevatedButton.icon(icon: Icon(Icons.shuffle), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800))` + `Tooltip` 비활성 조건
- **비활성 조건**: flight.status != `Running`, 또는 `isRebalanceInProgress == true` (중복 실행 차단)

클릭 → 확인 다이얼로그(`showDialog()`) → `POST /Tables/Rebalance` 호출. `Idempotency-Key` 헤더에 `uuidv4()` 를 클라이언트가 생성해 첨부 (CCR-010 §멱등성 필수).

#### 진행 중 배너 (q-linear-progress)

saga 응답 즉시 Table 목록 상단에 진행 배너가 표시된다. WebSocket 이벤트 `rebalance_progress` 구독으로 실시간 업데이트.

```
+--------------------------------------------------+
| 🔀 재배치 중   3 / 8 steps     [상세 보기]       |
| ▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░  37%                    |
+--------------------------------------------------+
```

| 요소 | Flutter widget | 바인딩 |
|------|--------|--------|
| 배너 컨테이너 | `q-banner dense class="bg-orange-1"` | `rebalanceState.visible` |
| 진행 바 | `q-linear-progress stripe rounded` | `completedSteps / totalSteps` |
| 라벨 | `div` text | `$t('rebalance.inProgress', { cur, total })` |
| [상세 보기] | `q-btn flat dense` | `showDetailDialog = true` |

i18n key: `$t('rebalance.inProgress')`, `$t('rebalance.detail')`, `$t('rebalance.retry')`.

#### 상세 다이얼로그 (step-by-step)

[상세 보기] 클릭 시 `showDialog()` 안에 `q-list` 로 각 step 을 표시한다.

```
+----------------------------------------------+
|  Rebalance 진행 상황          sg-20260410-001 |
+----------------------------------------------+
|  ✅ 1. acquire_locks        42 ms             |
|  ✅ 2. compute_plan         18 ms             |
|  ✅ 3. release_seats       120 ms             |
|  ⏳ 4. assign_seats        ... in progress    |
|  ⬜ 5. notify_wsop_live                       |
|  ⬜ 6. broadcast_ws                           |
|                                              |
|  이동 완료: 3 명                              |
|  목표: balanced (9 players/table)             |
|                                              |
|                          [ 닫기 ]             |
+----------------------------------------------+
```

| 상태 | 아이콘 | Quasar | 색상 |
|------|:------:|--------|------|
| `ok` | ✅ | `q-icon name="check_circle"` | `text-positive` |
| `in_progress` | ⏳ | `q-spinner-dots` | `text-warning` |
| `failed` | ❌ | `q-icon name="error"` | `text-negative` |
| `compensated` | ↩️ | `q-icon name="undo"` | `text-grey` |
| (대기) | ⬜ | `q-icon name="radio_button_unchecked"` | `text-grey-5` |

각 step row 는 `ListTile` + `q-item-section avatar/main/side` (duration). 실패 행은 `q-expansion-item` 으로 펼쳐 `error.code` / `error.message` 표시.

#### 3가지 종료 상태 처리

| 응답 | saga status | Lobby 반응 |
|------|-------------|-----------|
| **200** | `completed` | 배너를 ✅ 로 전환 후 3초 후 사라짐. `moved[]` 수 toast 알림. Table 카드 새로고침 |
| **207** | `compensated` | 배너를 "⚠ 부분 실패 — 원상복구 완료" 로 전환. `[재시도]` 버튼 노출. 다이얼로그 상세에 compensation step 강조 |
| **500** | `compensation_failed` | 빨간 모달 강제 표시 "수동 개입 필요". `audit_cursor` 표시 + BO-03 §4 Scenario D 복구 절차 안내 링크 |

#### [재시도] 버튼 동작 (207 케이스)

`compensated` 상태는 **"원 상태로 복원 완료, 재시도 안전"** 을 의미한다 (CCR-020 원문). 버튼 클릭 시 동일한 `/Tables/Rebalance` 요청을 새로운 `Idempotency-Key` 로 재호출한다 (기존 saga_id 는 재사용하지 않음).

```
+----------------------------------------------+
| ⚠ 재배치 부분 실패 — 원상복구 완료          |
| 실패 단계: assign_seats (seat_conflict)       |
|                                              |
|  [ 상세 보기 ]   [ 재시도 ]   [ 닫기 ]       |
+----------------------------------------------+
```

500 케이스는 **재시도 금지** — 수동 개입 모드로 진입해야 한다.

#### WebSocket 이벤트

`ws/lobby` 채널로 수신 (API-05 구독):

| 이벤트 | payload (요약) | UI 반응 |
|--------|----------------|---------|
| `rebalance_started` | `{ saga_id, total_steps }` | 배너 표시, 진행=0 |
| `rebalance_progress` | `{ saga_id, step_no, status, duration_ms }` | 진행 바 +1, 상세 다이얼로그 row 업데이트 |
| `rebalance_completed` | `{ saga_id, status: "completed", moved }` | ✅ 전환 + Table 카드 새로고침 |
| `rebalance_compensated` | `{ saga_id, failed_step, error }` | ⚠ 전환 + [재시도] 노출 |
| `rebalance_compensation_failed` | `{ saga_id, audit_cursor }` | 🔴 수동 개입 모달 |

#### 권한

| 역할 | [🔀 Rebalance] 버튼 | 진행 배너 | [재시도] |
|------|:-------------------:|:---------:|:--------:|
| Admin | 표시 | 표시 | 가능 |
| Operator (할당 테이블 범위 외) | 숨김 | 표시 (read-only) | 불가 |
| Viewer | 숨김 | 표시 (read-only) | 불가 |

> Operator 가 자기 할당 테이블만 가진 경우에도 rebalance 는 보통 flight 전체 연산이라 Admin 전용으로 운영한다. 그러나 부분 실패 상황에서 "내 테이블이 영향받았다" 는 사실을 Operator 도 알아야 하므로 배너 read-only 노출은 유지한다.

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Table 행 클릭 | Table 상세 (좌석 확인) |
| Table Action > Enter CC | CC Flutter 앱 실행 |
| 사이드바 > Players | 화면 4 Player (독립) |
| [🔀 Rebalance] 클릭 | 확인 다이얼로그 → saga 배너 |
| Day 탭 클릭 | 같은 화면, 해당 Day 테이블만 표시 |

---

## 화면 4: Player (독립 레이어)

> 디자인 SSOT: `References/EBS_Lobby_Design/screens.jsx:359` (`PlayersScreen`) + 시각 캡쳐 `visual/screenshots/ebs-lobby-05-players.png` (KPI 5 + All/Active/Away/Elim seg + chips bar 시각화 + VPIP/PFR/AGR/FT 4컬럼)
> Legacy mockup (deprecated 2026-05-05): `docs/mockups/ebs-lobby-04-players.html`
> **독립 레이어 (2026-04-13)**: Player는 Table의 하위 단계가 아니다. 사이드바, 메인 화면 등 어디서든 상시 접근 가능한 독립 화면이다. Table 화면에서도 플레이어를 직접 추가할 수 있다.

```
+================================================================+
| [★ Admin]                04/13/2026 07:02:14 UTC+2  Aiden Kim ⚙ |
+================================================================+
| ■ Tournaments  | EBS > Players                                |
|   ...          |                                                |
| ■ Staff        | [Search Player...    ] [Filter: All Status v]  |
| ■ Players    * |                              [+ Add Player]    |
|   Player List  |                                                |
|   Create Player| +----------------------------------------------+
| ■ History      | | Name          | Table  | Seat | Stack  | St |
|                | |---------------|--------|------|--------|-----|
|                | | Mike Johnson  | Tbl 1  |  0   |125,000 | ● A|
|                | | Sarah Kim     | Tbl 1  |  1   | 98,500 | ● A|
|                | | Tom Lee       | Tbl 3  |  3   | 45,200 | ● A|
|                | | (unassigned)  |  —     |  —   | 50,000 | ○ W|
|                | | James Park    | Tbl 7  |  5   | 72,000 | ● A|
|                | +----------------------------------------------+
|                |                                                |
|                | Showing 356 players                            |
+----------------+------------------------------------------------+
```

### 독립 접근 방법

| 진입점 | 동작 |
|--------|------|
| 좌측 사이드바 > Players > Player List | Player 화면 직접 이동 |
| Table 화면 > [+ Add Player] | 플레이어 검색/등록 다이얼로그 (Player 화면 내 기능) |
| 좌측 사이드바 > Players > Create Player | 플레이어 등록 다이얼로그 |
| 어떤 화면에서든 사이드바 클릭 | 즉시 Player 화면 전환 |

### DataTable 컬럼

| 컬럼 | 바인딩 | 정렬 | 비고 |
|------|--------|:----:|------|
| Name | `player.name` | ✅ | 플레이어 이름 |
| Table | `player.table_name` | ✅ | 현재 배정 테이블 (미배정 시 "—") |
| Seat | `player.seat_index` | ✅ | 좌석 번호 |
| Stack | `player.stack` | ✅ | 칩 수량 (숫자 포맷) |
| Status | `player.status` | ✅ | ● Active / ○ Waiting / ✕ Busted |
| Actions | — | — | 배정/이동/제거 버튼 |

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Search | `q-input dense` | 이름/ID 검색 |
| Status Filter | `q-select dense` | All / Active / Waiting / Busted |
| + Add Player | `ElevatedButton` | 플레이어 등록 다이얼로그 |
| Player Table | `DataTable` in `ListView.builder` (virtualization) or `PaginatedDataTable` | `GET /Players` 또는 `GET /Events/{id}/Players` |
| Table 링크 | Text (link) | 클릭 시 해당 Table 화면으로 이동 |

### Table 화면과의 연동

Table 화면(화면 3)에서도 플레이어를 직접 추가할 수 있다:
- Table 화면의 좌석 그리드에서 빈 좌석 클릭 → 플레이어 배정 다이얼로그
- `[+ Add Player]` 버튼 → 플레이어 검색/등록 → 좌석 자동 배정
- 이 기능은 Player 독립 화면의 기능을 Table 화면에서 **인라인 호출**하는 것

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Table 링크 클릭 | 해당 Table 화면 (화면 3) |
| Player 행 클릭 | 플레이어 상세 다이얼로그 |

---

## 화면 간 네비게이션 요약

> **구조 (2026-04-13 확정)**: 3계층 drill-down + 독립 레이어.

```
┌─ 메인 계층 (drill-down) ─────────────────────┐
│  Login ──→ Series ──→ Events ──→ Tables → CC  │
│                        (Day 탭)                │
└───────────────────────────────────────────────┘

┌─ 독립 레이어 (사이드바에서 상시 접근) ────────┐
│  Player   — 어디서든 확인/추가 가능            │
│  Staff    — Admin only                         │
│  Settings — 글로벌                              │
└───────────────────────────────────────────────┘
```

### 메인 계층

| 전환 | 방향 | 트리거 |
|------|:----:|--------|
| Login → Series | 단방향 | 로그인 성공 (또는 Google OAuth) |
| Series → Events | 양방향 | 카드 클릭 / Breadcrumb |
| Events → Tables | 양방향 | Flight 서브행 클릭 / Breadcrumb |
| Tables (Day 탭 전환) | 같은 화면 | Day 탭 클릭 |
| Tables → CC | 단방향 | Table Action > Enter CC |

### 독립 레이어

| 전환 | 트리거 | 비고 |
|------|--------|------|
| 어디서든 → Player | 사이드바 > Players | Table에 종속되지 않음 |
| 어디서든 → Staff | 사이드바 > Staff List | Admin only |
| 어디서든 → Settings | 헤더 ⚙ 아이콘 | 글로벌 설정 |

### 핵심 원칙

- **Player는 Table의 하위가 아니다**. Table → Player drill-down 없음.
- **Table 화면에서 플레이어 추가 가능** (인라인 호출). 단, Player 자체는 독립 화면.
- **Breadcrumb**: `EBS > Series > Event > Table` — Player 단계 없음.
- Event 목록에서 Flight는 인라인 서브행으로 표시, Flight 클릭 시 Tables 화면(해당 Day 탭)으로 직행.

---

## 9. WSOP LIVE Parity Notes

> **✅ CCR-017 APPLIED (2026-04-10)** — `contracts/specs/BS-01-auth/BS-01-auth.md §Permission Bit Flag` (구 BS-01-02-rbac.md, 통합됨), `BS-02-lobby/BS-02-02-event-flight.md`, `BS-02-lobby/BS-02-03-table.md`, `BS-03-settings/BS-03-04-rules.md`, `contracts/data/DATA-04-db-schema.md` 5개 파일에 EventFlightStatus / isRegisterable / dayIndex / BlindDetailType / isPause / Bit Flag Permission 확장 완료. 승격본: `docs/05-plans/ccr-inbox/promoting/CCR-017-wsop-parity.md`.
> 이 섹션은 WSOP LIVE Confluence 미러(`C:\claude\wsoplive\docs\confluence-mirror\`)의 핵심 규칙을 Team 1 기획서에 선반영한 내용이었고, 이제 **모든 규칙이 contracts/ 에 APPLIED 상태**다. 구현 시 아래 규칙을 곧바로 계약된 enum/필드명으로 사용한다. 기준선: **WSOP LIVE Staff Page + Confluence 미러 원본** (memory `feedback_staff_page_baseline.md` — 신규 추론 전 기존 방식 확인 필수).

### 9.0 Scope note (G-01)

> **Scope**: 본 §9 의 모든 규칙은 **Tournament 모드** 전제다. Cash Game 테이블은 Day/Flight/Late Reg 개념 자체가 없으므로 본 섹션의 상태 매트릭스·계산식·배지 규칙이 적용되지 **않는다**.
>
> Cash Game 지원은 현재 EBS 범위 외(**G-01 out-of-scope**) — 2027-01 런칭 범위(메모리 `project_2027_launch_strategy.md` = MVP 홀덤 토너먼트 1종) 기준. 향후 Cash Game 지원이 필요해질 경우 BS-02 확장 CCR 로 별도 제안한다.
>
> **구현 시 판정**: Lobby 가 Flight/Event 카드에 §9.1 상태 배지를 그릴 때, `event.mode == "cash"` 이면 본 섹션 규칙을 적용하지 않고 단순 "Active / Closed" 2상태만 사용한다. 단, 2027-01 시점에는 cash mode 자체가 Event 폼에서 선택 불가이므로 실제 분기는 발생하지 않는다.

### 9.1 도메인 규칙 SSOT — pointer 테이블 (CCR-017 APPLIED, 2026-04-14 정리)

§9.1~§9.5 에 있던 enum/매트릭스/계산식/권한 매핑(약 140줄)은 모두 **canonical SSOT 로 이미 이관 완료**되었다. UI 구현은 아래 SSOT 를 직접 참조한다 — 본 UI 문서는 화면 설계에 집중한다.

| 개념 | Canonical SSOT | 내용 |
|------|----------------|------|
| `EventFlightStatus` enum (`0/1/2/4/5/6`) + 전환 규칙 + Day×isRegisterable 매트릭스 + `Restricted` 배지 + `dayIndex` 필드 | `../Specs/BS-02-lobby/BS-02-02-event-flight.md` | 상태값·전환·UI 배지 매핑. WSOP LIVE 원본 값 3 skip. |
| `BlindDetailType` enum (`Blind/Break/DinnerBreak/HalfBlind/HalfBreak`) + Late Reg 남은 시간 계산식 + Mix Game 특수 규칙(G-02) | `../Specs/BS-03-settings/BS-03-04-rules.md §5` | 계산식은 variant 개수와 무관. `flight.is_pause == true` 시 elapsed 증가 멈춤. |
| `TableFSM` (`EMPTY/SETUP/LIVE/PAUSED/CLOSED`) × `is_pause` 직교 축 + scheduled break vs in-hand pause 구분 (G-04) | `../Specs/BS-02-lobby/BS-02-03-table.md` | 일시정지 아이콘(`⏸`)은 `is_pause == true` 로만 판정 — GUI status 단독 판단 금지 |
| Bit Flag `Permission` enum (`None=0/Read=1/Write=2/Delete=4`) + 역할×리소스 매트릭스 + 액션 단위 권한 4행(G-03: Series 생성/CC Assignment/Flight lifecycle/Blind override) | `../../Contracts/Specs/BS-01-auth/BS-01-auth.md §Permission Bit Flag` | UI 활성화는 비트 연산 (`role.permission & Permission.Write != 0`). enum 문자열 (`"admin"/"operator"/"viewer"`) 비교 금지. |
| Entity 필드 정의 (`Flight.dayIndex`, `Table.is_pause` 등 124필드) | `../../Contracts/Data/DATA-04-db-schema.md`, `../../Contracts/Data/DATA-02-entities.md` | 서버 응답 스키마. WSOP LIVE API 매핑은 BS-02-00-overview §WSOP LIVE API 데이터 매핑 참조. |

> **CCR-017 승격본**: `docs/05-plans/ccr-inbox/promoting/CCR-017-wsop-parity.md` (5개 파일 반영 완료).
> **이력**: 2026-04-10 작성된 §9.1~§9.5 본문(약 140줄)은 모든 규칙이 contracts/ 및 팀 행동명세에 APPLIED 되어 2026-04-14 본 pointer 테이블로 축약. WSOP LIVE Staff Page + Confluence 미러(`C:\claude\wsoplive\docs\confluence-mirror\`)가 원 baseline (memory `feedback_staff_page_baseline.md`).
> **§9.0 (Cash Game scope-out), §9.6 (Session Restore 거동), §9.7 (특수 토너먼트)** 은 UI 고유 콘텐츠로 보존됨.

### 9.6 Session Restore 거동 (G-07)

> 근거: BS-01-auth A-20, A-22 ~ A-25. §0.3 Session Restore Dialog 와 cross-link. G-07 gap 해결.

Operator 가 Flight 진행 중 브라우저를 새로고침하거나 재로그인했을 때, 이전 작업 문맥으로 최대한 빠르게 복귀시키는 플로우다. §0.3 이 UI 측면을 정의한다면 본 섹션은 **서버 계약 + 복원 조건 + 실패 시 fallback** 을 정의한다.

#### 서버 응답 계약

`POST /Auth/Login` / `POST /Auth/Verify2FA` / `GET /Auth/Session` 응답 body 에 `lastContext` 필드를 포함한다.

```
lastContext {
  seriesId    : string   // 필수
  eventId     : string   // 필수
  flightId    : string   // 필수
  tableId     : string?  // optional — Table 화면까지 진입했을 때만
  operatorId  : string   // 필수 — 토큰 사용자와 동일해야 함
  timestamp   : ISO-8601 // lastContext 가 기록된 시각
}
```

`lastContext == null` 이면 복원 다이얼로그 생략.

#### 복원 성공 3 조건 (AND)

| # | 조건 | 검증 위치 | 실패 시 |
|:-:|------|-----------|--------|
| 1 | `now() - lastContext.timestamp < 24h` | 클라이언트 | 다이얼로그 생략 → `/Series` |
| 2 | 대상 `flightId` 가 여전히 `Running` 상태 + `tableId` 존재 | 서버 (route 진입 시) | "테이블 상태 변경" → Event 화면 Day 탭 (A-23) |
| 3 | 현재 로그인 사용자의 할당에 해당 `tableId` 포함 (Operator 인 경우) | 서버 | "할당 변경" → 할당 테이블 목록 (A-24) |

Admin 은 조건 3 을 면제 (모든 테이블 접근 권한).

#### 부분 복원 규칙

Table 까지 복원 불가 하더라도 더 높은 계층(Series/Event/Flight)은 복원 시도한다:

```
Full restore failure case ladder:
  tableId fail   → Event 화면 Day 탭 (해당 Flight의 Table 목록)
  flightId fail  → Event 화면 (Event 목록)
  eventId fail   → Series 의 Event 목록 화면
  seriesId fail  → Series 목록 화면 (/Series)
```

각 fallback 시점에 `q-notify` 로 한 줄 안내 ("테이블이 종료되어 Event 화면으로 이동합니다" 등).

#### Operator 재할당 특수 처리

A-24 시나리오: Operator 가 로그아웃한 사이 Admin 이 다른 테이블로 재할당한 경우. 이 때 session restore 는 **중단**되고 대신 "새 할당 목록" 화면을 표시한다.

```
+------------------------------------------+
|  할당이 변경되었습니다                    |
+------------------------------------------+
|  이전: Table #47                          |
|  새 할당:                                 |
|    • Table #12 (Day 2, 8/9 players)       |
|    • Table #18 (Day 2, 9/9 players)       |
|                                          |
|  [ 확인 ]                                 |
+------------------------------------------+
```

할당 테이블이 0개면 "테이블 미할당 — 관리자에게 문의" (A-24 Edge Case).

#### A-25: [Enter CC] 자동 표시

복원이 Table 화면까지 성공했고 해당 Operator 에게 이전에 Launch 한 CC 세션 기록이 있으면, Table 화면의 [Enter CC] 버튼에 "이전 세션 이어하기" 배지를 표시한다.

```
[ Enter CC ]   [ 🔄 Launch CC (이어하기) ]
```

CC 직접 복원은 불가 — Lobby 에서 테이블 선택 후 재Launch 필요 (BS-01 A-25 Edge Case).

#### §0.3 와의 관계

- **§0.3** = 다이얼로그 UI, Quasar 컴포넌트, 상태 전이
- **§9.6** = 서버 계약, 복원 조건, fallback ladder, Operator 재할당 특수 처리

두 섹션은 동일한 기능의 두 측면이며 상호 일관성 필수.

### 9.7 특수 토너먼트 구조 Scope Note (G-08)

> **Scope out**: 다음 특수 토너먼트 구조는 현재 Team 1 UI 범위 외다. 각 구조는 기본 Tournament 대비 UI 흐름이 다르거나 추가 필드가 필요하므로, 필요 시점에 BS-02 확장 CCR 로 별도 제안한다.

#### 1) Satellite (좌석 티켓 payout)

- **특징**: 우승자에게 금액이 아닌 **메인 이벤트 좌석**(티켓) 지급. 1 위부터 N 위까지 동일한 좌석 1 장씩.
- **다른 점**: Flight status `Completed` 시 payout 구조가 통상 `prize_pool → ranked payout` 이 아니라 `seat_tickets` 배열로 표현되어야 함.
- **범위 외 이유**: 2027-01 MVP = WSOP Main Event 1종 타겟, satellite 는 WSOP 본 대회에선 별도 앱(WSOP LIVE) 에서 운영.
- **향후 확장 시**: Event 생성 폼에 `mode: "satellite"` 옵션 + payout 필드를 `seat_count` 로 치환. Flight Completed 시 우승자 카드에 "좌석권 N 장" 표시.

#### 2) Hyper Turbo

- **특징**: Blind level 지속시간이 3~5 분 (일반 60 분 대비 극단적으로 짧음). Late Reg 구간도 그만큼 짧아짐.
- **다른 점**: 계산식 자체(§9.3)는 동일하나 **UX 압박**이 커진다. Operator 가 level 전환을 놓칠 위험이 높아 UI 에 큰 카운트다운 필요.
- **범위 외 이유**: 수식/데이터 모델 변경은 없으므로 UI 만의 문제. MVP 이후 "Hyper Turbo UI profile" 로 별도 제안.
- **향후 확장 시**: Flight 카드 헤더에 40px+ 크기의 level timer, level 전환 10초 전 `q-notify` + 사운드 알림.

#### 3) Unlimited Re-entry

- **특징**: Re-entry 횟수 제한 없음. `registered_player_count` 가 Late Reg 종료까지 계속 증가.
- **다른 점**: 현재 Flight 생성 폼은 "Standard Tournament / Re-entry (N 회) / Freezeout" 3 옵션. Unlimited 는 N = ∞ 특수 케이스지만 UI 는 단순 체크박스로 충분할 가능성 있음.
- **범위 외 이유**: 데이터 모델상 Re-entry 카운트 필드의 max 제약만 풀면 되는 작은 변경이지만, prize pool 계산과 entries display 가 실시간 변동하므로 전용 UX 검증 필요.
- **향후 확장 시**: Flight 폼에 `reentryLimit: int | "unlimited"` + Lobby Flight 카드 entries 표시에 "🔄 Unlimited Re-entry" 배지.

#### 현재 Flight 생성 폼 지원 범위

화면 3 (Table 관리) Day 탭의 `[+ New Day]` 다이얼로그는 **다음 3 옵션만** 제공한다 (G-08 명시적 scope):

| 옵션 | 필드 |
|------|------|
| Standard Tournament | (추가 필드 없음) |
| Re-entry | `reentryLimit: int` (1~∞ 중 정수 입력) |
| Freezeout | (재입장 불가 플래그만) |

Satellite/Hyper Turbo/Unlimited 는 위 3 옵션 어디에도 체크되지 않으며, 관련 UI 컴포넌트가 **존재하지 않는다**.

---

## 화면 5: RBAC 계정 권한 관리 (Admin only)

> 신규 (2026-04-13). WSOP LIVE 사이드바 Staff 섹션에 대응. 좌측 사이드바 "Staff > Staff List" 클릭 시 표시.

```
+================================================================+
| [★ Admin]                04/13/2026 07:02:14 UTC+2  Aiden Kim ⚙ |
+================================================================+
| ■ Tournaments  | EBS > Staff Management                       |
|   ...          |                                                |
| ■ Staff        | [Search...    ] [Filter: All Roles v]          |
|   Staff List * |                          [+ New User]          |
| ■ Players      |                                                |
|   ...          | +----------------------------------------------+
|                | | Email         | Name    | Role     | Status  |
|                | |---------------|---------|----------|---------|
|                | | admin@ebs     | Aiden K | Admin  ★ | ● Active|
|                | | op1@ebs       | J.Smith | Operator | ● Active|
|                | | op2@ebs       | K.Park  | Operator | ● Active|
|                | | op3@ebs       | T.Lee   | Operator | ○ Disabled|
|                | | viewer@ebs    | M.Cho   | Viewer   | ● Active|
|                | +----------------------------------------------+
+----------------+------------------------------------------------+
```

### 사용자 목록 DataTable

| 컬럼 | 바인딩 | 정렬 | 비고 |
|------|--------|:----:|------|
| Email | `user.email` | ✅ | — |
| Name | `user.display_name` | ✅ | — |
| Role | `user.role` | ✅ | 뱃지: Admin=빨강, Operator=파랑, Viewer=회색 |
| Status | `user.is_active` | ✅ | ● Active / ○ Disabled |
| Tables | `user.assigned_tables[]` | — | Operator만 표시 ("All" 또는 테이블 목록) |
| 2FA | `user.is_2fa_enabled` | — | ✅ / — |
| Last Login | `user.last_login_at` | ✅ | 상대 시간 표시 |
| Actions | [Edit] [⋮] | — | 수정 + 더보기 메뉴 |

**API**: `GET /Users` (Admin only, API-01 §5.2)

### 사용자 생성/수정 다이얼로그

```
+----------------------------------------------+
| 사용자 생성                           [X]     |
+----------------------------------------------+
|                                              |
| Email Address *                              |
| +------------------------------------------+|
| | operator@ebs.local                        ||
| +------------------------------------------+|
|                                              |
| Display Name *                               |
| +------------------------------------------+|
| | Operator 1                                ||
| +------------------------------------------+|
|                                              |
| Password * (생성 시만)                       |
| +------------------------------------------+|
| | ●●●●●●●●                           [눈]  ||
| +------------------------------------------+|
| ✓ 8자 이상  ✓ 영문+숫자                     |
|                                              |
| Role *                                       |
| (●) Admin  (○) Operator  (○) Viewer         |
|                                              |
| ┌─ Operator 선택 시 ──────────────────────┐  |
| │ Table Access                             │  |
| │ (●) All Tables — 모든 테이블 접근 가능  │  |
| │ (○) Specific Tables — 지정 테이블만     │  |
| │                                          │  |
| │ ┌─ Specific 선택 시 ──────────────────┐ │  |
| │ │ [✓ Table 1] [✓ Table 3] [ Table 5] │ │  |
| │ │ [ Table 7]  [ Table 9]  [ Table 11]│ │  |
| │ │ [Select All] [Clear All]            │ │  |
| │ └────────────────────────────────────┘ │  |
| └──────────────────────────────────────────┘  |
|                                              |
| Account Status                               |
| [●] Active  [○] Disabled                    |
|                                              |
|              [Cancel]  [  Save  ]            |
+----------------------------------------------+
```

### 폼 필드

| 필드 | 타입 | 필수 | 유효성 검증 | 비고 |
|------|------|:----:|------------|------|
| Email Address | `q-input type="email"` | ✅ | 이메일 형식 + 중복 체크 | 수정 시 readonly |
| Display Name | `TextField` | ✅ | 2~50자 | — |
| Password | `q-input type="password"` | 생성 시만 | 8자+, 영문+숫자 | 수정 시 별도 "Reset Password" 버튼 |
| Role | `q-option-group type="radio"` | ✅ | Admin/Operator/Viewer | — |
| Table Access | `q-option-group type="radio"` | Operator만 | All Tables / Specific Tables | Role=Operator 시만 표시 |
| Assigned Tables | `q-option-group type="checkbox"` | Specific 시 | 최소 1개 | Table Access=Specific 시만 표시 |
| Account Status | `Switch` | ✅ | Active/Disabled | Disabled = 로그인 차단 |

**API**: 생성 `POST /Users` → 201. 수정 `PUT /Users/:id` → 200. 삭제 `DELETE /Users/:id` → 204.

### Table Access 모드

| 모드 | JWT `assigned_tables` | 권한 효과 |
|------|----------------------|----------|
| **All Tables** | `["*"]` (와일드카드) | 모든 테이블에 Operator 권한 |
| **Specific Tables** | `["tbl_01", "tbl_05"]` | 지정 테이블만 Write, 나머지 Read |

All Tables 용도: 수석 Operator나 Floor Manager가 모든 테이블을 순회하며 관리해야 할 때.

### 역할 변경 부수 효과 (BS-01 A-13)

- 역할 변경 → 해당 사용자의 **모든 토큰 즉시 무효화** (강제 재로그인)
- 사용자 비활성화 → 동일 + 활성 WebSocket 강제 종료
- 감사 로그: `audit_logs`에 `role_changed` / `user_disabled` 이벤트

### Admin Force Logout (BS-01 A-19)

사용자 행의 `[⋮]` 메뉴 → `[Force Logout]` 클릭:
1. 확인 다이얼로그: "J.Smith의 모든 활성 세션을 종료합니다"
2. `POST /Users/:id/force-logout`
3. 해당 사용자의 모든 Refresh Token 무효화 + WebSocket 강제 종료
4. 감사 로그: `admin_force_logout`

### 화면 접근 권한

| 역할 | Staff Management | 사용자 CRUD | Force Logout |
|------|:----------------:|:----------:|:------------:|
| Admin | ✅ | ✅ Full | ✅ |
| Operator | ❌ 사이드바 숨김 | ❌ | ❌ |
| Viewer | ❌ 사이드바 숨김 | ❌ | ❌ |

**Router guard**: `/Staff/*` 경로에 `requireRole('admin')` 가드 적용.

---

## 10. WSOP LIVE Divergence 로그

> 신규 (2026-04-13). WSOP LIVE Staff Page 스크린샷 비교에서 식별된 의도적 divergence 목록.

| ID | WSOP LIVE 기능 | EBS 결정 | 이유 |
|----|---------------|----------|------|
| DIV-ROLE | Series별 Select Role 드롭다운 | 계정 수준 고정 역할 | 소규모 운영팀, RBAC 단순화. 역할 변경은 Admin이 Staff Management에서 수행 |
| DIV-SIDEBAR | Cage/Payroll/Chip Master/Ticket 등 20+ 메뉴 | EBS 범위 내 7개만 | EBS Core = 실시간 오버레이 출력. 금전/칩/급여 관리는 별도 시스템 |
| DIV-MULTITAB | Event 상세 11탭 뷰 (MAIN~HISTORY) | 3계층 drill-down + 독립 레이어 | PAYOUT/PRICE POOL/ASSESSMENT/PAYMENTS/HISTORY는 EBS Core 범위 외 |
| DIV-AUTOSEAT | Auto Seating (Disable/Enable/Open Seats) | Phase 2 검토 | Phase 1은 수동 좌석 배정 우선 |
| DIV-WAITING | Waiting List 탭 | Phase 2 검토 | Phase 1 범위 외 |
| DIV-CALCULATOR | View By Calculator 링크 | 미구현 | 프라이즈풀 계산기 EBS out-of-scope |
| DIV-REMEMBER | Remember me 체크박스 (Login) | EBS 추가 | WSOP에 없지만 UX 향상. 유지 |
| DIV-FORGOT | Forgot password 링크 (Login) | EBS 추가 | WSOP에 없지만 보안 운영 필수. 유지 |
| DIV-PWDEYE | Password 눈 아이콘 (Login) | EBS 추가 | UX 향상. 유지 |

---

## 관련 CCR

본 문서 §9 WSOP LIVE Parity Notes 와 Graphic Editor 경계 서술의 근거가 된 CCR 목록. 모두 **APPLIED** 상태 (2026-04-10).

| CCR | 상태 | 변경 대상 | 관련 섹션 |
|-----|------|----------|----------|
| **CCR-017** wsop-parity (EventFlightStatus / isRegisterable / dayIndex / Restricted / BlindDetailType / isPause / Bit Flag RBAC) | ✅ APPLIED | `contracts/specs/BS-01-auth/BS-01-auth.md §Permission Bit Flag` (구 BS-01-02-rbac.md 통합됨), `BS-02-lobby/BS-02-02-event-flight.md`, `BS-02-lobby/BS-02-03-table.md`, `BS-03-settings/BS-03-04-rules.md`, `contracts/data/DATA-04-db-schema.md` | §9.1 ~ §9.5 전체 |
| **CCR-016** tech-stack-ssot (Lobby Quasar 확정 + BS-00 SSOT 문장 신설) | ✅ APPLIED | `contracts/specs/BS-00-definitions.md` | §0 기술 스택, Lobby 전체 기술 근거 |
| **CCR-011** ge-ownership-move (Graphic Editor Team 4 → Team 1 Lobby 허브 이관) | ✅ APPLIED | `../Specs/BS-08-graphic-editor/BS-08-00~04`, `BS-00-definitions.md` | Lobby 화면 범위(Graphic Editor 허브 추가), §권한(Admin/Operator/Viewer RBAC gate) |
| **CCR-025** bs03-graphic-settings-tab (BS-03-02-gfx 시각 asset 메타 확장) | ✅ APPLIED | `../Specs/BS-03-settings/BS-03-02-gfx.md` | (간접) Settings GFX 탭의 Team 4 기여 필드 |

CCR 경로: `docs/05-plans/ccr-inbox/promoting/CCR-{011,016,017,025}-*.md`
원본 drafts: `docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260410-{wsop-parity,tech-stack-ssot}.md`, `CCR-DRAFT-conductor-20260410-ge-ownership-move.md`, `CCR-DRAFT-team4-20260410-bs03-graphic-settings-tab.md`

### 대기 중 CCR (2026-04-13)

| CCR Draft | 상태 | 변경 대상 | 관련 섹션 |
|-----------|------|----------|----------|
| `CCR-DRAFT-team1-20260413-google-oauth.md` | 🔶 DRAFT | `BS-01-auth.md`, `API-06-auth-session.md` | §0 Login Google OAuth |
