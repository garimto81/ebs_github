# PokerGFX 역공학 분석 프로젝트 PRD

**버전**: 1.0.0
**작성일**: 2026-02-12
**프로젝트 코드**: POKERGFX-RE-2026
**예상 기간**: 4-8주 (1인 기준)

---

## 1. 배경 및 목적

### 1.1 프로젝트 배경

PokerGFX는 프로페셔널 포커 방송용 그래픽 엔진으로, 전세계 주요 포커 토너먼트에서 사용되는 상용 소프트웨어입니다. 2024년 12월 PokerGO가 인수하여 현재 운영 중입니다.

본 프로젝트는 다음과 같은 목적으로 PokerGFX 애플리케이션의 전체 아키텍처, 프로토콜, 비즈니스 로직을 역공학 분석합니다.

### 1.2 분석 목적

| 목적 | 세부 내용 |
|------|----------|
| **상호운용성 확보** | 기존 방송 시스템과의 통합 인터페이스 개발 |
| **보안 감사** | RFID 프로토콜 및 데이터 암호화 검증 |
| **경쟁력 분석** | 포커 핸드 평가 알고리즘 및 렌더링 파이프라인 이해 |
| **기술 학습** | .NET 기반 방송 그래픽 시스템 아키텍처 연구 |

### 1.3 법적 근거

- 한국 저작권법 제101조의4: 정당한 권한 보유자의 상호운용성 목적 역공학 허용
- PokerGFX EULA 검토 필요 (역공학 제한 조항 확인)
- 상용 컴포넌트 라이선스 준수 (Medialooks, EO.WebBrowser 등)

---

## 2. 분석 대상 개요

### 2.1 주요 바이너리

| 파일 | 크기 | 타입 | 내부명 | 역할 |
|------|------|------|--------|------|
| **PokerGFX-Server.exe** | 372MB | .NET WinForms | vpt_server | 메인 그래픽 엔진 + 비디오 출력 |
| **ActionTracker.exe** | 9.2MB | .NET WPF | vpt_remote | 딜러 터치스크린 원격 제어기 |
| **GFXUpdater.exe** | 57KB | .NET Console | - | 자동 업데이트 도구 |
| **PokerGFX.Common.dll** | 565KB | .NET Library | - | 공유 라이브러리 (42개 타입) |

### 2.2 임베디드 네이티브 DLL (Costura 패키징)

```
Costura.Fody → 136개 리소스 임베드
├── hand_eval.dll       # 포커 핸드 평가 알고리즘 (CRITICAL)
├── RFIDv2.dll          # RFID 카드 인식 프로토콜 (CRITICAL)
├── net_conn.dll        # Server-Remote 통신 (WCF 추정)
├── analytics.dll       # 게임 데이터 분석
├── mmr.dll             # 미디어 렌더링
└── [131개 추가 DLL]
```

### 2.3 버전 정보

- **버전**: 3.2.985.0
- **.NET Framework**: 4.0.30319 (4.x)
- **난독화 수준**: 없음~최소 (라이선스 관련 2개 리소스만 난독화)
- **디버그 심볼**: PDB 파일 전체 존재 (완전 소스 복원 가능)
- **서명**: PublicKeyToken=null (강력한 이름 없음, 패칭 가능)

---

## 3. 구현 범위

### Phase 1: 환경 구축 및 바이너리 추출 (2-4시간)

- [ ] ILSpy + Costura Plugin 설치
- [ ] Simple-Costura-Decompressor로 임베디드 DLL 추출
- [ ] dnSpy 설치 및 PDB 심볼 로드
- [ ] 추출된 바이너리 디렉토리 구조화

### Phase 2: Common.dll 공유 라이브러리 분석 (4-8시간)

- [ ] 42개 타입 전수 조사
- [ ] Data Model 추출 (Entity Framework 6.0 매핑)
- [ ] EncryptionService 암호화 구현 분석
- [ ] 공통 유틸리티 함수 문서화

### Phase 3: Database 및 통신 프로토콜 분석 (8-16시간)

