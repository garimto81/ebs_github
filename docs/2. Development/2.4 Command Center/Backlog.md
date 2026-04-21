---
title: Backlog
tier: internal
decomposed: true
---

# Backlog (디렉토리화됨)

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
