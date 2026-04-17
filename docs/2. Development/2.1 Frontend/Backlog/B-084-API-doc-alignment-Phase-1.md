---
id: B-084
title: "API 경로 문서 준수 전환 (Phase 1)"
status: DONE
completed: 2026-04-17
branch: work/team1/20260417-api-alignment
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# B-084 — Frontend API 경로를 Backend_HTTP.md 명세대로 전환

## 배경

선행 감사(2026-04-17)에서 Frontend가 문서에 반하는 경로를 호출하던 4개 Repository 발견:
- BlindStructureRepository: flat path (`/blind-structures/:id`) → series-nested 필요
- PayoutStructureRepository: flat path → series-nested 필요
- SkinRepository.upload: 전역 `/skins/upload` → skin-specific `/skins/:id/upload`
- TableRepository.rebalance: `/flights/:id/rebalance` → `/tables/rebalance` (Saga)

## 완료 내역

| Repository | 변경 | 호출부 업데이트 |
|-----------|------|-----------------|
| settings_repository.dart | 5개 메소드 series-nested | blind_structure_provider (family) + blind_structure_screen (3곳) |
| payout_structure_repository.dart | 5개 메소드 series-nested | payout_structure_provider (family) + prize_structure_screen (4곳) |
| skin_repository.dart | uploadSkin → createSkin + uploadSkinFile 2-step | 호출부 없음 (향후 UI) |
| table_repository.dart | rebalance body 구조화 (event_flight_id 등) | 호출부 없음 (향후 UI) |

## 검증

- `flutter analyze` — No issues found
- 문서 기준: `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` §BlindStructure/PayoutStructure/Skins/Tables
