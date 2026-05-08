---
title: NOTIFY team1 Round2 — CC Settings ⚙ 메뉴 Preferences 탭 제거
owner: team4
tier: internal
confluence-page-id: 3819078286
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078286/EBS+NOTIFY+team1+Round2+CC+Settings+Preferences
---

# NOTIFY — CC 앱 Settings ⚙ 메뉴에서 Preferences 탭 제거

**발신**: team1  
**수신**: team4  
**일자**: 2026-04-15  
**근거 PR**: #4

## 변경 사항

Round 2 에서 팀1 Frontend Settings 가 **6탭 → 5탭** 으로 축소 (`Outputs/Graphics/Display/Rules/Stats`). 구 **Preferences** 탭은 `Lobby/Operations.md` 로 이전되어 Lobby 하위 페이지가 됨.

## CC Flutter 에 미치는 영향

CC 의 `Settings ⚙` 버튼/메뉴가 Lobby 웹 Settings 페이지를 연다면:

1. **Settings 페이지가 이제 5탭만 표시** — Preferences 탭 UI 없음
2. **Preferences 기능 (테이블 Name/Password, Diagnostics, Export) 접근 경로 변경** — 사용자는 Lobby 헤더의 `[Operations ⚙]` 로 이동해야 함
3. CC 에서 직접 Preferences 에 접근하던 단축 경로가 있었다면 **Lobby 복귀 후 Operations 진입** 으로 UX 변경

## 액션

- [ ] team4: CC 의 Settings ⚙ 진입 동작 확인 (Lobby 웹 로딩? 별도 CC 내부 화면?)
- [ ] team4: CC 가 Preferences 기능을 자체 화면으로 보유했다면, Operations 이관 반영 여부 검토
- [ ] team4: CC → Lobby 전환 시 `last_table_id` 세션 데이터 유지되는지 검증 (Round 2 `Session_Restore.md §다중 기기` 정책 호환)

## 참조

- `../../2.1 Frontend/Settings/Overview.md §2` (5탭 구조)
- `../../2.1 Frontend/Lobby/Operations.md`
- `../../2.1 Frontend/Lobby/Overview.md §UI 화면 설계` (Lobby 헤더 진입점 표)
