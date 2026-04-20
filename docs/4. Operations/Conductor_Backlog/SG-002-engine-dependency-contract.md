---
id: SG-002
title: "Engine 의존 계약 — ENGINE_URL, timeout, graceful 대기, fallback"
type: spec_gap
sub_type: spec_contradiction_and_gap  # Type B + C 복합
status: RESOLVED  # default 채택, decision_owner 재고 여지 보존
owner: conductor
decision_owners_notified: [team3, team4]
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/1. Product/Foundation.md §Ch.7
  - docs/2. Development/2.4 Command Center/Overlay/**
  - docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md
  - team4-cc/CLAUDE.md
  - team3-engine/CLAUDE.md
protocol: Spec_Gap_Triage
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, default 채택 완결"
---
# SG-002 — Engine 의존 계약

## 공백 서술

team4 CC/Overlay 앱은 team3 Game Engine harness(`http://localhost:8080`) 에 의존한다. 그러나 다음 4가지 계약이 문서화되지 않아 **Type B 공백**이었음:

1. **ENGINE_URL 환경변수 표준**: CC 가 engine 주소를 어디서 읽는가? (hardcoded / dart-define / launch_config / OS env)
2. **연결 timeout**: engine 응답이 없을 때 얼마나 기다리는가?
3. **graceful 대기 계약**: engine 미준비 시 UI 상태는? (splash / disabled / mock mode fallback / error modal)
4. **fallback 정책**: engine 계속 실패 시 CC 가 어떻게 동작하는가?

관련 Roadmap FAIL: Foundation Ch.7, team4 Overlay (두 FAIL 이 동일 공백의 두 증상).

## 결정 (default, decision_owner 재고 여지 보존)

### 1. ENGINE_URL 환경변수 표준

**채택**: **`--dart-define=ENGINE_URL=http://host:port` 우선, 미지정 시 `http://localhost:8080` 기본값**

team1 `EBS_BO_HOST` 패턴과 통일. launch_config JSON 은 보조 (WebSocket 으로 수신 가능).

```dart
const kEngineUrl = String.fromEnvironment('ENGINE_URL', defaultValue: 'http://localhost:8080');
```

**Why**: team1 이 이미 `--dart-define=EBS_BO_HOST` 채택. 동일 패턴이 개발자 혼란 최소화. OS env var 는 Flutter Desktop 에서 쉽게 읽기 어려움.

**Alternatives considered**:
- `launch_config` JSON — 보조로만 유지 (BO 에서 전달받는 경우)
- OS environment — Flutter `Platform.environment` 가능하나 dart-define 보다 IDE 통합 약함

### 2. 연결 timeout

**채택**: **초기 연결 5초, 요청 timeout 3초, 재시도 exponential backoff (1s → 2s → 4s, 최대 3회)**

```dart
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 5),
  sendTimeout: Duration(seconds: 3),
  receiveTimeout: Duration(seconds: 3),
));
```

**Why**: RFID 카드 감지 → 오버레이 렌더 파이프라인의 **100ms 실시간성** (Foundation Ch.1.4) 을 고려하면 단일 요청 3초 이내, 그러나 초기 기동 시 Docker compose 지연 고려 5초.

**Alternatives**:
- 단일 값 10초 — 실시간성 훼손
- 무제한 — UX 차단

### 3. graceful 대기 계약

**채택**: **3-stage 상태 머신**

| Stage | 조건 | UI 상태 | 사용자 행동 |
|:---:|------|---------|------------|
| **Connecting** | 앱 시작 ~ 초기 연결 5초 내 | Splash screen + "엔진 연결 중…" + 진행 애니메이션 | 대기 |
| **Degraded** | 초기 연결 실패, 재시도 중 (최대 ~15초) | Command Center UI 활성, 경고 배너 "엔진 응답 없음 — 로컬 Mock 모드로 전환" | **Demo Mode** 자동 진입 |
| **Offline** | 재시도 3회 모두 실패 | Demo Mode 유지, 상단 고정 배너 "ENGINE_URL 확인 필요" + "재연결" 버튼 | 수동 재연결 또는 Demo Mode 지속 |

**Why**: 프로토타입 목적(기획서 검증)상 **engine 없이도 CC 화면이 살아있어야** 데모·교육·스크린샷 가능. 기존 `f539eac feat(team4): Demo & Test Mode` 커밋을 graceful fallback 으로 승격.

**Alternatives**:
- "연결될 때까지 블로킹" — 현재 암묵 구현 추정. 개발 불편
- "에러 다이얼로그 후 종료" — 프로토타입 부적합
- "Mock 모드 자동 진입 (현재 채택)" — RFID HAL Mock 과 동일 패턴, 일관성 ✓

### 4. fallback 정책

**채택**: **Demo Mode (엔진 없이 in-process stub 엔진)**

- `lib/features/command_center/services/stub_engine.dart` 추가 (제안)
- Stub engine 은 basic 게임 진행만 지원 (Pre-flop/Flop/Turn/River 고정 시퀀스, 카드 랜덤)
- Demo Mode 진입 시 실제 OutputEvent 대신 stub 이벤트 방출
- 복귀 시(engine 복구) 자동 전환 — 단, 현재 hand 종료 후에만

**Why**: 사용자 요구(개발팀 인계용 프로토타입)는 **engine 없이도 UI/UX 시연 가능**해야 함. Demo Mode 승격이 합리적.

**Alternatives**:
- "No fallback" — engine 필수 설치. 인계팀 배포 부담 증가
- "Remote mock server" — 별도 인프라 필요, 오버엔지니어링

## 영향 챕터 업데이트 (이 SG 와 함께 커밋)

- [ ] `team4-cc/CLAUDE.md` §"엔진 연동" 에 위 3-stage 상태 머신 + ENGINE_URL 환경변수 반영 (team4 세션 위임)
- [ ] `docs/2. Development/2.4 Command Center/Overlay/` 에 `Engine_Dependency_Contract.md` 신규 (team4 세션 위임 또는 Conductor)
- [x] `docs/1. Product/Foundation.md` Ch.7 frontmatter 재판정 (FAIL→UNKNOWN) + 본 SG 참조 주석
- [x] `docs/4. Operations/Roadmap.md` Ch.7 + team4 Overlay 라인 PASS 전환 (SG-002 resolved)
- [ ] `team4-cc/src/lib/foundation/configs/app_config.dart` 에 ENGINE_URL dart-define 추가 (team4 세션 위임)

## 수락 기준

- [ ] `--dart-define=ENGINE_URL=...` CLI flag 동작
- [ ] engine 미기동 상태 `flutter run -d windows` → 5초 splash → Demo Mode 진입 확인
- [ ] engine 복구 후 다음 hand 시작 시 실제 OutputEvent 수신 전환 확인
- [ ] `Engine_Dependency_Contract.md` 에 3-stage 상태 머신 도식

## 재구현 가능성 재판정

- Foundation Ch.7: FAIL → UNKNOWN → PASS (수락 기준 충족 후)
- team4 Overlay: FAIL → UNKNOWN → PASS (수락 기준 충족 후)
- SG-002 자체: **DONE (default 채택)**, team4 구현으로 확정
