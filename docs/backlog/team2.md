# Team 2 — Backend 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### [B-021] CC WebSocket 연결 추적
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: CC 연결 시 `OperatorConnected` 이벤트 → Lobby로 전파. CC 연결 해제 시 `OperatorDisconnected`. CC 활성 시 설정 잠금 적용.
- **수락 기준**: CC 연결 → Lobby monitor 채널에 OperatorConnected 이벤트 수신.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md, team2-backend/specs/back-office/BO-09-data-sync.md

### [B-022] CC 설정 잠금 매트릭스
- **날짜**: 2026-04-09
- **teams**: [team2, team1]
- **설명**: LOCK (CC 활성 중 변경 불가): game_type, max_players, rfid_reader_id, 삭제, 상태 전환. CONFIRM (다음 핸드부터): blinds, output. FREE (즉시): 오버레이 표시 설정.
- **수락 기준**: CC 활성 중 game_type 변경 → 423 응답. FREE 항목 변경 → 즉시 CC에 반영.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md

### [B-023] 핸드 기록 수신 — CC → BO WebSocket
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: CC로부터 핸드 완료 이벤트 수신. hands, hand_players, hand_actions INSERT (append-only). Event Sourcing 보장.
- **수락 기준**: CC에서 HandCompleted 이벤트 전송 → 3개 테이블에 레코드 생성 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-024] 핸드 조회 API
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /tables/{id}/hands`, `GET /hands/{id}`, `GET /players/{id}/hands`, `GET /hands/{id}/replay`.
- **수락 기준**: 핸드 목록 페이지네이션. 리플레이 데이터 액션 순서 정렬 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-025] 통계 계산 엔진
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: VPIP, PFR, AGR, WTSD, Cumulative P&L, 핸드 수. 핸드 종료 시 증분 업데이트. `GET /players/{id}/stats`, `GET /tables/{id}/stats`.
- **수락 기준**: 10핸드 완료 후 VPIP 계산값이 수동 계산값과 일치.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-026] CC 로컬 버퍼 동기화 프로토콜
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: seq 시퀀스 번호 기반 FIFO. CC 재연결 시 누락 이벤트 일괄 전송. Last Write Wins 충돌 해결.
- **수락 기준**: CC 오프라인 10분 후 재연결 → 누락 이벤트 순서대로 수신 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-09-data-sync.md

### [B-027] Google OAuth 2.0 추가
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /auth/google`, `GET /auth/google/callback`. 기존 Email+2FA에 Google OAuth 옵션 추가.
- **수락 기준**: Google 계정으로 로그인 → JWT 발급 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-02-user-management.md

### [B-028] RFID 리더 등록 관리
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: RFID 리더 CRUD (테이블 할당). `PUT /tables/{id}` — rfid_reader_id 업데이트. RFID 상태 추적 (연결/해제/에러).
- **수락 기준**: RFID 리더 등록 → 테이블에 할당. 상태 변경 → WebSocket 이벤트 전파.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md

### [B-029] 덱 등록 관리
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: RFID 카드 52장 매핑. `POST /tables/{id}/deck-register`. deck_registered 플래그. 덱 교체 이력 (audit_logs).
- **수락 기준**: 52장 매핑 완료 → deck_registered=true. 교체 → audit_logs에 기록.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md

### [B-030] 출력 장비 상태 추적
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: NDI/SDI/RTMP 출력 상태. `GET /tables/{id}/output-status`. output_type, delay_seconds 필드 관리.
- **수락 기준**: output_type 변경 → 상태 조회 시 변경값 반환.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md

### [B-031] Lobby WebSocket 모니터 채널 완성
- **날짜**: 2026-04-09
- **teams**: [team2, team1]
- **설명**: monitor 채널 완성. 모든 테이블 상태 변경 이벤트 Lobby로 전파. TableStatusChanged, SeatUpdated, PlayerJoined/Left.
- **수락 기준**: 테이블 상태 변경 → Lobby 모니터에 실시간 이벤트 수신.
- **관련 PRD**: team2-backend/specs/back-office/BO-09-data-sync.md

### [B-032] 테이블 실시간 상태 이벤트
- **날짜**: 2026-04-09
- **teams**: [team2, team1]
- **설명**: TableStatusChanged, SeatUpdated, PlayerJoined, PlayerLeft WebSocket 이벤트 구현.
- **수락 기준**: 좌석 변경 → 100ms 이내 Lobby에 SeatUpdated 이벤트 수신.
- **관련 PRD**: team2-backend/specs/back-office/BO-09-data-sync.md

