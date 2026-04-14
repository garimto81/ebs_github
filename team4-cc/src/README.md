# Team 4 CC — Flutter Project (`ebs_cc`)

**Role**: EBS Command Center + Overlay (Skin Consumer)

> Graphic Editor는 team1 Lobby 소유 (CCR-011). 본 프로젝트는 Skin Consumer로서
> `skin_updated` WebSocket 이벤트를 수신하여 Overlay를 리렌더한다.

## 초기화

프로젝트는 `pubspec.yaml`과 `lib/` 디렉토리가 수동 작성되어 있으므로
`flutter create` 없이 바로 `flutter pub get`으로 시작할 수 있다.

```bash
cd team4-cc/src

# 의존성 설치
flutter pub get

# 플랫폼별 스캐폴딩 필요 시 (windows/macos/linux 폴더 생성)
flutter create --org com.ebs --project-name ebs_cc --platforms windows,macos,linux .

# 코드 생성 (Freezed, Retrofit, Riverpod)
dart run build_runner build --delete-conflicting-outputs
```

## 개발 실행

```bash
flutter run -d windows   # Windows 데스크톱
flutter run -d macos     # macOS
flutter run -d linux     # Linux
```

## 테스트

```bash
flutter test             # Unit + Widget
```

## 코드 생성 watch 모드

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 디렉토리 구조

```
lib/
├── main.dart                  # entry point
├── app.dart                   # root widget, Sentry 초기화, ProviderScope
│
├── data/                      # API / Local 접근 레이어
│   ├── remote/                # BO API + WebSocket (CCR-019, CCR-021)
│   └── local/                 # Event buffer, local storage
│
├── repositories/              # 도메인 데이터 소스
│
├── features/                  # 기능별 모듈 (Feature-based)
│   ├── command_center/        # BS-05 CC (AT-00~07)
│   ├── overlay/               # BS-07 Overlay (layer1/ + services/)
│   │   └── layer1/            # ← Phase 1 범위 (CCR-035 Layer 경계)
│   └── stats/                 # BS-05-07 AT-04 Statistics (CCR-027)
│
├── rfid/                      # BS-04 RFID HAL (API-03, CCR-022)
│   ├── abstract/              # IRfidReader 인터페이스
│   ├── real/                  # ST25R3911B (Phase 2)
│   ├── mock/                  # MockRfidReader (Phase 1 주력)
│   └── providers/             # Riverpod DI
│
├── models/                    # Freezed DTO/엔티티
│   ├── enums/
│   └── entities/
│
├── foundation/                # 인프라
│   ├── theme/                 # SeatColors SSOT (BS-05-03/BS-07-01)
│   ├── audio/                 # AudioPlayerProvider (BS-07-05)
│   ├── error_reporting/       # Sentry
│   ├── configs/               # Feature flags
│   └── utils/                 # SeqTracker, UuidIdempotency
│
└── resources/                 # 정적 자산, 상수
```

상세 구조 및 CCR 매핑은 `../CLAUDE.md` 및 WSOP Fatima.app 프로덕션 패턴 참고.

## CCR 수용 현황

| CCR | 구현 위치 |
|-----|---------|
| CCR-012 .gfskin ZIP | `lib/repositories/skin_repository.dart` |
| CCR-015 skin_updated WS | `lib/features/overlay/services/skin_consumer.dart` |
| CCR-019 Idempotency-Key | `lib/data/remote/bo_api_client.dart` (Dio 인터셉터) |
| CCR-021 seq/replay | `lib/foundation/utils/seq_tracker.dart` + WS 클라이언트 |
| CCR-022 RFID 생명주기 | `lib/rfid/**` |
| CCR-032/034 SeatColors | `lib/foundation/theme/seat_colors.dart` (SSOT) |
| CCR-033 Audio | `lib/foundation/audio/audio_player_provider.dart` |
| CCR-036 Security Delay | `lib/features/overlay/services/output_event_buffer.dart` |