- [ ] net_conn.dll 디컴파일 (WCF 프로토콜 추정)
- [ ] SQLite DB 스키마 추출 (DB Browser)
- [ ] SQL Server 옵션 스키마 분석
- [ ] Server-Remote 통신 메시지 구조 파악
- [ ] Wireshark로 네트워크 트래픽 캡처

### Phase 4: hand_eval.dll 핸드 평가 알고리즘 (4-8시간)

- [ ] 포커 핸드 랭킹 로직 추출
- [ ] 승률 계산 알고리즘 분석
- [ ] 테이블별 핸드 히스토리 처리
- [ ] 성능 최적화 기법 파악

### Phase 5: RFIDv2.dll 카드 인식 프로토콜 (8-16시간)

- [ ] RFID 하드웨어 통신 프로토콜 분석
- [ ] 카드 ID → 카드 값 매핑 로직
- [ ] 에러 처리 및 재시도 메커니즘
- [ ] HidLibrary USB 통신 구현 분석

### Phase 6: vpt_server 핵심 로직 (40-80시간)

- [ ] 43개 WinForms UI 분석
- [ ] RFID 입력 → 핸드 평가 → 그래픽 렌더링 플로우
- [ ] Medialooks MFormats SDK 비디오 I/O 통합
- [ ] NDI, Blackmagic ATEM, SRT 출력 구현
- [ ] EO.WebBrowser Chromium 기반 UI 컴포넌트
- [ ] Bugsnag 에러 리포팅 통합
- [ ] NVIDIA Nsight GPU 제어 (NvAPIWrapper)

### Phase 7: Skin 시스템 분석 (16-32시간)

- [ ] 253MB .skn 바이너리 포맷 리버싱
- [ ] Skin 로딩 및 파싱 로직
- [ ] 커스터마이징 가능 요소 파악
- [ ] 애셋 추출 도구 개발

### Phase 8: 그래픽 파이프라인 (24-40시간)

- [ ] SkiaSharp 2D 렌더링 레이어
- [ ] SharpDX Direct2D/Direct3D11 통합
- [ ] 실시간 오버레이 합성 로직
- [ ] GPU 가속 최적화 기법
- [ ] 비디오 출력 인코딩 파이프라인

### Phase 9: ActionTracker 원격 제어 (16-24시간)

- [ ] WPF + Touch UI 구조 분석
- [ ] 딜러 터미널 기능 맵핑
- [ ] Server와의 실시간 동기화 메커니즘
- [ ] 게임 상태 머신 분석

### Phase 10: 동적 분석 및 검증 (16-32시간)

- [ ] Process Monitor로 파일/레지스트리 액세스 추적
- [ ] WCF Test Client로 통신 프로토콜 테스트
- [ ] 실제 실행 환경에서 동작 검증
- [ ] 패치 및 수정 가능성 테스트

**총 예상 시간**: 138-260시간 (4-8주, 1인 기준)

---

## 4. 기술 스택 분석

### 4.1 코어 프레임워크

| 기술 | 버전 | 용도 |
|------|------|------|
| **.NET Framework** | 4.0.30319 | 런타임 환경 |
| **WinForms** | 4.x | Server UI (43개 폼) |
| **WPF** | 4.x | ActionTracker UI |
| **Entity Framework** | 6.0 | ORM + DB 접근 |
| **DependencyInjection** | 9.0 | IoC 컨테이너 |

### 4.2 그래픽 렌더링

| 라이브러리 | 용도 |
|-----------|------|
| **SkiaSharp** | 2D 벡터 그래픽 + 텍스트 렌더링 |
| **SharpDX** | Direct2D, Direct3D11 하드웨어 가속 |
| **Medialooks MFormats SDK** | 프로페셔널 비디오 I/O |
| **EO.WebBrowser** | Chromium 기반 웹 컴포넌트 임베딩 |

### 4.3 방송 출력

| 프로토콜/SDK | 용도 |
|-------------|------|
| **NDI** | Network Device Interface 실시간 전송 |
| **Blackmagic ATEM** | 하드웨어 스위처 통합 |
| **SRT** | Secure Reliable Transport 스트리밍 |

### 4.4 데이터 및 통신

