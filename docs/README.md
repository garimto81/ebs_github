# docs/ — Conductor 문서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | v4 | 5팀 구조 재편. BS/API/DATA를 `contracts/`로, UI/QA를 팀 폴더로 이관. |
| 2026-04-02 | v3 | 페르소나 순서 초기 구조 (대체됨) |

## 개요

이 디렉터리는 **Conductor(Team 0)** 가 소유하는 상위 문서를 담는다. 행동 명세(BS), API/Data 계약, 팀별 구현 명세는 이제 이 폴더가 아니라 각자의 정식 위치에 있다:

| 과거 위치 (삭제됨) | 현재 위치 |
|------------------|----------|
| `docs/02-behavioral/BS-*` | `contracts/specs/BS-00~07` |
| `docs/api/API-*` | `contracts/api/API-01~06` |
| `docs/data/DATA-*` | `contracts/data/DATA-01~06` |
| `docs/03-ui-design/UI-*` | `team1-frontend/ui-design/`, `team4-cc/ui-design/` |
| `docs/qa/` | `team{1,2,3,4}/qa/` |
| `docs/04-rules-games/games/` | `team3-engine/specs/games/` |
| `docs/impl/`, `docs/back-office/`, `docs/testing/` | `team2-backend/specs/`, `team4-cc/specs/testing/` |

## 현재 구조

```
docs/
├── README.md              이 파일
├── backlog.md             글로벌 백로그 (teams: 필드로 팀별 필터)
├── mockups/               공유 HTML 목업 (flows, lobby)
├── images/                공유 그래픽 자산 (구조도, 포스터 등)
│
├── 00-reference/          WSOP 프로덕션 분석, PokerGFX 매뉴얼, 이미지 라이브러리
│   ├── 2026-WSOP-Production-Plan-V2.pdf
│   ├── PokerGFX-User-Manual.md
│   ├── WSOP-Production-Structure-Analysis.md
│   ├── field-registry.json
│   ├── images/            PokerGFX, Action Tracker, overlays 참조 스크린샷
│   ├── production-plan-graphics/
│   └── user-manual-images/
│
├── 01-strategy/
│   ├── PRD-EBS_Foundation.md   ★ SSOT (v41.0.0)
│   └── visual/                 도해 HTML
│
├── 05-plans/              현재 실행 계획 (구식 plan은 07-archive/05-plans-legacy/)
│
├── 06-reports/            완료 보고서
│
└── 07-archive/            아카이브 (참조 전용, 편집 금지)
    ├── 01-pokergfx-analysis/   PokerGFX 역설계 (설계 참고용)
    ├── 03-plans/, 04-reports/  구 plan/report
    ├── 05-plans-legacy/        5팀 전환 이전 구식 plan
    ├── 07-legacy/              구버전 Foundation PRD 등
    └── legacy-repos/           Phase 9 이전 개별 레포 8종 (ebs_app, ebs_bo, ebs_ecosystem, ebs_github, ebs_lobby-react, ebs_poc, ebs_reverse, ebs_reverse_app, ebs_table, ebs_ui)
```

## 온보딩 읽기 순서

### 1단계 — 전체 이해
1. `../CLAUDE.md` — Conductor 규칙, 팀 구조, CCR 프로세스
2. `01-strategy/PRD-EBS_Foundation.md` — EBS Foundation PRD (SSOT)

### 2단계 — 계약·명세
3. `../contracts/specs/BS-00-definitions.md` — 용어/상태/트리거 총괄
4. `../contracts/api/` — API-01~06 명세
5. `../contracts/data/` — DATA-01~06 + PRD

### 3단계 — 담당 팀 진입
- **Lobby/Frontend**: `../team1-frontend/CLAUDE.md` → `contracts/specs/BS-02-lobby/`
- **Backend/BO**: `../team2-backend/CLAUDE.md` → `../contracts/api/API-01-*.md`
- **Game Engine**: `../team3-engine/CLAUDE.md` → `team3-engine/specs/engine-spec/`, `team3-engine/specs/games/`
- **Command Center**: `../team4-cc/CLAUDE.md` → `contracts/specs/BS-05-command-center/`

### 4단계 — 참고 자료
- `00-reference/PokerGFX-User-Manual.md` — 벤치마크 매뉴얼
- `07-archive/01-pokergfx-analysis/` — PokerGFX 역설계 상세 분석

## 문서 표준

모든 문서는 WSOP LIVE Confluence 표준을 따른다. Edit History 테이블, 개요, 상세, 검증/예외 섹션, 기능별 경우의 수 열거, 상태값 테이블, 트리거 발동 주체 명시 — 상세는 `../CLAUDE.md > 문서 표준` 참조.
