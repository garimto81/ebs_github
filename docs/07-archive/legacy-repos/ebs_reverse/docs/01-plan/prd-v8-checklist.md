# PRD v8.0.0 개선 체크리스트

> **생성일**: 2026-02-17
> **대상 문서**: `docs/01-plan/pokergfx-prd-v2.md` (v7.0.0 → v8.0.0)
> **참조 문서**: `docs/02-design/pokergfx-reverse-engineering-complete.md`

---

## A. 문서 구조 개편

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| A-1 | 문서 Chunking 전략 수립 | [~] | 2,169줄 단일 문서 → Part별 분리 검토 |
| A-2 | Part VI: 서비스 인터페이스 설계 분리 | [~] | 별도 문서로 분리 또는 축소 |
| A-3 | 메인 윈도우 섹션 분리 | [~] | Section 18 내 메인 윈도우 상세를 별도 분리 |
| A-4 | 기술 범위 침해 내용 분리/제거 | [~] | 프로토콜 상세(UDP Discovery, TLS 등) → 기획서에서 제거, 기술 설계 문서 참조만 남김 |

## B. 아키텍처 및 모듈 구조 정리

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| B-1 | 전체 아키텍처 흐름 재정리 | [x] | 모듈과 클라이언트 앱이 혼재 → 하나의 일관된 흐름으로 재구성 |
| B-2 | 모듈 분류 명확화: 외부장치/내부장치/소프트웨어 | [x] | Card Recognition=내부장치, Action Tracker=소프트웨어, Viewer Overlay=소프트웨어, ATEM Switcher=외부장치, GFX Console=소프트웨어 |
| B-3 | 미사용 클라이언트 앱 완전 제거 | [x] | ActionClock, CommentaryBooth, Pipcap → 문서에서 완전 삭제 (새 프로젝트에 불필요) |
| B-4 | Pipcap 개념 정의 후 제거 판단 | [x] | 역공학: `pgfx_pipcap` = "다른 VPT 인스턴스 PIP 캡처" → PIP(Picture-in-Picture) 캡처 클라이언트. 원격 서버의 PIP 비디오를 캡처하는 도구. 제거 대상 |
| B-5 | Commentary 관련 내용 정리/제거 | [x] | 정보 보안 경계 다이어그램에서 Commentary 제거 |
| B-6 | 7개 앱 → 4개 핵심 앱으로 축소 | [x] | GfxServer + ActionTracker + StreamDeck + HandEvaluation만 남김 |
| B-7 | 카메라 전환 방식 명확화 | [x] | 역공학 확인: Internal 방식(CAM/SOURCE_MODE 프로토콜 명령) + External 방식(ATEM Switcher) 두 가지 존재. Auto Camera 기능이 내부 소프트웨어 전환 |

## C. Dual Canvas 용어 및 개념 정리

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| C-1 | Dual Canvas 용어 통일 | [x] | "Delayed Canvas" → 잘못된 용어. Dual Canvas는 모두 실시간 송출. Venue Canvas(현장용, 카드 숨김) + Broadcast Canvas(방송용, 카드 공개) |
| C-2 | Delayed 송출 별도 개념으로 분리 | [x] | Dual Canvas와 별도로 "Security Delay Buffer" 개념 추가. 방송 신호 자체를 30-60분 지연하는 것 |
| C-3 | 3계층 아키텍처 다이어그램 용어 수정 | [x] | "Live Canvas와 Delayed Canvas" → "Venue Canvas와 Broadcast Canvas" |
| C-4 | Outputs 탭 설명 용어 수정 | [x] | 전체 문서에서 "Delayed Canvas" → "Broadcast Canvas" 일괄 치환 |
| C-5 | 보안 설계(Part VIII) 용어 수정 | [x] | Trustless Mode, Realtime Mode 설명에서 용어 정리 |