### [B-033] 세션 복원
- **날짜**: 2026-04-09
- **teams**: [team2, team1]
- **설명**: user_sessions 저장/조회. 마지막 접속 Series/Event/Flight/Table 기억. 재로그인 시 이전 화면 복원.
- **수락 기준**: 로그아웃 후 재로그인 → 마지막 테이블 화면 자동 복원.
- **관련 PRD**: team2-backend/specs/back-office/BO-02-user-management.md

### [B-034] 오버레이 프리셋 관리
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: skin/layout/animation 프리셋 저장/조회/삭제. `GET/POST/DELETE /configs/presets`.
- **수락 기준**: 프리셋 저장 후 조회 → 동일 설정값 반환.
- **관련 PRD**: team2-backend/specs/back-office/BO-07-system-config.md

### [B-035] Hold'em 핸드 완전 지원
- **날짜**: 2026-04-09
- **teams**: [team2, team3]
- **설명**: Hold'em 전용 핸드 기록 완전 지원 (BS-06 연동). 5-street 보드카드, 사이드팟 처리.
- **수락 기준**: 올인 핸드의 사이드팟 구조 저장 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-036] 플레이어 DB 검색 고도화
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: wsop_id, 국적(country_code), is_demo 필터 추가. 결과 정렬 (이름, 통계 기준).
- **수락 기준**: `?country_code=US` 필터 → 미국 플레이어만 반환.
- **관련 PRD**: team2-backend/specs/back-office/BO-05-player-database.md

### [B-037] 리포팅 — Dashboard API
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/dashboard`. 오늘 총 핸드, 활성 테이블, 활성 플레이어, 평균 핸드 시간, RFID 에러. 5분 갱신.
- **수락 기준**: Dashboard 응답에 6개 지표 모두 포함.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-038] 리포팅 — Table Activity
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/table-activity/{table_id}`. 핸드 수, 평균 팟, 게임 타입 분포.
- **수락 기준**: 특정 테이블의 리포트 데이터 조회 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-039] 리포팅 — Player Statistics
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/player-stats/{player_id}`. VPIP/PFR/AGR/WTSD/P&L.
- **수락 기준**: 플레이어 통계 리포트 데이터 조회 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-041] WSOP LIVE API 폴링 스케줄러
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Series 1시간, Event 5분, Flight 30초, Player 30초 증분 폴링 스케줄러.
- **수락 기준**: 스케줄러 기동 → 각 주기별 WSOP LIVE API 호출 로그 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-10-wsop-live-sync.md

### [B-042] WSOP LIVE UPSERT 로직
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: wsop_id 기준 매칭 → INSERT/UPDATE. source='manual' 필드 보호. API 끊김 시 재시도 + DB 캐시 폴백.
- **수락 기준**: source='manual' 플레이어 → WSOP LIVE 동기화 대상 제외 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-10-wsop-live-sync.md

### [B-043] 동기화 상태 조회
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /sync/wsop-live/status`. `POST /sync/wsop-live` (수동 트리거).
- **수락 기준**: 상태 조회 → 마지막 동기화 시각, 성공/실패 카운트 반환.
- **관련 PRD**: team2-backend/specs/back-office/BO-10-wsop-live-sync.md

### [B-044] PostgreSQL 마이그레이션
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: SQLite → PostgreSQL 마이그레이션 스크립트. Alembic 마이그레이션 버전 관리.
- **수락 기준**: 마이그레이션 후 동일 데이터 PostgreSQL에서 조회 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-01-overview.md

### [B-045] 9종 게임 핸드 기록 지원
- **날짜**: 2026-04-09
- **teams**: [team2, team3]
- **설명**: Omaha, Short Deck, PLO8, Razz, Stud, Stud8, HORSE 등 9종 핸드 기록 구조 지원.
- **수락 기준**: Omaha 핸드 기록 저장 → game_type='Omaha' 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-046] 다중 게임 통계 계산
- **날짜**: 2026-04-09
- **teams**: [team2, team3]
- **설명**: VPIP/PFR/AGR를 게임 타입별로 분리 계산. 종합 통계 + 게임별 세부 통계.
- **수락 기준**: 홀덤/오마하 혼용 세션에서 게임별 VPIP 분리 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-047] Entra ID (Microsoft OAuth) 추가
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Microsoft Entra ID (Azure AD) OAuth 2.0 통합.
- **수락 기준**: Microsoft 계정으로 로그인 → JWT 발급 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-02-user-management.md

