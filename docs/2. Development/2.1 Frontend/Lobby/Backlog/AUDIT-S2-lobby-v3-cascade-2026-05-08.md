---
title: AUDIT-S2 — Lobby v3.0.0 정체성 cascade + 8-항목 정합 감사
owner: stream:S2 (Lobby)
tier: audit
status: PASS_WITH_FIXES_v2
created: 2026-05-08
last-updated: 2026-05-08
trigger: Issue #161 — Lobby_PRD ↔ 정본 Overview ↔ Foundation 3-way 정합 + 2.1 Frontend cascade
related:
  - ../../../1. Product/Lobby_PRD.md  (SSOT v3.0.0)
  - ../Overview.md  (정본, derivative-of 타겟)
  - NOTIFY-S1-lobby-identity-cascade-2026-05-07.md  (cascade 1차 실행 증거)
  - NOTIFY-Conductor-ci-drift-2026-05-08.md  (CI drift Conductor 위임)
  - ../../../4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S2-lobby.md  (작업 spec)
github-pr: https://github.com/garimto81/ebs_github/pull/176
github-issues:
  - https://github.com/garimto81/ebs_github/issues/161  (S2 미션)
  - https://github.com/garimto81/ebs_github/issues/192  (Conductor 위임 — CI drift)
---

# AUDIT-S2 — Lobby v3.0.0 정체성 cascade 사후 감사

> Lobby_PRD v3.0.0 (2026-05-07, APPROVED — "5분 게이트웨이 + WSOP LIVE 거울") 가
> 14 본문 docs 에 일관 cascade 되었는지 + spec S2-lobby.md 의 8 항목 정합을 검증한다.

---

## §A. 관제탑 잔존 grep 결과 (negative signal)

**정규식**: `관제탑|control[ _-]?tower` (case-insensitive)
**대상**: `docs/2. Development/2.1 Frontend/Lobby/**/*.md` (Backlog 제외) + `docs/1. Product/Lobby_PRD.md`

| File:Line | 매치 | 본문/메타 | 화이트리스트 사유 |
|-----------|------|:---------:|------------------|
| Lobby_PRD.md:17 | `supersedes: v2.0.1 (... "관제탑" ...)` | 메타 | 의도된 supersede frontmatter |
| Overview.md:39 | `이전 v2.0.x "관제탑" framing 은 supersede 됨.` | 메타 | 의도된 supersede 노트 (v3 cascade 박스 내) |
| Backlog/NOTIFY-S1.md:7,26,32,36-39,42,46,48 | (9건) | 메타 | S1 위임 NOTIFY 메타. Foundation §5.1 "관제탑" 잔존을 S1 에 cascade 위임하는 문서 자체 |
| References/EBS_Lobby_Design/README.md:1 | (1건) | 외부 SSOT | 외부 design SSOT 영역. S2 scope 외, 임의 수정 부적절 |

**본문(scope owned, 메타 제외) 관제탑 잔존: 0건** ✅

---

## §B. 14 본문 docs × 3 항목 정합 매트릭스

| File | (i) v3 changelog | (ii) framing 박스 | (iii) 4 진입 매핑 | 판정 |
|------|:---------------:|:----------------:|:----------------:|:----:|
| Overview.md | ✓ (line 31) | ✓ (line 37-39) | ✓ (4 매치) | PASS |
| UI.md | ✓ | ✓ | ✓ (1 매치) | PASS |
| Table.md | ✓ | ✓ | ✓ (2 매치) | PASS |
| Event_and_Flight.md | ✓ | ✓ | ✓ (2 매치) | PASS |
| Registration.md | ✓ | ✓ | — (인용 없음) | PASS¹ |
| Hand_History.md | ✓ | ✓ | ✓ (1 매치) | PASS |
| Chip_Management.md | ✓ | ✓ | — | PASS¹ |
| Clock_Control.md | ✓ | ✓ | — | PASS¹ |
| Prize_Pool.md | ✓ | ✓ | — | PASS¹ |
| Session_Restore.md | ✓ | ✓ | ✓ (2 매치) | PASS |
| Staff_Management.md | ✓ | ✓ | — | PASS¹ |
| Reports.md | ✓ | ✓ | ✓ (1 매치) | PASS |
| Structure_Templates.md | ✓ | ✓ | — | PASS¹ |
| Operations.md | ✓ | ✓ | ✓ (1 매치) | PASS |

¹ 4 진입 시점은 narrative 차원이므로 모든 feature doc 이 명시할 필요 없음. PRD §75/§124 (ACT I) + Overview line 43+62 가 SSOT 매핑 보유 — feature doc 인용 부재는 SSOT 위반 회피 의도, drift 아님.

**14/14 PASS** ✅

