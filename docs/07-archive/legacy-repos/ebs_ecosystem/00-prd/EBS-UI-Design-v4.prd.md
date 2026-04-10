---
doc_type: "prd"
doc_id: "EBS-UI-Design-v4"
version: "4.0.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-06"
last_updated: "2026-03-06"
phase: "phase-1"
priority: "critical"

depends_on:
  - "EBS-UI-Design-v3.prd.md (레이아웃/오버레이 원본)"
  - "EBS-UI-Design-v2.prd.md (기술 아키텍처)"
  - "ebs-eco-system.md (설계 원칙)"
  - "ebs-kickoff-2026.md (킥오프 기획서)"

source_analysis:
  - ref: "pokergfx-v3.2-complete-whitepaper"
    path: "C:/claude/ui_overlay/docs/03-analysis/pokergfx-v3.2-complete-whitepaper.md"
    desc: "PokerGFX 247개 요소 분석, 54개 비활성화 식별, 15종 오버레이 상세"
---

# EBS UI Design v4.0 — 순수 그래픽 렌더러 앱 레이아웃 & 오버레이 그래픽 설계

## 1장. 문서 개요

### 1.1 이 문서의 목적

EBS 앱이 **어떻게 생겨야 하는지** 정의한다. 기능 카탈로그, 게임 규칙, 시나리오는 선행 문서(pokergfx-prd-v2.md)에 정의되어 있으며, 기술 스택과 아키텍처는 v2.0(EBS-UI-Design-v2.prd.md)에 정의되어 있다. 본 문서는 이 두 문서와 **중복 없이** 앱 레이아웃과 오버레이 그래픽 배치만 다룬다.

**v4.0의 핵심 변경**: EBS 설계 원칙(ebs-eco-system.md §1.1, ebs-kickoff-2026.md S2)에 따라 **순수 그래픽 렌더러** 원칙을 문서 전체에 반영한다. v3의 Sources 탭(비디오 입력/카메라/ATEM 제어)을 완전 제거하고, Outputs 탭을 NDI/Browser 출력 중심으로 재설계한다. 비디오 입력 캡처, 합성, 스위칭, 녹화는 OBS/vMix에 위임한다.

### 1.2 설계 철학

**PokerGFX 구조를 따라갈 이유가 없다.** PokerGFX는 2010년대 WinForms 6탭 구조다. EBS는 프로덕션 검증된 5개 벤치마크 앱에서 추출한 패턴을 적용하여, 가장 세련되고 혁신적인 방송 제어 앱으로 설계한다.

#### 비디오 책임 외부화 원칙

PokerGFX는 비디오 입력 캡처(Decklink/USB/NDI), DirectX 11 합성, ATEM 스위처 제어, PIP, Dual Canvas, 녹화까지 **단일 프로세스에서 처리하는 올인원 모놀리스**였다. EBS는 이 책임을 분리한다.

| 책임 | PokerGFX (올인원) | EBS Phase 1-2 | EBS Phase 5+ |
|------|:---:|:---:|:---:|
| 비디오 입력 캡처 (카메라) | 내장 (Decklink/USB/NDI) | **OBS / vMix에 위임** | Multi-cam AI |
| 비디오 합성 / 스위칭 | 내장 (DirectX 11 + ATEM) | **OBS / vMix에 위임** | AI Production |
| 그래픽 렌더링 (GFX) | 내장 | **EBS 핵심 — 순수 그래픽 생성에 집중** | EBS 핵심 |
| 녹화 / 송출 | 내장 | **OBS / vMix에 위임** | OTT 파이프라인 |

> **현재 Phase(1-2) 원칙**: EBS 앱은 순수하게 그래픽을 생성하여 출력하는 역할에 집중한다. 비디오 입력, 합성, 스위칭, 녹화는 프로덕션 소프트웨어(OBS/vMix)가 담당한다. 비디오 관련 책임은 Phase 5 이후 AI Production으로 점진적 내재화한다.
>
> — ebs-kickoff-2026.md S2, ebs-eco-system.md §1.1

### 1.3 벤치마크 앱 5선

모든 설계 결정은 아래 5개 프로덕션 검증 앱에서 추출한 패턴에 근거한다. BM-1은 **Console 앱 레이아웃**, BM-2는 **정보 구조와 키보드 UX**, BM-3은 **오버레이 시각 언어**, BM-4는 **그래픽 전용 렌더러 아키텍처**, BM-5는 **클라우드 그래픽 + NDI 출력**을 정의한다.

**BM-1: Ross Video DashBoard** (방송 제어)

- 검증: Super Bowl LVI AR 그래픽 운영 (NBC Sports + Van Wagner), SoFi Stadium 상설 시스템, Rogers Sportsnet(토론토), QTV 중계차 운영. NBC/ESPN/Sky Sports 등 전 세계 방송국 표준 제어 소프트웨어. **라이브 스포츠 방송 제어의 사실상 표준**.
- 기술 상세: v9.16 (2026.01), **80+ openGear 파트너** 네이티브 지원, CustomPanel Visual Logic Editor, RBAC 접근 제어, RossTalk/VDCP/OGPJSON/HTTP(S)/TCP/UDP/MIDI 프로토콜 지원.
- 추출 패턴: CustomPanel 빌더 (운영자가 패널 직접 구성), 단일 인터페이스 철학, 역할별 레이아웃 전환, RBAC 접근 제어
- EBS 적용: Top-Preview 레이아웃 (상단 전폭 프리뷰 + 하단 탭 컨트롤), 역할별 UI 커스터마이징

#### BM-1 보조 레퍼런스: Top-Preview 레이아웃 수렴 현상

EBS Console의 Top-Preview 레이아웃은 Ross DashBoard 단독 참조가 아니라, 2024~2026년 기준 **주요 방송 제어 소프트웨어 전부**가 동일 패턴으로 수렴한 업계 표준이다.

| 소프트웨어 | 레이아웃 패턴 | 프리뷰 위치 | 컨트롤 위치 | EBS 차용 요소 |
|-----------|:----------:|:---------:|:---------:|------------|
| **OBS Studio** | Top-Preview + Bottom-Docks | 상단 전폭 | 하단 5도크 | 도크 구조, 씬/소스 관리 |
| **vMix** | Dual-Preview + Bottom-Input | 상단 좌우 | 하단 Input Bar | 듀얼 프리뷰 모드, 색상 코드 탭 |
| **ATEM Software** | Bus-Style + Right-Palette | 상단 버스 | 우측 팔레트 + 하단 탭 | 탭 기반 설정 분리, 팔레트 UI |
| **Ross DashBoard** | CustomPanel (자유 배치) | 운영자 설정 | 운영자 설정 | 역할별 레이아웃, RBAC |

> **결론**: 4개 소프트웨어 모두 "프리뷰=상단, 컨트롤=하단/측면"으로 수렴. EBS는 이 패턴을 따르되, **하단 전폭 탭 패널(가변 높이, 스크롤 금지)**로 5탭 설정을 통합한다.

**BM-2: Bloomberg Terminal** (정보 밀도 + 키보드 퍼스트)

- 검증: **325,000+ 전문 구독자**, 연간 $25,000/좌석, 2019년 Chromium 기반 전환, 금융 업계 40년 표준. **실시간 데이터 밀도 UI의 최고 레퍼런스**.
- UX 설계 원칙 (Bloomberg UX 팀 공식):
  - **Concealing Complexity**: 수천 개 기능을 사용자 여정(journey)별로 은닉
  - **Consistency**: 수천 개 화면에서 동일한 인터랙션 패턴 유지
  - **Gradual Evolution**: UI 급변은 치명적. 점진적 변화만 허용
  - **GO Key 패턴**: 모든 화면 상단에 커맨드 바 존재. 기능명/티커 입력 + GO(Enter) = 즉시 이동
  - **Launchpad**: 사용자 맞춤 대시보드. 임의의 탭/윈도우 수 배치 가능
- 추출 패턴: 적응형 정보 밀도, 키보드 우선 조작, 맥락 기반 복잡성 은닉
- EBS 적용: 게임 상태별 정보량 자동 조절, 일관된 컨트롤 패턴

**BM-3: GGPoker + GTO Wizard + WSOP 방송** (포커 오버레이 혁신)

- 검증: GGPoker — 세계 2위 온라인 포커 플랫폼, WSOP 공식 파트너. GTO Wizard — 실시간 GTO 분석 오버레이. WSOP Paradise 2025 — GGPoker 기반 라이브 방송.
- 추출 패턴: Glassmorphism 카드 UI, 네온/글로우 이벤트 강조, Bold 타이포 핵심 수치 강조, 듀얼 디스플레이 마스킹 (Streamer Mode)
- EBS 적용: 오버레이 시각 언어 전체 (반투명 프로스트 배경, 네온 올인 강조, Bold 스택/팟 표시)

**BM-4: CasparCG** (그래픽 전용 렌더러) — **v4.0 신규**

- 검증: SVT(스웨덴 공영방송), NRK(노르웨이 공영방송), 전 세계 수백 개 방송국 사용. **오픈소스 방송 그래픽의 사실상 표준**.
- 아키텍처: Server(렌더링 엔진) + Client(제어 UI) **완전 분리**. 비디오 입력 관리 없음 — **순수 그래픽 플레이아웃 전용**.
- 출력: SDI/HDMI Fill & Key (Alpha 분리), NDI. AMCP 프로토콜로 외부 제어.
- 추출 패턴: Server-Client 분리, HTML5 템플릿 렌더링, AMCP 프로토콜 제어, Fill & Key Alpha 분리 출력
- EBS 적용: Console(Client) ↔ Overlay Engine(Server) 분리 아키텍처 근거. **EBS가 "순수 그래픽 렌더러"를 지향하는 가장 직접적인 업계 선례**.

**BM-5: Singular.live** (클라우드 그래픽 + NDI) — **v4.0 신규**

- 검증: TVU Networks 통합, 글로벌 클라우드 방송 그래픽 플랫폼. BBC, Sky Sports, ESPN 등 주요 방송사 채택.
- 아키텍처: 웹 기반 제어 UI + 클라우드/엣지 렌더링. **비디오 입력 없음** — 그래픽 레이어만 생성하여 NDI/Browser Source로 출력.
- 출력: NDI (Alpha 포함), Browser Source (OBS/vMix 직접 연동), HLS/RTMP 오버레이 인젝션.
- 추출 패턴: 웹 기반 제어 UI, NDI Alpha 출력, Browser Source 보조 경로, 원격 운영 모델
- EBS 적용: **NDI 기본 출력 아키텍처 근거**. Browser Source 보조 경로 설계 참조.

### 1.4 설계 패턴 ↔ 벤치마크 매핑

| 설계 패턴 | 벤치마크 출처 | EBS 적용 |
|-----------|:------------:|----------|
| Top-Preview 레이아웃 | OBS/ATEM/vMix/Ross | 상단 전폭 프리뷰 + 하단 탭 컨트롤 (업계 수렴 패턴) |
| 적응형 정보 밀도 | BM-2 Bloomberg + BM-3 Smart HUD | AT/오버레이에서 게임 진행에 따라 정보량 자동 조절 |
| 복잡성 은닉 | BM-2 Bloomberg | 수십 개 설정을 5탭 + 서브그룹으로 계층화 |
| Glassmorphism 오버레이 | BM-3 GGPoker | 반투명 프로스트 카드/팟/확률 패널 |
| Bold 타이포 + 네온 | BM-3 GGPoker | 핵심 수치 강조, 올인 이벤트 발광 효과 |
| 듀얼 디스플레이 마스킹 | BM-3 GGPoker Streamer Mode | 방송 딜레이 중 홀 카드 자동 마스킹 |
| LCH 색공간 테마 | BM-3 + 업계 트렌드 | 3변수(base, accent, contrast) 커스텀 테마 |
| Server-Client 분리 | BM-4 CasparCG | Console(제어) ↔ Overlay Engine(렌더링) 아키텍처 |
| NDI Alpha 기본 출력 | BM-4 CasparCG + BM-5 Singular.live | RGBA NDI 스트림 기본 출력. Browser Source 보조 |
| 웹 기반 제어 UI | BM-5 Singular.live | Electron 기반 Console 웹 앱 접근 |

