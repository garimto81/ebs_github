# PokerGFX 7개 마일스톤 구현 PDCA 완료 보고서

> **날짜**: 2026-03-03
> **모드**: HEAVY (복잡도 5/5)
> **Architect 판정**: APPROVE (~91-92%)

---

## 1. 요약

PokerGFX Server (.NET WinForms) 역설계 기반 Flutter Desktop 재구현 프로젝트의 7개 핵심 마일스톤을 완료했다.

| 항목 | 수치 |
|------|:----:|
| 구현 파일 | 64개 |
| 테스트 파일 | 38개 |
| 테스트 케이스 | 277+ |
| Plan 대비 Match Rate | ~91% |
| 역설계 참조 C# 파일 | 2,402개 |

---

## 2. 마일스톤별 결과

### M2: 핸드 평가 알고리즘 (Match Rate: 95%)

**포팅 원본**: `hand_eval/Hand.cs` (8,098줄)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `lookup_tables.dart` | 신규 | nBitsTable, straightTable, topFiveCardsTable, topCardTable (8192 엔트리) |
| `bitmask_evaluator.dart` | 재작성 | C# Hand.Evaluate → Dart 완전 포팅, 64비트 bitmask, `>>>` unsigned shift |
| `omaha_evaluator.dart` | 신규 | Omaha 4/5/6 pocket, Hi/Lo split |
| `short_deck_evaluator.dart` | 신규 | 6+ Hold'em, trips>straight 변형 |
| `stud_evaluator.dart` | 신규 | 7-Card Stud Hi + Razz (Ace-to-Five lowball) |
| `badugi_evaluator.dart` | 신규 | Badugi 4-card unique suit+rank lowball |
| `draw_evaluator.dart` | 신규 | 5-Card Draw, 2-7 Lowball, A-5 Triple |
| `game_evaluator_router.dart` | 신규 | 17+ 게임 변형 라우팅 (core.cs 포팅) |
| `monte_carlo.dart` | 신규 | Hold'em MC=100K, Omaha MC=10K |

### M1: RFID HID 연결 (Match Rate: 90%)

**포팅 원본**: `RFIDv2/` (26파일)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `hidapi_loader.dart` | 신규 | Windows/Linux/macOS DynamicLibrary 로드 |
| `hidapi_bindings.dart` | 재작성 | 10개 FFI 함수 바인딩, VID=0xAFEF, PID=0x0F02 |
| `rfid_command.dart` | 신규 | `\n{CMD}\r` 프레이밍, BASE32 안테나 시퀀스 |
| `antenna_poller.dart` | 신규 | 66ms 간격 폴링, TagChanges 스트림 |
| `hidapi_rfid_service.dart` | 재작성 | Isolate 기반 HID 폴링 (UI 비블로킹) |
| `tcp_rfid_service.dart` | 재작성 | TCP/WiFi + SecureSocket TLS |
| `card_parser.dart` | 신규 | Tag ID → Card(Suit, Rank) 매핑 |

**테스트**: 7파일, 50개 케이스 ALL PASS

### M3: 네트워크 프로토콜 (Match Rate: 92%)

**포팅 원본**: `net_conn/` (168파일)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `protocol_constants.dart` | 신규 | 포트(9000/9001), 암호화 키, 타이머 |
| `pbkdf1.dart` | 신규 | .NET PasswordDeriveBytes 호환, SHA1 100회 |
| `aes_util.dart` | 재작성 | AES-256-CBC, 고정 IV, PKCS7 패딩 |
| `message_encoder.dart` | 신규 | JSON → AES 암호화 → SOH 프레이밍 |
| `message_decoder.dart` | 신규 | TCP 스트림 SOH 파싱 → AES 복호화 |
| `udp_discovery_impl.dart` | 신규 | UDP 브로드캐스트 서버 탐색 (포트 9000) |
| `tcp_connection_impl.dart` | 신규 | TCP 영구 연결, keepalive 3초, 재연결 |
| `command_type.dart` | 확장 | 29개 → 131개 명령어 wire value 매핑 |
| `protocol_models.dart` | 신규 | 30개 Request/Response DTO |
| `remote_registry_impl.dart` | 신규 | 명령어→타입 매핑 레지스트리 |

