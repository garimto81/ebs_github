---
id: B-066
title: SSOT compliance recovery (Phase C)
backlog-status: open
source: docs/4. Operations/Reports/2026-04-17_SSOT_Audit.md
mirror: none
---

# [B-066] SSOT compliance recovery (Phase C 잔여 항목)

- **날짜**: 2026-04-17
- **teams**: [team2]
- **배경**: 2026-04-17 전수 감사(`docs/4. Operations/Reports/2026-04-17_SSOT_Audit.md`) 결과 REST ~47% / Auth ~32% / DB+BO ~40% 준수. Phase A (Top 10 차단급) + Phase B.1 (CCR-050) + Phase B.2 (sync 네임스페이스) + Phase D (CI gate) 이 2026-04-17 완료. 본 항목은 Phase C 잔여 작업.

## 요구사항 (Phase C — 약 2~3주 규모)

### 1. BlindStructure 시리즈 스코프 (Backend_HTTP.md L758-763, 8 endpoints)
- `GET /series/:id/blind-structures`
- `GET /series/:id/blind-structures/templates/:blind_type`
- `GET /series/:id/blind-structures/:bs_id`
- `POST /series/:id/blind-structures`
- `PUT /series/:id/blind-structures/:bs_id`
- `DELETE /series/:id/blind-structures/:bs_id`
- CCR-049: blind_structures 테이블에 `series_id` FK, `is_template`, `creator_user_id`, `blind_type`, `is_auto_renaming`, `details` JSON 컬럼 추가 (Alembic migration)
- 기존 플랫 `/blind-structures/*` 는 deprecated alias 유지

### 2. PayoutStructure 시리즈/Flight 스코프 (Backend_HTTP.md L815-821, 7 endpoints)
- `GET /series/:id/payout-structures`, `POST`, `GET :ps_id`, `PUT`, `DELETE`
- `GET /flights/:id/payout-structure`, `PUT /flights/:id/payout-structure`
- Schema.md §4 payout_structures + payout_structure_levels 전면 재설계 (entries JSON vs level rows 결정)

### 3. Skin 파일 I/O (Backend_HTTP.md L747-750, 3 endpoints)
- `POST /skins/:id/upload` — `.gfskin` 파일 업로드
- `GET /skins/:id/download` — `.gfskin` 다운로드
- `POST /skins/:id/duplicate` — 깊은 복제
- GFSkin 패키지 스키마 정의 (GFSkin_Schema.md 참조)

### 4. DB 스키마 마무리 (DB+BO 감사 Top 5 중 미해결)
- `event_flights.status` 완전 INT 전환 (어댑터만 현재, 컬럼은 여전히 TEXT)
  - Clock FSM 의 "paused" 상태를 별도 `clock_status` 컬럼으로 분리 선행
- `users.is_suspended` / `is_locked` / `last_failed_at` / `idx_users_status` (CCR-053)
- `blind_structures` 필드 6종 (CCR-049): series_id FK, is_template, creator_user_id, blind_type, is_auto_renaming, details JSON
- `output_presets` 필드 3종: security_delay_sec, chroma_key, is_default
- `events.status` / `tables.status` / `decks.status` CHECK 제약 추가
- `sync_cursors` Redis/DB 영속화
- Sync_Protocol Fallback Queue (Redis Stream)
- SeatFSM `EMPTY→MOVED`, `MOVED→PLAYING` 전이 추가

### 5. Auth 보안 정책 (감사 Top 5 잔여)
- CCR-052 Rate Limiting (카테고리별 한계 + 헤더 + IP whitelist)
- Lockout 정책 5회/30분 → 10회/영구 (CCR-048)
- Suspend vs Lock 이원화 (CCR-053)
- Permission Bit Flag (CCR-017): `compute_permission()`, JWT claim, 응답 필드
- `DELETE /auth/session` 메서드 정렬 (현재 POST /auth/logout)
- `/auth/exchange` (one_time_token → JWT, CC Lobby-Only Launch)
- Token 만료/무효/취소 에러 코드 분리 (AUTH_TOKEN_EXPIRED / REVOKED / INVALID)

## 수락 기준
- `python tools/ssot_route_diff.py` exit 0 (현재 16 missing)
- SSOT 대비 REST 준수율 ≥ 95%
- pytest 전체 통과 (현재 210+ → 목표 250+)
- Auth CCR-048/052/053 정책 3종 모두 반영

## 관련 문서
- `docs/4. Operations/Reports/2026-04-17_SSOT_Audit.md` — 통합 감사 보고서
- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` — REST SSOT
- `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` — Auth SSOT
- `docs/2. Development/2.2 Backend/Database/Schema.md` — DB SSOT