| 기술 | 용도 |
|------|------|
| **SQLite** | 로컬 데이터베이스 (기본) |
| **SQL Server** | 엔터프라이즈 DB 옵션 |
| **WCF** | Server-Remote 통신 (System.ServiceModel 참조) |
| **AWS SDK S3** | 클라우드 스토리지 |

### 4.5 유틸리티

| 라이브러리 | 용도 |
|-----------|------|
| **FluentValidation** | 11.0 - 데이터 검증 |
| **Newtonsoft.Json** | 13.0 - JSON 직렬화 |
| **BearSSL** | SSL/TLS 암호화 |
| **HidLibrary** | USB HID 장치 통신 (RFID 리더) |
| **Bugsnag** | 에러 추적 및 리포팅 |
| **NvAPIWrapper** | NVIDIA GPU 제어 |

### 4.6 패키징

| 도구 | 용도 |
|------|------|
| **Costura.Fody** | 136개 DLL을 단일 EXE에 임베딩 |

---

## 5. 아키텍처 분석

### 5.1 전체 시스템 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                       PokerGFX 시스템 아키텍처                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         RFID 카드 입력                           │
│                    (RFIDv2.dll + HidLibrary)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PokerGFX-Server.exe                          │
│                      (vpt_server, 372MB)                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              핵심 로직 레이어                             │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌───────────┐  │  │
│  │  │  hand_eval.dll │  │ PokerGFX.      │  │analytics  │  │  │
│  │  │  핸드 평가     │→ │ Common.dll     │→ │.dll       │  │  │
│  │  │  알고리즘      │  │  (EF6 + Crypto)│  │  데이터   │  │  │
│  │  └────────────────┘  └────────────────┘  └───────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│                             ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           그래픽 렌더링 파이프라인                         │  │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────────┐   │  │
│  │  │ SkiaSharp  │→ │  SharpDX   │→ │  Medialooks      │   │  │
│  │  │ 2D 그래픽  │  │ D3D11 가속 │  │  MFormats SDK    │   │  │
│  │  └────────────┘  └────────────┘  └──────────────────┘   │  │
│  │         │               │                  │              │  │
│  │         └───────────────┴──────────────────┘              │  │
│  │                         │                                  │  │
│  │                         ▼                                  │  │
│  │              ┌──────────────────────┐                     │  │
│  │              │   Skin 시스템        │                     │  │
│  │              │  (.skn 253MB 포맷)   │                     │  │
│  │              └──────────────────────┘                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│                             ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              비디오 출력 레이어                            │  │
│  │  ┌──────┐  ┌──────────────┐  ┌──────┐  ┌──────────┐     │  │
│  │  │ NDI  │  │  Blackmagic  │  │ SRT  │  │ 로컬 출력 │     │  │
│  │  │ 출력 │  │  ATEM 출력   │  │ 출력 │  │          │     │  │
│  │  └──────┘  └──────────────┘  └──────┘  └──────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        │ net_conn.dll (WCF 통신)
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ActionTracker.exe                             │
│                  (vpt_remote, 9.2MB)                            │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              WPF + Touch UI                               │  │
│  │  ┌────────────────┐  ┌────────────────┐                  │  │
│  │  │  딜러 터미널   │  │  게임 상태     │                  │  │
│  │  │  제어 인터페이스│  │  실시간 동기화 │                  │  │
│  │  └────────────────┘  └────────────────┘                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      데이터 레이어                               │
│  ┌──────────────┐        ┌──────────────┐                      │
│  │   SQLite     │   OR   │  SQL Server  │                      │
│  │  (로컬 DB)   │        │ (엔터프라이즈)│                      │
│  └──────────────┘        └──────────────┘                      │
│         │                        │                              │
│         └────────────┬───────────┘                              │
│                      ▼                                          │
│           ┌──────────────────────┐                             │
│           │   AWS S3 백업/저장   │                             │
│           └──────────────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 데이터 흐름

