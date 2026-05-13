---
title: Doc Causality Audit (Cycle 22 W1)
owner: s10-a
tier: internal
last-updated: 2026-05-13
audience-target: 모든 stream owner + conductor
related-tools: doc-discovery skill (~/.claude/skills/doc-discovery/)
---

# Doc Causality Audit — Cycle 22 Wave 1

## §1 Context — 왜 이 audit이 필요한가

Cycle 19/20/21 동안 다중 stream에서 cross-cutting 변경이 누적 머지되었다. 특히:

- **Cycle 20 #436** — S7 chip_count_synced WebSocket webhook 신규 (chip count contract)
- **Cycle 21 W1 (PR #443 in-flight)** — S2 Lobby 4 진입 시점 동기 (Foundation §A.1 cascade)
- **Cycle 20 #429~** — S7 BO API 92 endpoints 확장

세 변경은 모두 정본 spec 문서(Foundation.md, Lobby/Overview.md, WebSocket_Events.md)를 손대거나 새로운 contract를 추가했다. 그러나 **외부 PRD ↔ 정본 spec의 derivative-of 양방향 정합** (룰 20)이 자동으로 보장되지 않는다 — `tools/spec_drift_check.py`는 contract 수준의 drift만 감지하며, "Foundation에 신규 chip count contract 역참조가 누락" 같은 양방향 link 비대칭은 별도 검증이 필요하다.

본 audit은 `doc-discovery` skill 의 PageRank + reverse-dependency graph를 사용하여 변경 hotspot의 cascade 누락을 사전 식별하고, Cycle 22 Wave 분배 근거를 산출한다.

---

## §2 PageRank 중심성 분석 (top 30 — .md only)

`doc_discovery.py --rank --top 100` 결과에서 순수 코드 심볼(pathlib, sys, json 등)을 제외한 markdown 파일 상위 30:

| # | PageRank | 파일 |
|--:|---------:|------|
| 1 | 0.003428 | docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/ebs-ui-layout-anatomy.md |
| 2 | 0.002514 | docs/2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md |
| 3 | 0.002170 | docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/archive/ebs-ui-design-strategy.md |
| 4 | 0.001813 | docs/2. Development/2.3 Game Engine/Behavioral_Specs/Betting_and_Pots.md |
| 5 | 0.001813 | docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md |
| 6 | 0.001517 | docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/archive/EBS-Skin-Editor.prd.md |
| 7 | 0.001381 | docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/archive/ebs-ui-design-plan.md |
| 8 | 0.001113 | docs/2. Development/2.3 Game Engine/Behavioral_Specs/Lifecycle_and_State_Machine.md |
| 9 | 0.000996 | **docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md** ⭐ |
| 10 | 0.000975 | docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/prd-skin-editor.prd.md |
| 11 | 0.000975 | docs/2. Development/2.5 Shared/Stream_Entry_Guide.md |
| 12 | 0.000953 | ../../ebs/docs/00-prd/EBS-UI-Design-v3.prd.md *(외부 레포 참조)* |
| 13 | 0.000939 | docs/4. Operations/Message_Bus_Runbook.md |
| 14 | 0.000853 | docs/1. Product/Product_SSOT_Policy.md |
| 15 | 0.000848 | docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_State.md |
| 16 | 0.000801 | ../../2.%20Development/2.3%20Game%20Engine/Rules/Multi_Hand_v03.md *(URL-encoded 참조)* |
| 17 | 0.000784 | docs/2. Development/2.3 Game Engine/Backlog/B-356-oe-catalog-self-inconsistency.md |
| 18 | 0.000776 | Backlog.md §우선작업 항목 5 (harness /engine/health endpoint) |
| 19 | 0.000774 | docs/4. Operations/Multi_Session_Design_v11.md |
| 20 | 0.000757 | **docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md** ⭐ |
| 21 | 0.000756 | ../../../4.%20Operations/Conductor_Backlog/SG-002-engine-dependency-contract.md |
| 22 | 0.000756 | docs/2. Development/2.2 Backend/Back_Office/Overview.md |
| 23 | 0.000752 | ./Game_Rules/Betting_System.md |
| 24 | 0.000752 | docs/_generated/confluence-pagename-audit.md |
| 25 | 0.000689 | ../../../1.%20Product/Foundation.md *(URL-encoded 외부 PRD 참조)* |
| 26 | 0.000689 | ../../2.5%20Shared/Chip_Count_State.md |
| 27 | 0.000689 | **docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md** ⭐ |
| 28 | 0.000664 | docs/4. Operations/Multi_Session_Design_v10.3.md |
| 29 | 0.000613 | docs/4. Operations/Conductor_Backlog/B-222-inter-session-chat-ui.md |
| 30 | 0.000583 | **docs/2. Development/2.1 Frontend/Lobby/Overview.md** ⭐ |

⭐ = Cycle 22 hotspot (W2~W4 변경 후보).

**해석**:
- skin-editor (Graphic_Editor References) 가 상위 10 중 6개 — 외부 인계 PRD의 비대한 derivative 클러스터.
- **Variants_and_Evaluation / Betting_and_Pots / Triggers_and_Event_Pipeline** = Game Engine Behavioral_Specs 3 정본이 #2/4/5 — Cycle 7~12에서 v01/v02/v03 e2e가 모두 이를 검증한 영향.
- **WebSocket_Events.md (#9)** 가 정본 API 중 최상위 — chip_count_synced 신규 contract의 정합 검증이 cycle 22의 최우선.
- **Foundation.md (#25, URL-encoded 형태)** 는 자체 순위(`docs/1. Product/Foundation.md`) 와 함께 외부 PRD가 비대칭 참조하는 hub 문서.

---

## §3 변경 핫스팟 영향 분석 (impact-of, reverse-dep)

`doc_discovery.py --impact-of` 4건 실행 결과:

| 파일 | 영향 받는 파일 | 비고 |
|------|---------------|------|
| `docs/1. Product/Lobby_PRD.md` | **0** | 외부 PRD — derivative-of 단방향, 정본이 아니므로 정상 |
| `docs/1. Product/Command_Center_PRD.md` | **0** | 동일 |
| `docs/1. Product/Foundation.md` | **1** (docs/1. Product/1. Product.md) | 1. Product.md 가 Foundation을 toc-include 하는 단일 link |
| `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | **2** (2.2 Backend.md, WSOP_LIVE_Chip_Count_Sync.md) | toc + sibling cross-ref |

```
        +---------------------------+
        |  외부 PRD (Lobby/CC)      |
        |  영향 0 = "참조 받음 0"   |
        |  (derivative-of 단방향)   |
        +-------------+-------------+
                      |
                      | derivative-of
                      v
        +---------------------------+
        |  정본 spec (Overview.md)  |
        |  영향 N>0 = "참조 받음 N" |
        +---------------------------+
```

**⚠ 영향 0 ≠ 정상 ⚠** — `--impact-of`는 **reverse-dependency** (= 누가 나를 참조하는가) 만 계산한다. 외부 PRD는 `derivative-of: ../<정본>.md` 만 가지므로 "나를 참조하는 다른 문서"가 0인 것이 정상이다. 그러나 **정본 spec이 변경되면 외부 PRD를 동시에 갱신해야 한다 (룰 20)** — 본 audit은 이를 markdown body 자연어 참조로는 감지하지 못한다 (§7 한계 참조).

**Foundation.md → 1 affected**: 1. Product.md (table-of-contents) 만 직접 link한다. **그러나 Foundation은 PageRank #25 hub** 이며, body 내 `related-docs:` 자연어로 12+ 정본 spec을 cross-ref한다. graph 상 1 affected = link 1개만 빌드되었다는 의미일 뿐 의미적 cascade 부재가 아니다 — GAP-1 의 근거.

**WebSocket_Events.md → 2 affected**: 2.2 Backend.md (toc) + WSOP_LIVE_Chip_Count_Sync.md (sibling). chip_count_synced 신규 이벤트가 sibling에는 cross-ref 되어 있으나, **Foundation related-docs / Chip_Count_State.md cross-ref / 외부 BO PRD 갱신이 누락**되었을 가능성 — GAP-1 의 또 다른 측면.

---

## §4 GAP 매트릭스 (사전 식별)

| ID | Severity | 갭 | 영향 파일 | 권고 Wave |
|----|:--------:|-----|----------|:----------:|
| **GAP-1** | HIGH | Foundation.md ← 신규 chip count contract 2종 (WSOP_LIVE_Chip_Count_Sync.md + Chip_Count_State.md) 역참조 누락. Foundation related-docs에 명시 안 됨 | Foundation.md | W4 |
| **GAP-2** | HIGH | Lobby/Overview.md (last-updated 2026-05-11) + UI.md (last-updated **2026-05-07, 6일 stale**) — Cycle 21 W1 cascade 후 last-updated 갱신 누락 가능성 | Lobby/Overview.md, Lobby/UI.md | W2 |
| **GAP-3** | MEDIUM | 양방향 link 비대칭 — 외부 PRD `derivative-of: ../정본.md` 단방향만 존재. 정본 → 외부 PRD related-docs 역참조 없음 (Foundation 외 12+ 정본 spec 공통) | 모든 외부 PRD + 정본 spec | W4 (Foundation case 우선) |
| **GAP-4** | MEDIUM | Cycle 21 W1 in-flight (PR #443) — Lobby 4 진입 시점 동기 cascade가 W2와 충돌 가능 | docs/2.1/Lobby/* | (자동 해소 — PR 머지 시점에 W2 진입) |
| **GAP-5** | LOW | mockups/EBS Command Center/ frontmatter 없음 — tokens.css / app.css 등 자산 파일에 owner/tier 메타 부재 | tokens.css, app.css | (선택적, 본 cycle 스코프 외) |

**Severity 기준**:
- **HIGH** — 정본 변경이 cross-stream 의사결정에 영향. 미해소 시 외부 PRD가 stale.
- **MEDIUM** — 즉시 implementation을 막지 않으나 다음 cycle의 doc-discovery rebuild에서 추적 가능.
- **LOW** — 자산 파일 메타데이터. 본 cycle 우선순위 외.

---

## §5 추가 발견 (audit 중 추가 갭)

본 audit 실행 중 carry-over 형태로 잔존하는 기존 갭이 확인됨:

| 발견 | 출처 | 상태 |
|------|------|:----:|
| spec_aggregate legacy-id 중복 (BS-06-04 / 05 / 08) | issue #413 | carry-over |
| Equity_Calculator.md broken link to Betting_System.md | issue #413 | carry-over |
| Scenario Lint v02-* / v03-* CCR 누락 | issue #408 | carry-over |
| PageRank #18 "Backlog.md §우선작업 항목 5 (harness /engine/health endpoint)" — text fragment가 노드화 | parser 인공물 | 무시 가능 (URL anchor 파싱) |

이들은 **본 Cycle 22 W1 audit의 스코프 외** (issue #413/#408 owner stream으로 carry). 본 보고서는 식별만 하고 후속 PR을 생성하지 않는다.

---

## §6 Wave 분배 권고

```
  Wave 1 (S10-A)          본 audit report (write-only)
    │
    ├─ Wave 2 (S2 Lobby cascade)
    │    └─ Lobby/Overview.md + UI.md last-updated 갱신
    │       Cycle 21 W1 (#443) 후속 정합
    │
    ├─ Wave 3 (S7 Backend cascade)
    │    └─ WebSocket_Events.md last-updated 갱신
    │       chip_count_synced cross-ref 추가
    │       (Chip_Count_State.md + sibling 보강)
    │
    ├─ Wave 4 (S1 Foundation 역참조)
    │    └─ Foundation.md related-docs 보강
    │       ├─ WSOP_LIVE_Chip_Count_Sync.md
    │       └─ Chip_Count_State.md
    │       Ch.2 #1 트리거 cross-ref 추가
    │
    └─ Wave 5 (S10-A verify)
         └─ doc-discovery rebuild
            impact-of 4 hotspot → 0 stale ref 검증
            last-updated 정합 (모두 ≥ 2026-05-13)
```

### W2 ~ W5 세부 작업

**W2 (S2 Lobby cascade)** — branch `work/s2/cycle-22-lobby-cascade`
- `docs/2. Development/2.1 Frontend/Lobby/Overview.md`: last-updated → 2026-05-13
- `docs/2. Development/2.1 Frontend/Lobby/UI.md`: last-updated → 2026-05-13 (6일 stale 해소)
- Cycle 21 W1 변경분과 정합 (4 진입 시점 동기 cascade 정합)

**W3 (S7 Backend cascade)** — branch `work/s7/cycle-22-websocket-events-sync`
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`: last-updated → 2026-05-13
- chip_count_synced 이벤트 정의에 Foundation §A.1 cross-ref 추가
- sibling `WSOP_LIVE_Chip_Count_Sync.md` 와의 related-docs 양방향 확인

**W4 (S1 Foundation 역참조)** — branch `work/s1/cycle-22-foundation-related-docs`
- `docs/1. Product/Foundation.md`: related-docs 에 추가
  - `docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md`
  - `docs/2. Development/2.5 Shared/Chip_Count_State.md`
- Ch.2 #1 트리거 섹션에 신규 contract 2종 cross-ref

**W5 (S10-A verify)** — branch `work/s10-a/cycle-22-verify`
- `python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py --rebuild --root .`
- `--impact-of` 4 hotspot 재실행 → 0 orphan/stale ref 확인
- last-updated 정합 audit (≥ 2026-05-13)

---

## §7 본 audit의 한계

| # | 한계 | 영향 |
|--:|------|------|
| 1 | doc-discovery는 frontmatter graph + code import만 분석. Markdown **body 내 "참조" 자연어**는 미감지. | "Foundation §A.1 참조" 같은 inline 자연어 cross-ref 누락 시 graph는 정상으로 보고. |
| 2 | governance 룰 (예: 룰 20 derivative-of 동기화 강제, 룰 21 사례 등록 강제) 은 별도 검증 도구 필요. | 본 audit은 "graph drift" 만 감지하며 "정책 위반" 은 감지 못 함. |
| 3 | **본 audit은 cycle 22 W2~W5 작업 분배 근거** 이며 실제 갭 수정은 후속 PR. | 본 보고서 머지 자체로는 갭 해소 0건. W2~W5 PR이 actual 갭 해소. |
| 4 | URL-encoded 참조 (`../../2.%20Development/...`) 가 별도 노드로 분리되어 PageRank가 분산됨. | Foundation.md 가 graph 상 본명 + URL-encoded 두 노드로 출현 — 실제 중심성은 더 높음. |
| 5 | reverse-dep graph 특성 상 "영향 0 = 정상" 케이스를 자동 구분 못 함. | §3 표 footnote 로 인간 해석 필수. |

---

## §8 Cycle 22 exit criteria

본 cycle은 다음 조건 충족 시 close:

- [ ] W2 PR 머지 (S2 Lobby last-updated 정합)
- [ ] W3 PR 머지 (S7 WebSocket_Events cross-ref 정합)
- [ ] W4 PR 머지 (S1 Foundation 역참조 보강)
- [ ] W5 verify — `doc-discovery --rebuild` 후 4 hotspot impact-of 0 stale ref
- [ ] 본 보고서 + W2~W5 PR 4개 모두 머지 → issue #445 close

**KPI**:
- Doc graph 정합도: 4 hotspot 모두 last-updated ≥ 2026-05-13
- 양방향 link 보강: Foundation related-docs +2 (Chip_Count contract 2종)
- carry-over 잔존 갭 (#413 / #408) 미증가

---

## Appendix A — doc-discovery 명령 재현

```bash
# PageRank top 30 (코드 심볼 포함 raw)
python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py --rank --top 30 --root .

# Impact-of (reverse-dep) 4 hotspot
python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py \
  --impact-of "docs/1. Product/Lobby_PRD.md" --root .
python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py \
  --impact-of "docs/1. Product/Command_Center_PRD.md" --root .
python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py \
  --impact-of "docs/1. Product/Foundation.md" --root .
python ~/.claude/skills/doc-discovery/scripts/doc_discovery.py \
  --impact-of "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md" --root .
```

## Appendix B — 관련 issue / cycle

- Issue #445 — Cycle 22 W1 audit (본 보고서)
- Issue #413 — spec_aggregate legacy-id 중복 + Equity broken link (carry-over)
- Issue #408 — Scenario Lint CCR 누락 (carry-over)
- PR #443 — Cycle 21 W1 in-flight (W2 진입 시 자동 해소 확인 필요)
- PR #436 — Cycle 20 S7 chip_count_synced webhook (본 audit의 W3/W4 cascade 근거)
