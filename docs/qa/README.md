# docs/qa — QA 문서 디렉터리

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | QA 디렉터리 생성, Game Engine QA |
| 2026-04-09 | 추가 | 앱별 QA 디렉터리 (lobby, commandcenter, graphic-editor) |
| 2026-04-09 | 추가 | Lobby WSOP Parity 체크리스트 (QA-LOBBY-WSOP-PARITY.md) |
| 2026-04-09 | 추가 | Spec Gap 프로세스 도입 (QA-*-03-spec-gap.md) |

---

## 개요

EBS 프로젝트의 품질 보증(Quality Assurance) 관련 문서를 관리한다.

- **대상**: EBS Core 소프트웨어 계층 (3입력 → Game Engine → Overlay Graphics)
- **비대상**: 물리 RFID 하드웨어, WSOP LIVE 자체, 포스트프로덕션, 방송 송출 장비

---

## 디렉터리 구조

```
docs/qa/
  ├─ README.md                          ← 이 파일
  ├─ QA-EBS-Master-Plan.md              ← 전체 5-Phase Master Plan
  ├─ lobby/                             ← Lobby 앱 QA
  │    ├─ QA-LOBBY-00-audit.md          ← 감사 결과
  │    ├─ QA-LOBBY-01-strategy.md       ← 전략 + 구현 가이드
  │    ├─ QA-LOBBY-02-checklist.md      ← BS-02 기반 체크리스트 + 구현 대조
  │    ├─ QA-LOBBY-WSOP-PARITY.md      ← WSOP LIVE 기능 동등성 체크리스트
  │    ├─ QA-LOBBY-03-spec-gap.md      ← 기획 문서 Gap 리포트
  │    └─ QA-LOBBY-04-implementation-guide.md ← 구현 Gap 해소 지시서 (화면 0-4)
  ├─ commandcenter/                     ← Command Center 앱 QA
  │    ├─ QA-CC-00-audit.md             ← 감사 결과
  │    ├─ QA-CC-01-strategy.md          ← 전략 + 구현 가이드
  │    └─ QA-CC-02-checklist.md         ← BS-05 기반 체크리스트 + 구현 대조
  ├─ graphic-editor/                    ← Graphic Editor 앱 QA
  │    ├─ QA-GE-00-audit.md             ← 감사 결과
  │    ├─ QA-GE-01-strategy.md          ← 전략 + 구현 가이드
  │    └─ QA-GE-02-checklist.md         ← BS-07 기반 체크리스트 + 구현 대조
  (game-engine/ → docs/04-rules-games/games/qa/ 로 이전됨)
```

---

## 앱별 QA 문서

| 앱 | 감사 | 전략 | 행동 명세 | 레포 | 기타 |
|---|------|------|----------|------|------|
| **Lobby** | `lobby/QA-LOBBY-00-audit.md` | `lobby/QA-LOBBY-01-strategy.md` | BS-02 | `/ebs_lobby_web/` | `lobby/QA-LOBBY-WSOP-PARITY.md` |
| **Command Center** | `commandcenter/QA-CC-00-audit.md` | `commandcenter/QA-CC-01-strategy.md` | BS-05 | `/ebs_app/` | — |
| **Graphic Editor** | `graphic-editor/QA-GE-00-audit.md` | `graphic-editor/QA-GE-01-strategy.md` | 없음 (역설계 참조) | `/ebs_ui/ebs-skin-editor/` | — |

---

## 문서 번호 규칙

| 접두사 | 범위 | 예시 |
|--------|------|------|
| `QA-LOBBY-` | Lobby 앱 | `QA-LOBBY-00-audit.md` |
| `QA-CC-` | Command Center 앱 | `QA-CC-01-strategy.md` |
| `QA-GE-` (graphic-editor/) | Graphic Editor 앱 | `graphic-editor/QA-GE-00-audit.md` |
| `QA-GE-` (game-engine/) | Game Engine | `game-engine/QA-GE-01-fsm-transitions.md` |

> `QA-GE-` 접두사가 graphic-editor와 game-engine에서 중복되나, **디렉터리로 구분**한다.

---

## 참조 가이드 (다른 세션용)

### Lobby QA 작업 시