### [B-048] 리포팅 — Hand Distribution
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/hand-distribution/{event_id}`. 게임 타입별 핸드 분포, 평균 핸드 시간.
- **수락 기준**: Event 단위 핸드 분포 리포트 생성 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-049] 리포팅 — RFID Health Report
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/rfid-health`. RFID 리더별 에러율, 덱 등록 성공/실패 이력.
- **수락 기준**: RFID 에러 발생 후 리포트에 에러 카운트 증가 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-050] 리포팅 — Operator Activity Report
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/operator-activity/{user_id}`. 운영자별 액션 이력, 테이블 운영 시간.
- **수락 기준**: 운영자 활동 내역 리포트 생성 확인 (Admin만 접근).
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-051] CSV/JSON 내보내기
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: `GET /reports/export/{type}`. CSV/JSON 내보내기. 최대 10MB (~100,000행).
- **수락 기준**: 1,000건 핸드 데이터 CSV 내보내기 → 10MB 이하 파일 생성.
- **관련 PRD**: team2-backend/specs/back-office/BO-11-reporting.md

### [B-052] 자동 백업 스크립트
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: 30분 주기 자동 백업. SQLite dump (Phase 1~2) / PostgreSQL pg_dump (Phase 3+).
- **수락 기준**: 30분 주기 백업 파일 생성 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-07-system-config.md

### [B-053] 감사 로그 아카이브 정책
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Series 종료 후 1년 보관 → 아카이브 → 2년 후 삭제 자동화 스크립트.
- **수락 기준**: 아카이브 대상 로그 → archive 상태로 이동 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-08-audit-log.md

### [B-054] TLS 1.3 HTTPS/WSS 설정
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: TLS 1.3 기반 HTTPS/WSS 설정. 인증서 자동 갱신 (Let's Encrypt).
- **수락 기준**: `https://` 접근 성공. `wss://` WebSocket 연결 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-01-overview.md

### [B-056] 13종 게임 핸드 기록 완전 지원
- **날짜**: 2026-04-09
- **teams**: [team2, team3]
- **설명**: 22종 게임 중 13종 핸드 기록 완전 지원 (Phase 4).
- **수락 기준**: 지원 게임 타입 목록 API 반환값 13종 이상.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md

### [B-057] 스킨 에디터 BO 연동
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: overlay presets API를 통한 스킨 에디터 연동. 실시간 프리셋 적용.
- **수락 기준**: 스킨 에디터에서 프리셋 변경 → 오버레이 실시간 반영.
- **관련 PRD**: team2-backend/specs/back-office/BO-07-system-config.md

### [B-058] Hybrid 인증
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Email + Google OAuth + Entra ID 통합 인증. 계정 연결 관리.
- **수락 기준**: 동일 사용자가 3가지 방법으로 모두 로그인 가능.
- **관련 PRD**: team2-backend/specs/back-office/BO-02-user-management.md

### [B-059] 통계 AI 무인화 기반 준비
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Phase 5 AI 무인화를 위한 데이터 파이프라인 기반 준비. ML 학습용 데이터 포맷 설계.
- **수락 기준**: 핸드 데이터 ML 포맷 내보내기 API.
- **관련 PRD**: docs/01-strategy/PRD-EBS_BackOffice.md

### [B-060] Multi-region 지원
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: time_zone 처리 완전 지원. UTC 저장 + 지역 시간 변환.
- **수락 기준**: 다른 timezone의 클라이언트에서 현지 시간으로 조회 성공.
- **관련 PRD**: team2-backend/specs/back-office/BO-03-tournament-management.md

### [B-061] 고가용성 WebSocket (Redis Pub/Sub)
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: 다중 서버 환경을 위한 Redis Pub/Sub 기반 WebSocket 허브.
- **수락 기준**: 서버 2대 운영 시 어느 서버에 연결되어도 동일 이벤트 수신.
- **관련 PRD**: team2-backend/specs/back-office/BO-09-data-sync.md

