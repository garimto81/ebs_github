---
id: B-078
title: team1 specs 이미지 ↔ docs/00-reference 동기화 자동화
status: PENDING
source: docs/2. Development/2.1 Frontend/Backlog.md
mirror: none
---

# [B-078] team1 specs 이미지 ↔ docs/00-reference 동기화 자동화
- **날짜**: 2026-04-14
- **teams**: [team1, conductor]
- **설명**: BS-02-lobby 이미지 13개를 미리보기 호환을 위해 `team1-frontend/specs/BS-02-lobby/visual/screenshots/` 에 로컬 복사함 (원본: `docs/00-reference/images/lobby/`). 워크스페이스 외부 `../../../` 경로가 일부 markdown 미리보기 도구에서 차단되므로 short relative path 가 필요. 원본 갱신 시 자동 동기화 스크립트 또는 hook 필요.
- **수락 기준**: `tools/sync_specs_images.py` 작성 + pre-commit 또는 CI 단계에서 drift 검출. team2/3/4 도 재사용 가능한 일반화.
- **관련**: Phase C (2026-04-14), `docs/00-reference/images/lobby/` (19종 ↔ team1 mirror)