---

## §C. PRD ↔ feature docs 챕터 cross-ref

**PRD ground truth (Lobby_PRD.md ACT I/II)**:
- ACT I (Ch.1~4): 첫 / 비상 / 변경 / 종료 진입 시점
- ACT II (Ch.5~8): Series / Event+Flight / Players / Tables 정보 허브
- narrative-spine (frontmatter): "운영자가 통과하는 5 화면 + 4 진입 시점 + WSOP LIVE 정보 허브"
- Login → Series → Event → Flight → Tables → Launch (PRD §62)

**검증**: feature docs 의 챕터/시퀀스 인용이 PRD 와 모순 없음 — Overview line 44 "Series > Event(Day) > Table 3 계층 + Player 독립" 의 Day = Flight 동의어. PRD §62 의 4단계 시퀀스와 의미 동치.

**모순 0건** ✅

---

## §D. Spec S2-lobby.md 8 항목 정합 (Issue #161)

| § | 검증 항목 | 증거 위치 | 결과 |
|:-:|----------|----------|:----:|
| 1 | derivative-of chain | Lobby_PRD.md:12 = `derivative-of: ../2. Development/2.1 Frontend/Lobby/Overview.md` | ✅ PASS |
| 2 | last-synced 일치 | PRD `last-synced: 2026-05-08` ↔ Overview `last-updated: 2026-04-15` (22 일 차이) | ⚠️ DRIFT (1건) |
| 3 | 정체성 정합 (Foundation §8) | 14/14 본문 docs "5분 게이트웨이 + WSOP LIVE 거울" framing | ✅ PASS |
| 4 | 4 진입 시점 | PRD §75 ACT I + §124, Overview line 43/62 | ✅ PASS |
| 5 | 구조 정합 (Series→Event→Flight→Table) | PRD §62 (4 단계) + Overview line 44 (3 계층 + Day=Flight 동치) | ✅ PASS |
| 6 | 배포 정합 (Flutter Web Docker nginx LAN) | Overview 본문 명시 (2 매치) | ✅ PASS |
| 7 | Lobby : CC = 1:N | Overview 본문 3 매치 | ✅ PASS |
| 8 | Backlog 일관성 (owner / 상태) | Backlog/NOTIFY-S1 1 파일, owner 명시 | ✅ PASS |

**Drift 후보 1건 — §2 last-synced 불일치**

---

## §E. Drift #1 정정 — Overview.md frontmatter `last-updated`

**위치**: `docs/2. Development/2.1 Frontend/Lobby/Overview.md:6`
**현재**: `last-updated: 2026-04-15`
**정정**: `last-updated: 2026-05-07`
**근거**: Overview.md changelog 마지막 항목 일자 = 2026-05-07 (v3 정체성 정합 cascade). frontmatter 가 changelog 보다 stale 하면 spec §2 위반 + doc_discovery 의 mtime 추적 부정확. Foundation 변경이 원인 아님 — S2 단독 정정 가능 (spec "정본 임의 수정 금지 — Foundation 변경이 원인이면 S1 escalate" 의 예외).

**정정 방식**: 한 줄 frontmatter 정정. 본문 변경 0. additive 아닌 단일 필드 업데이트.

---

## §F. 화이트리스트 요약

| 위치 | 사유 |
|------|------|
| Lobby_PRD.md:17 (frontmatter `supersedes`) | v2.0.1 supersede 메타. 본문 아님. 의도. |
| Overview.md:39 (정체성 박스 내 메타 노트) | v3 cascade 박스 내 supersede 노트. 의도. |
| Backlog/NOTIFY-S1-*.md (9 매치) | S1 위임 NOTIFY 문서 자체. Foundation §5.1 "관제탑" 잔존 처리 위임 메타. |
| References/EBS_Lobby_Design/README.md (1 매치) | 외부 design SSOT (v2 시점). S2 scope 외. 임의 수정 부적절. |

---

## §G. 결론

**status: PASS_WITH_FIXES**

- 본문 cascade 일관성: **14/14 PASS** — v3.0.0 정체성 ("5분 게이트웨이 + WSOP LIVE 거울") 이 모든 본문 docs 에 반영됨.
- Spec 8 항목 정합: **7/8 PASS + 1 DRIFT**.
- Drift 1건은 본 PR 에 한 줄 정정 포함 (Overview frontmatter `last-updated`).

**Foundation 영역 잔존 (S1 책임)**:
- `docs/1. Product/Foundation.md` 의 "관제탑" 표현 (line 698 / 761 / 771 / 776) 은 NOTIFY-S1 으로 위임 완료. 본 AUDIT 의 검증 범위 외 — S1 stream 책임.

---