```
1. RFID 카드 스캔
   └→ RFIDv2.dll: USB HID 통신 (HidLibrary)
      └→ 카드 ID → 카드 값 변환

2. 핸드 평가
   └→ hand_eval.dll: 포커 핸드 랭킹 계산
      └→ Common.dll: Entity Framework 6.0 데이터 저장
         └→ SQLite/SQL Server

3. 그래픽 렌더링
   └→ SkiaSharp: 2D 벡터 그래픽 생성
      └→ SharpDX: GPU 가속 합성
         └→ Skin 시스템: 테마 오버레이 적용

4. 비디오 출력
   └→ Medialooks MFormats SDK: 프레임 버퍼 관리
      └→ NDI/ATEM/SRT: 방송 출력

5. 원격 제어
   └→ ActionTracker: 딜러 입력
      └→ net_conn.dll: WCF 통신
         └→ Server: 게임 상태 업데이트
```

### 5.3 클래스 계층 (추정)

```
PokerGFX.Common.dll
├── Entities/
│   ├── Game
│   ├── Player
│   ├── Hand
│   ├── Card
│   └── TableConfig
├── Services/
│   ├── EncryptionService      # BearSSL 암호화
│   ├── DatabaseService        # EF6 컨텍스트
│   └── ValidationService      # FluentValidation
└── Models/
    ├── HandResult
    ├── GameState
    └── NetworkMessage

hand_eval.dll
├── HandEvaluator
├── RankingCalculator
└── WinProbability

RFIDv2.dll
├── RFIDReader
├── CardMapper
└── USBCommunication

net_conn.dll
├── ServerEndpoint              # WCF 서비스
├── RemoteClient                # WCF 클라이언트
└── MessageSerializer

PokerGFX-Server.exe
├── Forms/ (43개)
│   ├── MainForm
│   ├── TableSetupForm
│   ├── GraphicsConfigForm
│   └── ...
├── Graphics/
│   ├── SkiaRenderer
│   ├── DirectXCompositor
│   └── SkinManager
├── Output/
│   ├── NDIOutput
│   ├── ATEMOutput
│   └── SRTOutput
└── Core/
    ├── GameController
    └── EventBus

ActionTracker.exe
├── Views/ (WPF)
│   ├── MainWindow
│   ├── DealerControl
│   └── GameStatus
├── ViewModels/
└── Services/
    └── ServerConnection
```

---

## 6. 핵심 분석 영역

### 우선순위 1: CRITICAL (프로토콜 및 알고리즘)

| 모듈 | 이유 | 예상 시간 |
|------|------|----------|
| **hand_eval.dll** | 포커 핸드 평가 알고리즘 - 비즈니스 로직 핵심 | 4-8시간 |
| **RFIDv2.dll** | 카드 인식 프로토콜 - 하드웨어 통합 핵심 | 8-16시간 |
| **net_conn.dll** | Server-Remote 통신 프로토콜 - 시스템 통신 핵심 | 8-16시간 |

### 우선순위 2: HIGH (렌더링 및 데이터)

| 모듈 | 이유 | 예상 시간 |
|------|------|----------|
| **Skin 시스템** | 253MB 커스텀 포맷 - 그래픽 테마 시스템 | 16-32시간 |
| **EF6 Data Model** | 데이터베이스 스키마 - 전체 데이터 구조 | 4-8시간 |
| **EncryptionService** | 암호화 구현 - 보안 메커니즘 | 4-8시간 |
| **Graphics Pipeline** | SkiaSharp + SharpDX - 렌더링 최적화 | 24-40시간 |

### 우선순위 3: MEDIUM (UI 및 부가 기능)

| 모듈 | 이유 | 예상 시간 |
|------|------|----------|
| **vpt_server UI** | 43개 WinForms - 운영자 인터페이스 | 20-40시간 |
| **ActionTracker** | WPF + Touch UI - 딜러 터미널 | 16-24시간 |
| **License Validation** | 난독화된 라이선스 체크 로직 | 8-16시간 |

### 우선순위 4: LOW (보조 기능)

| 모듈 | 이유 | 예상 시간 |
|------|------|----------|
| **analytics.dll** | 게임 데이터 분석 - 부가 기능 | 4-8시간 |
| **GFXUpdater** | 자동 업데이트 도구 - 배포 관련 | 2-4시간 |
| **Bugsnag 통합** | 에러 리포팅 - 디버깅 보조 | 2-4시간 |