## D. 누락 워크플로우 추가

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| D-1 | DB API 정보 워크플로우 추가 | [x] | PokerGFX → DB API(JSON) → 자막 담당자(정제, Google Sheets/Supabase) → 그래픽 담당자(After Effects) → 렌더링 → 편집 담당자(자막 삽입) → 렌더링 → 송출 담당자 → 최종 방송 |
| D-2 | 2가지 송출 방식 명시 | [x] | ① 자체 오버레이(카메라 + 실시간 합성), ② DB API → 프로덕션 워크플로우(자막 변환 후 합성) |
| D-3 | 핸드 히스토리 DB API 타이밍 수정 | [x] | 핸드 종료 시마다 DB API로 즉시 생성. 모든 핸드 종료 후 일괄이 아님 |
| D-4 | 후처리 다이어그램 수정 | [x] | 본방송(Live) 안에 후처리 포함. 방송 종료 후 별도 작업 거의 없음 |
| D-5 | 플레이어 통계 → GTO 전략 연계 언급 | [x] | 플레이어 통계(VPIP, PFR 등)를 토대로 GTO 전략이 수립되는 맥락 추가 |

## E. 게임 엔진 수정

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| E-1 | 22개 게임 계열별 수량 수정 | [x] | 역공학 enum 기준: Community Card **12개**(0-11), Draw **7개**(12-18), Stud **3개**(19-21) = 22개. PRD의 "13-7-3" 수정 필요 |
| E-2 | Stud 7th Street 종료 조건 명확화 | [x] | 역공학 상태머신: THIRD_STREET → FOURTH → ... → SEVENTH → SHOWDOWN. 7th까지만 진행(7-Card Stud는 최대 7장). 무한 진행 아님 |
| E-3 | Live Ante 개념 상세 설명 추가 | [x] | Live Ante = 앤티가 "라이브 머니"로 취급됨. 즉, 앤티 금액이 첫 베팅 라운드에서 해당 플레이어의 베팅으로 인정되어, 액션이 돌아오면 Check 대신 Raise 옵션 보유. Standard Ante는 데드 머니(팟에 사라지고 추가 블라인드 별도 납부). 캐시 게임에서 주로 사용 |
| E-4 | 토너먼트 BB Ante 전환 배경 추가 | [x] | 2018-2019년 기점, 딜러/플레이어 실수 감소 + 게임 속도 향상 목적으로 대부분 메인 토너먼트가 BB Ante로 전환 |

## F. Lookup Table & DB 문서

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| F-1 | Lookup Table DB 문서 별도 생성 | [x] | 역공학 문서의 Section 6.4 기반. 538개 테이블, ~2.1MB. 원본 시스템 설계 그대로 가져옴 |
| F-2 | 암호화 여부 확인 | [x] | 역공학: `topFiveCards.bin`, `topCard.bin` memory-mapped 파일. 암호화 아님, 바이너리 포맷 |

## G. 통계 및 용어 보강

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| G-1 | 플레이어 통계 축약어 전체 단어 추가 | [x] | VPIP(Voluntarily Put money In Pot), PFR(Pre-Flop Raise), AGR(Aggression Factor), WTSD(Went To ShowDown), 3Bet%(Three-Bet Percentage), CBet%(Continuation Bet Percentage), WIN%(Win Rate), AFq(Aggression Frequency) |
| G-2 | Pip 그래픽 요소 설명 보강 | [x] | 역공학: pip_element = PIP(Picture-in-Picture). 카메라 입력을 캔버스 임의 위치에 배치하는 요소. src_rect(소스 영역), dst_rect(대상 영역), opacity, z_pos, dev_index(캡처 디바이스) |
| G-3 | gRPC 서비스 용어 설명 | [x] | ToggleTrust = Trustless Mode 전환(Live Canvas 홀카드 완전 차단 토글). SetTicker = 뉴스 티커(하단 스크롤 텍스트) 설정 |
| G-4 | 113+ 명령어 카테고리별 상세 보강 | [x] | 각 카테고리의 수량에 포함되는 구체적 명령어 목록 추가. 부록 B와 연계 |
| G-5 | GameInfoResponse 75+ 필드 상세 보강 | [x] | 역공학 Section 8.6 기반: 블라인드(8), 좌석(7), 베팅(6), 게임(4), 보드(5), 상태(6), 디스플레이(7), 특수(6), 드로우(4) = 53+ 핵심 필드. 플레이어별 반복 필드 포함 시 75+ |
| G-6 | Master-Slave 구성 부가 설명 | [x] | "대형 방송" = 멀티테이블 동시 운영(예: WSOP 메인 이벤트, 4-8 테이블). 소형 방송(단일 테이블)은 단일 서버로 충분. 멀티 서버는 렌더링 부하 분산 목적 |