### [B-062] 로그 대시보드 (Admin용)
- **날짜**: 2026-04-09
- **teams**: [team2, team1]
- **설명**: Admin용 실시간 로그 대시보드. 에러 알림, 감사 로그 검색 UI.
- **수락 기준**: 대시보드에서 실시간 에러 로그 조회 가능.
- **관련 PRD**: team2-backend/specs/back-office/BO-08-audit-log.md

### [B-063] API Rate Limiting
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: 엔드포인트별 Rate Limiting. 인증 엔드포인트 강화 (5회/분).
- **수락 기준**: 로그인 6회/분 시도 → 429 응답.
- **관련 PRD**: team2-backend/specs/back-office/BO-02-user-management.md

### [B-064] 데이터 보존 정책 자동화
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: 감사 로그 아카이브 + 삭제 정책 자동화 (cron). 핸드 기록 영구 보존.
- **수락 기준**: cron 실행 후 대상 로그 아카이브/삭제 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-08-audit-log.md

### [B-065] 성능 모니터링
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: Prometheus + Grafana 연동. API 응답 시간, WebSocket 연결 수, DB 쿼리 시간.
- **수락 기준**: Grafana 대시보드에서 실시간 메트릭 조회 가능.
- **관련 PRD**: team2-backend/specs/back-office/BO-01-overview.md



### [NOTIFY-LEGACY-CCR-016] [LEGACY] 검토 요청: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-016-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md, contracts/specs/BS-02-lobby/BS-02-03-table.md, contracts/specs/BS-03-settings/BS-03-04-rules.md, contracts/specs/BS-01-auth/BS-01-02-rbac.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-017] [LEGACY] 검토 요청: BS-05에 AT 화면 체계(AT-00~AT-07) 도입
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-017-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md, contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-018] [LEGACY] 검토 요청: BS-05 서버 프로토콜 매핑 및 내부 모호성 해소
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-018-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md, contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-020] [LEGACY] 검토 요청: API-03 RFID HAL 에러 복구 및 생명주기 시나리오 보강
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-020-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-03-rfid-hal-interface.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-021] [LEGACY] 검토 요청: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-021-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-022] [LEGACY] 검토 요청: BS-04 AT-05 RFID Register 화면 명세 추가
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-022-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md, contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-025] [LEGACY] 검토 요청: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-025-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md, contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md, contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md, contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-012] 검토 요청: .gfskin ZIP 포맷 단일화 및 DATA-07 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-012-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/data/DATA-07-gfskin-schema.md, contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-011] 검토 요청: Graphic Editor 소유권 Team 4 → Team 1 이관 (Lobby 허브)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-011-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md, contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md, contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md, contracts/specs/BS-00-definitions.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-014] 검토 요청: GE 요구사항 ID prefix 재편 (범위 축소 반영)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-014-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/specs/BS-00-definitions.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-013] 검토 요청: API-07 Graphic Editor 엔드포인트 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-013-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/api/API-07-graphic-editor.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-015] 검토 요청: API-05에 skin_updated WebSocket 이벤트 추가

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-015-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-026] 검토 요청: BS-04 AT-05 RFID Register 화면 명세 추가

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-026-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md, contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-023] 검토 요청: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-023-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-024] 검토 요청: API-05 WriteGameInfo 프로토콜 22+ 필드 스키마 완전 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-024-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-027] 검토 요청: BS-05-07 Statistics 화면 (AT-04) 신규 작성

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-027-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-07-statistics.md, contracts/specs/BS-05-command-center/BS-05-00-overview.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-028] 검토 요청: BS-05에 AT 화면 체계(AT-00~AT-07) 도입

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-028-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md, contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-029] 검토 요청: BS-05 Lobby → BO → CC Launch 플로우 상세 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-029-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/api/API-01-backend-api.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-031] 검토 요청: BS-05 서버 프로토콜 매핑 및 내부 모호성 해소

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-031-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md, contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-035] 검토 요청: BS-07 Overlay Layer 1/2/3 경계 및 자동화 범위 명시

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-035-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md, contracts/specs/BS-07-overlay/BS-07-00-overview.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-036] 검토 요청: BS-07 Security Delay (홀카드 공개 지연) 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-036-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md, contracts/api/API-04-overlay-output.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-037] 검토 요청: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-037-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md, contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md, contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md, contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-038] 검토 요청: Google OAuth Phase 1 도입
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-038-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기

## IN_PROGRESS

_현재 진행 중인 항목 없음_