---

## 7. 필요 도구 및 환경

### 7.1 역공학 도구

| 도구 | 용도 | 설치 방법 |
|------|------|----------|
| **ILSpy** | .NET 디컴파일러 (최신 권장) | https://github.com/icsharpcode/ILSpy |
| **dnSpy** | 디버깅 가능 디컴파일러 + PDB 지원 | https://github.com/dnSpy/dnSpy |
| **Costura Plugin** | ILSpy용 Costura 추출 플러그인 | ILSpy Extensions |
| **Simple-Costura-Decompressor** | 독립형 Costura 추출 도구 | https://github.com/dr-BEat/Simple-Costura-Decompressor |

### 7.2 데이터 분석 도구

| 도구 | 용도 |
|------|------|
| **DB Browser for SQLite** | SQLite DB 스키마 분석 |
| **SQL Server Management Studio** | SQL Server 옵션 분석 (필요 시) |
| **HxD** | 16진수 에디터 (.skn 바이너리 분석) |

### 7.3 네트워크 및 프로세스 분석

| 도구 | 용도 |
|------|------|
| **Wireshark** | WCF 통신 패킷 캡처 |
| **Process Monitor** | 파일/레지스트리 액세스 추적 |
| **WCF Test Client** | WCF 서비스 테스트 |

### 7.4 선택적 도구

| 도구 | 용도 | 필요 시점 |
|------|------|----------|
| **NVIDIA Nsight** | GPU 렌더링 프로파일링 | Graphics Pipeline 분석 시 |
| **x64dbg** | 네이티브 DLL 디버깅 | hand_eval.dll/RFIDv2.dll 네이티브 코드 시 |

### 7.5 개발 환경

| 항목 | 사양 |
|------|------|
| **OS** | Windows 10/11 (64-bit) |
| **.NET SDK** | 4.8 Developer Pack |
| **Visual Studio** | 2022 Community (선택) |
| **RAM** | 16GB 이상 (디컴파일 시 메모리 사용) |
| **HDD** | 10GB 이상 여유 공간 |

---

## 8. 작업 일정

### 8.1 Phase별 스케줄 (4주 시나리오)

| 주차 | Phase | 작업 내용 | 산출물 |
|:----:|-------|----------|--------|
| **1주차** | Phase 1-3 | 환경 구축, Common.dll, DB/프로토콜 | 기본 아키텍처 문서 |
| **2주차** | Phase 4-5 | hand_eval.dll, RFIDv2.dll | 핵심 알고리즘 문서 |
| **3주차** | Phase 6-7 | vpt_server, Skin 시스템 | 렌더링 파이프라인 문서 |
| **4주차** | Phase 8-10 | Graphics, ActionTracker, 동적 분석 | 최종 보고서 + 검증 |

### 8.2 Phase별 스케줄 (8주 시나리오)

| 주차 | Phase | 작업 내용 | 산출물 |
|:----:|-------|----------|--------|
| **1주차** | Phase 1-2 | 환경 구축, Common.dll | 환경 설정 문서 |
| **2주차** | Phase 3 | DB 스키마, 통신 프로토콜 | 데이터 모델 문서 |
| **3주차** | Phase 4 | hand_eval.dll | 핸드 평가 알고리즘 문서 |
| **4주차** | Phase 5 | RFIDv2.dll | RFID 프로토콜 문서 |
| **5주차** | Phase 6 (Part 1) | vpt_server UI + 입력 처리 | UI 구조 문서 |
| **6주차** | Phase 6 (Part 2) | vpt_server 출력 + 통합 | 비디오 출력 문서 |
| **7주차** | Phase 7-8 | Skin 시스템, Graphics Pipeline | 렌더링 문서 |
| **8주차** | Phase 9-10 | ActionTracker, 동적 분석 | 최종 보고서 + 검증 |

### 8.3 마일스톤