**테스트**: 10파일, 104개 케이스 ALL PASS

### M6: 게임 상태 머신 (Match Rate: 93%)

**포팅 원본**: `vpt_server/GameTypes/GameType.cs` (271 메서드)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `game_variant_info.dart` | 신규 | 22개 게임 변형 메타데이터 |
| `game_state_machine.dart` | 재작성 | Phase 시퀀스 기반 전이, advance/skipToShowdown |
| `betting_engine.dart` | 신규 | NL/PL/FL 3모드, minRaise, raiseCap |
| `pot_calculator.dart` | 신규 | 메인팟 + N개 사이드팟, all-in 처리 |
| `action_processor.dart` | 신규 | fold/check/call/bet/raise/allIn 검증+처리 |
| `showdown_resolver.dart` | 신규 | Hi/Lo split, M2 연동, 다중 팟 승자 결정 |
| `game_play_service_impl.dart` | 신규 | 4개 엔진 통합 오케스트레이션 |
| `game_cards_service_impl.dart` | 신규 | 덱 생성/셔플/딜/보드 |
| `game_players_service_impl.dart` | 신규 | 좌석 관리, Freezed copyWith |
| `game_database.dart` | 수정 | 8개 Drift SQL 쿼리 구현 |

**테스트**: 10파일, 123개 케이스 ALL PASS

### M4: Rive 렌더링 (Match Rate: 88%)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `rive_artboard_loader.dart` | 신규 | .riv 파일 로딩, StateMachineController 연결 |
| `rive_state_controller.dart` | 재작성 | SMIBool/SMINumber/SMITrigger 동적 설정 |
| `game_state_mapper.dart` | 신규 | GameState → Rive input 변환 (10석, 5보드) |
| `frame_capturer.dart` | 신규 | Artboard → RGBA → BGRA 변환 (1920x1080) |
| `rive_renderer_impl.dart` | 재작성 | 렌더러 파이프라인 통합 |
| `skin_loader.dart` | 재작성 | 3종 스킨 레지스트리 + 외부 등록 API |
| `game_canvas.dart` | 신규 | RiveAnimation Flutter 위젯 |

**테스트**: 3파일 (game_state_mapper, frame_capturer, skin_loader)

### M5: NDI SDK FFI (Match Rate: 90%)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `ndi_loader.dart` | 신규 | Windows/macOS/Linux NDI SDK 경로 탐색 |
| `ndi_bindings.dart` | 재작성 | 5개 NDI API + 구조체 (NdiVideoFrameV2) |
| `frame_converter.dart` | 신규 | FrameBuffer → native 메모리, NTSC fps 변환 |
| `ndi_service_impl.dart` | 재작성 | initialize/sendFrame/dispose 파이프라인 |
| `broadcast_providers.dart` | 수정 | SDK 유무 자동 감지 → 시뮬레이션 fallback |

**테스트**: 4파일 (frame_converter, ndi_bindings, ndi_loader, ndi_service_impl)

### M7: 설정 UI 에디터 (Match Rate: 91%)

| 파일 | 유형 | 핵심 내용 |
|------|------|----------|
| `config_loader.dart` | 수정 | saveToFile + loadFromAsset + createDefault |
| `config_watcher.dart` | 재작성 | FileSystemEntity.watch, 300ms debounce |
| `config_service_impl.dart` | 신규 | ConfigLoader + ConfigWatcher 통합 |
| `preset_repository_impl.dart` | 수정 | JSON 파일 저장, 손상 파일 건너뛰기 |
| `settings_screen.dart` | 신규 | 6탭 TabBarView (RFID/Network/Render/Game/Broadcast/Presets) |
| `config_editor.dart` | 신규 | 타입별 자동 위젯 (bool→Switch, int/double/String→TextField) |
| `preset_manager.dart` | 신규 | 프리셋 CRUD, GameType 드롭다운 |
| `config_providers.dart` | 수정 | Riverpod 6개 Provider 연결 |

