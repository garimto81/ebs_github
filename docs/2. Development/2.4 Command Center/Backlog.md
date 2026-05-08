---
title: Backlog
tier: internal
decomposed: true
confluence-page-id: 3819209295
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209295/EBS+Backlog+1565
---

# Backlog (디렉토리화됨)

## 🔥 2026-04-22 Foundation 재설계 후속 작업 (최우선)

Foundation.md 전면 재설계 (F1/Ch.4/§5.0/§6.3/§6.4/§7.1/§8.5, 2026-04-22) 에 따른 team4 기획 문서 정합 복원.

**영향도 매트릭스**: `./Foundation_Impact_Review.md` 참조 (SSOT).

| 우선순위 | 항목 | 영역 |
|:------:|------|------|
| **P0** | [B-team4-007](Backlog/B-team4-007-foundation-critical-multi-table-sequences.md) | CRITICAL — Multi_Table Pattern B 재정의 + Sequences 2 모드 다이어그램 |
| **P1** | [B-team4-008](Backlog/B-team4-008-foundation-high-overlay-overview-runtime-modes.md) | HIGH — Overlay Overview 2 런타임 모드 분기 + 배경 config flag |
| **P2** | [B-team4-009](Backlog/B-team4-009-foundation-medium-reference-updates.md) | MEDIUM — 참조·주석 일괄 보강 (M1~M8) |
| **P3** | [B-team4-010](Backlog/B-team4-010-foundation-low-link-fixes.md) | LOW — 참조 링크 갱신 (L1~L4) |

**예상 총 공수**: ~8h (1 working day).

## 🎯 2026-04-21 이관 우선 작업 (baseline 커밋 `7543452`)

팀 세션 시작 시 `team4-cc/CLAUDE.md §"2026-04-21 이관 시 우선 작업"` 섹션 필독.
전체 이관 가이드: `docs/4. Operations/Multi_Session_Handoff.md`

1. **IMPL-002 Engine Connection UI 완결** — `Conductor_Backlog/IMPL-002-team4-engine-connection-ui.md`
   - ✅ skeleton 완료: provider + banner + splash + router
   - 🟡 남은: widget test + integration + `/engine/health` 응답 정합
2. **SG-002 stub_engine 연동** — Overlay Rive 로 실제 스트리밍 테스트
3. **Overlay Rive 21 OutputEvent consume** — `Overlay_Output_Events.md §6.0` 전부 매핑
4. **SG-006 Deck 등록 3 모드 UI** — Scan/Bulk/자동 (team2 `/api/v1/decks` API 호출)
5. **Manual_Fallback e2e** — `Manual_Card_Input.md §6` 시나리오

### ENGINE_URL
```bash
flutter run -d windows --dart-define=ENGINE_URL=http://host:port
```
default `localhost:8080`. 미연결 시 Demo Mode 자동.

### 관련 SG
- SG-002 RESOLVED (3-stage + Demo) · SG-006 RESOLVED (Deck) · SG-011 OUT_OF_SCOPE (RFID 하드웨어)

### 금지 / 범위 밖
- **SG-011 RFID 하드웨어** (제조사 SDK 필요, 범위 밖)
- Graphic Editor UI (team1)
- `IRfidReader` 직접 인스턴스화 (Riverpod DI)

---

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Backlog/` (21개 항목)
- 신규 항목 추가: `./Backlog/{ID}-{slug}.md` 작성 (frontmatter 필수)
- 통합 읽기 뷰: `tools/backlog_aggregate.py` 가 `_generated/` 에 자동 생성

신규 항목 frontmatter 예시:

```yaml
---
id: B-XXX
title: "항목 제목"
status: PENDING  # PENDING | IN_PROGRESS | DONE
source: (이 파일 경로)
---
```