| 마일스톤 | 완료 조건 | 기한 (4주 기준) |
|---------|----------|-----------------|
| **M1: 환경 완료** | 모든 DLL 추출, 디컴파일 환경 구축 | 1주차 |
| **M2: 프로토콜 완료** | hand_eval + RFID + net_conn 분석 완료 | 2주차 |
| **M3: 렌더링 완료** | Graphics Pipeline + Skin 시스템 분석 완료 | 3주차 |
| **M4: 프로젝트 완료** | 최종 문서 + 동적 검증 완료 | 4주차 |

---

## 9. 예상 영향 파일 목록

### 9.1 분석 대상 바이너리

```
C:\claude\ebs_reverse\binaries\
├── PokerGFX-Server.exe           # 메인 분석 대상 (372MB)
├── ActionTracker.exe             # 원격 제어 분석 (9.2MB)
├── GFXUpdater.exe                # 업데이트 도구 (57KB)
├── PokerGFX.Common.dll           # 공유 라이브러리 (565KB)
└── extracted\                    # Costura 추출 결과
    ├── hand_eval.dll             # CRITICAL
    ├── RFIDv2.dll                # CRITICAL
    ├── net_conn.dll              # HIGH
    ├── analytics.dll
    ├── mmr.dll
    └── [131개 추가 DLL]
```

### 9.2 분석 산출물

```
C:\claude\ebs_reverse\docs\
├── 01-plan\
│   └── pokergfx-reverse-engineering.plan.md   # 본 문서
├── 02-design\
│   ├── architecture-overview.md               # 전체 아키텍처
│   ├── hand-evaluation-algorithm.md           # hand_eval.dll 분석
│   ├── rfid-protocol.md                       # RFIDv2.dll 분석
│   ├── network-protocol.md                    # net_conn.dll 분석
│   ├── skin-format-spec.md                    # .skn 포맷 명세
│   ├── graphics-pipeline.md                   # 렌더링 파이프라인
│   └── database-schema.md                     # EF6 스키마
├── 03-analysis\
│   ├── common-dll-types.md                    # Common.dll 타입 전수 조사
│   ├── ui-forms-mapping.md                    # 43개 WinForms 맵핑
│   ├── encryption-analysis.md                 # EncryptionService 분석
│   └── license-validation.md                  # 라이선스 체크 로직
├── 04-report\
│   └── final-report.md                        # 최종 보고서
└── images\
    ├── architecture-diagram.png
    ├── data-flow.png
    └── ui-screenshots\
```

### 9.3 추출 및 디컴파일 결과

```
C:\claude\ebs_reverse\decompiled\
├── PokerGFX-Server\
│   ├── src\                      # ILSpy 디컴파일 소스
│   ├── symbols\                  # PDB 심볼 파일
│   └── resources\                # 임베디드 리소스
├── ActionTracker\
│   ├── src\
│   └── symbols\
├── Common\
│   ├── src\
│   └── symbols\
└── native-dlls\
    ├── hand_eval\                # 네이티브 코드 분석 결과
    └── RFIDv2\
```

### 9.4 동적 분석 데이터

```
C:\claude\ebs_reverse\analysis\
├── network-captures\
│   ├── wcf-messages.pcapng       # Wireshark 캡처
│   └── message-samples.json      # 샘플 메시지
├── process-monitor\
│   ├── file-access.csv           # 파일 액세스 로그
│   └── registry-access.csv       # 레지스트리 액세스 로그
├── database\
│   ├── sample-schema.sql         # SQLite 스키마 추출
│   └── sample-data.db            # 샘플 데이터
└── logs\
    ├── runtime-logs.txt          # 런타임 로그
    └── error-traces.txt          # 에러 추적
```

---

## 10. 위험 요소 및 법적 검토

### 10.1 기술적 위험 요소

