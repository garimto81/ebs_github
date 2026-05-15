---
id: doc-wiki-schema-v0.1
title: "Doc Wiki Schema -- Stream-Owned Topic Wiki"
type: meta_schema
status: DRAFT
owner: SMEM
tier: meta
mirror: none
created: 2026-05-14
---

# Doc Wiki Schema -- v0.1 DRAFT

PR #476 (S10-W) 에서 frame 정의. S11 도구 구현 PR.

## 디렉토리 레이아웃

```
docs/_meta/doc-wiki/
  _schema.md       -- 본 파일 (구조 정의)
  Index.md         -- topic 9개 -> wiki 페이지 매핑 (자동 생성)
  Log.md           -- append-only event log
  candidates/      -- PR Draft 대기 영역
  <topic>.md       -- topic 별 wiki 1 페이지
```

## 5 event 형식

```
2026-05-14T09:30:00Z [ingest      ] lobby                src=docs/.../Overview.md  reason=PR-#NNN merged
2026-05-14T09:31:00Z [lint        ] lobby                result=PASS  tokens=312  drift=0%
2026-05-14T09:32:00Z [supersede   ] back-office          prev=old.md  now=new.md
2026-05-14T09:33:00Z [contradict  ] command-center       with=lobby  resolution=SG-NNN
2026-05-14T09:34:00Z [prune       ] qa-e2e               removed=obsolete.md  reason=archive
```
