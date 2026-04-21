---
title: Standalone Mode
owner: team4
tier: feature
supersedes: Demo_Test_Mode.md (Standalone 측면만. Demo Scenario 는 2026-04-21 scope 제외)
last-updated: 2026-04-21
---

# Command Center — Standalone Mode

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | Lobby 미경유 독립 실행 모드의 공식 정의. Launch Modes 2-분류 (Linked vs Standalone). Demo Scenario 는 scope 제외 결정 (사용자 2026-04-21). `Demo_Test_Mode.md` supersedes. |

---

## 개요

Command Center 는 두 가지 실행 경로 중 하나로 기동된다:

| Mode | 목적 | 진입 | 프로덕션 사용 |
|------|------|------|:------------:|
| **Linked** | 실방송 운영 | Lobby `[Launch]` 버튼 → args 전달 | ✅ |
| **Standalone** | 개발·QA 검증 | CLI `--standalone[=table_id]` | ❌ |

본 문서는 **Standalone 의 계약**을 정의한다. Linked 는 `../Overview.md §Lobby-Command Center 관계` 가 SSOT.

**목적** (WHY): Phase 1 프로토타입 개발 중 Lobby / Backend / RFID 의존 없이 CC 자체 동작을 검증.

**비목적** (WHAT THIS IS NOT):
- 프로덕션 운영 대체 경로 아님 — 실방송은 Linked 만 허용
- 사전 녹화 시나리오 자동 재생 아님 (Demo Scenario 는 2026-04-21 scope 제외 — `##11 제외 범위` 참조)

---

## §1. Launch Modes 매트릭스

### §1.1 2-Mode Capability 매트릭스

| Capability | Linked (Lobby 경유) | Standalone |
|------------|:--------------------:|:----------:|
| 진입 CLI | `--table_id=N --token=JWT --cc_instance_id=UUID --ws_url=ws://...` | `--standalone[=N]` (N 생략 시 1) |
| Table 컨텍스트 | Lobby 가 선택·전달 | CLI 인자 또는 기본 `table_id=1` |
| 사용자 인증 (JWT) | Lobby 발급 토큰 | **bypass** (local admin 가정) |
| BO REST API | 필수 (Online) | 선택 — 미연결 허용, 미연결 시 in-memory fallback |
| BO WebSocket | 필수 (실시간 publish) | 선택 — 미연결 시 로컬 dispatch |
| Game Engine | real (`http://localhost:8080`) | real or `StubEngine` (`Engine_Dependency_Contract §4`) |
| RFID | real HAL or MockRfidReader (Settings) | **MockRfidReader 강제** |
| Hand DB 영속성 | BO DB 저장 | **in-memory 한정** (앱 종료 시 소실) |
| Overlay 출력 (NDI) | 필요 시 활성 | 비활성 권장 (platform channel 없음 시 에러 방지) |
| 시각적 배지 | 없음 (default UI) | `"STANDALONE"` 주황 배지 (Toolbar 좌측 고정) |
| Overlay 캔버스 테두리 | 없음 | 2px 주황 보더 |

### §1.2 판정 규칙

앱 부트 시 다음 순서로 mode 를 판정한다:

```
1) args 에 --standalone 포함 → Standalone
2) args 에 --table_id + --token + --cc_instance_id + --ws_url 모두 포함 → Linked
3) 그 외 (args 없음 또는 일부 누락)
   → Standalone 로 fallback + WARN 로그
   → UI 에 노란 배너 "Launch args incomplete — running Standalone"
```

**근거**: empty-args 실행은 개발자 `flutter run` default 경로. 현재 코드 (`launch_config.dart:68`) 는 null 반환 후 `EbsCcApp` 진입 — UI 상 불명확 상태. §1.2 판정 규칙으로 확정.

---

## §2. 진입 방법

### §2.1 CLI 인자 (Canonical)

```bash
# Standalone (기본 table_id=1)
flutter run -d windows -- --standalone

# Standalone (table_id 지정)
flutter run -d windows -- --standalone=5

# ENGINE_URL 지정 (Engine_Dependency_Contract.md §1 과 호환)
flutter run -d windows \
  --dart-define=ENGINE_URL=http://localhost:8080 \
  -- --standalone=1
```

### §2.2 하위 호환 — `--demo` alias

과도기적으로 기존 `--demo` flag 는 `--standalone` 의 alias 로 동작한다.

| Flag | 동작 | 상태 |
|------|------|:----:|
| `--standalone[=N]` | canonical | 신규 |
| `--demo` | `--standalone=1` 과 동일 | legacy (Phase 2 에서 제거 예정) |

**근거**: 코드 (`launch_config.dart:53-66`) 가 현재 `--demo` 만 인식. 기획 정합성을 위해 `--standalone` canonical 로 추가하되 `--demo` 도 동일 효과. Code follow-up Backlog: `B-team4-004`.

### §2.3 런타임 토글 금지