| 위험 요소 | 발생 확률 | 영향도 | 대응 방안 |
|----------|:--------:|:------:|----------|
| **네이티브 DLL 난독화** | 중 | 상 | x64dbg 동적 분석, 어셈블리 패턴 매칭 |
| **라이선스 체크 실패** | 하 | 중 | 패칭 또는 Mock 환경 구축 |
| **RFID 하드웨어 부재** | 상 | 중 | 시뮬레이터 개발, 프로토콜 리플레이 |
| **WCF 통신 암호화** | 중 | 중 | 인증서 추출, SSL Strip 프록시 |
| **.skn 포맷 복잡도** | 중 | 중 | 점진적 리버싱, 샘플 비교 분석 |
| **GPU 의존 렌더링** | 하 | 하 | NVIDIA Nsight 프로파일링 |
| **PDB 심볼 누락** | 극저 | 극상 | 현재 전체 존재 확인 (위험 없음) |

### 10.2 법적 위험 요소

| 위험 요소 | 심각도 | 법적 근거 | 대응 방안 |
|----------|:------:|----------|----------|
| **EULA 역공학 금지 조항** | 중 | PokerGFX 사용자 계약 | 정당한 목적 문서화, 상호운용성 명시 |
| **상용 컴포넌트 라이선스** | 중 | Medialooks, EO.WebBrowser EULA | 리버싱 범위를 PokerGFX 코드로 제한 |
| **영업비밀 침해** | 중 | 부정경쟁방지법 | 공개된 정보 우선, 독자 개발 증명 |
| **특허 침해** | 하 | 포커 알고리즘 특허 조사 필요 | 특허 회피 설계, 선행 기술 조사 |
| **저작권 침해** | 하 | 한국 저작권법 | 상호운용성 목적 명시 (제101조의4) |

### 10.3 법적 검토 체크리스트

- [ ] PokerGFX EULA 전문 검토 (역공학 제한 조항 확인)
- [ ] 프로젝트 목적 문서화 (상호운용성/보안 감사/경쟁력 분석)
- [ ] PokerGO 법무팀 연락 (공식 허가 가능성 타진)
- [ ] 상용 컴포넌트 라이선스 개별 확인
  - [ ] Medialooks MFormats SDK
  - [ ] EO.WebBrowser
  - [ ] Bugsnag
  - [ ] NVIDIA Nsight
- [ ] 포커 핸드 평가 알고리즘 특허 조사
  - [ ] USPTO 검색: "poker hand evaluation"
  - [ ] KIPRIS 검색: "포커 핸드 평가"
- [ ] 분석 결과 보안 (NDA 체결 검토)
- [ ] 외부 공개 전 법무 자문

### 10.4 권장 안전 조치

| 조치 | 설명 |
|------|------|
| **정당한 목적 명시** | "기존 방송 시스템과 통합을 위한 프로토콜 분석" |
| **Clean Room 방법론** | 분석팀과 구현팀 분리 (재구현 시) |
| **독자 개발 증명** | 리버싱 과정 전체 문서화 (본 PRD 포함) |
| **내부 사용 제한** | 분석 결과를 상업적 공개 금지 (회사 내부만) |
| **라이선스 준수** | 정품 PokerGFX 라이선스 보유 확인 |

---

## 11. 성공 기준

### 11.1 Phase별 성공 기준

| Phase | 성공 기준 | 검증 방법 |
|-------|----------|----------|
| **Phase 1** | 136개 DLL 전체 추출 + 디컴파일 환경 구축 | ILSpy/dnSpy에서 정상 로드 |
| **Phase 2** | Common.dll 42개 타입 문서화 + EF6 모델 추출 | 클래스 다이어그램 생성 |
| **Phase 3** | WCF 프로토콜 메시지 구조 파악 + DB 스키마 추출 | 샘플 메시지 송수신 성공 |
| **Phase 4** | hand_eval.dll 핸드 랭킹 알고리즘 재구현 | 알고리즘 검증 테스트 통과 |
| **Phase 5** | RFID 프로토콜 명세 문서화 | 시뮬레이터로 통신 재현 |
| **Phase 6** | vpt_server 전체 워크플로우 문서화 | 데이터 흐름 다이어그램 완성 |
| **Phase 7** | .skn 포맷 파서 개발 | 기존 Skin 파일 로드 성공 |
| **Phase 8** | Graphics Pipeline 렌더링 로직 분석 | 렌더링 단계별 다이어그램 |
| **Phase 9** | ActionTracker UI 전체 맵핑 | 기능별 화면 스크린샷 |
| **Phase 10** | 실제 실행 환경 동적 검증 | Process Monitor 트레이스 수집 |