## H. 인터페이스 설계 수정

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| H-1 | 방송 워크스테이션 설명 수정 | [x] | "3개의 장치를 동시에 조작" → "하나의 주 장치(GfxServer)를 중심으로, 필요에 따라 각 장치 사용". Stream Deck은 별개 장치가 아니라 AT/키보드/GfxServer 조작을 키 바인딩 연동하는 외부 장치 |
| H-2 | Action Tracker 입력 방식 다양화 | [x] | 터치스크린 방식뿐 아니라 키보드/입력 제어 방식으로도 설계 가능함을 명시 |
| H-3 | 자동화 그래디언트 "반자동" 개념 설명 | [x] | 반자동 = 시스템이 자동으로 데이터를 준비하지만, 최종 실행은 운영자 확인(클릭/터치)이 필요한 단계. 예: New Hand 시작은 시스템이 준비 완료 상태를 보여주지만, 운영자가 확인 버튼을 눌러야 실행 |
| H-4 | 설정 태스크 플로우: 하드웨어/소프트웨어 병렬화 | [x] | 현재 순차 플로우 → 하드웨어 설정(RFID, 캡처카드)과 소프트웨어 설정(스킨, 게임)을 병렬로 변경 |
| H-5 | 정보 보안 경계 다이어그램 수정 | [x] | Commentary 노드 제거. 현장 모니터(Venue Canvas) + 시청자(Broadcast Canvas) 2가지만 |

## I. 역사 및 배경 정보 보강

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| I-1 | 1세대 Hole Camera 한계 설명 보강 | [x] | 1세대는 카메라 기반이라 생방송이 불가능 → 편집 방송으로만 진행 |
| I-2 | 주요 방송 플랫폼 목록 정리 | [x] | WPT/PokerStars는 자체 시스템과 PokerGFX 병행 운용 추정(확인 불가), Triton Poker는 자체 시스템만 확인 |
| I-3 | RFID 배치도 명칭 변경 | [x] | "RFID 리더 12대 배치도" → "RFID 리더 배치도" |

## J. 목업 개선 (--mockup --bnw --force)

| # | 항목 | 상태 | 상세 |
|:-:|------|:----:|------|
| J-1 | 전체 HTML 목업 아이콘 제거 | [x] | 모든 아이콘을 텍스트/약어로 대체 |
| J-2 | 불필요한 박스 크기 확장 제거 | [x] | 과도하게 큰 박스를 콘텐츠에 맞게 축소 |
| J-3 | 텍스트/노드 박스 크기 적절 설계 | [x] | 가독성과 공간 효율 균형 |
| J-4 | PNG 재캡처 | [x] | 수정된 HTML → PNG 재캡처 + 시각 검증 + Dual Canvas 용어 수정 |

---

## 실행 우선순위

| 순서 | 그룹 | 근거 |
|:----:|------|------|
| 1 | B (아키텍처 정리) | 전체 문서 흐름의 기반 |
| 2 | C (Dual Canvas 용어) | 문서 전체에 영향 |
| 3 | E (게임 엔진 수정) | 팩트 오류 수정 |
| 4 | D (누락 워크플로우) | 핵심 콘텐츠 추가 |
| 5 | G (용어 보강) | 이해도 향상 |
| 6 | H (인터페이스 수정) | UI 설계 정확성 |
| 7 | I (배경 보강) | 보조 정보 |
| 8 | A (문서 구조) | 최종 구조화 |
| 9 | F (Lookup Table DB) | 별도 문서 생성 |
| 10 | J (목업) | 시각 자료 최종 |

---

## Agent Teams 배치 계획

| Team | Agent Type | 역할 | 담당 체크리스트 |
|------|-----------|------|---------------|
| **researcher** | explore-high (opus) | 역공학 문서 심층 분석, 팩트 검증 | E-1~4, F-1~2, G-4~5, B-4, B-7 |
| **restructurer** | executor-high (opus) | 문서 구조 재편, Dual Canvas 용어 통일 | A-1~4, B-1~3, B-5~6, C-1~5 |
| **content-editor** | executor (sonnet) | 내용 수정, 누락 워크플로우 추가 | D-1~5, G-1~3, G-6, H-1~5, I-1~3 |
| **mockup-designer** | designer (sonnet) | HTML 목업 개선 | J-1~4 |
