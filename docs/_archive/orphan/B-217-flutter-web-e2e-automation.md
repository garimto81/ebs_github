---
id: B-217
title: "B-217 — Flutter Web E2E 자동화 (integration_test 기반)"
owner: team1
tier: internal
status: PENDING
type: backlog
severity: LOW
blocker: false
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
related:
  - B-211
last-updated: 2026-05-10
---

## 개요

E2E 검증 v1.1에서 발견: Playwright headless로 Flutter Web의 form 자동화는 한계. Flutter framework이 native HTMLInputElement를 IME proxy로만 사용하고 자체 TextEditingController가 framework state 관리하므로 DOM 표준 자동화 도구가 form value를 set해도 화면 미반영.

## 증상 (E2E 보고서 §5.1 분석)

- `getByRole('textbox', {name: 'X'}).fill(...)` → 두 번째 fill이 첫 textbox에 합쳐짐
- `keyboard.type(...)` after Tab → focus 이동은 되나 라우팅이 단일 IME proxy input으로 모임
- `HTMLInputElement.value = X` + `dispatchEvent(InputEvent)` → native value set되나 framework 미반영
- `dispatchEvent(PointerEvent)` 좌표 click → glasspane 미인식

## 대응 옵션

| Option | 비용 | 권장 |
|--------|------|------|
| A. integration_test (Flutter Driver) | 중간 | ✅ **권장** — in-app, Dart로 작성, framework 직접 제어 |
| B. flutter_test widget test | 낮음 | 컴포넌트 단위 검증 (e2e 아님) |
| C. 사용자 직접 헤드드 브라우저 | 0 | 임시, 회귀 검출 불가 |
| D. Playwright + canvaskit-html | 높음 | Flutter 3.27+에서 폐기됨, 비추천 |

## 작업 범위 (Option A 기준)

1. `team1-frontend/integration_test/` 신규
   - `login_flow_test.dart`: admin@ebs.local 로그인 → 시리즈 화면 진입
   - `series_drilldown_test.dart`: Series → Event → Flight → Table 1단계
   - (선택) `settings_5tab_test.dart`: 5탭 진입 검증
2. `team4-cc/integration_test/` 신규
   - `cc_connect_test.dart`: BO connect → operator 화면
3. CI 통합:
   ```yaml
   - name: Flutter integration test
     run: flutter drive --target=integration_test/login_flow_test.dart -d web-server
   ```

## 완료 기준

- [ ] `flutter drive` 명령으로 login → 시리즈 화면 진입 검증 GREEN
- [ ] team4 CC connect 시나리오 GREEN
- [ ] `.github/workflows/`에 통합 (선택)
- [ ] B-211 풀 핸드 e2e 시나리오와 정합 — integration_test에서 RFID Mock + Engine harness 호출 가능 확인

## 참조

- E2E 보고서: §5.1 Flutter Web 자동화 한계
- B-211 (End-to-End 풀 핸드 플로우 — Flutter Web 부분 의존)
- Flutter docs: https://docs.flutter.dev/cookbook/testing/integration/introduction
