# Back Office (BO) 문서 네비게이션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | BO 문서 12개 초기 구성 |
| 2026-04-09 | 구조 축소 | 12개 → 3개 축소. BS/API/DATA 중복 제거, 고유 콘텐츠만 잔류 |

---

## 개요

Back Office는 Lobby(웹)와 Command Center(Flutter) 사이의 **간접 데이터 공유 계층**이다. FastAPI + SQLite 백엔드로 REST API와 WebSocket을 제공한다.

## 문서 목록

| ID | 제목 | 설명 |
|----|------|------|
| BO-01 | [Architecture](BO-01-overview.md) | 3-앱 아키텍처, 기술 스택, Phase별 진화, 성능 요구사항 |
| BO-02 | [Sync Protocol](BO-02-sync-protocol.md) | Lobby↔BO↔CC 동기화 정책, 오프라인 대응, 충돌 해결, WSOP LIVE 폴링 |
| BO-03 | [Operations](BO-03-operations.md) | 감사 로그 기록 대상/보존 정책, 리포트 카탈로그, 내보내기 |

## SSOT 참조

BO 문서는 **정책과 아키텍처**만 정의한다. 상세 구현은 아래 문서가 SSOT:

| 영역 | SSOT 문서 |
|------|----------|
| API 엔드포인트 | API-01 Backend Endpoints |
| WebSocket 이벤트 | API-05 WebSocket Events |
| WSOP LIVE API 계약 | API-02 WSOP LIVE Integration |
| 인증/보안 | API-06 Auth & Session |
| 데이터 모델 | DATA-02 Entities |
| ER 다이어그램 | DATA-01 ER Diagram |
| 사용자 관리/RBAC | BS-01 Auth |
| 대회/테이블/플레이어 CRUD | BS-02 Lobby |
| Settings 컨트롤 | BS-03 Settings |

## 참조

- 용어/상태/트리거 정의: `contracts/specs/BS-00-definitions.md`
- Lobby 행동 명세: `contracts/specs/BS-02-lobby/BS-02-lobby.md`
- 트리거 경계: `contracts/specs/BS-06-game-engine/BS-06-00-triggers.md`