**테스트**: 4파일 (config_loader, config_watcher, preset_repository, config_service_impl)

---

## 3. Architect 보류 사항 (경미, APPROVE 유지)

| # | 마일스톤 | 이슈 | 영향도 | 상태 |
|:-:|---------|------|:------:|:----:|
| 1 | M2 | Badugi `_aceLowMask` Ace 외 rank shift 원본 교차 검증 필요 | 낮음 | 미해결 |
| 2 | M2 | ShortDeck trips/straight 이중 스왑 잠재적 경로 | 낮음 | 미해결 |
| 3 | M7 | SettingsScreen onChanged 빈 콜백 (섹션→전체 config 반영 미완) | 중간 | **해결** |
| 4 | M4 | layer_compositor 별도 파일 미존재 (Rive Artboard 내장) | 낮음 | 미해결 |
| 5 | M5 | broadcast_pipeline 별도 파일 미존재 (ndi_service_impl 통합) | 낮음 | **해결** |
| 6 | M1 | `hidapi_rfid_service.dart:241` Future.delayed await 누락 | 낮음 | **해결** |
| 7 | M4 | `.riv` 에셋 미존재 — Rive Editor에서 별도 제작 필요 | 높음 | 미해결 |
| 8 | M4 | `rive_artboard_loader.dart` stateMachineNames API 불일치 (Rive 0.13.x) | 낮음 | **해결** |

---

## 4. 기술 결정 사항

| 결정 | 이유 |
|------|------|
| `>>>` unsigned right shift 사용 | C# `ulong` → Dart `int` signed 차이 보정 |
| PBKDF1 .NET 비표준 확장 구현 | `PasswordDeriveBytes` 20바이트 초과 시 자체 알고리즘 |
| AES IV/Key 하드코딩 유지 | 원본 시스템 호환성 (보안 취약점이나 필수) |
| SOH(0x01) 메시지 구분자 | 원본 `net_conn.dll` 프로토콜 호환 |
| GameVariantInfo.phases 통합 | StudStateMachine 별도 분리 대신 메타데이터 기반 |
| NDI SDK graceful fallback | SDK 미설치 환경에서 시뮬레이션 자동 전환 |

---

## 5. 팀 구성

| 역할 | 에이전트 | 담당 | 모델 |
|------|---------|------|------|
| planner | planner | 956줄 통합 계획서 작성 | opus |
| m2-executor | executor | M2 핸드 평가 (12파일) | opus |
| m1-executor | executor | M1 RFID HID (8파일, 7테스트) | opus |
| m3-executor | executor | M3 네트워크 (10파일, 10테스트) | opus |
| m6-executor | executor | M6 게임 엔진 (13파일, 10테스트) | opus |
| m4m5m7-executor | executor | M4+M5+M7 (21파일, 11테스트) | opus |
| architect | architect | APPROVE 판정 (~92%) | opus |
| architect-verify | architect | APPROVE 재검증 (~91%) | opus |

실행 전략: 3-Wave 병렬 (M2+M1 → M3+M6 → M4+M5+M7)

---

## 6. 추가 구현 이력 (후속 PDCA)

| 날짜 | 커밋 | 내용 |
|------|------|------|
| 2026-03-03 | d9d76b4 | Architect 보류 #3 #6 수정 — SettingsScreen onChanged + hidapi sleep() |
| 2026-03-03 | 2bffae6 | Architect 보류 #5 #8 해결 — BroadcastPipeline 분리 + Rive API 수정 |

## 7. 후속 작업

1. **`.riv` 에셋 제작** — Rive Editor에서 포커 테이블/카드 애니메이션 제작 (M4 통합 테스트 필수)
2. **Badugi/ShortDeck 교차 검증** — C# 원본 소스와 엣지 케이스 비교
3. **NDI 더블 버퍼링** — 고부하 시 프레임 드롭 방지
4. **통합 테스트** — M2↔M6 ShowdownResolver, M4↔M5 렌더→NDI 파이프라인
5. **NDI SDK 라이선스** — 상업 배포 시 별도 라이선스 확인
