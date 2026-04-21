---
id: B-team4-004
title: Standalone Mode 기획 정렬 — code follow-up
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# [B-team4-004] Standalone Mode 기획 정렬 — code follow-up

- **등록일**: 2026-04-21
- **관련 기획**: `docs/2. Development/2.4 Command Center/Command_Center_UI/Standalone_Mode.md`
- **선행 결정**: 사용자 2026-04-21 — "CC 는 개발 중 검증을 위해 독립적으로도 실행할 수 있어야 하고, Lobby 와 연동되어 실행이 되어야 해. Demo Scenario 는 필요 없고, Standalone mode 만 추가."

## 배경

기획 문서 `Standalone_Mode.md` 가 Launch Modes 를 Linked / Standalone 2-분류로 확정. Demo Scenario 자동 재생은 scope 제외. 이 결정을 코드에 반영하는 follow-up 작업.

## 목표 (code-side)

| 항목 | 현재 | 목표 | 파일 |
|------|------|------|------|
| CLI flag 파싱 | `--demo` only | `--standalone[=N]` canonical + `--demo` alias | `team4-cc/src/lib/models/launch_config.dart` |
| Feature flag | `Features.enableDemoMode` | `Features.enableStandalone` primary + `enableDemoMode` deprecated alias | `team4-cc/src/lib/foundation/configs/features.dart` |
| 배지 문자열 | `"DEMO"` | `"STANDALONE"` | `team4-cc/src/lib/features/command_center/widgets/demo_control_panel.dart` (or rename) |
| 배지 색상 상수 | inline `#E65100` | `EbsColors.standaloneAccent` | theme 파일 |
| Empty args fallback | null 반환 → 불명확 | Standalone fallback + WARN 로그 + 노란 배너 | `main.dart`, `launch_config.dart`, `app.dart` |
| Demo Scenario UI | `demo_control_panel.dart` + `demo/scenarios.dart` + `demo/scenario_runner.dart` 존재 | **제거** (scope 제외 결정) | `team4-cc/src/lib/features/command_center/demo/*` · `.../widgets/demo_control_panel.dart` |
| 디렉토리 rename | `lib/features/command_center/demo/` | `lib/features/command_center/standalone/` (Demo Scenario 자산 삭제 후 standalone-only 요소만 유지) | 동상 |
| Subsystem 인디케이터 | 없음 | BO/WS/Engine/RFID 상태 배너 (§3.1) | 신규 위젯 |

## Scope 제외 (기획 §11 준수)

아래는 **제거 대상**이다 (Demo Scenario 자산):

- `lib/features/command_center/demo/scenarios.dart` (Quick Hand, All-in Preflop, Full Street, Miss Deal, RFID Fallback, Multi-action)
- `lib/features/command_center/demo/scenario_runner.dart`
- `DemoScenario`, `DemoEvent` 클래스
- Demo 제어 패널 §2 시나리오 선택 UI
- Demo 제어 패널 §4 수동 이벤트 주입 UI (일반 CC UI 로 충분)

제거 전 `git log -- <path>` 로 마지막 변경 확인 + 삭제 커밋 단독 분리.

## 테스트

| 테스트 | 내용 |
|--------|------|
| `test/standalone/launch_config_test.dart` (rename from `test/launch_config_test.dart`) | `--standalone`, `--standalone=5`, `--demo` alias, empty args fallback |
| `test/standalone/mode_badge_test.dart` | Standalone 배지 표시, Linked 미표시 |
| `test/standalone/feature_gating_test.dart` | NDI/실 RFID/JWT refresh 비활성 |
| 기존 Linked 테스트 | 영향 없음 |

## Phase 분리 권고

| Phase | 범위 | Risk |
|:-----:|------|:----:|
| 1 | `--standalone` flag 추가 (alias) + 배지 문자열 + 배너 | Low |
| 2 | Feature flag rename + widget rename | Mid (ripple) |
| 3 | Demo Scenario 자산 삭제 | Low (이미 사용 안 함 가정) |
| 4 | Subsystem 인디케이터 UI | Mid |

각 Phase 별도 commit 권장. Phase 3 (삭제) 는 사용자 명시 승인 후에만 진행 (git log 에 남아있으므로 복구 가능하지만 명시 결정으로 처리).

## 수락 기준

- [ ] `flutter run -- --standalone` → 배지 `STANDALONE` 표시
- [ ] `flutter run -- --demo` → 동일 효과 (alias)
- [ ] `flutter run` (empty) → Standalone fallback + 노란 배너
- [ ] Linked 경로 (`--table_id --token --cc_instance_id --ws_url`) 영향 없음
- [ ] `Features.enableStandalone` 확인 가능, `enableDemoMode` 는 `@Deprecated('use enableStandalone')` 주석
- [ ] Demo Scenario 관련 파일 5종 삭제 + 관련 import 모두 정리
- [ ] `dart analyze team4-cc/src` 0 errors
- [ ] 모든 관련 테스트 green

## 참조

- 기획 SSOT: `docs/2. Development/2.4 Command Center/Command_Center_UI/Standalone_Mode.md`
- DEPRECATED 원문: `docs/2. Development/2.4 Command Center/Command_Center_UI/Demo_Test_Mode.md`
- Engine 계약: `docs/2. Development/2.4 Command Center/Overlay/Engine_Dependency_Contract.md`
- CC Overview §2.0: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md`
