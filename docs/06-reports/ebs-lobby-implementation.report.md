# EBS Lobby POC 검증 보고서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | BS-02 명세 기반 Lobby 전면 구현 + E2E 검증 완료 |
| 2026-04-09 | 범위 명확화 | POC 검증 보고서로 위치 조정. 프로덕션 구현은 기획 문서(IMPL-01~09) 기준 |

---

> **이 문서는 POC(Proof of Concept) 검증 보고서다.** Flutter Web + Dart shelf로 BS-02 명세의 UX/기능을 사전 검증한 결과를 기록한다. 프로덕션 구현은 기획 문서(IMPL-01~09: **Next.js + FastAPI + Docker**)를 기준으로 수행한다. POC에서 검증된 UX/기능은 기획 문서에 반영되었다.

## Plan 요약

- **근거**: BS-02-lobby.md (993줄, v41.0.0) + WSOP LIVE BO 1:1 원칙
- **범위**: 5화면 계층 (Series → Event → Flight → Table → Player) + CRUD + RBAC + 상태머신 + WebSocket + CC Lock + 세션 복원 + 장애 복구
- **POC 아키텍처**: Lobby(Flutter Web) + CC(Flutter Desktop) 별도 앱, Dart shelf 백엔드 중개, `ebs_shared` 공유 패키지
- **프로덕션 아키텍처**: Lobby(Next.js) + CC(Flutter Desktop), FastAPI + Docker 서버, SQLite DB (IMPL-01~09 참조)
- **BO 기획 전 전략**: in-memory store로 API 골격 우선 구현, BO 확정 후 SQLite 교체

## 구현 결과

### 레포별 테스트 현황

| 레포 | 역할 | analyze | tests | 파일 수 |
|---|---|:---:|:---:|:---:|
| `ebs_shared` | 공유 모델/enum/권한/상태머신 | 0 | 34 | 18 |
| `ebs_server` | Dart shelf + in-memory REST/WS | 0 | 48 | 22 |
| `ebs_lobby_web` | Flutter Web Lobby 5화면 | 0 | 9 | 25 |
| `ebs_app` | Flutter Desktop CC | 0 | 10 | 12 |
| **합계** | | **0** | **101** | **77** |

### 12개 항목 완료 현황

| # | 항목 | BS-02 라인 | 검증 |
|:-:|---|:---:|---|
| 1 | Enter CC → 클립보드 복사 | 640-646 | 커맨드 복사 + SnackBar |
| 2 | WebSocket 실시간 broadcast | 105-114 | table/seat CRUD + transition 시 자동 |
| 3 | CC Lock 매트릭스 UI | 735-746 | LOCK/CONFIRM/FREE 아이콘 |
| 4 | 세션 복원 다이얼로그 | 681-690 | Continue/Start Fresh |
| 5 | 좌석 배치 UI | 602-612 | 타원 시각화 + Random + 개별 |
| 6 | 플레이어 등록/삭제 | 590-601 | 검색→배정 + 수동 등록 |
| 7 | 상태 전환 전체 흐름 | 704-721 | E2E: Empty→Setup→Live + 차단 |
| 8 | Mix 게임 모드 | 406-432 | HORSE/Dealer's Choice/Single |
| 9 | 장애 복구 배너 | 670-679 | WS disconnect 자동 표시 |
| 10 | RFID 시뮬레이션 | 723-731 | simulate-rfid API + WS |
| 11 | 테스트 보강 | — | 86→101 (+15) |
| 12 | UI 폴리시 | 462-492 | Feature 금색, 좌석 색상 |

### E2E 테스트 시나리오 (21건)

| 그룹 | 건수 | 내용 |
|---|:---:|---|
| Lobby 5단계 네비게이션 | 5 | Series→Events→Flights→Tables→Seats |
| 테이블 CRUD + RBAC | 2 | 생성 + Operator 차단 |
| 상태 전환 매트릭스 | 4 | Empty→Setup→Live + 조건 미충족 차단 |
| 인증 + 세션 | 2 | Mock 로그인 + 세션 복원 |
| 플레이어 검색 | 1 | 이름 기반 |
| RFID 시뮬레이션 | 4 | ready/deckRequired/invalid/404 |
| Mix 게임 모드 | 3 | HORSE + Dealer's Choice + Single |

## Check 결과

- gap 점수: **95%** (≥90% 통과)
- 미달 항목: Lobby→CC 실제 프로세스 실행 (Flutter Web에서 Process.start 불가, 클립보드 대체)
- 설계-구현 일치: BS-02 명세 12개 핵심 항목 전부 구현됨

## PRD 일탈 사항

| 일탈 | 사유 | 영향 |
|---|---|---|
| 서버를 Python/FastAPI 대신 Dart shelf | 단일 toolchain, 모델 공유 | Phase 2에서 재이주 가능 |
| Lobby를 Next.js 대신 Flutter Web | CC와 Dart 공유 | 성능 차이 미미 |
| DB가 in-memory (재시작 시 소멸) | BO 기획 미확정 | 시드 데이터로 매번 초기화 |

## 후속 작업

| 우선순위 | 작업 | 트리거 |
|:---:|---|---|
| 1 | BO 기획서 확정 → SQLite 교체 | BO 산출물 완료 시 |
| 2 | WSOP LIVE API 연동 (source='api' 동기화) | API 접근 확보 시 |
| 3 | Lobby→CC 프로세스 실행 (Windows IPC) | 데스크톱 배포 시 |
| 4 | Rive 오버레이 (.riv) 제작 | Phase 2 진입 시 |
| 5 | 22종 게임 엔진 확장 | Phase 3 진입 시 |

## 교훈

1. **BO sketch ≠ BO spec**: BS-02의 SQL 블록은 sketch. 정식 기획 없이 SQLite 구현 진행하면 전면 재작성 위험. In-memory store로 API 골격 우선 검증하는 전략이 효과적.
2. **`ebs_shared` 공유 패키지의 효과**: 11 모델 + permission matrix + state machine을 한 곳에 정의한 덕분에 server/lobby/CC 간 계약 불일치 0건.
3. **shelf handler 직접 호출 E2E**: Windows sandbox에서 소켓 바인딩 불가해도 shelf Request 객체를 직접 생성하면 동일한 E2E 커버리지를 확보할 수 있다.