### 1.5 불필요 기능 제거

PokerGFX 247개 요소 중 **54개 비활성화** (whitepaper 분석) + **v4 추가 제거 19개**:

| 범주 | 수량 | 사유 |
|------|:----:|------|
| 카메라/녹화/연출 | 19 | 프로덕션 팀(스위처/카메라)이 담당 |
| Delay/Secure Mode | 9 | EBS 송출 딜레이 장비로 대체 |
| 외부 연동 기기 | 7 | Stream Deck, MultiGFX, ATEM 미사용 |
| Twitch 연동 | 5 | Twitch 스트리밍 미운영 |
| 기타 | 14 | 태그, 라이선스, 시스템, 레거시 UI |

**v4.0 추가 제거 (비디오 책임 외부화)**:

| 범주 | 수량 | 제거 항목 |
|------|:----:|----------|
| Video Input 관리 | 5 | Camera 1/2 (S-02~S-03), NDI Input (S-04), Camera Mode (S-05), Video Input 헤더 (S-01) |
| Chroma Key (Sources) | 3 | Chroma Enable (S-07), Chroma Color (S-08), Chroma Tolerance (S-09) → Outputs O-04/O-05로 이관 |
| ATEM 스위처 | 6 | ATEM Connection (S-12), Auto-Cut (S-13), Transition Type (S-14), T-Bar (S-15), DSK Fill (S-16), ATEM Control 헤더 (S-11) |
| Board Sync | 1 | Board Sync Offset (S-10) — 외부 스위처 영역 |
| 스트리밍 출력 | 2 | RTMP Stream (O-08), SRT Output (O-09) — OBS 영역 |
| Fill & Key 하드웨어 | 2 | DeckLink Channel Map (O-11.2), Fill/Key Preview (O-16) — 외부 처리 |

## 2장. EBS Console

PokerGFX의 776x660px WinForms 6탭 구조를 완전히 탈피한다.

### 핵심 혁신

| PokerGFX  | EBS v4.0  | 벤치마크 |
|-------------------|-----------------|:--------:|
| 6탭 WinForms (Sources, Outputs, GFX 1/2/3, System) | Top-Preview 레이아웃 (상단 전폭 프리뷰 + 하단 5탭 컨트롤) | OBS/ATEM/vMix |
| 비디오 입력/합성/스위칭 내장 | **순수 그래픽 출력 전용** — 비디오는 OBS/vMix에 위임 | BM-4 CasparCG |
| 고정 컨트롤 패널 | 탭 기반 설정 패널 (5탭 구조) | OBS |
| 메뉴 → 탭 → 서브그룹 탐색 | 키보드 단축키 (Ctrl+1~5) 즉시 접근 | OBS/vMix |

### 2.1 메인 레이아웃

**최소 해상도**: 1024x768 | **권장**: 1920x1080
**레이아웃**: Menu Bar 28px (고정) / Preview Area 가변 (1fr) / Info Bar 36px (고정) / Tab Bar 36px (고정) / Tab Content 가변 (auto, 스크롤 금지)

CSS: `grid-template-rows: 28px 1fr 36px 36px auto; height: 100vh;`

#### 운영 워크플로우

**방송 전 (Setup)**:
1. System 탭에서 RFID 연결 확인 (Info Bar RFID 상태 Green)
2. Outputs 탭에서 출력 해상도(1080p/4K), NDI 출력, 배경(Transparent/Chroma) 설정
3. GFX 탭에서 레이아웃(Board Position, Player Layout), 스킨, 브랜딩 설정
4. Register Deck으로 새 덱 등록 → 카드 RFID 매핑 확인
5. Launch AT로 Action Tracker 실행

**긴급 상황**:
- 오버레이 오류 → Hide GFX (즉시 숨김) → 문제 해결 → Hide GFX 토글 복원
- 카드 인식 오류 → Reset Hand → 현재 핸드 전체 초기화
- AT 연결 끊김 → Launch AT로 재실행, 자동 재연결 시도

#### 개발 스펙

**리사이즈 동작**: 윈도우 리사이즈 시 Menu Bar(28px), Info Bar(36px), Tab Bar(36px)는 고정.
Preview Area와 Tab Content가 가변. Tab Content는 탭별 콘텐츠 높이에 따라 결정되며, 스크롤은 금지된다.

### 2.2 Menu Bar (28px)

표준 데스크톱 앱 메뉴바. 좌측에 EBS 로고(M-01), 이어서 File/Edit/View/Table/Help 메뉴.

```
[EBS] File  Edit  View  Table  Help
```

| 메뉴 | 항목 |
|------|------|
| File | New Session, Open Session, Save Session, Export Hand History, Exit |
| Edit | Undo, Redo, Preferences (M-12 흡수) |
| View | Toggle Preview (F11), Toggle Tab Panel (Ctrl+M), Toggle Lock (Ctrl+L) |
| Table | Switch Table (M-02t 기능), Register Deck (M-13), Launch AT (M-14) |
| Help | About (M-01 기능), Keyboard Shortcuts, Documentation, Export Logs |

#### EBS Logo (M-01)

운영: 로고 클릭 시 About 다이얼로그를 표시한다. 앱 버전, 빌드 번호, 라이선스 정보, 진단 로그 내보내기 버튼을 포함한다. 더블클릭 시 개발자 콘솔(DevTools)을 토글한다.

개발: About 다이얼로그는 모달 오버레이. 진단 로그 내보내기는 `system.export_logs` 명령으로 최근 24시간 로그를 ZIP으로 패키징한다. DevTools 토글은 `Ctrl+Shift+I` 바인딩과 동일하며, 프로덕션 빌드에서도 접근 가능하다(디버깅용).

#### Settings / Preferences (M-12)

운영: Edit > Preferences로 접근한다. 앱 전반에 적용되는 설정을 관리한다: 테마(Dark/Light), 언어, 단축키 커스터마이징, 자동 저장 간격, 로그 레벨 등.

개발: Settings 다이얼로그는 모달 오버레이. 설정값은 로컬 `settings.json` 파일에 저장된다. 변경 즉시 적용 (Apply 버튼 없음, 실시간 반영). Escape로 닫기.

### 2.2b Info Bar (36px)

Preview Area와 Tab Bar 사이에 위치한다. 테이블 식별, 상태 인디케이터, Quick Actions를 제공한다.

```
[Table: Final Table ▼] ── [RFID ●] [CPU ▐▐▐] [GPU ▐▐] ── [🔒] [Reset] [Deck] [AT] [Hide]
```

| 영역 | 내용 |
|------|------|
| 좌측 — 식별 | 테이블 드롭다운 (활성 테이블 전환) |
| 중앙 — 상태 인디케이터 | RFID 연결 상태 (●), CPU 사용률 바 (▐▐▐), GPU 사용률 바 (▐▐) |
| 우측 — Quick Actions | Reset Hand, Register Deck, Launch AT, Hide GFX — 항상 접근 가능한 핵심 버튼 4개 |

#### Info Bar 요소 상세 (9개)

**좌측 — 식별 영역**

**Table Dropdown (M-02t)**

운영: 현재 활성 테이블을 표시하고, 드롭다운으로 다른 테이블로 전환한다. 테이블 전환 시 Preview Area, AT, 모든 오버레이가 선택된 테이블의 데이터로 갱신된다.

개발: WebSocket `tables.list` 요청으로 사용 가능한 테이블 목록을 조회한다. `tables.switch { table_id }` 요청으로 활성 테이블을 전환한다.

**중앙 — 상태 인디케이터**

**RFID Status (M-05)**

운영: RFID 리더의 현재 상태를 7색 아이콘으로 표시한다.

| 색상 | 상태 | 원인 | 운영자 대응 |
|------|------|------|------------|
| Green | 정상 연결 | 리더 연결 + 안테나 정상 | 없음 |
| Yellow | 카드 읽기 중 | RFID 태그 감지, 데이터 수신 중 | 없음 (자동 전환) |
| Blue | 캘리브레이션 모드 | 안테나 캘리브레이션 진행 중 | 캘리브레이션 완료 대기 |
| Orange | 신호 약함 | 안테나 간섭 또는 거리 초과 | 안테나 위치 조정 |
| Red | 연결 끊김 | USB 분리, 리더 전원 OFF | USB 재연결, 리더 전원 확인 |
| White | 미초기화 | 앱 시작 직후, 리더 탐색 중 | 자동 연결 대기 (5초) |
| Black (비활성) | RFID 비활성화 | System 탭에서 수동 비활성화 | 필요 시 System 탭에서 재활성화 |

개발: `rfid.status` WebSocket 이벤트로 상태 변경을 수신한다. 5초 이상 RED 유지 시 Info Bar 전체에 경고 배너를 표시한다.

**RFID Connection Icon (M-06)**

운영: M-05 보조 아이콘. 연결(링크 아이콘) / 미연결(끊긴 링크 아이콘) 2상태만 표시한다.

개발: M-05 상태에서 파생되는 UI 전용 요소. `rfid.status ∈ {RED, BLACK}` → 미연결 아이콘, 그 외 → 연결 아이콘.

**CPU Indicator (M-03)**

운영: CPU 사용률을 수평 바 그래프로 표시한다. 50% 이하 녹색, 50~80% 황색, 80% 이상 적색.

개발: `system.metrics` WebSocket 이벤트에서 `cpu_usage` 필드를 500ms 간격으로 수신한다. 이동 평균(5초 윈도우). 임계값: `warn: 50`, `critical: 80`.

**GPU Indicator (M-04)**

운영: GPU 사용률을 수평 바 그래프로 표시한다. M-03과 동일한 색상 임계값 적용.

개발: `system.metrics` WebSocket 이벤트에서 `gpu_usage` 필드를 수신한다. M-03과 동일한 패턴.

**우측 — Quick Actions**

**Lock Toggle (M-07)**

운영: 설정 잠금/해제를 토글한다. 잠금 상태에서는 Tab Content의 모든 설정 컨트롤이 비활성화(회색 처리). **예외**: Info Bar의 Quick Actions는 Lock 상태에서도 항상 활성화된다.

개발: Lock 상태는 `ui.lock` 로컬 상태로 관리한다. 단축키: `Ctrl+L`.

**Reset Hand (M-11)**

운영: 현재 핸드를 긴급 초기화한다. 확인 다이얼로그가 표시된다.

개발: `game.reset` WebSocket 메시지를 서버로 전송한다. 단축키: `Ctrl+R`.

**Register Deck (M-13)**

운영: 새 카드 덱의 RFID 등록 프로세스를 시작한다. 52장(+ 조커 2장) 카드를 순서대로 RFID 리더에 태그하여 UID를 매핑한다.

개발: `rfid.register` WebSocket 메시지로 등록 모드를 시작한다. 단축키: `Ctrl+D`.

**Launch AT (M-14)**

운영: Action Tracker를 실행하거나, 이미 실행 중이면 AT 윈도우로 포커스를 전환한다.

개발: AT 실행 상태는 WebSocket `at.status` 이벤트로 모니터링한다. 단축키: `Ctrl+T`.

**Hide GFX (M-15)**

운영: 모든 오버레이 그래픽을 즉시 숨기거나 복원한다.

개발: `overlay.visibility` WebSocket 메시지를 서버로 전송한다. 숨김/복원 전환 시간: 1프레임 이내(16ms). 단축키: `Ctrl+H`. Lock 상태에서도 동작한다.

### 2.3 Preview Area (가변)

