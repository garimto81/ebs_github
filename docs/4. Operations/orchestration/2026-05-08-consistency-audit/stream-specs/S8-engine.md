---
owner: conductor
tier: internal
stream: S8
name: Game Engine
worktree: C:/claude/ebs-engine-stream
phase: P2 (정합성 감사 — 활성화)
blocked_by: S1
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
note: "2026-05-08 정합성 감사용 활성화. team_assignment v10.3 에서 streams.S8 로 promote 완료."
last-updated: 2026-05-08
confluence-page-id: 3819209416
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209416/EBS+S8+Game+Engine+spec
---

# S8 Game Engine — 정합성 감사 작업 spec

## 🎯 미션

**2.3 Game Engine 전 영역 ↔ Foundation §10 (22 룰) ↔ Game_Rules 4 cascade**.

## 📂 영향 파일 (62)

| 영역 | 패턴 |
|------|------|
| APIs | `docs/2. Development/2.3 Game Engine/APIs/**` |
| Backlog | `docs/2. Development/2.3 Game Engine/Backlog/**` |
| Behavioral_Specs | `docs/2. Development/2.3 Game Engine/Behavioral_Specs/**` |

## ✅ 검증 항목

1. **22 게임 룰 (Foundation §10)**: 12 + 7 + 3 = 22 합 일치
2. **Mixed Game (Foundation §10)**: HORSE 5종 / 8-Game 8종 정확
3. **21 OutputEvent (Foundation §B.1)**: 모든 OutputEvent 카탈로그 일관
4. **Engine = SSOT (Foundation §11)**: gameState 응답 = 게임 상태 truth
5. **Engine = Pure Dart (Foundation §7)**: 스택 정합
6. **Engine = 코드 내장 상수**: 매 핸드 외부 입력 X (Foundation §3)
7. **Game_Rules 4 ↔ Engine Behavioral_Specs**: 각 룰의 외부 측 ↔ 내부 측 정합
8. **CC → Engine REST stateless query (Foundation §11)**: API 정합

## 🔄 자율 Iteration

```
1. python tools/doc_discovery.py --impact-of "docs/1. Product/Game_Rules/Flop_Games.md"
2. Behavioral_Specs/** ↔ Game_Rules 4 cascade
3. APIs/ ↔ Foundation §11 통신 매트릭스
4. 21 OutputEvent 카탈로그 self-consistency
5. drift 정정
6. PR ready (Game_Rules drift 발견 시 NOTIFY-S1 backlog)
```

## 🚫 금지

- `Game_Rules/*.md` 직접 수정 → S1 영역
- 다른 Stream 영역 수정
- meta files 수정

## 📋 PR 체크리스트

- [ ] 22 룰 합 일치
- [ ] HORSE / 8-Game 정확
- [ ] 21 OutputEvent 일관
- [ ] Game_Rules cascade 보증 (drift = NOTIFY-S1)
- [ ] PR title: `docs(s8-engine): consistency audit 2026-05-08`
- [ ] PR label: `stream:s8`, `consistency-audit`