- Linked ↔ Standalone **런타임 전환 금지**. 프로세스 재기동 필수.
- 이유: JWT context / WS 연결 life cycle 이 mode 별로 상이. 런타임 전환은 상태 오염 위험.
- 기존 `Demo_Test_Mode.md §8 런타임 토글 규칙` 은 Demo Scenario 의 내부 전환이었으므로 본 정책과 무관. Scope 제외로 함께 폐기.

---

## §3. Subsystem 연결 상태 머신

Standalone 에서 각 외부 의존성의 연결 상태는 **독립적으로 결정**된다.

| Subsystem | 연결 시 동작 | 미연결 시 동작 | 전환 감지 |
|-----------|--------------|--------------|-----------|
| **BO REST** | 정상 CRUD | 404 응답을 local store 로 리다이렉트 | 5s probe `/health` |
| **BO WebSocket** | 이벤트 publish/subscribe | 로컬 dispatch only | connect 시도 → 5s timeout |
| **Game Engine** | `Engine_Dependency_Contract §3` 3-stage | StubEngine | 동 §3 그대로 |
| **RFID** | N/A (Standalone 은 Mock 강제) | MockRfidReader | 해당 없음 |

> **핵심**: Engine 상태머신은 기존 SG-002 resolution 그대로 재사용. Standalone 은 그 외 Subsystem 에 동일 "연결 실패 → local fallback" 원칙을 확장.

### §3.1 Subsystem 상태 배너

Standalone 배지 (§4.1) 옆에 각 subsystem 연결 상태 인디케이터를 표시한다:

```
[STANDALONE] [BO ●] [WS ●] [Engine ●] [RFID Mock]
```

- `●` 녹색 = Online · `◐` 주황 = Degraded · `○` 빨강 = Offline · `Mock` = 의도적 Mock
- 각 인디케이터 클릭 시 해당 subsystem 진단 모달 open (추가 Backlog)

---

## §4. 시각적 구분

프로덕션(Linked) UI 와 혼동 방지:

| 요소 | 사양 |
|------|------|
| Toolbar 배경 | `#E65100` (주황) — `EbsColors.standaloneAccent` 상수 신설 |
| `STANDALONE` 배지 | Toolbar 좌측 고정, `FontWeight.w900`, 흰색. Subsystem 인디케이터 우측 배치 |
| 전체 화면 보더 | 2px 주황색 보더 |
| Overlay 캔버스 | 동일 2px 보더 (NDI 출력 비활성 전제) |

### §4.1 배지 반드시 표시 조건

- 앱 시작 시 즉시 노출 (SplashScreen 이후 첫 frame 부터)
- 사용자가 숨기거나 토글할 수 없음 (의도 혼동 방지)
- Linked 모드에서는 해당 위젯 자체가 tree 에 없음 (conditional)

---

## §5. 기능 on/off 명시

Standalone 에서 다음 기능은 **의도적으로 비활성**된다:

| 기능 | Standalone 상태 | 이유 |
|------|:--------------:|------|
| NDI 송출 | OFF | platform channel 의존 — 에러 방지 |
| 실 RFID 리더 | OFF | 하드웨어 의존 |
| JWT refresh token | OFF | 로컬 admin 가정 |
| Audit log 서버 전송 | OFF | BO 의존 |
| Hand History 영속 조회 | **in-memory 현 세션만** | BO 없을 수 있음 |
| 멀티테이블 | OFF (단일 table_id) | Lobby 관제 부재 |
| Operator 세션 broadcast | OFF | Lobby 모니터링 대상 없음 |

다음 기능은 **정상 동작**:

- 핸드 FSM (HandFsmNotifier)
- 카드 입력 (MockRfidReader + 수동 AT-03 Card Selector)
- Action Buttons (FOLD/CHECK/CALL/BET/RAISE/ALL-IN)
- Pot/Side pot 계산
- Seat 관리
- Showdown / HandComplete
- Overlay Rive 애니메이션 (로컬 재생)

---

## §6. 구현 파일 매핑 (team4 코드 follow-up)

기획 정합성을 위해 다음 코드 변경이 필요하다. 세부 구현은 `Backlog/B-team4-004` 참조.

| 항목 | 현재 | 목표 |
|------|------|------|
| Feature flag | `Features.enableDemoMode` | `Features.enableStandalone` (primary) + `enableDemoMode` deprecated alias |
| CLI flag 파싱 | `--demo` only | `--standalone[=N]` canonical + `--demo` alias |
| UI 배지 문자열 | `"DEMO"` | `"STANDALONE"` |
| 배지 색상 상수 | inline `#E65100` | `EbsColors.standaloneAccent` |
| `demo_control_panel.dart` | 존재 (Demo Scenario UI) | **제거 또는 isolate** (Demo Scenario scope 제외 — §11) |
| `lib/features/command_center/demo/` | scenarios, scenario_runner, local_dispatcher | **`lib/features/command_center/standalone/`** 로 rename (Demo Scenario 자산 삭제 후 standalone-only 로 정리) |

---

## §7. 테스트 계획

