---
title: QA Pass Criteria — e2e Screenshot 추출 + 사용자 확인 SSOT
owner: S0 Conductor
tier: internal
audience: developer
status: ACTIVE
version: v1.0
created: 2026-05-12
related:
  - .claude/agents/s9-qa.md
  - integration-tests/playwright/
  - docs/4. Operations/Multi_Session_Design_v11.md
---

# QA Pass Criteria — 통과 정의 SSOT

**사용자 명시 정의 (2026-05-12)**:
> "qa 의 정의 e2e screenshot 을 추출하여 검증후 확인되면 통과"

본 문서는 EBS 프로젝트의 모든 QA 통과 판정 기준을 정의한다. 이전 cycle 에서 `curl 200` 만으로 QA 통과 판정한 실수를 영구 방지.

---

## 1. QA 통과 정의 (3 단계)

QA 통과는 **3 단계를 모두 충족**할 때만 인정된다:

```
Step 1.  e2e screenshot 추출  (Playwright 실 실행)
Step 2.  검증 (UI 실 로드 + 기능 작동)
Step 3.  사용자 확인 (절대 경로 보고 + 사용자 직접 확인)

→ 3 단계 모두 PASS 시 "QA 통과"
→ 1 단계라도 미달 시 "QA 통과 아님"
```

## 2. ❌ QA 통과 아닌 경우 (반복 금지 패턴)

| 잘못된 판정 | 이유 |
|------------|------|
| `curl POST /api/v1/auth/login → 200` 만으로 통과 | API 만, UI 검증 X |
| `integration-tests/scenarios/v0X.http` 5/5 PASS 만으로 통과 | REST harness 만, 브라우저 검증 X |
| evidence 파일 main 머지 = 통과 | 파일 존재 ≠ UI 실 작동 |
| broker `pipeline:qa-pass` publish 만 통과 | 신호 ≠ 결과 |
| Docker container healthy 만 통과 | 인프라 ≠ 기능 |

## 3. ✅ QA 통과 인정 패턴

### 3.1 Step 1 — e2e Screenshot 추출

```
도구:    Playwright (integration-tests/playwright/tests/*.spec.ts)
실행:    npx playwright test <spec>
산출물:  test-results/<scenario>/*.png 또는 evidence/<cycle>/<scenario>/*.png

최소 screenshot:
  01-load.png       URL 첫 진입 시 화면
  02-after-action.png  사용자 액션 후 (로그인, 클릭 등)
  03-end-state.png  최종 상태 (dashboard 진입 등)

권장 6+ phase screenshot (시나리오 별)
```

### 3.2 Step 2 — 검증 (UI 실 로드 + 기능 작동)

```
검증 체크리스트:
  ✅ HTTP 응답 200 (curl)
  ✅ HTML body 로드 (Flutter Web 의 main.dart.js / assets 모두 200)
  ✅ Console 에 ERR_CONNECTION_REFUSED / 4xx / 5xx 없음
  ✅ 사용자 액션 (로그인, 입력 등) 실 작동
  ✅ 화면 전환 (login → dashboard 등) 검증
  ✅ Screenshot 가 실 UI 표시 (loading spinner 아님)
```

### 3.3 Step 3 — 사용자 확인

```
보고 형식 (S9 → 사용자):
  - Screenshot 절대 경로 (Windows: C:\claude\ebs\test-results\...)
  - 시나리오 명 + Phase
  - 검증 결과 (자체 audit)
  - 사용자 검토 요청

사용자 확인 방법:
  - 절대 경로 파일 직접 열어서 화면 확인
  - LAN 디바이스 (모바일/태블릿) 실 접속 (선택)
  - 통과/거부 명시
  
→ 사용자 통과 명시 후 PR 머지 가능
```

## 4. 시나리오 분류 + 최소 Screenshot

### 4.1 v01 1-hand e2e

```
Phase A   01-load        Lobby 첫 진입
Phase B   02-login       admin@local 로그인 → dashboard
Phase C   03-table       Table 생성 → 6-seat 표시
Phase D   04-cc-assign   CC 할당 → CC 화면 진입
Phase E   05-rfid        RFID Mock 카드 등록
Phase F   06-hand-end    Hand 1 종료 → winner 표시

총: 6 screenshot
```