```
다음 문서를 읽고 작업:
1. docs/qa/lobby/QA-LOBBY-00-audit.md       — 현황 진단
2. docs/qa/lobby/QA-LOBBY-01-strategy.md    — 전략 + 테스트 항목 (L-U/W/E)
3. docs/qa/lobby/QA-LOBBY-WSOP-PARITY.md   — WSOP LIVE 기능 동등성 체크리스트
4. docs/02-behavioral/BS-02-lobby/          — 행동 명세
레포: /ebs_lobby_web/
```

### Command Center QA 작업 시

```
다음 문서를 읽고 작업:
1. docs/qa/commandcenter/QA-CC-00-audit.md   — 현황 진단
2. docs/qa/commandcenter/QA-CC-01-strategy.md — 전략 + 테스트 항목 (C-U/I/W/E)
3. docs/02-behavioral/BS-05-command-center/   — 행동 명세 (7파일)
레포: /ebs_app/
```

### Graphic Editor QA 작업 시

```
다음 문서를 읽고 작업:
1. docs/qa/graphic-editor/QA-GE-00-audit.md   — 현황 진단
2. docs/qa/graphic-editor/QA-GE-01-strategy.md — 전략 + 테스트 항목 (G-U/C/E)
레포: /ebs_ui/ebs-skin-editor/
```

---

## Spec Gap 프로세스

구현 중 기획 문서에 명시되지 않은 판단이 필요한 경우, `QA-*-03-spec-gap.md`에 Gap 항목을 기록한다.

| 단계 | 활동 | 산출물 |
|:----:|------|--------|
| 1 | 구현 중 기획 누락 발견 | Gap 항목 기록 (GAP-{앱}-{번호}) |
| 2 | 임시 구현 (workaround) | 코드 + Gap 문서에 workaround 명시 |
| 3 | 기획자 확인 | 기획 문서 보강 + Gap Status → RESOLVED |

> 상세 규칙: `CLAUDE.md` "Spec Gap 프로세스" 섹션 참조

---

## QA 방법론: Spec-First

| 단계 | 활동 | 산출물 |
|:----:|------|--------|
| 1 | 기획 문서(BS) → 체크리스트 명세 | `QA-*-02-checklist.md` |
| 2 | 구현 코드 대조 | 체크리스트 구현 열 (✅/⚠️/❌) |
| 3 | E2E Playwright 캡처 | 체크리스트 Playwright 열 |
| 4 | Gap 발견 → 문서 기록 | 체크리스트 Gap Analysis 섹션 |

### 원칙

- QA 체크리스트는 **행동 명세(BS)에서 도출**한다. 코드에서 역추적하지 않는다.
- BS에 있는데 체크리스트에 없는 항목 = **누락** (있으면 안 됨)
- 체크리스트에 있는데 BS에 없는 항목 = **근거 없음** (있으면 안 됨)
- 구현 확인은 실제 코드 file:line으로 근거를 남긴다.

### 구현 대조 현황 (2026-04-09)

| 앱 | 체크리스트 | 구현율 | ✅ | ⚠️ | ❌ |
|---|----------|:------:|:--:|:--:|:--:|
| **Lobby** | `QA-LOBBY-02-checklist.md` | ~60-65% | 20 | 8 | 4 |
| **CC** | `QA-CC-02-checklist.md` | ~10-15% | 0 | 14 | 22 |
| **GE** | `QA-GE-02-checklist.md` | ~40% | 14 | 6 | 30 |

---

## 관련 문서

| 문서 | 경로 |
|------|------|
| 상위 테스트 전략 | `docs/testing/TEST-01-test-plan.md` |
| E2E 시나리오 | `docs/testing/TEST-02-e2e-scenarios.md` |
| Mock 데이터 | `docs/testing/TEST-04-mock-data.md` |
| Foundation PRD | `docs/01-strategy/PRD-EBS_Foundation.md` |
| 행동 명세 | `docs/02-behavioral/BS-00~07` |

---

## 원칙

- 이 디렉터리는 "무엇을 검증할 것인가"만 규정한다
- 실제 테스트 코드는 각 앱 레포에서 관리한다
- 감사 문서(`*-00-audit.md`)는 현황 스냅샷이며, 구현 후 업데이트한다
- 전략 문서(`*-01-strategy.md`)는 구현 가이드이며, 완료 시 체크 표시한다