### 11.2 최종 성공 기준

| 항목 | 기준 | 측정 방법 |
|------|------|----------|
| **아키텍처 이해도** | 전체 시스템 구조 90% 이상 파악 | 아키텍처 다이어그램 검토 |
| **핵심 알고리즘 분석** | hand_eval + RFID 프로토콜 완전 분석 | 재구현 가능 수준 문서화 |
| **프로토콜 명세** | WCF 메시지 구조 100% 파악 | 샘플 메시지 파싱 성공 |
| **데이터 모델** | EF6 스키마 전체 추출 | ERD 생성 |
| **렌더링 파이프라인** | SkiaSharp → SharpDX 플로우 분석 | 단계별 코드 트레이싱 |
| **문서 완성도** | 각 Phase별 문서 작성 완료 | 문서 리뷰 통과 |
| **법적 검토** | EULA + 라이선스 준수 확인 | 체크리스트 100% 완료 |

### 11.3 KPI

| 지표 | 목표 | 측정 시점 |
|------|:----:|----------|
| **분석 완료율** | 90% | 프로젝트 종료 시 |
| **문서 작성량** | 50+ 페이지 | 프로젝트 종료 시 |
| **코드 이해도** | 재구현 가능 수준 | Phase별 리뷰 |
| **일정 준수율** | 80% | 주차별 마일스톤 |
| **법적 리스크** | 0건 | 법무 검토 완료 |

---

## 12. 다음 단계

### 12.1 즉시 실행

1. **법적 검토 우선**
   - [ ] PokerGFX EULA 전문 확보 및 분석
   - [ ] PokerGO 법무팀 컨택 (공식 허가 요청)
   - [ ] 상용 컴포넌트 라이선스 개별 확인

2. **환경 구축**
   - [ ] ILSpy 7.x 최신 버전 설치
   - [ ] dnSpy 6.x 설치 (디버깅용)
   - [ ] Costura 추출 도구 설치

3. **초기 분석**
   - [ ] Phase 1 시작: 136개 DLL 추출
   - [ ] PDB 심볼 파일 확인
   - [ ] Common.dll 타입 전수 조사 착수

### 12.2 승인 필요 사항

- [ ] 프로젝트 예산 승인 (도구 라이선스, 하드웨어)
- [ ] 법무팀 최종 승인
- [ ] 작업 시간 할당 (4-8주)
- [ ] 결과물 보안 등급 결정

### 12.3 리스크 모니터링

- 주간 법적 리스크 점검
- Phase별 기술적 리스크 재평가
- 상용 컴포넌트 라이선스 변경 추적

---

## 부록

### A. 참조 문서

| 문서 | 위치 |
|------|------|
| PokerGFX 공식 문서 | https://pokergfx.com/docs |
| .NET Decompilation Guide | https://github.com/icsharpcode/ILSpy/wiki |
| Costura.Fody Documentation | https://github.com/Fody/Costura |
| 한국 저작권법 제101조의4 | 국가법령정보센터 |

### B. 약어 정리

| 약어 | 전체 명칭 |
|------|----------|
| **VPT** | VideoPokerTable |
| **EF** | Entity Framework |
| **WCF** | Windows Communication Foundation |
| **RFID** | Radio-Frequency Identification |
| **NDI** | Network Device Interface |
| **ATEM** | Advanced Television Equipment Manufacturer (Blackmagic) |
| **SRT** | Secure Reliable Transport |
| **PDB** | Program Database (디버그 심볼) |
| **EULA** | End User License Agreement |

### C. 연락처

| 역할 | 담당자 | 연락처 |
|------|--------|--------|
| 프로젝트 리드 | TBD | - |
| 법무 검토 | TBD | - |
| 기술 자문 | TBD | - |

---

**문서 종료**

본 PRD는 PokerGFX 역공학 분석 프로젝트의 전체 계획을 담고 있습니다. 실행 전 반드시 법적 검토를 완료하고, 정당한 목적을 명확히 문서화해야 합니다.