라이브 오버레이 미리보기. 전체 폭을 사용하며, 16:9 비율을 유지하고 남는 좌우 공간은 배경색(#1a1a2e)으로 채운다.

| 속성 | 값 |
|------|-----|
| 너비 | 전폭(100vw). 실제 16:9 영역은 height 기준으로 자동 계산 |
| 높이 | 가변 (1fr — Menu Bar/Info Bar/Tab Bar/Tab Content 제외한 나머지) |
| 종횡비 | 16:9 (고정). CSS `aspect-ratio: 16/9` |
| 배경 | 프리뷰 영역: 오버레이 배경색 (Outputs 탭 O-04/O-05 설정). 좌우 여백: #1a1a2e |
| 렌더링 | 오버레이 엔진 iframe 임베드 (실시간 합성) |
| 인터랙션 | 오버레이 요소 클릭 → 하단 탭에서 해당 설정으로 자동 전환 + 포커스 |

#### 운영 설명

Preview Area는 시청자가 보는 방송 화면과 동일한 오버레이를 실시간으로 표시한다. 운영자는 GFX 탭에서 설정을 변경하면 Preview에서 즉시 결과를 확인할 수 있다.

**클릭 인터랙션**: Preview의 오버레이 요소를 클릭하면 하단 Tab Content에서 해당 설정으로 자동 전환된다.

| 클릭 대상 (Preview) | 전환 탭 | 포커스 대상 | element-catalog |
|---------------------|---------|------------|:---------------:|
| Player Graphic | GFX | Card & Player 서브그룹 | G-04~G-05.1 |
| Board Graphic | GFX | Layout 서브그룹 | G-01.1 |
| Sponsor Logo | GFX | Branding 서브그룹 | G-10.1~G-10.3 |
| Strip (하단 배너) | GFX | Branding 서브그룹 | G-15 |
| Blinds Graphic | Display | Blinds 서브그룹 | D-01~D-16 |
| Ticker | GFX | Branding 서브그룹 | G-14.1 |
| Leaderboard | GFX | Layout 서브그룹 | G-01.5 |

#### 개발 스펙

**렌더링 방식**: 오버레이 엔진을 iframe으로 임베드한다. iframe의 `src`는 로컬 오버레이 렌더러 URL(`http://localhost:{port}/overlay`)이다.

**스케일링 알고리즘**: `object-fit: contain` + `aspect-ratio: 16/9` CSS 적용.

**상태별 표시**:

| 상태 | Preview 표시 | 조건 |
|------|-------------|------|
| 정상 | 실시간 오버레이 렌더링 | 오버레이 엔진 연결 정상 |
| GFX HIDDEN | 반투명 "GFX HIDDEN" 워터마크 | Hide GFX(M-15) 활성화 |
| SERVER DISCONNECTED | 회색 배경 + 연결 끊김 메시지 | WebSocket 연결 끊김 |
| 해상도 변경 중 | 블랙아웃 (약 1초) | Outputs 탭에서 Canvas Size 변경 |
| RFID 미연결 | 정상 렌더링 + Info Bar 경고만 | RFID 상태 RED (Preview는 영향 없음) |

**클릭 매핑 구현**: 오버레이 엔진이 각 요소에 `data-element-id` 속성을 부여한다. iframe 내 클릭 이벤트를 `postMessage`로 Console에 전달한다.

### 2.4 Tab Bar + Tab Content

하단 영역 전체를 두 레이어로 구성한다. 기존 우측 320px 세로 스택 → 1920px 전폭 가로 다중 컬럼으로 재배치.

**Tab Bar (36px)**:

```
[Outputs] [GFX] [Display] [Rules] [System]                           [▼ 패널 최소화]
```

**Tab Content (가변)**: 전폭 활용. 스크롤 금지 — 모든 콘텐츠가 한 번에 표시된다. Console은 **오버레이 표시 방식**만 제어하며, 게임 데이터(블라인드 값, 플레이어, 스택)는 AT에서 입력한다.

| 탭 | 내용 | PokerGFX 대응 |
|----|------|:---:|
| Outputs | 캔버스 해상도, 배경 설정, NDI 출력, Browser Source 출력 | Outputs 탭 (재설계) |
| GFX | 오버레이 레이아웃(Board Position, Player Layout), 카드/플레이어, 애니메이션(Transition In/Out), 브랜딩(스폰서 로고, 스킨) | GFX 1+2 통합 |
| Display | 수치 형식(8종 영역별 정밀도), 통화 기호, 블라인드/Equity 표시 조건, BB 모드 | GFX 3 Numbers |
| Rules | 게임 규칙(Bomb Pot, Straddle), 플레이어 표시(좌석번호, 탈락, 정렬) | GFX 2 Rules |
| System | RFID 안테나 제어(UPCARD/Muck/Community), AT 접근 허용, 캘리브레이션, 테이블 진단 | System 탭 |
| 프리뷰 요소 클릭 시 | 해당 오버레이 요소의 Tab으로 자동 전환 + 포커스 | EBS 신규 |

**패널 최소화**: Tab Bar 우측의 `[▼]` 버튼으로 Tab Content를 접을 수 있다. 최소화 시 Tab Bar(36px)만 남고 Preview Area가 확장된다. 단축키: `Ctrl+M`.

**Lock 영향**: Lock Toggle(M-07) 활성화 시 Tab Content의 모든 컨트롤이 비활성화된다. 탭 전환 자체는 Lock 상태에서도 가능하다 (읽기 전용 확인 용도).

#### 개발 스펙

**Tab Content 3-Column 그리드**: 각 탭의 Content 영역은 3-Column CSS Grid로 구성된다.

CSS: `grid-template-columns: 1fr 1fr 1fr; gap: 16px; padding: 12px; overflow: hidden;`

**컨트롤 6종 표준**: Tab Content에서 사용하는 UI 컨트롤은 6종으로 제한한다.

| 컨트롤 | 용도 | 예시 |
|--------|------|------|
| Dropdown | 고정 선택지 | Canvas Size (1080p / 4K) |
| TextField | 자유 텍스트 입력 | Vanity Text, NDI Name |
| Checkbox | ON/OFF 토글 | NDI Enable, Show Blinds |
| ColorPicker | 색상 선택 | Chroma Color |
| Slider | 연속 범위 값 | X Margin (0.0~1.0), Transition 시간 |
| NumberInput | 정수/소수 직접 입력 | Frame Rate, Browser Port |

**실시간 WebSocket 반영**: Tab Content에서 설정값을 변경하면 `config.update { key, value }` WebSocket 메시지가 서버로 즉시 전송된다. 디바운스: 300ms.

#### Sub-ID 범례

v4 annotation 박스보다 세밀한 기능은 sub-ID로 확장한다:

| 패턴 | 의미 | 예시 |
|------|------|------|
| `X-nn` | v4 annotation 정본 ID | O-07, G-04, Y-06 |
| `X-nn.m` | 하위 세부 기능 (m = 1, 2, 3…) | G-10.1 (Sponsor Logo 1) |

### 2.5 Outputs 탭 기능 상세

Outputs 탭은 EBS의 **그래픽 출력 파이프라인**을 구성한다. v3의 비디오 입력/RTMP/SRT/DeckLink 요소를 완전 제거하고, **순수 그래픽 렌더러** 원칙에 맞는 캔버스 + NDI + Browser 출력으로 재설계한다. 3-Column 그리드 내에 **Canvas**, **NDI Output**, **Browser Output** 서브그룹을 배치한다.

#### Canvas 서브그룹 (O-01~O-05)

렌더링 캔버스의 기본 속성을 설정한다.

| # | 요소명 | ID | 컨트롤 | 설명 | 기본값 |
|:-:|--------|:--:|--------|------|--------|
| 1 | Canvas Size | O-01 | Dropdown | 렌더링 캔버스 해상도 | 1080p |
| 2 | Aspect Ratio | O-02 | SegmentedButton | 화면 비율 전환 | 16:9 |
| 3 | Frame Rate | O-03 | Dropdown | 렌더링 프레임레이트 | 60fps |
| 4 | Background | O-04 | SegmentedButton | 배경 모드: Transparent / Chroma Key | Transparent |
| 5 | Chroma Color | O-05 | ColorPicker | 크로마키 배경색 (O-04가 Chroma일 때만 활성) | #0000FF |

**동작**: Canvas Size 변경 시 Preview Area와 오버레이 렌더링 캔버스가 동시에 재초기화된다. 재초기화 중 Preview는 일시 블랙아웃(약 1초). Aspect Ratio 16:9/9:16 전환 시 전체 오버레이 좌표계가 전환된다. Background가 Transparent이면 RGBA Alpha 채널이 투명으로 출력되어 NDI Alpha 합성에 최적. Chroma Key 모드는 Browser Source 사용 시 OBS 크로마키 필터와 연동하는 레거시 호환 옵션이다.

#### NDI Output 서브그룹 (O-06~O-08)

EBS의 **기본 출력 경로**. RGBA 프레임을 NDI 스트림으로 네트워크에 송출한다.

| # | 요소명 | ID | 컨트롤 | 설명 | 기본값 |
|:-:|--------|:--:|--------|------|--------|
| 6 | NDI Enable | O-06 | Checkbox | NDI 출력 활성화 | ON |
| 7 | NDI Name | O-07 | TextField | NDI 스트림 이름 (네트워크 discovery용) | "EBS-GFX" |
| 8 | NDI Alpha | O-08 | Checkbox | Alpha 채널 포함 RGBA 출력 | ON |

**동작**: NDI Enable 활성화 시 EBS Server가 NDI 송신자(sender)를 생성하고, 오버레이 렌더링 프레임을 NDI 스트림으로 출력한다. NDI Name은 네트워크에서 이 스트림을 식별하는 이름이다 (예: "EBS-GFX", "EBS-TABLE1-GFX"). NDI Alpha가 ON이면 RGBA 4채널로 출력되어 OBS/vMix에서 별도 키잉 없이 투명 합성이 가능하다. OFF이면 RGB 3채널로 출력되며, Background(O-04) 설정에 따라 배경이 채워진다.

> **CasparCG 패턴 참조 (BM-4)**: CasparCG는 Fill(RGB) + Key(Alpha) 신호를 SDI 포트 2개로 물리 분리 출력한다. EBS는 NDI RGBA 단일 스트림으로 Fill + Key를 통합 출력하되, 외부 스위처가 Fill & Key 분리를 요구하면 OBS NDI 출력 설정에서 분리한다 (§6.3 참조).

#### Browser Output 서브그룹 (O-09~O-10)

NDI의 **보조 출력 경로**. localhost URL을 제공하여 OBS Browser Source로 직접 연동한다.

| # | 요소명 | ID | 컨트롤 | 설명 | 기본값 |
|:-:|--------|:--:|--------|------|--------|
| 9 | Browser Enable | O-09 | Checkbox | Browser Source URL 활성화 | ON |
| 10 | Browser Port | O-10 | NumberInput | localhost 포트 번호 | 8080 |

**동작**: Browser Enable 활성화 시 `http://localhost:{port}/overlay` URL이 활성화된다. OBS Browser Source에서 이 URL을 입력하면 오버레이가 실시간으로 표시된다. Browser Source는 NDI 인프라가 없는 환경에서의 폴백 경로이며, Alpha 투명도는 CSS `background: transparent` + OBS "Allow source to control browser visibility" 설정으로 지원된다.

> **v3 대비 제거 항목**: RTMP/SRT 출력 → OBS 영역. Broadcast Delay → 외부 장비. DeckLink Channel Map → OBS/외부 스위처. Fill & Key 분리 하드웨어 출력 → NDI Alpha로 대체. Live Video/Audio/Device → 비디오 입력 제거.

### 2.6 GFX 탭 기능 상세

GFX 탭은 오버레이의 시각적 설정을 관리하는 핵심 탭이다. 4개 서브그룹을 배치한다: **Layout → Card & Player → Animation → Branding**. 스크롤 금지 — 3-Column 밀집 배치로 모든 설정이 한 번에 표시된다. Branding은 기본 접힘 상태로 시작한다. Numbers와 Rules는 각각 Display 탭(§2.6b)과 Rules 탭(§2.6c)으로 분리되었다.

##### 요소 설명

| # | 요소명 | ID | 컨트롤 | 설명 |
|:-:|--------|:--:|--------|------|
| 1 | Layout (col) | G-01 | SectionHeader | 레이아웃 컬럼 헤더 |
| 2 | Template | G-02 | Dropdown | 오버레이 레이아웃 템플릿 (Standard/Custom) |
| 3 | Strip Pos | G-03 | SegmentedButton | 플레이어 스트립 위치 (BOT/TOP) |
| 4 | Show Hole Cards | G-04 | Checkbox | 홀카드 표시 활성화 |
| 5 | Card Reveal | G-05 | Dropdown | 카드 공개 시점 (Auto/Immediate/On Action) |
| 6 | Player Name Style | G-06 | Dropdown | 플레이어 이름 표시 형식 (Full/First/Nickname) |
| 7 | Animation (col) | G-07 | SectionHeader | 애니메이션 컬럼 헤더 |
| 8 | Transitions | G-08 | Checkbox | 등장/퇴장 애니메이션 활성화 |
| 9 | Speed | G-09 | Slider | 트랜지션 속도 (0.1x~2.0x) |
| 10 | Logo Overlay | G-10 | Checkbox | 스폰서 로고 오버레이 활성화 |
| 11 | Logo Position | G-11 | Dropdown | 로고 위치 (TL/TR/BL/BR) |
| 12 | Watermark | G-12 | Checkbox | 워터마크 표시 활성화 |
| 13 | Skin (col) | G-13 | SectionHeader | 스킨 컬럼 헤더 |
| 14 | Active Skin | G-14 | Dropdown | 활성 스킨 선택 |
| 15 | Vanity Text | G-15 | TextField | 테이블 표시 텍스트 + Game Variant 대체 옵션 |

#### Layout 서브그룹 (G-01.1~G-01.5, G-02)

오버레이의 전체 배치를 결정한다. 4장 오버레이 설계의 9-Grid 시스템과 연동된다.

| 요소 | ID | 기능 | 유효 범위 |
|------|:--:|------|----------|
| Board Position | G-01.1 | 보드 카드 위치 | Left / Right / Centre / Top |
| Player Layout | G-02 | 플레이어 배치 모드 | Horizontal / Vert-Bot-Spill / Vert-Bot-Fit / Vert-Top-Spill / Vert-Top-Fit |
| X Margin | G-01.2 | 좌우 여백 (정규화 좌표) | 0.0~1.0 (기본 0.04) |
| Top Margin | G-01.3 | 상단 여백 | 0.0~1.0 (기본 0.05) |
| Bot Margin | G-01.4 | 하단 여백 | 0.0~1.0 (기본 0.04) |
| Leaderboard Position | G-01.5 | 리더보드 위치 | Centre / Left / Right |

**동작**: Layout 값을 변경하면 Preview Area의 오버레이가 즉시 재배치된다. Board Position과 Player Layout의 조합이 4장의 배치 프리셋(A~D)에 해당한다.

#### Card & Player 서브그룹 (G-04, G-04.1, G-05.1, G-01.6)

| 요소 | ID | 기능 | 유효 범위 |
|------|:--:|------|----------|
| Reveal Players | G-04 | 홀카드 공개 시점 | Immediate / On Action / After Bet / On Action + Next |
| How to Show Fold | G-04.1 | 폴드 표시 방식 + 지연 시간 | Immediate / Delayed (초 입력) |
| Reveal Cards | G-05.1 | 카드 공개 연출 | Immediate / After Action / End of Hand / Showdown Cash / Showdown Tourney / Never |
| Show Leaderboard | G-01.6 | 핸드 후 리더보드 자동 표시 + 설정 | Checkbox + Settings |

#### Animation 서브그룹 (G-08.1, G-08.2, G-07.1, G-07.2)

| 요소 | ID | 기능 | 유효 범위 |
|------|:--:|------|----------|
| Transition In | G-08.1 | 등장 애니메이션 타입 + 시간(초) | Dropdown + NumberInput |
| Transition Out | G-08.2 | 퇴장 애니메이션 타입 + 시간(초) | Dropdown + NumberInput |
| Indent Action Player | G-07.1 | 액션 플레이어 들여쓰기 | Checkbox |
| Bounce Action Player | G-07.2 | 액션 플레이어 바운스 효과 | Checkbox |

**동작**: Transition In/Out 타입은 Default/Pop/Expand/Slide 중 선택하며, 시간은 0.1~2.0초 범위다. Indent와 Bounce는 현재 액션 차례(Action-on) 플레이어를 시각적으로 구별하는 효과로, 동시 활성화 가능하다.

#### Branding 서브그룹 (G-10.1~G-10.3, G-15, G-14.1)

기본 접힘 상태.

| 요소 | ID | 기능 |
|------|:--:|------|
| Sponsor Logo 1 | G-10.1 | Leaderboard 위치 스폰서 로고 (ImageSlot) |
| Sponsor Logo 2 | G-10.2 | Board 위치 스폰서 로고 (ImageSlot) |
| Sponsor Logo 3 | G-10.3 | Strip 위치 스폰서 로고 (ImageSlot) |
| Vanity Text | G-15 | 테이블 표시 텍스트 + Game Variant 대체 옵션 (TextField + Checkbox) |
| Skin Info | G-14.1 | 현재 스킨명 + 용량 (읽기 전용) |

**동작**: 3개 로고 슬롯에 PNG/SVG 이미지를 드래그 앤 드롭으로 등록한다. Vanity Text에 입력한 문자열은 Board Graphic의 배니티 영역(4장 §4.5)에 표시된다.

> **[v2.0 Defer]** Skin Editor (G-14s, SV-027) / Graphic Editor (SV-028) — 스킨 편집기는 v2.0 커스터마이징 단계에서 구현.

### 2.6b Display 탭 기능 상세

Display 탭은 수치 표시 형식을 영역별로 세밀하게 제어한다. PokerGFX GFX 3 탭의 Display 설정을 계승한다. 3개 서브그룹: **Blinds → Precision → Mode**.

##### 요소 설명

| # | 요소명 | ID | 컨트롤 | 설명 |
|:-:|--------|:--:|--------|------|
| 1 | Blinds (col) | D-01 | SectionHeader | 블라인드 컬럼 헤더 |
| 2 | Show Blinds | D-02 | Dropdown | 블라인드 표시 조건 (When Changed) |
| 3 | Show Hand # | D-03 | Checkbox | 핸드 번호 동시 표시 |
| 4 | Currency Symbol | D-04 | TextField | 통화 기호 (₩) |
| 5 | Trailing Currency | D-05 | Checkbox | 통화 기호 후치 여부 (₩100 vs 100₩) |
| 6 | Divide by 100 | D-06 | Checkbox | 전체 금액을 100으로 나눠 표시 |
| 7 | Precision (col) | D-07 | SectionHeader | 정밀도 컬럼 헤더 |
| 8 | Leaderboard Precision | D-08 | Dropdown | 리더보드 칩카운트 (Exact Amount / Smart k-M / Divide) |
| 9 | Player Stack Precision | D-09 | Dropdown | Player Graphic 스택 (Smart k-M 기본) |
| 10 | Player Action Precision | D-10 | Dropdown | 액션 금액 BET/RAISE (Smart Amount 기본) |
| 11 | Blinds Precision | D-11 | Dropdown | Blinds Graphic 수치 (Smart Amount 기본) |
| 12 | Pot Precision | D-12 | Dropdown | Board Graphic 팟 (Smart Amount 기본) |
| 13 | Mode (col) | D-13 | SectionHeader | 모드 컬럼 헤더 |
| 14 | Chipcounts Mode | D-14 | SegmentedButton | 칩카운트 표시 단위 (Amount / BB) |
| 15 | Pot Mode | D-15 | SegmentedButton | 팟 표시 단위 (Amount / BB) |
| 16 | Bets Mode | D-16 | SegmentedButton | 베팅 표시 단위 (Amount / BB) |

**동작**: BB 모드 활성화 시 모든 수치가 Big Blind 배수로 표시된다 (예: 스택 50,000 / BB 1,000 → "50 BB"). Amount 모드에서는 Precision 설정에 따라 Smart k-M(예: 1.2M) 또는 정확 금액이 표시된다.

> **[v2.0 Defer]** Outs 서브그룹 (G-40~G-42) — Show Outs / Outs Position / True Outs는 Equity 엔진(v2.0)과 함께 구현.

### 2.6c Rules 탭 기능 상세

Rules 탭은 게임 규칙이 오버레이 표시에 영향을 미치는 설정을 관리한다. 2개 서브그룹: **Game Rules → Player Display**. 방송 시작 전 세팅하고 핸드 진행 중에는 변경하지 않는 것이 원칙이다.

##### 요소 설명

| # | 요소명 | ID | 컨트롤 | 설명 |
|:-:|--------|:--:|--------|------|
| 1 | Game Rules (col) | R-01 | SectionHeader | 게임 규칙 컬럼 헤더 |
| 2 | Move Button Bomb Pot | R-02 | Checkbox | Bomb Pot 후 딜러 버튼 이동 여부 |
| 3 | Limit Raises | R-03 | Checkbox | 유효 스택 기반 레이즈 제한 |
| 4 | Straddle Sleeper | R-04 | Dropdown | 스트래들 위치 규칙 (버튼/UTG 이외 슬리퍼) |
| 5 | Sleeper Final Action | R-05 | Checkbox | 슬리퍼 스트래들 최종 액션 여부 |
| 6 | Player Display (col) | R-06 | SectionHeader | 플레이어 표시 컬럼 헤더 |
| 7 | Add Seat # | R-07 | Checkbox | 플레이어 이름에 좌석 번호 추가 |
| 8 | Show as Eliminated | R-08 | Checkbox | 스택 소진 시 탈락 표시 |
| 9 | Clear Previous Action | R-09 | Dropdown | 이전 액션 초기화 + 'x to call'/'option' 표시 |
| 10 | Order Players | R-10 | Dropdown | 플레이어 정렬 순서 |
| 11 | Hilite Winning Hand | R-11 | Dropdown | 위닝 핸드 강조 시점 (Immediately / After Delay) |

**동작**: Move Button Bomb Pot이 활성화되면 Bomb Pot 핸드 후 딜러 버튼이 다음 좌석으로 이동한다. Hilite Winning Hand가 "After Delay"이면 쇼다운 후 설정된 지연 시간 후에 위닝 핸드 카드가 하이라이트된다.

### 2.7 System 탭 기능 상세

System 탭은 RFID 하드웨어, 테이블 인증, AT 접근 정책, 시스템 진단을 관리한다. RFID 연결이 방송 시작의 첫 번째 전제 조건이므로 최상단에 배치한다. 5개 서브그룹: **Table → RFID → AT → Diagnostics → Startup**.

##### 요소 설명

| # | 요소명 | ID | 컨트롤 | 설명 |
|:-:|--------|:--:|--------|------|
| 1 | RFID (col) | Y-01 | SectionHeader | RFID 컬럼 헤더 |
| 2 | Reader Status | Y-02 | StatusIndicator | RFID 리더 연결 상태 (ST25R3911B 칩명 표시) |
| 3 | Antenna Power | Y-03 | Slider | 안테나 출력 강도 (0~100%) |
| 4 | Reset Reader | Y-04 | TextButton | RFID 시스템 초기화 (RESET) |
| 5 | Calibrate | Y-05 | TextButton | 안테나 캘리브레이션 실행 (RUN) |
| 6 | Table Name | Y-06 | Dropdown | 테이블 식별 이름 선택 |
| 7 | Action Tracker (col) | Y-07 | SectionHeader | AT 컬럼 헤더 |
| 8 | AT Status | Y-08 | StatusIndicator | Action Tracker 연결 상태 |
| 9 | Auto-Launch | Y-09 | Checkbox | AT 자동 실행 활성화 |
| 10 | WebSocket Port | Y-10 | NumberInput | AT WebSocket 포트 번호 |
| 11 | Launch AT | Y-11 | TextButton | AT 수동 실행 (OPEN) |
| 12 | Server | Y-12 | StatusIndicator | EBS Server 엔진 상태 |
| 13 | WS Clients | Y-13 | ReadOnly | 연결된 WebSocket 클라이언트 수 |
| 14 | Diagnostics (col) | Y-14 | SectionHeader | 진단 컬럼 헤더 |
| 15 | CPU Usage | Y-15 | ProgressBar | CPU 사용률 (%) |
| 16 | GPU Usage | Y-16 | ProgressBar | GPU 사용률 (%) |
| 17 | Memory | Y-17 | ReadOnly | 메모리 사용량 (GB) |
| 18 | Frame Drop | Y-18 | ReadOnly | 프레임 드롭 카운터 (빨간색 경고) |
| 19 | Log Level | Y-19 | Dropdown | 로그 레벨 (DEBUG/INFO/WARN/ERROR) |
| 20 | Export Logs | Y-20 | TextButton | 로그 파일 내보내기 (EXPORT) |

#### Table 서브그룹 (Y-06, Y-06.1)

| 요소 | ID | 기능 |
|------|:--:|------|
| Table Name | Y-06 | 테이블 식별 이름 (TextField). AT 연결 시 이 이름으로 테이블을 찾는다 |
| Table Password | Y-06.1 | AT 접속 비밀번호 (TextField, 마스킹). 빈 값이면 비밀번호 없이 접속 허용 |

#### RFID 서브그룹 (Y-04, Y-05, Y-01.1~Y-01.3)

| 요소 | ID | 기능 |
|------|:--:|------|
| RFID Reset | Y-04 | RFID 시스템 초기화 — 재시작 없이 연결 재설정 (TextButton) |
| RFID Calibrate | Y-05 | 안테나별 캘리브레이션 — 초기 설치 시 1회 실행 (TextButton) |
| UPCARD Antennas | Y-01.1 | UPCARD 안테나로 홀카드 읽기 활성화 (Checkbox) |
| Disable Muck | Y-01.2 | AT 모드 시 muck 안테나 비활성화 (Checkbox) |
| Disable Community | Y-01.3 | 커뮤니티 카드 안테나 비활성화 (Checkbox) |

#### AT 서브그룹 (Y-07.1, Y-07.2)

| 요소 | ID | 기능 |
|------|:--:|------|
| Allow AT Access | Y-07.1 | AT 접근 허용 — 비활성 시 AT Auto 모드만 가능 (Checkbox) |
| Predictive Bet | Y-07.2 | 베팅 예측 자동완성 활성화 (Checkbox) |

#### Diagnostics 서브그룹 (Y-14.1, Y-14.2, Y-14.3)

| 요소 | ID | 기능 |
|------|:--:|------|
| Table Diagnostics | Y-14.1 | 안테나별 상태/신호 강도 별도 창 (TextButton) |
| System Log | Y-14.2 | 실시간 이벤트/오류 로그 뷰어 별도 창 (TextButton) |
| Export Folder | Y-14.3 | JSON 핸드 히스토리 내보내기 폴더 지정 (FolderPicker) |

#### Startup 서브그룹 (Y-12.1)

| 요소 | ID | 기능 |
|------|:--:|------|
| Auto Start | Y-12.1 | OS 시작 시 EBS Server 자동 실행 (Checkbox) |

> **[DROP]** License Key / Activation Code / License Server / Serial Number — PokerGFX 라이선스 관련 4개 요소 불필요.
>
> **[DROP]** Kiosk Mode (Y-15) — 키오스크 잠금 모드 배제.
>
> **[DROP]** MultiGFX (SV-025) / Stream Deck 연동 (SV-026) — 다중 테이블 운영 및 외부 컨트롤러 연동 배제.

### 2.8 탭 간 교차 참조

Console 5탭의 설정이 AT와 오버레이에 어떻게 전파되는지를 요약한다. Console은 **사전 세팅 도구**이므로 방송 시작 전에 설정을 완료하고, 방송 중에는 AT와 오버레이가 이 설정을 참조하여 동작한다.

| 탭 | Console 설정 | AT 영향 | 오버레이 영향 |
|----|-------------|---------|-------------|
| Outputs | Canvas Size (O-01) | — | 렌더링 캔버스 해상도 결정 |
| Outputs | Frame Rate (O-03) | — | 오버레이 렌더링 fps 결정 |
| Outputs | Background (O-04~O-05) | — | Preview + 출력 배경 (Transparent/Chroma) |
| Outputs | NDI Alpha (O-08) | — | NDI RGBA vs RGB 출력 결정 |
| GFX | Board Position (G-01.1) | — | Board Graphic 9-Grid 위치 |
| GFX | Player Layout (G-02) | — | Player Graphic 배치 모드 |
| GFX | Reveal Players (G-04) | AT에서 카드 공개 시점 연동 | 홀카드 공개 시각 효과 |
| GFX | How to Show Fold (G-04.1) | AT 폴드 시 시각 전환 | 폴드 플레이어 Graphic 제거 타이밍 |
| GFX | Transition In/Out (G-08.1~G-08.2) | — | 등장/퇴장 애니메이션 |
| Display | Currency/Precision (D-04~D-12) | — | 모든 수치 표시 형식 |
| Display | BB Mode (D-14~D-16) | — | 칩카운트/팟/베팅 BB 배수 표시 |
| System | Table Name/Password (Y-06~Y-06.1) | AT 인증 시 사용 | — |
| System | Allow AT Access (Y-07.1) | AT "Track the Action" 활성화 여부 | — |
| System | RFID 안테나 (Y-01.1~Y-01.3) | 카드 자동 인식 경로 결정 | 카드 데이터 소스 (RFID vs 수동) |

## 3장. Action Tracker — 터치 최적화 재설계

PokerGFX 버튼 나열식 → 제스처 기반 터치 인터페이스로 재설계한다.

### 핵심 혁신

| PokerGFX (레거시) | EBS v3.0 (혁신) | 벤치마크 |
|-------------------|-----------------|:--------:|
| 버튼 그리드 나열 | 제스처 인터랙션 (탭=선택, 스와이프=폴드, 롱프레스=상세) | EBS 독자 설계 |
| 고정 10인 레이아웃 | 그리드 기반 배치 + 템플릿 시스템 (최대 10인) | BM-1 + BM-2 |
| 텍스트 입력 금액 | 전용 숫자 키패드 + Quick Bet 프리셋 | BM-3 GGPoker |
| 딜러 전용 좌석 (P5) | 딜러는 좌석이 아닌 BTN 뱃지로 표시 | EBS 독자 설계 |

### 3.1 메인 레이아웃 (가로 고정)

기본 9인 레이아웃. 딜러(P5)를 제거하고 P1-P9로 재구성한다.

**포지션 재구성 매핑** (기존 10인 → 9인):

| 기존 (10인) | 신규 (9인) | 변경 사유 |
|:-----------:|:---------:|----------|
| P1 | P1 | 유지 |
| P2 | P2 | 유지 |
| P3 | P3 | 유지 |
| P4 | P4 | 유지 |
| P5 (딜러) | — | 제거: 딜러는 BTN 뱃지로 표시 |
| P6 | P5 | 번호 재배치 |
| P7 | P6 | 번호 재배치 |
| P8 | P7 | 번호 재배치 |
| P9 | P8 | 번호 재배치 |
| P10 | P9 | 번호 재배치 |

### 3.2 좌석 시스템

| 요소 | 사양 |
|------|------|
| 좌석 수 | P1-P9 (기본 9인). 설정에서 최대 10인까지 확장 가능 |
| 배치 방식 | 그리드 기반 좌표 시스템 (3.3절 참조) |
| 선택 | 탭하여 좌석 선택 → Action-on 하이라이트 |
| 최소 터치 타겟 | 48x48px (WCAG 2.5.8) |
| 카드 표시 | 홀카드 슬롯 (Holdem 2장, PLO 4/5/6장) — 게임 타입 연동 |

**딜러 표시**: 딜러는 별도 좌석이 아니다. 임의의 플레이어 좌석에 BTN 뱃지가 부착된다.

| 뱃지 | 표시 조건 | 시각 처리 |
|------|----------|----------|
| BTN | 딜러 버튼 보유 플레이어 | 흰색 원형 뱃지, 좌석 우상단 |
| SB | Small Blind 위치 | 노란색 뱃지 |
| BB | Big Blind 위치 | 파란색 뱃지 |

좌석 상태별 시각 처리:

| 상태 | 시각 처리 |
|------|----------|
| Active (Action-on) | 밝은 테두리 + 펄스 애니메이션 |
| Acted | 액션 텍스트 (BET 500, CALL, RAISE TO 1000) |
| Folded | 반투명 (opacity 0.4) + 회색 |
| All-in | 스택 강조 + 네온 글로우 (BM-3) |
| Empty | 빈 좌석 아이콘 + "OPEN" 라벨 |
| Sitting Out | 회색 + "AWAY" 라벨 |

### 3.3 테이블 레이아웃 템플릿

운영자가 테이블 형태를 선택하면 좌석 배치가 자동 적용된다. 4종 기본 템플릿을 제공한다.

#### 3.3.1 그리드 시스템

테이블 영역을 **12x8 그리드**로 분할한다. 각 좌석은 그리드 셀 좌표 `(col, row)`로 배치된다.

- 보드 카드 영역: 고정 위치 `(C5-C8, R4)` — 이동 불가
- POT 표시: 보드 카드 하단 `(C6-C7, R5)` — 자동 배치
- 좌석은 그리드 셀 위에 드래그 앤 드롭으로 재배치 가능

#### 3.3.2 템플릿 A: 타원형 (Oval) — 기본값

| 좌석 | 그리드 좌표 |
|:----:|:----------:|
| P1 | (C10, R2) |
| P2 | (C11, R3) |
| P3 | (C11, R6) |
| P4 | (C10, R7) |
| P5 | (C3, R7) |
| P6 | (C2, R6) |
| P7 | (C2, R3) |
| P8 | (C3, R2) |
| P9 | (C6, R1) |

#### 3.3.3 템플릿 B: 육각형 (Hexagonal)

| 좌석 | 그리드 좌표 |
|:----:|:----------:|
| P1 | (C4, R7) |
| P2 | (C2, R6) |
| P3 | (C2, R3) |
| P4 | (C4, R2) |
| P5 | (C9, R2) |
| P6 | (C11, R3) |
| P7 | (C11, R6) |
| P8 | (C9, R7) |

#### 3.3.4 템플릿 C: 반원형 (Semicircle)

| 좌석 | 그리드 좌표 |
|:----:|:----------:|
| P1 | (C1, R4) |
| P2 | (C2, R2) |
| P3 | (C3, R1) |
| P4 | (C5, R1) |
| P5 | (C7, R1) |
| P6 | (C9, R1) |
| P7 | (C11, R1) |
| P8 | (C12, R2) |
| P9 | (C12, R4) |

#### 3.3.5 커스텀 배치

| 기능 | 사양 |
|------|------|
| 드래그 앤 드롭 | 좌석을 그리드 셀로 이동. 스냅 적용 |
| 좌석 추가 | 최대 10인까지 확장. [+] 버튼으로 P10 추가 |
| 좌석 제거 | 빈 좌석을 길게 눌러 제거 (최소 2인 유지) |
| 프리셋 저장 | 커스텀 배치를 이름 붙여 저장 (최대 10개) |
| 충돌 방지 | 좌석 간 최소 1셀 간격 유지 (겹침 불허) |

### 3.4 액션 패널 (하단 고정)

화면 하단 1/3에 고정. 게임 상태별로 버튼이 **동적 전환**된다.

| 게임 상태 | 표시 버튼 |
|----------|----------|
| PRE_FLOP | CHECK, BET, CALL, RAISE, FOLD, ALL-IN |
| FLOP~RIVER | CHECK, BET, CALL, RAISE, FOLD, ALL-IN |
| SHOWDOWN | MUCK, SHOW, SPLIT POT |
| SETUP_HAND | NEW HAND, EDIT SEATS |

**UNDO**: 항상 표시. 최대 5단계 되돌리기.

### 3.5 베팅 입력

| 요소 | 사양 |
|------|------|
| Quick Bet | 1/2 POT, 2/3 POT, POT, 2x POT 프리셋 버튼 |
| 숫자 키패드 | 전용 키패드 (시스템 키보드 미사용). BET/RAISE 선택 시 슬라이드업 |
| +/- 조정 | BB 단위 증감 버튼 |
| Min/Max | 최소 레이즈/올인 바로가기 |

### 3.6 화면 상태 전환

| 상태 | 정보량 | 변화 |
|------|:------:|------|
| IDLE | 최소 | 좌석 배치 + 스택만 표시 |
| PRE_FLOP | 기본 | 액션 버튼 활성화, 포지션 뱃지 표시 |
| FLOP | 중간 | 보드 카드 3장 표시, 팟 금액 갱신 |
| TURN/RIVER | 높음 | 보드 카드 추가, 팟/사이드팟 상세 |
| SHOWDOWN | 최대 | 위너 강조, 팟 분배 표시, 핸드 결과 |

### 3.7 Pre-Start Setup

#### 설정 순서 (PS-001~PS-012)

| 단계 | 기능 ID | 내용 | 입력 방식 |
|:----:|:-------:|------|----------|
| 1 | PS-001 | Event Name 입력 | TextField |
| 2 | PS-002 / AT-005 | Game Type 선택 | Dropdown (22종). v1.0은 Texas Hold'em 전용 |
| 3 | PS-008 | Blinds 설정 — SB/BB/Ante 금액 | 3개 숫자 입력 |
| 4 | PS-003 | Min Chip 설정 | 숫자 입력 |
| 5 | PS-009 | Straddle 추가 (선택) | 토글 + 금액 입력 |
| 6 | PS-004~PS-005 | 플레이어 이름 + 칩 스택 입력 | 좌석별 탭 → 이름/스택 입력 |
| 7 | PS-006 / PS-010 | 포지션 할당 — BTN 위치 드래그 | BTN 뱃지를 좌석으로 드래그 |
| 8 | PS-012 | **TRACK THE ACTION** 버튼 | 설정 완료 후 게임 트래킹 시작 |

**Ante 7가지 유형**:

| 유형 | 납부자 | 설명 |
|------|--------|------|
| No Ante | — | Ante 없음 (기본값) |
| Standard | 전원 | 동일 금액 납부. 데드 머니 |
| Button Ante | 딜러만 | 딜러 위치 플레이어만 납부 |
| BB Ante | Big Blind만 | BB가 전원 Ante 대납 (토너먼트 표준) |
| Live Ante | 전원 | Ante가 라이브 머니로 취급 |
| TB Ante | SB + BB | Two Blind 합산 Ante |
| Bring In | 특정 | Stud 계열 전용 (v2.0 Defer) |

### 3.8 게임 진행 루프 — UI 관점

#### 8단계 상태별 AT 화면 변화

| 상태 | 좌석 영역 | 보드 영역 | 액션 패널 | 정보 바 |
|------|----------|----------|----------|---------|
| **IDLE** | 이름+스택만 | 비어있음 | NEW HAND, EDIT SEATS | Hand # |
| **SETUP_HAND** | 포지션 뱃지 표시. 블라인드 자동 수거 | 비어있음 | 대기 (자동 진행) | SB/BB/Ante |
| **PRE_FLOP** | 홀카드 슬롯 활성. Action-on 펄스 | 비어있음 | CHECK, BET, CALL, RAISE, FOLD, ALL-IN | 팟 실시간 |
| **FLOP** | 액션 하이라이트. 폴드 반투명 | 3장 순차 표시 | 동일 | 팟 갱신 |
| **TURN** | 동일 | 4장 | 동일 | 팟 갱신 |
| **RIVER** | 동일 | 5장 | 동일 | 최종 팟 |
| **SHOWDOWN** | 위너 네온 글로우. 핸드 공개 | 5장 + 위닝 핸드명 | MUCK, SHOW, SPLIT POT | 결과 요약 |
| **HAND_COMPLETE** | 팟 지급 → 스택 갱신 → IDLE | 클리어 | — (자동) | Hand # +1 |

#### 예외 흐름

| 예외 | AT 화면 변화 | 운영자 조작 |
|------|------------|-----------|
| **전원 폴드** | 팟 자동 합산 → HAND_COMPLETE | 없음 (자동) |
| **전원 올인** | 보드 자동 전개(런아웃) | 없음 (자동) |
| **Bomb Pot** | SETUP_HAND → FLOP 직행 | 합의 금액 입력 |
| **RFID 실패** | 5초 후 52장 카드 그리드 팝업 | 수동 카드 선택 |

### 3.9 카드 인식과 수동 입력

#### RFID 자동 인식 (AT-020, v3.0)

| 상태 | 카드 슬롯 표시 | 트리거 |
|------|-------------|--------|
| EMPTY | 빈 슬롯 (점선 테두리) | 초기 상태 |
| DETECTING | 노란색 펄스 | RFID 신호 수신 시작 |
| DEALT | 카드 이미지 표시 | UID → 카드 매핑 성공 |
| WRONG_CARD | 빨간 테두리 + 경고 | 중복 카드 감지 |

#### 수동 입력 폴백 (v1.0 기본)

**52장 카드 그리드 팝업**: 4행(♠♥♦♣) x 13열(A~K). 이미 사용된 카드는 회색 비활성화. 게임별: Holdem 2장, PLO4 4장, PLO5 5장 연속 선택.

### 3.10 플레이어 관리

#### 좌석 등록 (PS-004, PS-005)

| 조작 | 동작 |
|------|------|
| 빈 좌석(OPEN) 탭 | 등록 폼: 이름 + 초기 스택 |
| 확인 | 좌석 활성화. 오버레이 Player Graphic 생성 |
| 사진/국기 | 프로필 사진 (80x80 원형) + 국가 코드 |

#### 칩 스택 조정 (AT-023)

좌석 스택 영역 탭 → ADJUST STACK 숫자 키패드 → 스택 즉시 갱신.

#### 포지션 할당 (PS-006, PS-010)

BTN 뱃지 드래그 → SB/BB 자동 재배치. Heads-up(2인)에서는 BTN=SB 규칙 자동 적용.

### 3.11 특수 규칙 UI

#### Bomb Pot

| 항목 | 동작 |
|------|------|
| 트리거 | BOMB POT 버튼 탭 (SETUP_HAND) |
| 상태 전이 | SETUP_HAND → FLOP 직행 |
| 딜러 이동 | Rules 탭 R-02 설정에 따름 |

#### Straddle (PS-009)

Pre-Start에서 Straddle 토글 ON + 금액 입력. 3rd Blind 위치에 STR 뱃지 표시. Sleeper Straddle은 Rules 탭 R-04~R-05 설정에 따름.

> **[v2.0 Defer]** Run It Twice (AT-025), CHOP (AT-024), Miss Deal (AT-026)

### 3.12 키보드 단축키 (AT-014)

#### 액션 단축키

| 키 | 기능 |
|:--:|------|
| F | FOLD |
| C | CHECK / CALL |
| B | BET (숫자 키패드 활성화) |
| R | RAISE (숫자 키패드 활성화) |
| A | ALL-IN |
| Z | UNDO |

#### 좌석/진행 단축키

| 키 | 기능 |
|:--:|------|
| 1~9 | P1~P9 좌석 선택 |
| 0 | P10 좌석 선택 |
| N | NEW HAND |
| H | HIDE GFX 토글 |
| Enter | 입력 확인 |
| Esc | 입력 취소 / 팝업 닫기 |

### 3.13 UNDO와 오류 복구 (AT-013)

| 속성 | 사양 |
|------|------|
| 최대 깊이 | 5단계 |
| 복원 대상 | 액션, 카드 배정, 스택 조정 |
| 시각 피드백 | "UNDO (3)" 잔여 단계 표시 |
| 단축키 | Z |

| 시나리오 | 복구 방법 |
|----------|----------|
| 잘못된 플레이어 폴드 | Z → 폴드 취소 → 올바른 좌석 → 폴드 |
| 베팅 금액 오입력 | Z → 베팅 취소 → 올바른 금액 입력 |
| 카드 오인식 | 슬롯 탭 → 배정 취소 → 재감지 대기 |
| 잘못된 핸드 시작 | Z 연속. 불가 시 Reset Hand(M-11) |

## 4장. 오버레이 그래픽 — HTML 템플릿 기반 재설계

오버레이는 메인 방송 영상 위에 **덧입히는 부가 그래픽**이다. 화면 중앙은 메인 영상이 차지하고, 오버레이는 가장자리(좌/우/상/하)에 배치한다. 폴드한 플레이어는 즉시 제거하여 **액티브 플레이어만** 표시한다.

### 핵심 혁신

| PokerGFX (레거시) | EBS v3.0 (혁신) | 벤치마크 |
|-------------------|-----------------|:--------:|
| 불투명 박스 배경 | Glassmorphism (반투명 프로스트 + backdrop-blur) | BM-3 GGPoker |
| 고정 정보량 | 적응형 정보 밀도 (프리플랍=기본, 리버=최대) | BM-2 Bloomberg |
| 정적 텍스트 | 네온/글로우 이벤트 강조 (올인, 빅 팟) | BM-3 GGPoker |
| 일반 폰트 크기 | Bold 타이포 핵심 수치 (팟, 스택) 시각 강조 | BM-3 GGPoker |
| 고정 배치 (10인 전원 표시) | HTML 템플릿 + 가장자리 배치 (액티브만 표시) | EBS 독자 설계 |

### 배제 6종 (PokerGFX 15종 → EBS 9종)

| 배제 오버레이 | 사유 |
|-------------|------|
| Commentary Header | SV-021 Drop |
| PIP Commentary | SV-022 Drop |
| Countdown | Console Status Bar로 이관 |
| Action Clock | SV-017 Drop |
| Split Screen Divider | 헤즈업 전용, v1.0 Defer |
| Heads-Up History | 헤즈업 전용, v1.0 Defer |

### 4.1 오버레이 설계 철학

#### 부가 그래픽 원칙

| 원칙 | 설명 |
|------|------|
| 메인 영상 우선 | 화면 중앙(약 60% 영역)은 메인 카메라 영상 전용. 오버레이 침범 금지 |
| 가장자리 배치 | Player Graphic은 좌/우/하단 가장자리에만 배치 |
| 액티브 플레이어만 표시 | 폴드한 플레이어는 **즉시 제거** |
| 3인 기본 | 대부분의 실전 핸드는 플랍 이후 2~4인. **3인 액티브가 디폴트 레이아웃** |
| 최소 정보량 | 필수 정보(이름, 스택, 카드, 액션)만 표시 |

#### 표시 규칙

| 이벤트 | 오버레이 동작 |
|--------|-------------|
| 핸드 시작 | 모든 참여 플레이어 Player Graphic 표시 |
| 플레이어 폴드 | 해당 Player Graphic **즉시 페이드아웃 제거** (300ms) |
| 쇼다운 진입 | 남은 액티브 플레이어만 유지 |
| 핸드 종료 | 위너 하이라이트 2초 → 전체 클리어 |

### 4.2 전체 배치도 (1920x1080)

#### 9-Position 그리드 시스템

Player Graphic 그룹과 Board Graphic은 각각 **독립적으로** 9개 위치 중 하나에 배치된다.

| 위치 코드 | 설명 | 기준점 |
|-----------|------|--------|
| TOP-LEFT | 좌상단 | anchor: top-left |
| TOP-CENTER | 중상단 | anchor: top-center |
| TOP-RIGHT | 우상단 | anchor: top-right |
| MID-LEFT | 좌중단 | anchor: mid-left |
| CENTER | 중단 | anchor: center |
| MID-RIGHT | 우중단 | anchor: mid-right |
| BOT-LEFT | 좌하단 | anchor: bottom-left |
| BOT-CENTER | 중하단 | anchor: bottom-center |
| BOT-RIGHT | 우하단 | anchor: bottom-right |

**기본 세팅**: Player Graphic 그룹 = **BOT-LEFT**, Board Graphic = **BOT-RIGHT**

#### 배치 프리셋

| 프리셋 | Player Graphic 위치 | Board Graphic 위치 | 적합한 상황 |
|--------|--------------------|--------------------|-----------|
| **배치 A — 하단 집중** | BOT-LEFT | BOT-LEFT (세로 스택) | 범용, 정면 카메라 |
| **배치 B — 센터형** | BOT-LEFT | BOT-CENTER | 중앙 강조 |
| **배치 C — 일렬형** | MID-LEFT | BOT-LEFT (수직 정렬) | 좌측 집중, 우측 개방 |
| **배치 D — 좌우 반전** | BOT-RIGHT | BOT-LEFT | 좌측 앵글 확보 |
| **기본값 (Default)** | BOT-LEFT | BOT-RIGHT | 일반 방송 |

#### 배치 커스터마이징

| 속성 | 타입 | 설명 | 기본값 예시 |
|------|------|------|-----------|
| grid_position | enum | 9-grid 위치 코드 | BOT-LEFT |
| offset_x | int | X 오프셋 (px) | 20 |
| offset_y | int | Y 오프셋 (px) | -20 |
| width | int | 너비 (px) | 280 |
| height | int | 높이 (px) | 180 |
| visible | bool | 표시 여부 | true |
| z-index | int | 레이어 순서 | 100 |

### 4.3 HTML 템플릿 시스템

모든 오버레이는 **HTML 파일**로 정의된다. OBS/vMix Browser Source로 로드하며, CSS 변수와 JavaScript 바인딩으로 실시간 데이터를 반영한다.

#### 템플릿 구조

```
templates/
  player/
    standard.html      # 기본 Player Graphic
    compact.html        # 축소형
    minimal.html        # 최소형
  board/
    standard.html       # 기본 Board Graphic
    compact.html        # 축소형
  blinds/
    standard.html       # 기본 Blinds 바
  field/
    standard.html       # Field 오버레이
  leaderboard/
    standard.html       # Leaderboard 테이블
  ticker/
    standard.html       # Ticker 스크롤
  strip/
    standard.html       # Strip 상단 바
  custom/               # 사용자 커스텀 템플릿
```

#### CSS 변수 커스터마이징

| CSS 변수 | 용도 | 기본값 |
|----------|------|--------|
| `--player-width` | Player Graphic 너비 | 280px |
| `--player-height` | Player Graphic 높이 | 180px |
| `--player-bg` | 배경색 | rgba(13, 13, 26, 0.65) |
| `--player-blur` | 배경 블러 | 12px |
| `--player-border` | 테두리 | 1px solid rgba(255,255,255,0.08) |
| `--font-primary` | 기본 폰트 | 'Inter', sans-serif |
| `--font-size-name` | 이름 폰트 크기 | 16px |
| `--font-size-stack` | 스택 폰트 크기 | 20px |
| `--color-accent` | 강조 색상 | #00d4ff |
| `--color-allin` | 올인 글로우 | #ff6b35 |
| `--card-width` | 카드 너비 | 60px |
| `--card-height` | 카드 높이 | 84px |

#### 템플릿 변수 바인딩

| 변수 | 타입 | 설명 |
|------|------|------|
| `{{player.name}}` | string | 플레이어명 |
| `{{player.stack}}` | number | 스택 금액 |
| `{{player.cards}}` | array | 홀카드 배열 |
| `{{player.action}}` | string | 현재 액션 |
| `{{player.amount}}` | number | 액션 금액 |
| `{{player.position}}` | string | 포지션 뱃지 |
| `{{player.photo}}` | string | 사진 URL |
| `{{player.country}}` | string | 국가 코드 |
| `{{player.active}}` | bool | 액티브 여부 |
| `{{board.cards}}` | array | 보드 카드 배열 |
| `{{pot.main}}` | number | 메인 팟 |
| `{{pot.side}}` | array | 사이드팟 배열 |
| `{{hand.number}}` | number | 핸드 번호 |
| `{{blinds.sb}}` | number | Small Blind |
| `{{blinds.bb}}` | number | Big Blind |
| `{{blinds.ante}}` | number | Ante |

### 4.4 Player Graphic — HTML 템플릿

핵심 오버레이. 액티브 플레이어에게만 표시된다.

#### 서브 컴포넌트

| ID | 서브 컴포넌트 | 내용 | 표시/숨김 |
|:--:|-------------|------|:---------:|
| A | 사진 | 80x80px 원형 크롭 | 설정 가능 |
| B | 이름 | 최대 16자, 초과 시 말줄임 | 항상 표시 |
| C | 스택 | **Bold 타이포** (BM-3). smart precision | 항상 표시 |
| D | 홀카드 | 2~7장 (게임 타입별) | 항상 표시 |
| E | 액션 | BET/CALL/RAISE/FOLD/ALL-IN + 금액 | 액션 시 |
| F | 국기 | 16x12px 국기 아이콘 | 설정 가능 |
| G | 포지션 | BTN/SB/BB/UTG 등 뱃지 | 항상 표시 |
| H | 에퀴티 바 | 올인 시 승률 프로그레스 바 | 올인 시 |

#### 템플릿 변형 3종

| 변형 | 크기 | 구성 | 적합한 상황 |
|------|------|------|-----------|
| Standard | 280x180px | 전체 서브 컴포넌트 (A~H) | 기본. 3~4인 이하 |
| Compact | 220x120px | 사진 제외 | 5~6인 |
| Minimal | 160x80px | 이름+카드만 | 7인 이상 |

#### Glassmorphism 스타일 (BM-3)

- 배경: `rgba(13, 13, 26, 0.65)` + `backdrop-filter: blur(12px)`
- 테두리: `1px solid rgba(255, 255, 255, 0.08)`
- 그림자: `0 4px 30px rgba(0, 0, 0, 0.3)`

#### 상태별 시각 전환

| 상태 | 시각 효과 |
|------|----------|
| Idle | 이름 + 스택만 |
| Action-on | 밝은 테두리 + 미세 펄스 |
| Acted | 액션 텍스트 애니메이션 등장 |
| Fold | **즉시 페이드아웃 제거** (300ms) |
| All-in | **네온 글로우** (BM-3) + 에퀴티 바 |
| Showdown | 카드 공개 + 위너 하이라이트 |

### 4.5 Board Graphic — HTML 템플릿

커뮤니티 카드 5슬롯 + POT + 사이드팟.

| 서브 컴포넌트 | 내용 |
|-------------|------|
| 카드 슬롯 (5) | Flop 3장 + Turn 1장 + River 1장. 순차 등장 애니메이션 |
| POT | 메인 팟 금액. **Bold 28pt**. smart precision |
| 사이드팟 | 복수 사이드팟 금액 |
| 위닝 핸드명 | "Full House", "Straight" 등 |
| 배니티 텍스트 | 커스텀 문자열 |

#### 템플릿 변형 2종

| 변형 | 크기 | 구성 |
|------|------|------|
| Standard | 480x200px | 전체 서브 컴포넌트 |
| Compact | 360x120px | 카드 + POT만 |

### 4.6 Blinds Graphic — HTML 템플릿

SB/BB/Ante/핸드번호/이벤트 로고를 표시하는 정보 바.

| 구성 | 내용 |
|------|------|
| 블라인드 | SB/BB 금액 (smart precision) |
| Ante | Ante 금액 + 타입 |
| 핸드 번호 | Hand #247 (자동 증가) |
| 이벤트 로고 | 120x40px 이벤트/스폰서 로고 |
| 레벨 표시 | 블라인드 레벨 번호 (토너먼트) |

**표시 조건**: 매 핸드 자동 표시.

#### 배치 옵션

| 옵션 | 위치 |
|------|------|
| 상단 | Status Bar 아래 (y=50) |
| 하단 (기본) | Player Graphic 위 (y=980) |
| 좌측 | 좌측 세로 (x=0, y=450) |
| 우측 | 우측 세로 (x=1720, y=450) |

### 4.7 Field Graphic — HTML 템플릿

토너먼트 잔여/전체 플레이어 수를 표시하는 소형 오버레이.

| 구성 | 내용 |
|------|------|
| 잔여/전체 | 현재 플레이어 수 / 시작 플레이어 수 |
| 평균 스택 | 잔여 플레이어 평균 스택 (선택 표시) |

**표시 조건**: 운영자 수동 토글.

### 4.8 Leaderboard — HTML 템플릿

전체 플레이어 순위/스택/통계를 표시하는 풀스크린 또는 사이드 오버레이.

| 구성 | 내용 |
|------|------|
| 순위 | 스택 기준 내림차순 |
| 플레이어명 | 이름 + 국기 (선택) |
| 스택 | smart precision 적용 |
| 통계 | 승리 횟수, 올인 횟수 등 (컬럼 설정 가능) |
| 페이지네이션 | 10인 초과 시 자동 페이징 (5초 간격) |

**표시 조건**: 운영자 수동 토글.

### 4.9 Ticker — HTML 템플릿

화면 최하단에 가로 스크롤되는 텍스트 오버레이.

| 구성 | 내용 |
|------|------|
| 스크롤 텍스트 | 좌→우 또는 우→좌 연속 스크롤 |
| 구분자 | 메시지 간 `\|` 구분 |
| 내용 소스 | 자동 (핸드 결과, 엘리미네이션) + 수동 (운영자 입력) |

**표시 조건**: 자동 (핸드 결과 발생 시) + 운영자 수동 토글.

### 4.10 Strip — HTML 템플릿

화면 최상단에 모든 플레이어를 가로 요약하는 바 오버레이.

| 구성 | 내용 |
|------|------|
| 플레이어 요약 | 좌석번호:이름 + 스택 (축약) |
| 정렬 | 좌석 순서 또는 스택 내림차순 |
| 폴드 표시 | 폴드 플레이어는 회색 처리 (Strip에서는 제거하지 않음) |
| 누적 승리 | 승리 횟수 표시 옵션 |

**표시 조건**: 운영자 수동 토글.

### 4.11 Cards 에셋 + 게임별 카드 수

#### 에셋 규격

| 속성 | 값 |
|------|-----|
| 총 수 | 52장 (조커 미사용) |
| 크기 | 60x84px (1080p 기준) |
| 포맷 | PNG 투명 배경 |
| 명명 | `{rank}{suit}.png` — 예: `Ah.png`, `2c.png` |
| 카드 백 | `back.png` (비공개 상태) |
| 스타일 | 4색 덱 옵션 (♠ 검정, ♥ 빨강, ♦ 파랑, ♣ 초록) |

#### 게임별 카드 수

| 게임 타입 | 홀카드 수 | 레이아웃 변형 |
|----------|:---------:|-------------|
| Holdem | 2 | 기본 2슬롯 (60x84 x2) |
| PLO4 | 4 | 4슬롯 축소 (48x67 x4) |
| PLO5 | 5 | 5슬롯 축소 (42x59 x5) |
| PLO6 | 6 | 6슬롯 2행 (42x59 x6) |
| 5 Card Draw | 5 | PLO5 동일 |
| 7 Card Stud | 7 | 7슬롯 2행 (38x53 x7) |
| Short Deck | 2 | Holdem 동일 (36장 덱) |

## 5장. 화면 전환과 상태 흐름

기존 수동 전환에서 **게임 상태 연동 자동 전환**으로 진화한다.

### 5.1 게임 상태별 오버레이 변화

| 상태 | 표시 오버레이 | 정보 밀도 | 자동 동작 |
|------|-------------|:---------:|----------|
| IDLE | Blinds, Strip | 최소 | 이전 핸드 정리, 스택 갱신 |
| SETUP_HAND | Blinds, Strip, 액티브 Player만 (이름+스택) | 낮음 | 좌석 배치, 포지션 뱃지 표시 |
| PRE_FLOP | 액티브 Player만 (카드 슬롯 활성), Blinds | 기본 | 홀카드 슬롯 활성화, 액션 대기 |
| FLOP | 액티브 Player만, Board (3장), Blinds, Field | 중간 | 보드 3장 순차 등장 애니메이션 |
| TURN | 액티브 Player만, Board (4장), Blinds, Field | 높음 | Turn 카드 등장, 팟 갱신 |
| RIVER | 액티브 Player만, Board (5장), Blinds, Field | 높음 | River 카드 등장, 최종 팟 |
| SHOWDOWN | 액티브 Player만 (카드 공개), Board, Blinds | 최대 | 카드 공개 + 위너 하이라이트 + 핸드명 |
| HAND_COMPLETE | 결과 요약 → IDLE 전환 | 감소 | 3초 결과 표시 후 자동 정리 |

**액티브 플레이어 배치 자동 재정렬**: 폴드로 인해 액티브 플레이어 수가 변동하면, 남은 Player Graphic이 현재 배치 옵션에 맞춰 자동 재배치된다. 간격은 균등 분배, 트랜지션 400ms ease-out.

### 5.2 이벤트 기반 강조 (BM-3 GGPoker 패턴)

| 이벤트 | 연출 | 지속 시간 |
|--------|------|:---------:|
| **All-in** | 네온 글로우 테두리 + 에퀴티 바 슬라이드인 + 스택 Bold 강조 | 지속 (해소 시까지) |
| **Big Pot** (>50BB) | 팟 숫자 스케일업 + 글로우 펄스 | 2초 |
| **Bad Beat** | 위너 카드 빨간 하이라이트 + 카메라 전환 신호 | 3초 |
| **Showdown Winner** | 위닝 핸드 카드 블링크 + 핸드명 팝업 | 3초 |
| **Fold** | 폴드 플레이어 Graphic 즉시 페이드아웃 (300ms) + 남은 Player 자동 재배치 | 0.3초 |
| **Fold (단독 승리)** | 마지막 생존자 스택에 팟 합산 애니메이션 | 1.5초 |
| **Side Pot 생성** | 사이드팟 텍스트 슬라이드인 | 1초 |

### 5.3 Live vs Delayed 모드

| 항목 | Live 모드 | Delayed 모드 |
|------|----------|-------------|
| 홀카드 | 즉시 공개 (card_reveal=immediate) | 딜레이 버퍼 경과 후 공개 |
| 에퀴티 | 올인 시 즉시 표시 | 딜레이 후 표시 |
| 팟 금액 | 실시간 갱신 | 딜레이 적용 |
| 딜레이 버퍼 | 없음 | 30초 기본 (조절 가능) |

## 6장. 출력 아키텍처

EBS가 **순수 그래픽 렌더러**로서 외부 시스템(OBS/vMix/하드웨어 스위처)과 어떻게 연동하는지를 정의하는 장이다. EBS는 RGBA 그래픽 프레임을 생성하고, NDI 또는 Browser Source로 출력한다. 비디오 합성, 스위칭, 녹화는 외부 시스템의 책임이다.

### 6.1 NDI 출력 파이프라인

NDI(Network Device Interface)는 EBS의 **기본 출력 경로**다. 로컬 네트워크를 통해 저지연 비디오 프레임을 전송한다.

#### 파이프라인 흐름

```
EBS Overlay Engine
  → RGBA 프레임 렌더링 (60fps, 1080p/4K)
  → NDI SDK (grandiose Node.js 바인딩 또는 네이티브 모듈)
  → NDI 스트림 송출 (네트워크)
  → OBS/vMix NDI Source 수신
  → 비디오 합성 (외부)
```

#### NDI 송신자 설정

| 항목 | 값 |
|------|-----|
| SDK | NDI SDK 6.x (NewTek/Vizrt) |
| 바인딩 | `grandiose` (Node.js) 또는 네이티브 C++ 모듈 |
| 프레임 포맷 | RGBA (Alpha 포함) 또는 RGB (Alpha 제외) |
| 해상도 | 1920x1080 (기본) / 3840x2160 (4K) |
| 프레임레이트 | 60fps (기본) / 30fps |
| 스트림 이름 | Console Outputs 탭 O-07 설정값 (기본: "EBS-GFX") |
| Discovery | mDNS 자동 검색. 동일 서브넷 내 모든 NDI 수신자가 자동 감지 |

#### 성능 요구사항

| 항목 | 목표 |
|------|------|
| 렌더링 지연 | < 16ms (1프레임 이내) |
| NDI 인코딩 | < 5ms (SpeedHQ 코덱) |
| 네트워크 지연 | < 1ms (기가빗 LAN) |
| 총 E2E 지연 | < 22ms (1.3프레임 이내) |
| 대역폭 | ~120 Mbps (1080p RGBA 60fps, SpeedHQ) |

### 6.2 Browser Source 보조 출력

NDI 인프라가 없는 환경을 위한 **보조 출력 경로**. OBS Browser Source에서 localhost URL을 직접 로드한다.

#### 파이프라인 흐름

```
EBS Overlay Engine
  → HTML/CSS/JS 렌더링
  → localhost HTTP 서버 (포트: O-10 설정)
  → OBS Browser Source URL 입력
  → Chromium Embedded 렌더링 (OBS 내부)
  → 비디오 합성 (OBS)
```

#### 특성

| 항목 | 값 |
|------|-----|
| URL | `http://localhost:{port}/overlay` |
| 투명도 | CSS `background: transparent` + OBS "Custom CSS" 설정 |
| 데이터 바인딩 | WebSocket 실시간 업데이트 (Console → Overlay Engine → Browser) |
| 프레임레이트 | OBS Browser Source 설정에 의존 (기본 30fps, 최대 60fps) |
| 제한 | NDI 대비 프레임레이트 낮음. OBS Chromium 렌더링 오버헤드 존재 |

#### NDI vs Browser Source 비교

| 비교 항목 | NDI | Browser Source |
|----------|:---:|:-------------:|
| Alpha 채널 | 네이티브 RGBA | CSS transparent + OBS 설정 |
| 프레임레이트 | 60fps 안정 | 30~60fps (OBS 의존) |
| 지연 | < 22ms | 50~100ms (Chromium 오버헤드) |
| 네트워크 요구 | 기가빗 LAN | localhost (네트워크 불필요) |
| 설정 복잡도 | NDI SDK 설치 필요 | URL 입력만으로 즉시 연동 |
| 권장 시나리오 | **프로덕션 방송** | 개발/테스트, 소규모 스트리밍 |

### 6.3 Alpha 채널과 Fill & Key

EBS는 RGBA 프레임(Alpha 채널 포함)을 출력한다. 이는 외부 스위처에서 **키잉 없이 투명 합성**을 가능하게 한다.

#### EBS Alpha 출력 방식

| 모드 | 설명 | 용도 |
|------|------|------|
| RGBA NDI | Alpha 채널이 NDI 스트림에 포함 | OBS/vMix NDI Source로 직접 합성 |
| RGB NDI + Chroma | 배경이 Chroma Color(O-05)로 채워짐 | 레거시 크로마키 워크플로우 |
| Browser Transparent | CSS 투명 배경 | OBS Browser Source 합성 |

#### Fill & Key 분리가 필요한 경우

하드웨어 스위처(ATEM, Ross Carbonite 등)가 Fill & Key 분리 입력을 요구하는 경우:

1. **EBS**: RGBA NDI 스트림 출력 (단일 스트림)
2. **OBS/vMix**: NDI 수신 → Fill(RGB) + Key(Alpha) 분리 출력
3. **하드웨어 스위처**: Fill & Key 2개 SDI/HDMI 입력으로 합성

> **CasparCG 패턴 (BM-4)**: CasparCG는 Server 레벨에서 Fill & Key를 SDI 2포트로 물리 분리 출력한다. EBS는 NDI RGBA 단일 스트림으로 출력하되, Fill & Key 분리는 OBS/vMix 또는 NDI-to-SDI 컨버터에서 처리한다. 이는 EBS가 **그래픽 생성에만 집중**하고, 출력 분리를 외부에 위임하는 설계 원칙과 일치한다.

### 6.4 OBS/vMix 통합 가이드

#### OBS Studio 연동

**NDI 경로** (권장):
1. OBS에 `obs-ndi` 플러그인 설치
2. Sources → NDI Source 추가
3. Source Name에서 "EBS-GFX" (O-07 설정값) 선택
4. Alpha 채널이 자동으로 투명 처리됨

**Browser Source 경로** (보조):
1. Sources → Browser Source 추가
2. URL: `http://localhost:8080/overlay` (O-10 포트)
3. Width/Height: Outputs 탭 Canvas Size(O-01)에 맞춤
4. Custom CSS: `body { background: transparent !important; }`

#### vMix 연동

1. Add Input → NDI / Desktop Capture
2. NDI Source에서 "EBS-GFX" 선택
3. Input Properties → Alpha Channel: On

#### 하드웨어 스위처 연동

1. NDI-to-SDI 컨버터 (예: BirdDog, Magewell) 사용
2. 컨버터에서 Fill & Key SDI 분리 출력 설정
3. 스위처의 Key Input에 연결

## 7장. 제약 조건

### 7.1 화면 크기

| 앱 | 최소 | 권장 | 비고 |
|----|------|------|------|
| EBS Console | 1024x768 | 1920x1080 | 반응형, Top-Preview 레이아웃 (5탭 구조) |
| Action Tracker | 1024x600 | 1280x800 | 태블릿 가로(Landscape) 고정 |
| 오버레이 출력 | 1920x1080 | 1920x1080 | 방송 표준 (4K 스케일링 대응) |
| 오버레이 세로 | 1080x1920 | 1080x1920 | 9:16 모바일 스트리밍 |

### 7.2 터치 제약 (Action Tracker)

| 항목 | 사양 |
|------|------|
| 최소 터치 타겟 | 48x48px (WCAG 2.5.8) |
| 액션 버튼 영역 | 화면 하단 1/3 고정 (thumb zone) |
| 방향 | 가로(Landscape) 고정. 세로 전환 불가 |
| 제스처 | 탭(선택), 스와이프 좌측(폴드), 롱프레스(상세 정보) |
| 멀티터치 | 지원하지 않음 (오입력 방지) |

### 7.3 오버레이 렌더링 제약

| 항목 | 사양 |
|------|------|
| 프레임레이트 | 60fps 최소 (GPU 가속 렌더링) |
| 렌더링 영역 | 1920x1080 고정 캔버스 |
| 투명도 지원 | NDI RGBA 출력 (Alpha 채널 필수) |
| 폰트 | 시스템 산세리프 기본. 커스텀 폰트 로딩 지원 |
| 카드 에셋 | 60x84px PNG 투명 배경 x 52장 + 카드 백 1장 |
| HTML 템플릿 | 각 오버레이당 1개 HTML 파일. CSS 변수 바인딩 필수 |
| 커스터마이징 범위 | 위치/크기 자유 설정. 화면 경계 밖 배치 금지. 최소 크기 60x40px |
| 템플릿 저장 | 사용자 커스텀 템플릿 최대 20개 저장 |

### 7.4 출력 제약

| 항목 | 사양 |
|------|------|
| NDI 출력 | NDI SDK 6.x. RGBA 또는 RGB. SpeedHQ 코덱 |
| NDI 대역폭 | ~120 Mbps (1080p RGBA 60fps) |
| NDI 네트워크 | 기가빗 LAN 필수. 동일 서브넷 내 mDNS discovery |
| Browser Source | localhost HTTP. OBS Browser Source 또는 vMix Web Browser Input |
| Browser 포트 | 기본 8080. 충돌 시 Console Outputs 탭에서 변경 |
| Fill & Key 분리 | EBS 자체 미지원. OBS/vMix 또는 NDI-to-SDI 컨버터에서 처리 |
| 동시 출력 | NDI + Browser Source 동시 활성화 가능 |

### 7.5 레퍼런스

| 자료 | 경로 |
|------|------|
| PokerGFX 주석 이미지 | `docs/01_PokerGFX_Analysis/02_Annotated_ngd/` |
| Whitepaper (247개 요소) | `C:/claude/ui_overlay/docs/03-analysis/pokergfx-v3.2-complete-whitepaper.md` |
| v2.0 기술 아키텍처 | `docs/00-prd/EBS-UI-Design-v2.prd.md` |
| v3.0 레이아웃/오버레이 원본 | `C:/claude/ebs/docs/00-prd/EBS-UI-Design-v3.prd.md` |
| EBS 설계 원칙 | `docs/ebs-eco-system.md` |
| 킥오프 기획서 | `docs/00-prd/ebs-kickoff-2026.md` |

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-06 | v4.0.0 | v3 기반 전면 재설계: Sources 탭 제거(6탭→5탭), Outputs 탭 재설계(NDI/Browser 출력), BM-4(CasparCG)/BM-5(Singular.live) 추가, 6장 출력 아키텍처 신규 | 순수 그래픽 렌더러 원칙 — ebs-eco-system.md §1.1 + ebs-kickoff-2026.md S2 |
