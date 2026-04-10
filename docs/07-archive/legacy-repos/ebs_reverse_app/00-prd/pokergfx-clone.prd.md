# PokerGFX Clone PRD

## 개요

- **목적**: PokerGFX Server 역설계 결과를 기반으로 동일 기능의 커스터마이징 가능한 포커 방송 그래픽 시스템 구축
- **배경**: 기존 PokerGFX-Server.exe (355MB, .NET WinForms)를 Flutter + Rive + NDI 스택으로 완전 재구현
- **범위**: 8개 핵심 모듈 전체 스켈레톤 + 커스터마이징 시스템

## 기술 스택

| 영역 | 기술 | 이유 |
|------|------|------|
| **Framework** | Flutter (Windows Desktop) | 크로스플랫폼, 커스터마이징 용이 |
| **Animation** | Rive | 실시간 벡터 애니메이션, State Machine |
| **방송 출력** | NDI SDK (FFI) | 업계 표준, OBS/vMix/ATEM 연동 |
| **RFID** | hidapi (dart:ffi) | USB HID 디바이스 직접 접근 |
| **상태 관리** | Riverpod | 타입 안전, 모듈화 |
| **DB** | Drift (SQLite) | 오프라인 게임 데이터 저장 |
| **네트워크** | dart:io (TCP/UDP) | 서버-클라이언트 통신 |

## 요구사항

### 기능 요구사항

#### M1: RFID 모듈 (RFIDv2 클론)
1. USB HID 디바이스 자동 감지 (VID: 0xAFEF, PID: 0x0F01/0x0F02)
2. 듀얼 트랜스포트: USB HID + TCP/WiFi
3. TLS 1.2 핸드셰이크 (BearSSL 호환)
4. 16개 안테나 폴링 (~15Hz)
5. Card ID → 카드 매핑 (52장 + 조커)
6. **커스터마이징**: VID/PID 변경, 안테나 수, 폴링 주기, 카드 매핑 테이블

#### M2: 핸드 평가 모듈 (hand_eval 클론)
1. Bitmask 기반 7-card 핸드 평가 (ulong 64-bit)
2. 22개 포커 게임 변형 지원 (holdem=0 ~ razz=21)
3. Straight/Flush/Full House 등 핸드 랭킹
4. Monte Carlo 승률 계산
5. **커스터마이징**: 게임 규칙 편집, 커스텀 핸드 랭킹, 와일드카드 설정

#### M3: 네트워크 프로토콜 모듈 (net_conn 클론)
1. UDP Discovery (포트 9000)
2. TCP 영구 연결 (포트 9001)
3. AES-256-CBC 암호화 (PBKDF1 키 파생)
4. 113+ 프로토콜 명령어 (Request/Response 쌍)
5. **커스터마이징**: 포트 변경, 암호화 키, 명령어 추가/수정

#### M4: 렌더링 엔진 모듈 (mmr 클론)
1. Rive State Machine 기반 카드/테이블 렌더링
2. 플레이어 정보 오버레이 (이름, 칩, 핸드)
3. 핸드 히스토리 애니메이션
4. 스킨 시스템 (테마 전환)
5. **커스터마이징**: Rive 에셋 교체, 레이아웃 편집, 색상/폰트, 애니메이션 타이밍

#### M5: 방송 출력 모듈 (NDI)
1. NDI SDK 통합 (dart:ffi → native)
2. 1080p/4K @ 59.94fps 프레임 출력
3. 알파 채널 투명 오버레이
4. **커스터마이징**: 해상도, 프레임레이트, NDI 소스 이름

#### M6: 게임 로직 모듈 (vpt_server 핵심)
1. 22개 포커 게임 변형 상태 머신
2. 플레이어 관리 (최대 10명)
3. 라운드/핸드 진행 로직
4. 팟/사이드팟 계산
5. **커스터마이징**: 게임 규칙 편집기, 블라인드 구조, 타이머 설정

#### M7: 설정/구성 모듈 (ConfigurationPreset 클론)
1. JSON 기반 설정 파일
2. 게임 프리셋 저장/로드
3. 실시간 설정 변경 (핫리로드)
4. 설정 내보내기/가져오기
5. **커스터마이징**: 모든 설정 항목 UI 노출, 프리셋 관리

#### M8: 공통 라이브러리 (PokerGFX.Common 클론)
1. 의존성 주입 컨테이너
2. 암호화 유틸리티 (AES-256)
3. 로깅 시스템
4. 이벤트 버스 (모듈 간 통신)
5. **커스터마이징**: 로깅 레벨, 플러그인 시스템

### 비기능 요구사항

1. **성능**: 60fps 렌더링, RFID 폴링 15Hz 이상
2. **확장성**: 모듈별 독립 패키지, 플러그인 아키텍처
3. **커스터마이징**: 모든 파라미터 JSON/YAML 설정 가능, UI 에디터 제공
4. **테스트**: 각 모듈 단위 테스트, 하드웨어 없는 시뮬레이션 모드
5. **문서화**: 각 모듈 API 문서, 커스터마이징 가이드

## 원본 대비 아키텍처 매핑

| 원본 (.NET) | 클론 (Flutter) | 변경점 |
|-------------|---------------|--------|
| vpt_server (WinForms) | Flutter Desktop App | God Class → Clean Architecture |
| net_conn (TCP/UDP) | dart:io Sockets | WCF → 직접 소켓 |
| boarssl (TLS) | dart:io SecureSocket | 자체 TLS → 표준 TLS |
| mmr (DirectX 11) | Rive + Flutter Canvas | GPU 파이프라인 → Rive State Machine |
| hand_eval (C# bitmask) | Dart bitmask 포팅 | 알고리즘 동일, 언어만 변환 |
| PokerGFX.Common (DI) | Riverpod | Unity Container → Riverpod |
| RFIDv2 (HidLibrary) | hidapi FFI | .NET HidLibrary → native hidapi |
| analytics (S3) | 제거 (Phase 1 범위 외) | 텔레메트리 제외 |

## 구현 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| PRD | 완료 | 본 문서 |
| 아키텍처 설계 | 완료 | 계획서에 통합 |
| Flutter 스켈레톤 | 완료 | 170개 Dart 파일 |
| M1 RFID 모듈 | 완료 | hidapi FFI + Isolate 폴링, 50 tests |
| M2 핸드 평가 | 완료 | Bitmask 64-bit 포팅, 17+ 게임 라우팅 |
| M3 네트워크 프로토콜 | 완료 | PBKDF1 + AES-256-CBC + 131 명령어, 104 tests |
| M4 렌더링 엔진 | 완료 | Rive State Machine 파이프라인 (.riv 에셋 별도) |
| M5 NDI 출력 | 완료 | NDI SDK 5.x FFI, graceful fallback |
| M6 게임 상태 머신 | 완료 | 22개 변형, 베팅/팟/쇼다운, 123 tests |
| M7 설정 UI | 완료 | 6탭 설정 화면, 핫리로드, 프리셋 관리 |

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-04 | v1.2 | 7개 feature 화면 구현 완료 (RfidScreen→GameScreen→SettingsScreen), AppRouter 연결, 컴파일 에러 0개 | Architect APPROVE (94%), 앱 실행 가능 상태 완성 |
| 2026-03-03 | v1.1 | M1-M7 전체 구현 완료 반영, 구현 상태 업데이트 | 7개 마일스톤 PDCA 완료, Architect APPROVE (~91%) |
| 2026-03-03 | v1.0 | 최초 작성 | 역설계 문서 기반 재설계 |