### 4.2 v02 multi-hand e2e

v01 + Phase G~J:
```
Phase G   07-next-hand   POST /next-hand → handNumber=2
Phase H   08-rotate      button/SB/BB 회전 visible
Phase I   09-hand-2-end  Hand 2 winner
Phase J   10-handhistory  handHistory 표시

총: 10 screenshot
```

### 4.3 LAN 검증

```
01-lan-load        LAN IP 접속 (192.168.x.x:3000)
02-lan-login       다른 디바이스 로그인
03-lan-dashboard   dashboard 로드
04-mobile-touch    모바일 터치 입력 (선택)

총: 4 screenshot
```

## 5. S9 QA Stream 책임

```
S9 (.claude/agents/s9-qa.md) 의 cycle 진입 표준 절차:

1. 본 SSOT (QA_Pass_Criteria.md) 정의 준수
2. Playwright spec 작성 (.ts 파일)
3. 실 실행 → screenshot 추출
4. evidence/<cycle>/ 폴더 + summary.txt
5. 사용자에게 절대 경로 보고 + 검토 요청
6. 사용자 통과 명시 시 → broker publish pipeline:qa-pass
7. PR 머지는 사용자 확인 후

위반 금지:
  - curl 200 만으로 pipeline:qa-pass publish
  - evidence 파일 main 머지로 QA 통과 자처
  - 사용자 확인 없이 PR auto-merge
```

## 6. S0 Conductor 책임

```
본 SSOT 준수 강제:
  - PR auto-merge 시 QA 통과 검증 (sub-evidence + 사용자 확인 여부)
  - QA 통과 아닌 PR 머지 금지 (UI 검증 부재)
  - 사용자 비판 즉시 인정 + 정정

위반 시 (반복):
  - 즉시 PR revert
  - S9 재 dispatch (Step 1~3 충족)
  - 정직 보고
```

## 7. 검증 명령 (사용자 통과 판정 전 self-audit)

```bash
# A. Lobby 3000 실 로드 검증
curl -s http://localhost:3000/ -I | head -5
curl -s http://localhost:3000/main.dart.js -I | head -5
curl -s http://localhost:3000/flutter.js -I | head -5
# 모두 200 OK 이어야 함

# B. Screenshot 추출
cd integration-tests/playwright && npx playwright test tests/lobby-login.spec.ts
ls test-results/lobby-login/*.png

# C. evidence 폴더
ls evidence/cycleN-<date>/<scenario>/

# D. summary.txt (자체 검증)
cat evidence/cycleN-<date>/<scenario>/summary.txt
# 기대: 모든 phase PASS + screenshot 경로 명시

# E. 사용자 확인 (S0 → 사용자)
echo "Screenshot 경로 보고:"
echo "  C:\claude\ebs\test-results\<scenario>\01-load.png"
echo "사용자 검토 요청"
```

## 8. Anti-Pattern (반복 금지)

| 패턴 | 왜 금지 |
|------|--------|
| `curl 200 → 통과` | API 만, UI 우회 |
| `evidence 파일 main 머지 → 통과` | 파일 존재 ≠ 실 작동 |
| `broker publish pipeline:qa-pass → 통과` | 신호만, 검증 우회 |
| `Docker healthy → 통과` | 인프라 ≠ 기능 |
| `사용자 확인 없이 PR 머지` | 본 SSOT §1 Step 3 위반 |
| `Cycle 자동 진입 시 QA 우회` | mega-cycle 자율 = QA 회피 X |

## 9. 적용 cycle (실 적용 시점)

```
Cycle 9 (2026-05-12) - 본 SSOT 적용 시작
  - Lobby 3000 ERR_CONNECTION_REFUSED 발견 (S9 재 dispatch)
  - 이전 cycle 의 evidence 머지 PR (#357) 도 본 기준 미달 인정
  - 향후 모든 QA 통과는 본 SSOT 준수
```

## Changelog

| 날짜 | 버전 | 변경 | 근거 |
|------|------|------|------|
| 2026-05-12 | v1.0 | 최초 작성 — QA 통과 3 단계 정의 (screenshot + 검증 + 사용자 확인) | 사용자 명시 정의 + Cycle 9 ERR_CONNECTION_REFUSED 사고 후속 |
