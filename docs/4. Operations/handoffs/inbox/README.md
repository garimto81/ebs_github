# Session-Bridge Inbox (S11 Cycle 3)

> 자동 drop 영역. observer_loop `--action-mode` 가 broker event 의 `payload.next_action.type == "inbox-drop"` 신호를 받아 markdown 으로 떨어뜨린다.

## 흐름

```
[hook publish] -> broker -> [observer_loop --action-mode] -> {topic-slug}_seqNNN_to-{target}.md
```

## 파일 형식

frontmatter (source / topic / seq / ts / target / action_type / observer_dropped_at) + 본문 (Payload JSON).

## 처리 룰

| target | 처리 stream | SLA |
|--------|------------|-----|
| `all` | 모든 stream 자유 참조 | best effort |
| `S2,S3,S7,S8` | 도메인 4 SessionStart 시 inbox 점검 | 24h |
| `S9,S10-A` | QA + Gap Analysis 즉시 triage | 4h |
| `conductor` | 메인 세션 검토 후 redistribute | 12h |

## 정리

상대 stream 이 처리 완료 시 본 디렉토리에서 archive 로 이동:
`docs/4. Operations/handoffs/inbox/_archive/YYYY-MM/`

자동 archive: TBD (Cycle 4+ 후속).

---
Owner: S11 (Dev Assist Stream)  
신설: 2026-05-11 Cycle 3 (Issue follow-up)