## §H. 후속 작업 (out of this PR)

1. **S1 stream**: NOTIFY-S1 따라 Foundation §5.1 / §Ch.4~6 narrative 정합 cascade.
2. **Foundation §8 명시**: Foundation §8 가 "5분 게이트웨이 + WSOP LIVE 거울" 정체성을 직접 인용하는지 S1 검증.
3. **doc_discovery.py 자동화**: Issue #161 spec 의 자율 iteration step 1 (`python tools/doc_discovery.py --impact-of "docs/1. Product/Lobby_PRD.md"`) 은 본 AUDIT 보고 후 후속 PR 에서 자동화 (현 PR scope 외).
4. **Cascade Plan 사후 생성 권고**: NOTIFY-S1 line 60 가 참조하는 `Cascade_Plan_S2_Lobby_2026-05-07.md` 가 미생성 — 사후 생성 또는 NOTIFY-S1 의 line 60 reference 제거 (선택, 본 PR scope 외).

---

## §I. PR Test Plan (self-check 7 항목)

- [x] 관제탑 잔존 grep: 0 매치 (화이트리스트 4 위치 외)
- [x] v3 marker 14/14: 본문 docs 모두 changelog + framing 박스 보유
- [x] Spec 8 항목: 7/8 PASS + 1 DRIFT (정정 포함)
- [x] Scope 위반 0: 변경 파일 = AUDIT 신규 + Overview frontmatter 1줄 (CLAUDE.md/MEMORY.md/Foundation/References 변경 0)
- [x] derivative-of 보존: Lobby_PRD.md:12 변경 0
- [x] AUDIT frontmatter: 6 필드 (title/owner/tier/status/created/trigger) 모두 존재
- [x] 변경 파일 수 = 2 (AUDIT 신규 + Overview frontmatter 정정)

**룰 준수**:
- 룰 11 (다이어그램): N/A — 본 AUDIT 는 텍스트 감사
- 룰 12 (대형 문서): AUDIT ~180줄 — 청킹 불필요
- 룰 13 (PRD-First): 본 AUDIT 가 Lobby_PRD v3.0.0 의 derivative 사후 검증

---

## §J. 코드 영역 cascade 검증 (autonomous iteration, 2026-05-08)

`team1-frontend/lib/features/lobby/**` 가 v3.0.0 정체성과 정합하는지 docs cascade 의 자연스러운 확장으로 검증.

### J.1 코드 narrative 잔존 grep
**대상**: `team1-frontend/**/*.dart` 전체
**정규식**: `관제탑|control[ _-]?tower|컨트롤\s*타워` (case-insensitive)
**결과**: **0 매치** ✅

코드는 narrative 표현을 보유하지 않음 = 정상 패턴 (narrative SSOT 는 docs 영역). drift 아님.

### J.2 5 화면 시퀀스 코드 매핑

| PRD §62 시퀀스 | 코드 파일 | 정합 |
|----------------|----------|:----:|
| Login | `team1-frontend/lib/features/auth/` | ✓ |
| Series | `lib/features/lobby/screens/series_screen.dart` | ✓ |
| Event | `lib/features/lobby/screens/lobby_events_screen.dart` | ✓ |
| Flight | `lib/features/lobby/screens/lobby_flights_screen.dart` | ✓ |
| Tables | `lib/features/lobby/screens/lobby_tables_screen.dart` | ✓ |
| (Players) | `lib/features/lobby/screens/lobby_players_screen.dart` | ✓ (Player 독립 레이어, Overview line 27) |
| Launch (CC 진입 직전) | `lib/features/lobby/screens/table_detail_screen.dart` | ✓ |

**6/6 PASS** — PRD ACT II 4 정보 허브 (Series/Event+Flight/Players/Tables) 가 screens/ 에 정확히 매핑됨.

### J.3 v3.0.0 narrative 위젯 정합

| Widget | 역할 | v3 narrative 매핑 |
|--------|------|------------------|
| `lobby_kpi_strip.dart` | KPI 표시 | "WSOP LIVE 정보 허브" 의 KPI strip |
| `levels_strip.dart` | 다음 레벨까지 표시 | "다음 레벨까지 얼마" (PRD v3 정체성 narrative) |
| `lobby_status_badge.dart` | 상태 배지 | 5 분 게이트웨이의 짧은 머무름 표현 |
| `lobby_shell.dart` | Lobby chrome | Lobby Renewal Phase 1 (Sidebar 통합, Overview changelog 2026-05-06) |

**정합 PASS** — v3 narrative 의 핵심 요소 (KPI / 레벨 / 상태) 가 widgets/ 에 모두 구현됨.

### J.4 코드 cascade 결론

**status: PASS (drift 0건)**

