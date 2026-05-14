---
id: doc-wiki-log
title: Doc Wiki Log — Append-Only 이벤트 기록
type: meta_log
tier: meta
confluence-sync: false
owner: SMEM
append-only: true
status: ACTIVE
created: 2026-05-14
legacy-id: null
derivative-of: docs/_meta/doc-wiki/_schema.md
---

# Doc Wiki Log

> **append-only 원칙**: 이 파일의 기존 내용 삭제/수정 절대 금지.
> PR merge 시 자동 추가 예정 — `log-md-append.yml` (S11 후속 PR).
> 수동 추가 시: 아래 형식 엄수 + `## LOG ENTRIES BEGIN` 주석 아래에만 추가.

## 5 이벤트 형식

| event | trigger | 책임 stream | 의미 |
|-------|---------|:----------:|------|
| `ingest` | raw docs PR merge 완료 | 해당 owner_stream | source_files 흡수 + wiki 본문 갱신 |
| `lint` | wiki 본문 변경 / 주간 재계산 | SMEM | mtime drift 감지, stale wiki 보고 |
| `supersede` | source file 이동/이름 변경 | owner_stream + SMEM | 이전 → 신규 파일 대체 |
| `contradict` | 두 wiki 정의 충돌 발견 | S10-A (Gap Registry) | 사람 개입 필요 표시 |
| `prune` | source file 삭제/archive 이동 | owner_stream + SMEM | stale source 제거 |

## 로그 라인 형식

```
YYYY-MM-DDTHH:MM:SS+09:00 [event]  topic           key=value key=value
```

예시:
```
2026-05-14T19:00:00+09:00 [ingest]      lobby           src=docs/2.1.../Lobby/Overview.md  reason=PR-#NNN merged
2026-05-14T19:01:00+09:00 [lint]        lobby           result=PASS  tokens=312  drift=0%
2026-05-14T19:02:00+09:00 [supersede]   back-office     prev=old.md  now=new.md
2026-05-14T19:03:00+09:00 [contradict]  command-center  with=lobby  resolution=SG-NNN 신규
2026-05-14T19:04:00+09:00 [prune]       qa-e2e          removed=obsolete.md  reason=archive
```

---

<!-- LOG ENTRIES BEGIN — PR merge 자동 append 대기 (S11 log-md-append.yml 구현 후 자동화) -->
