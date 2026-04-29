---
title: Task Dispatch Board (분해 디렉토리)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.3
related: ["../Task_Dispatch_Board.md", "../../2. Development/2.5 Shared/team-policy.json"]
---

# Task Dispatch Board — 팀별 file 분해 (M2 해소 scaffold)

> **V9.3 M2 해소** (2026-04-29): v8.0 phase 6 가 폐기한 L0 와 동형의 단일 file race 문제를 팀별 file 분리로 해소.
>
> v9.3 PR 첫 도입 시점에는 본 디렉토리는 scaffold (가이드만). 실제 row 이동은 후속 cycle.

## 📁 분해 구조 (계획)

| File | 소유 |
|------|------|
| `conductor.md` | Conductor cross-team / infra task |
| `team1.md` | Team 1 Frontend dispatch |
| `team2.md` | Team 2 Backend dispatch |
| `team3.md` | Team 3 Game Engine dispatch |
| `team4.md` | Team 4 Command Center dispatch |

각 file 은 본인 팀 row 만 포함. 통합 view 는 `tools/dispatch_aggregate.py` 가 자동 생성하여 `../Task_Dispatch_Board.md` 의 활성 작업 큐 섹션을 갱신.

## 🔄 운영 변화

### V9.0~V9.2 (단일 file)
```
docs/4. Operations/Task_Dispatch_Board.md
  ├── 활성 작업 큐
  │   ├── Team 1 row (worker A 가 편집)
  │   ├── Team 2 row (worker B 가 편집)
  │   └── ... (race risk)
```

### V9.3 (분해)
```
docs/4. Operations/
├── Task_Dispatch_Board.md              ← 운영 가이드 + 통합 view
└── Task_Dispatch_Board/
    ├── conductor.md                     ← Conductor 만 편집
    ├── team1.md                         ← team1 만 편집
    ├── team2.md                         ← team2 만 편집
    ├── team3.md                         ← team3 만 편집
    └── team4.md                         ← team4 만 편집
```

각 worker 가 자기 file 만 편집 → row-level race 해소.

## ⚙️ 통합 view 자동 생성

```bash
python tools/dispatch_aggregate.py
# 출력: docs/4. Operations/Task_Dispatch_Board.md 의 활성 큐 섹션 갱신
```

CI workflow 가 PR open/sync 시 자동 실행 → 본문 항상 최신.

## 🚧 후속 작업 (별도 PR)

- 실제 row 이동 (현 `Task_Dispatch_Board.md` § 활성 작업 큐 → 팀별 file)
- `tools/dispatch_aggregate.py` 구현
- `.github/workflows/dispatch-aggregate.yml` 자동 실행

본 scaffold 는 분해 모델의 정책 명세. 실제 분해는 board 사용 cycle 가 충분히 누적된 후 진행.

## 📐 V9.3 critic 결함 매핑

| ID | 결함 | 본 scaffold 의 해소 |
|----|------|---------------------|
| **M2** | 단일 file git race (v8.0 phase 6 폐기 L0 와 동형) | 팀별 file 분리 모델 명세 — 실제 분해는 후속 PR |

## 🔗 관련

- `../Task_Dispatch_Board.md` — 통합 가이드 + 운영 규칙
- `../../2. Development/2.5 Shared/team-policy.json` `task_dispatch.ssot`
- v8.0 phase 6 record: `docs/4. Operations/Reports/2026-04-28-v8-phase6-l0-removal-record.md`