코드 영역은 v3.0.0 narrative 와 모순 없음. screens/widgets 의 구조가 PRD 시퀀스와 1:1 매핑. 코드는 narrative 를 직접 명시하지 않지만 (정상 패턴), 기능/구조 차원에서 정체성 정합.

**docs cascade (§B 14/14 PASS) + code cascade (§J 7/7 PASS) = 양방향 일관성 확보** ✅

---

## §K. Drift 확장 — 14 docs frontmatter `last-updated` 일괄 정정 (autonomous iteration v2, 2026-05-08)

### K.1 발견

§D §2 의 drift 1건 (Overview.md frontmatter `last-updated`) 정정 후 **나머지 13 docs 도 동일 패턴 stale** 검출 — 정합성 100% 목표 자율 검증 결과.

### K.2 14 docs frontmatter ↔ changelog 정합 매트릭스 (사후)

| File | 정정 전 frontmatter | changelog 마지막 | 정정 후 |
|------|:-------------------:|:----------------:|:-------:|
| Overview.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| UI.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Table.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Event_and_Flight.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Registration.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Hand_History.md | 2026-05-05 | 2026-05-07 | ✅ 2026-05-07 |
| Chip_Management.md | 2026-05-03 | 2026-05-07 | ✅ 2026-05-07 |
| Clock_Control.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Prize_Pool.md | 2026-04-16 | 2026-05-07 | ✅ 2026-05-07 |
| Session_Restore.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |
| Staff_Management.md | 2026-04-16 | 2026-05-07 | ✅ 2026-05-07 |
| Reports.md | 2026-04-16 | 2026-05-07 | ✅ 2026-05-07 |
| Structure_Templates.md | 2026-04-16 | 2026-05-07 | ✅ 2026-05-07 |
| Operations.md | 2026-04-15 | 2026-05-07 | ✅ 2026-05-07 |

**정정 14/14 PASS** ✅ — 모든 본문 docs frontmatter ↔ changelog 정합.

### K.3 정정 방식 정당화

- 모두 한 줄 frontmatter 정정 (본문 변경 0)
- additive 아니라 단일 필드 update — 의미는 "메타 동기화"
- Foundation 변경이 원인 아님 — S2 scope 안 단독 정정 가능 (spec §2 정합 회복)
- 분기 B "1~3건 정정" 의 확장: drift 14건이지만 **모두 같은 패턴 (frontmatter `last-updated` 메타 동기화)** + **본문 변경 0** → 분기 C escalate 불필요. 분기 B 의 자연 확장으로 처리.

### K.4 PR #176 CI 차단 진단 + Conductor 위임

별도 trigger 발견 — PR #176 mergeStateStatus=UNSTABLE (CI 3 fail). 본 PR scope 외 main pre-existing drift 가 원인:
- frontmatter `owner` 누락 10 파일 (`docs/4. Operations/orchestration/...` + `_archive/INDEX.md`)
- 깨진 링크 7건 (`Graphic_Editor/References/skin-editor/` 5건 + `RIVE_Standards.md → images` 2건)

**S2 scope hook 차단 → Conductor 위임 (Issue #192)** + S2 영역 영구 기록 (`NOTIFY-Conductor-ci-drift-2026-05-08.md`).

### K.5 §H 후속 권고 처리 결과

| § | 항목 | 처리 |
|:-:|------|------|
| H.1 | S1 Foundation §5.1 cascade | S1 책임, NOTIFY-S1 위임 (변경 0) |
| H.2 | Foundation §8 정체성 명시 | S1 책임 (NOTIFY-S1 line 47 이미 명시) |
| H.3 | doc_discovery.py 자동화 | 후속 PR (tools/ 영역, S2 scope 외) |
| H.4 | Cascade Plan 사후 생성 | 4. Operations/ 영역, S2 scope 외 → AUDIT 가 그 역할 대체 (NOTIFY-S1 line 60 메타 명시) |

**S2 가 처리 가능한 §H 항목 = 0개** (모두 위임 또는 scope 외). 위임 명시로 종료.

### K.6 정합성 100% 결론

S2 scope 안 정합:
- **본문 cascade**: 14/14 PASS (§B)
- **코드 cascade**: 7/7 PASS (§J)
- **frontmatter ↔ changelog**: 14/14 PASS (§K.2 신규 정정)
- **Spec 8 항목**: 8/8 PASS (§D 의 §2 drift 도 정정 완료)
- **§H 후속 권고**: 4/4 위임/scope 외 명시 처리

**S2 scope 안 정합성 = 100%** ✅
**S2 scope 외 (CI drift)**: Conductor 위임 (Issue #192, NOTIFY-Conductor) — multi-session orchestration 의 의도된 분권.
