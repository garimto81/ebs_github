# impl — 기술 구현 설계 문서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 구현 설계 문서 네비게이션 |

---

## 개요

이 디렉토리는 EBS 3-앱 아키텍처의 **기술 구현 설계 문서**를 포함한다. 행동 명세(BS-00~07)와 API 문서(API-03~06)를 기반으로 실제 구현 시 참조할 기술 결정 사항을 기술한다.

## 문서 목록

| ID | 제목 | 핵심 내용 |
|----|------|----------|
| IMPL-01 | 기술 스택 선정 | 3-앱 기술 스택 근거, 대안 기각 사유 |
| IMPL-02 | 프로젝트 구조 | 레포 분리 전략, 패키지 레이아웃 |
| IMPL-03 | 상태 관리 | CC Riverpod Provider 트리, Lobby 웹 상태 |
| IMPL-04 | 라우팅 | CC go_router, Lobby 라우팅, 가드 |
| IMPL-05 | 의존성 주입 | Real/Mock HAL 교체, 테스트 패턴 |
| IMPL-06 | 에러 처리 | 에러 분류, 복구 전략, 사용자 노출 |
| IMPL-07 | 로깅 | 로그 레벨, 필드, 저장 전략 |
| IMPL-08 | 테스트 전략 | 테스트 피라미드, Mock RFID 시나리오 |
| IMPL-09 | 빌드/배포 | 빌드 타겟, Docker, 환경 변수 |

## 참조 문서

| 문서 | 경로 |
|------|------|
| 용어 정의 | `docs/02-behavioral/BS-00-definitions.md` |
| RFID HAL 인터페이스 | `docs/api/API-03-rfid-hal-interface.md` |
| WebSocket 프로토콜 | `docs/api/API-05-websocket-events.md` |
| 인증/세션 | `docs/api/API-06-auth-session.md` |
| DB 스키마 | `docs/data/DATA-04-db-schema.md` |
| BO 아키텍처 | `docs/back-office/BO-01-overview.md` |
| Foundation PRD | `docs/01-strategy/PRD-EBS_Foundation.md` |
