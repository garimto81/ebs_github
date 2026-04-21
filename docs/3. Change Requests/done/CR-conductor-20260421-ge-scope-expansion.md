---
title: CR-conductor-20260421-ge-scope-expansion
owner: conductor
tier: internal
last-updated: 2026-04-21
relates-to: CR-conductor-20260410-ge-ownership-move (CR-011)
---

# CR: Graphic Editor scope 확장 (BS-08-05/06/07 추가, team5 신설 폐기)

- **제안팀**: conductor
- **제안일**: 2026-04-21
- **결정일**: 2026-04-21 (사용자 직접 결정)
- **영향팀**: [team1, team2]
- **변경 유형**: scope 확장 (CR-011 의 보강, **번복 아님**)
- **변경 근거**: 사용자가 5-Phase critic 결과를 받고 "Option B + Lobby 탭 위치 유지" 명시 결정. CR-011 의 "Lobby 허브 + 메타데이터 편집" 범위는 그대로 유지하되, **추가 3개 영역 (Trigger / DB Mapping / Extension Points)** 을 scope 에 신규 포함.

## 변경 요약

1. **유지**: GE 위치 = `team1` Lobby `/graphic-editor` 탭 (CR-011 결정)
2. **유지**: GE 핵심 책임 = `.gfskin` import + 메타데이터 편집 + Activate (`Graphic_Editor/Overview.md` 그대로)
3. **추가**: BS-08-05 `Trigger_Mapping.md` — 게임 이벤트 → 이미지 호출 trigger 정의 (EBS 자체 DSL)
4. **추가**: BS-08-06 `DB_Mapping.md` — skin field ↔ Backend Schema 매핑 spec
5. **추가**: BS-08-07 `Extension_Points.md` — 확장 plugin slot interface 정의 (구현 out-of-scope, 외부 개발팀 인계용)
6. **폐기**: team5 신설 안 (옹호 critic Option C)
7. **폐기**: 별도 Flutter Desktop 앱 분리 안 (`ebs_ge_studio.exe`)

## CR-011 과의 관계

| 항목 | CR-011 (2026-04-10) | 본 CR (2026-04-21) |
|------|---------------------|---------------------|
| owner | team4 → team1 이관 | team1 **유지** |
| 위치 | Lobby `/graphic-editor` 라우트 | **유지** |
| 핵심 책임 | import + metadata + activate | **유지** |
| 8모드 99컨트롤 | reference-only (out-of-scope) | **유지** (Rive 공식 에디터 위임) |
| 추가 영역 | — | **trigger / db mapping / extension** |

CR-011 의 결정은 모두 유지됨. 본 CR 은 추가 영역만 신설.

## 결정 근거

1. **Critic 5-Phase 병렬 분석**: 옹호 (41/60) vs 반대 (43/60) 거의 동일 강도
2. **자기반박 결과**: 옹호의 WSOP LIVE 3-tool 분리는 도구 분리이지 팀 분리가 아님 → team5 over-extrapolation
3. **반대 critic Option A 안의 zero 인프라 비용** + 사용자 비전 충족
4. **사용자 명시 결정**: "lobby 의 탭 중 하나" — 별도 앱/별도 팀 모두 거부

## 영향

| 팀 | 영향 | 추정 공수 |
|----|------|----------|
| team1 | BS-08-05/06/07 PRD 3 문서 작성 (B-077 PENDING) | 1주 (PRD 단계) |
| team2 | API-07 `Graphic_Editor_API.md` trigger 엔드포인트 추가 검토 (BS-08-05 PRD 후) | 0.5주 |
| Conductor | 본 CR 작성 + B-076 DONE + team1 Backlog 업데이트 | 완료 |
| 정책 변경 | **0건** (team-policy.json v7 그대로) | — |
| Hook 변경 | **0건** | — |

## 처분 항목

- `team5-graphic_editor/` 빈 디렉토리: 사용자 confirm 후 archive 또는 삭제
- `Conductor_Backlog/B-076` PENDING → **DONE**
- 본 CR 위치: `docs/3. Change Requests/done/` (즉시 done — 결정 완료)

## 미확정 — 후속 PRD 작성 전 필요

PRD 작성을 시작하려면 사용자 명세 필요:

1. **트리거 입력 소스 범위** — RFID HAL 이벤트 / CC 액션 / WSOP LIVE 데이터 / Game Engine OutputEvent / 사용자 정의 이벤트 중 어디까지?
2. **트리거 DSL 형태** — 선언적 (YAML/JSON) vs 절차적 (Lua/Python sandbox)?
3. **DB 매핑 방향성** — skin field → Backend Schema 단방향 read-only? 아니면 양방향?
4. **이미지 자산 저장 위치** — `.gfskin` ZIP 내부 (현행) / Backend asset CDN / 양쪽 hybrid?
5. **확장 plugin 의 trust boundary** — 1st-party only? 3rd-party 허용? 권한 모델?

위 5개는 BS-08-05/06/07 PRD 의 핵심 결정점. 사용자 confirm 후 PRD 작성 진행.

## 참고

- Critic Report: `docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md`
- 결정 항목: `docs/4. Operations/Conductor_Backlog/B-076-ge-team5-separation-decision.md`
- PRD 작성 task: `docs/2. Development/2.1 Frontend/Backlog/B-077-ge-scope-expansion-prd.md`
- 현행 GE: `docs/2. Development/2.1 Frontend/Graphic_Editor/Overview.md`
- 선행 CR: `docs/3. Change Requests/done/CR-conductor-20260410-ge-ownership-move.md`
