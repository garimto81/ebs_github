---
title: Conductor_Backlog
tier: internal
decomposed: true
confluence-page-id: 3818586692
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818586692/EBS+Conductor_Backlog
owner: conductor
---

# Conductor_Backlog (디렉토리화됨)

이 파일은 멀티 세션 충돌 방지를 위해 **항목별 파일**로 분해되었습니다.

- 항목 위치: `./Conductor_Backlog/` (6개 항목)
- 신규 항목 추가: `./Conductor_Backlog/{ID}-{slug}.md` 작성 (frontmatter 필수)
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
