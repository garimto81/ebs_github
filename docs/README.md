---
title: docs/ README
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# EBS Documentation — v10

모든 EBS 문서는 이 폴더(`docs/`) 아래에만 존재한다. 팀 폴더(`team1-frontend/` 등)는 코드 전용.

---

## 4 홈 폴더 — 답하는 질문

| 폴더 | 답하는 질문 | 대표 문서 |
|------|-------------|----------|
| [`1. Product/`](./1.%20Product/) | "이 제품이 무엇인가?" | Foundation, Architecture, Team_Structure, Game_Rules, PokerGFX_Reference |
| [`2. Development/`](./2.%20Development/) | "어떻게 만드나?" | 2.1 Frontend / 2.2 Backend / 2.3 Game Engine / 2.4 Command Center / 2.5 Shared |
| [`3. Change Requests/`](./3.%20Change%20Requests/) | "무엇을 바꾸나?" | pending / in-progress / done |
| [`4. Operations/`](./4.%20Operations/) | "어떻게 운영하나?" | Roadmap, Conductor_Backlog, Plans, Reports |

추가:
- `mockups/`, `images/` — 공유 그래픽 자산 (모든 팀 참조)
- `_generated/` — CI 자동 생성 인덱스 (수작업 편집 금지)

---

## `2. Development/` 5 섹션

| 섹션 | 소유 팀 | 내용 |
|------|---------|------|
| `2.1 Frontend/` | team1 | Login, Lobby, Settings 6탭, Graphic Editor, Console_UI, Engineering |
| `2.2 Backend/` | team2 (publisher: API/DB/BO) | APIs/, Database/, Back_Office/, Engineering/ |
| `2.3 Game Engine/` | team3 (publisher: API-04) | APIs/, Behavioral_Specs/ (+ Holdem/) |
| `2.4 Command Center/` | team4 (publisher: RFID HAL) | APIs/, RFID_Cards/, Command_Center_UI/, Overlay/ |
| `2.5 Shared/` | Conductor | BS_Overview, Authentication, EBS_Core, Risk_Matrix, Data_Analysis, `team-policy.json` |

---

## Frontmatter 스키마 (필수)

모든 `.md` 문서 최상단:

```yaml
---
title: Event & Flight Management
owner: team1          # team1 | team2 | team3 | team4 | conductor
tier: feature         # contract | feature | internal
legacy-id: BS-02-02   # 마이그레이션 추적 (기존 번호)
confluence-page-id: 123456
related:
  - 2. Development/2.1 Frontend/Lobby/Table.md
  - 2. Development/2.2 Backend/APIs/WebSocket_Events.md
last-updated: 2026-04-15
---
```

`legacy-id` 는 옛 문서 번호(BS-02-02 등)를 frontmatter 에서만 유지한다. 파일명에는 번호 prefix 를 넣지 않는다.

---

## 파일명 규칙

| 규칙 | 예시 |
|------|------|
| 홈 레벨 | `1. Product/`, `2. Development/`, `3. Change Requests/`, `4. Operations/` |
| 섹션 하위 (팀) | `2.1 Frontend/`, `2.5 Shared/` |
| feature 폴더 | PascalSnake: `Lobby/`, `RFID_Cards/`, `Holdem/` |
| 일반 파일 | PascalSnake: `Event_and_Flight.md`, `Auth_and_Session.md` |
| feature 내부 고정 | `UI.md`, `QA.md` (디자인·QA 통합) |
| 섹션 landing | 폴더명과 동일: `1. Product.md`, `2.1 Frontend.md` |

---

## legacy-id 로 파일 찾기

옛 번호(BS-04-04, API-01 등)로 새 위치를 찾으려면:

```bash
python tools/find_by_legacy.py BS-04-04
# → docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md
```

자동 집계 인덱스 활용:

```bash
# 전체 문서 목록
cat docs/_generated/full-index.md

# API 집계
cat docs/_generated/by-topic/APIs.md
```

---

## CR 프로세스 (팀 → Conductor)

v10 에서 CR(구 CCR) 라이프사이클:

1. **Draft**: `3. Change Requests/pending/CR-teamN-YYYYMMDD[-slug].md` (자기 팀 prefix 만 허용)
2. **Promoted**: Conductor 가 `3. Change Requests/in-progress/CR-NNN-{slug}.md` 로 승격
3. **Done**: 처리 완료 시 `3. Change Requests/done/` 로 이동

상세: `../CLAUDE.md` §"CCR 프로세스" / `3. Change Requests/3. Change Requests.md`

---

## Publisher 직접 편집 권한

publisher 팀은 자기 소유 계약 파일을 직접 수정 가능 (additive 원칙, 파괴적 변경 시 subscriber 합의 필수):

| 팀 | 직접 수정 경로 |
|----|---------------|
| team2 | `2.2 Backend/{APIs,Database,Back_Office}/**` |
| team3 | `2.3 Game Engine/APIs/**` |
| team4 | `2.4 Command Center/APIs/**` |

---

## 검증 도구

| 명령 | 목적 |
|------|------|
| `python tools/validate_links.py --scope=all` | 깨진 내부 링크 검출 |
| `python tools/spec_aggregate.py` | `_generated/` 인덱스 재생성 |
| `python tools/spec_aggregate.py --check` | frontmatter 누락 검증 |
| `python tools/find_by_legacy.py <legacy-id>` | 옛 번호 → 새 경로 |
| `python tools/wsop_alignment_check.py` | WSOP LIVE 정렬 확인 |

---

## WSOP LIVE 정렬

EBS 문서 구조는 WSOP LIVE Confluence(`C:/claude/wsoplive/docs/confluence-mirror/`, 1,361 페이지) 패턴을 우선 따른다. EBS 고유 요구로 달라지는 부분은 frontmatter 의 `Why:` 또는 섹션 내부에서 justify.
