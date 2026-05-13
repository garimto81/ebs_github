---
id: IMPL-001
title: "구현: 4팀 Backlog 3-Type retag + archive 정리"
type: implementation
status: PENDING
owner: each_team  # 각 팀 세션에서 자기 Backlog 에 대해 실행
created: 2026-04-20
spec_ready: true
blocking_spec_gaps: []
implements_chapters:
  - docs/4. Operations/Spec_Gap_Triage.md
tool: tools/backlog_retag.py
---

# IMPL-001 — 4팀 Backlog 3-Type retag + archive 정리

## 배경

2026-04-20 프로젝트 의도 재정의에 따라 Backlog 를 `Spec_Gaps` / `Prototype_Scenarios` / `Implementation` / `archive` 4 범주로 분류. `tools/backlog_retag.py` 로 초기 스캔 수행 결과:

| 팀 | 총 항목 | archive | spec_gap | prototype_scenario | implementation |
|----|:------:|:-------:|:--------:|:------------------:|:--------------:|
| team1 Frontend | 54 | 38 (70%) | 4 | 2 | 10 |
| team2 Backend | 69 | 23 (33%) | 8 | 11 | 27 |
| team3 Game Engine | 19 | 18 (95%) | 1 | 0 | 0 |
| team4 Command Center | 24 | 21 (88%) | 0 | 2 | 1 |
| **합계** | **166** | **100 (60%)** | **13** | **15** | **38** |

CCR 폐기(2026-04-17) 이후 `NOTIFY-CCR-*.md` + `-DONE-*.md` 가 60% 차지. 신규 세션의 "작업 대상" 식별을 오염.

## 실행 지시 (각 팀 세션에서)

> **중요**: Conductor 세션은 팀 Backlog 를 직접 수정하지 않습니다 (Ownership & Scope Guard v5). 각 팀 세션에서 아래 절차를 수행해 주세요.

### Step 1 — 현황 파악

```bash
cd C:/claude/ebs
python tools/backlog_retag.py --scan "docs/2. Development/2.N XXX/Backlog/" --summary
python tools/backlog_retag.py --scan "docs/2. Development/2.N XXX/Backlog/"  # 상세 제안
```

(팀별 경로는 `2.1 Frontend`, `2.2 Backend`, `2.3 Game Engine`, `2.4 Command Center` 중 자기 것)

### Step 2 — archive 정리

archive 로 제안된 파일들 (`NOTIFY-CCR-*`, `NOTIFY-LEGACY-CCR-*`, `-DONE-YYYY-MM-DD.md`):

1. 팀 Backlog 아래 `_archived-2026-04/` 서브폴더 생성
2. archive 분류 파일을 이동 (`git mv` 사용)
3. README.md 에 "CCR 폐기 전 history" 주석

```bash
mkdir -p "docs/2. Development/2.N XXX/Backlog/_archived-2026-04"
# 스크립트 출력에서 [archive] 표시된 파일만 이동
```

### Step 3 — spec_gap / prototype_scenario / implementation 리레이블

나머지 파일은 내용 확인 후 frontmatter 에 `type:` 필드 추가:

```yaml
---
id: B-XXX
title: "..."
status: PENDING
type: spec_gap  # 또는 prototype_scenario / implementation
source: 원본 경로 (있을 시)
---
```

원래 없던 frontmatter 가 많으므로 아래 템플릿 참조:
- `docs/4. Operations/Conductor_Backlog/_template_spec_gap.md`
- `docs/4. Operations/Conductor_Backlog/_template_prototype_scenario.md`
- `docs/4. Operations/Conductor_Backlog/_template_implementation.md`

### Step 4 — 폴더 구조 (선택적)

팀에 따라 Backlog/ 아래를 3 서브폴더로 분할해도 됨:

```
Backlog/
├── Spec_Gaps/
├── Prototype_Scenarios/
├── Implementation/
└── _archived-2026-04/
```

단, 이 단계는 거버넌스 v7 `free_write_with_decision_owner` 상 팀 재량. 단일 폴더에 frontmatter `type` 필드로 구분해도 무방.

## 수락 기준

- [ ] 팀 Backlog 의 `NOTIFY-CCR-*.md` + DONE 파일 100% 이동
- [ ] 나머지 항목의 `type` frontmatter 부여
- [ ] `python tools/backlog_retag.py --scan <팀경로> --summary` 에서 archive 비율 10% 미만
- [ ] 팀 CLAUDE.md 에 Backlog 경로 갱신 안내

## 완료 보고

각 팀 완료 시 이 파일 `status: DONE` 으로 변경 + `completed_by: [팀명, 날짜]` 추가.

## 관련

- `tools/backlog_retag.py` — 재실행 가능
- `docs/4. Operations/Spec_Gap_Triage.md` — 3-Type 프로토콜