| 테스트 | 검증 내용 |
|--------|----------|
| `test/standalone/launch_config_test.dart` | `--standalone`, `--standalone=5`, `--demo` alias, empty args fallback |
| `test/standalone/mode_badge_test.dart` | Standalone 에서 배지 표시, Linked 에서 미표시 |
| `test/standalone/subsystem_indicator_test.dart` | BO/WS/Engine 각 상태에 따른 배너 아이콘 색 |
| `test/standalone/feature_gating_test.dart` | NDI / real RFID / JWT refresh 비활성 확인 |
| 기존 테스트 | Linked 기본 경로에 영향 없음 |

---

## §8. 판정 예시 (Launch Flow 시나리오)

### 예시 1 — 개발자 dev 실행

```bash
flutter run -d windows -- --standalone
```
→ Standalone, table_id=1, BO/WS/Engine probe, 모두 실패 시 all-local.

### 예시 2 — QA 로컬 Backend + Standalone

```bash
flutter run -d windows --dart-define=ENGINE_URL=http://localhost:8080 -- --standalone=3
```
→ Standalone, table_id=3, BO/WS/Engine 정상 연결, RFID Mock 만 강제.

### 예시 3 — Lobby Launch (운영자 실방송)

```bash
# Lobby 가 spawn
flutter run -d windows -- --table_id=7 --token=eyJ... --cc_instance_id=a1b2c3 --ws_url=ws://ebs-bo:8000/ws/cc
```
→ Linked, 모든 subsystem 필수, 배지 없음.

### 예시 4 — empty args (실수)

```bash
flutter run -d windows
```
→ Standalone fallback (§1.2 rule 3), WARN 로그, 노란 배너 안내.

---

## §9. Linked ↔ Standalone 관계 (외부 문서 교차 참조)

| 문서 | 해당 섹션 | Standalone 관점 |
|------|-----------|----------------|
| `../Overview.md §Lobby-Command Center 관계` | 1:N 관계, Launch 흐름 | Standalone 은 이 흐름의 **bypass** — 개발 시나리오만 |
| `../../2.1 Frontend/Lobby/Overview.md §Lobby-Command Center 관계` | Lobby 측 설명 | Linked 의 SSOT |
| `../Overlay/Engine_Dependency_Contract.md §4` | Engine fallback = 구 "Demo Mode" 용어 | **용어 수정 필요** — "StubEngine Fallback" 으로 환원 (본 문서와 disambiguation) |
| `../Settings.md §RFID Mode scope=table` | real/mock 전환 | Standalone 은 Mock 강제이므로 Settings UI 잠금 |
| `Demo_Test_Mode.md` | supersedes — Standalone 부분 본 문서 | Demo Scenario §3 는 본 문서 §11 로 scope 제외 처리 |

---

## §10. 프로덕션 안전장치

Standalone 이 실방송에 잘못 사용되는 것을 방지:

| 방어 | 구현 |
|------|------|
| 시각 배지 | `STANDALONE` + 2px 주황 보더 (§4) |
| 로그 prefix | 모든 로그에 `[STANDALONE]` prefix |
| BO `table_session.mode = "standalone"` 기록 | BO 에 전송되는 세션 메타에 `mode` 필드 추가 (선택적 BO 개선) |
| 빌드 모드 차이 | `--release` 빌드에서 `--standalone` 호출 시 경고 다이얼로그 1회 (Phase 2) |

---

## §11. 제외 범위

본 Mode 에서 **다음은 scope 아님**:

| 항목 | 사유 | 결정일 |
|------|------|--------|
| **Demo Scenario 자동 재생** (구 `Demo_Test_Mode.md §3 시나리오 시스템`) | 사용자 요구사항 명시적 제외 | 2026-04-21 |
| Demo 시나리오 편집 UI | 동상 | 2026-04-21 |
| 시나리오 파일 import/export | 동상 | 2026-04-21 |
| 수동 이벤트 주입 UI (`§4 Demo 제어 패널`) | 동상 — 일반 CC UI 로 충분 | 2026-04-21 |
| 멀티테이블 Standalone | 단일 table_id 한정 | 2026-04-21 |
| Overlay Rive 자체 Standalone | Standalone CC 에 통합된 Overlay 만 | 2026-04-21 |
| 프로덕션 운영용 사용 | Linked 전용 | 2026-04-21 |

---

## 참조

- 구 문서: `Demo_Test_Mode.md` (DEPRECATED banner 추가됨, 일부 내용 본 문서로 이관)
- Lobby-CC 관계: `../Overview.md §Lobby-Command Center 관계`, `../../2.1 Frontend/Lobby/Overview.md`
- Engine 의존성: `../Overlay/Engine_Dependency_Contract.md`
- RFID Mock 계약: `../APIs/RFID_HAL.md`, `../APIs/RFID_HAL_Interface.md`
- Launch config 코드: `team4-cc/src/lib/models/launch_config.dart`
- Follow-up: `Backlog/B-team4-004-standalone-mode-code-alignment.md`
