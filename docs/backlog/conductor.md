# Conductor — 크로스팀/인프라 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### [B-040] Phase 2 통합 테스트 + E2E
- **날짜**: 2026-04-09
- **teams**: [team0, team2, team4]
- **설명**: CC WebSocket E2E 테스트. 핸드 기록 → 통계 계산 플로우. 버퍼 재연결 테스트.
- **수락 기준**: 전체 테스트 통과. CC 오프라인 → 재연결 시나리오 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-09-data-sync.md

### [B-055] Phase 3 통합 테스트 + 부하 테스트
- **날짜**: 2026-04-09
- **teams**: [team0, team2]
- **설명**: 다중 게임 E2E 테스트. WSOP LIVE 동기화 E2E. 동시 접속 100명 부하 테스트.
- **수락 기준**: 부하 테스트 API 응답 p99 < 200ms.
- **관련 PRD**: team2-backend/specs/back-office/BO-01-overview.md

### [B-066] 재해 복구 절차 문서화
- **날짜**: 2026-04-09
- **teams**: [team0, team2]
- **설명**: DB 복구, 서버 재시작, 데이터 일관성 복구 절차 문서화.
- **수락 기준**: 문서에 따라 DB 복구 절차 실습 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-01-overview.md

### [B-067] Phase 4 전격 운영 검증
- **날짜**: 2026-04-09
- **teams**: [team0, team1, team2, team3, team4]
- **설명**: 실제 운영 환경에서 전체 기능 검증. 운영자 교육 완료.
- **수락 기준**: 운영 시나리오 체크리스트 100% 통과.
- **관련 PRD**: docs/01-strategy/PRD-EBS_BackOffice.md

### [B-069] team3-engine 게임 PRD Confluence 동기화 상태 확인
- **날짜**: 2026-04-10
- **teams**: [team3, team0]
- **설명**: `team3-engine/specs/games/PRD-GAME-01~04.md`가 CLAUDE.md §Games PRD 규칙(markdown 링크 금지, 독립 완결)을 준수하는지 재확인하고, Confluence 업로드 상태(Page ID 매핑)가 `reference_confluence_pages` 메모리와 일치하는지 검증.
- **수락 기준**: 4개 PRD 파일 모두 `[text](url)` 0건, 각 파일에 대응하는 Confluence 페이지가 존재하거나 업로드 대기 항목이 명시됨.
- **관련 PRD**: CLAUDE.md §Games PRD 규칙, team3-engine/specs/games/


## IN_PROGRESS

_현재 진행 중인 항목 없음_


## DONE

| B-# | 제목 | 완료일 | 커밋/PRD |
|-----|------|--------|----------|
| B-001 | FastAPI 프로젝트 초기화 | 2026-04-09 | feat/bo |
| B-002 | DB 스키마 — SQLAlchemy ORM | 2026-04-09 | feat/bo |
| B-003 | JWT 인증 — 로그인/토큰/2FA | 2026-04-09 | feat/bo |
| B-004 | RBAC 미들웨어 | 2026-04-09 | feat/bo |
| B-005 | 사용자 관리 CRUD | 2026-04-09 | feat/bo — routers/users.py |
| B-006 | 시스템 설정 API | 2026-04-09 | feat/bo — routers/configs.py |
| B-007 | WebSocket 허브 기반 구조 | 2026-04-09 | feat/bo — websocket/hub.py |
| B-008 | ConfigChanged WebSocket 이벤트 | 2026-04-09 | feat/bo — routers/configs.py |
| B-009 | 감사 로그 자동 기록 | 2026-04-09 | feat/bo — routers/audit.py |
| B-010 | Mock RFID 모드 설정 | 2026-04-09 | feat/bo — seeds/config_defaults.py |
| B-011 | 대회 관리 — Series CRUD | 2026-04-09 | feat/bo — routers/series.py |
| B-012 | 대회 관리 — Event CRUD + FSM | 2026-04-09 | feat/bo — routers/events.py |
| B-013 | 대회 관리 — Flight CRUD | 2026-04-09 | feat/bo — routers/events.py |
| B-014 | 테이블 관리 — 기본 CRUD | 2026-04-09 | feat/bo — routers/tables.py |
| B-015 | 테이블 관리 — TableFSM + 상태 전이 | 2026-04-09 | feat/bo — services/table_fsm.py |
| B-016 | 테이블 관리 — 좌석 관리 | 2026-04-09 | feat/bo — routers/tables.py |
| B-017 | 플레이어 관리 | 2026-04-09 | feat/bo — routers/players.py |
| B-018 | Mock 데이터 시드 스크립트 | 2026-04-09 | feat/bo — routers/sync.py |
| B-019 | 표준 에러 응답 + 헬스체크 | 2026-04-09 | feat/bo — middleware/error_handler.py, routers/health.py |
| B-020 | Phase 1 통합 테스트 | 2026-04-09 | feat/bo — tests/ (64 passed) |
| B-070 | CCR 승격 워크플로우 v3 전환 (배치 계획 모드) | 2026-04-10 | CLAUDE.md §계약 관리, docs/05-plans/ccr-inbox/README.md, tools/ccr_promote.py (docstring) — per-draft 루프를 일괄 Read → 그룹핑 → 통합 Edit → 마감 배치 워크플로우로 변경. CLI 계약 불변. |
| B-071 | CCR-010~036 일괄 승격 + contracts/ 실제 적용 | 2026-04-10 | 28 CCR 처리 (5 skipped + 22 applied + 1 REJECT). contracts/ +1,612/-57 lines (22 modified). 신규 파일 18개 (BS-08 5, BS-05 4, BS-07 3, BS-04 1, BS-02 2, BS-01 1, DATA-07, API-07). v3 배치 모드 첫 적용. promoting/CCR-010~037 로그 파일. |
| B-072 | Integration test 시나리오 16건 작성 | 2026-04-10 | integration-tests/scenarios/ — Group 10~19 Auth/Idempotency/Saga/Replay, 20~29 Graphic Editor, 30~39 CC Launch/Recovery/WriteGameInfo, 40 Security Delay, 50 RFID Deck, 60~62 WSOP parity. 나머지 TODO는 `_TODO.md`. CCR 로그 체크리스트 15건 업데이트. |
| B-073 | CCR-037 REJECT (SUPERSEDED by CCR-011) | 2026-04-10 | team4 bs08-graphic-editor-new draft가 Conductor CCR-011 (GE ownership move to Team 1 Lobby) 와 충돌. 사용자 결정: REJECT. promoting/CCR-037 로그에 REJECT 사유 + CCR-011 대체 매핑 명시. |
