---
title: CYCLE 4 mediation — Betting_System.md §7-5 9 keys default 패치 제안
tier: notify
stream: S8
cycle: 4
issue: 265
mediator-issue: 270
status: AWAITING_CONDUCTOR_MERGE
last-updated: 2026-05-12
patch-target: docs/1. Product/Game_Rules/Betting_System.md
patch-section: "§7-5 (NEW)"
patch-rationale: "옵션 A — Engine harness 실측 default = 진실 (사용자 권고 채택)"
---

# CYCLE 4 mediation — Betting_System.md §7-5 9 keys default 패치 제안

## 트리거

Issue #265 (S8 Cycle 4) Settings engine_rules 9 keys 정합 작업의 2차 사이클. 1차 PR #273 (머지 완료) 에서 S8 scope 안에 `Rules/Engine_Defaults.md` 신설로 KPI (engine D2 9→0) 충족. 본 2차 사이클은 사용자 권고 옵션 A 에 따라 `docs/1. Product/Game_Rules/Betting_System.md` (BLOCKED meta file) §7-5 신설을 mediation 패턴으로 요청.

## hook 차단 evidence

```
PreToolUse:Edit hook error:
⛔ BLOCK: 'docs/1. Product/Game_Rules/Betting_System.md' is META file (orchestrator only).
   To request change, add '## Meta Changes Requested' to PR body.
```

S8 worktree 의 `.team` `meta_files_blocked: docs/1. Product/Game_Rules/**` 정책 작동. 정상 거버넌스 흐름.

## 패치 제안 — Betting_System.md §7-5 (NEW)

전체 패치 본문은 **본 PR body 의 `## Meta Changes Requested` 섹션** 참조. 핵심:

| # | Settings key | Engine field | Default (실측) | 분류 |
|---|--------------|--------------|----------------|------|
| 1 | `all_in` | `Seat.isAllIn` (derived) | `false` | Engine derived |
| 2 | `allow_rabbit` | (미정의) | N/A | Overlay (team4) |
| 3 | `allow_run_it_twice` | `runItTimes != null` | `false` | Engine config |
| 4 | `ante_override` | `anteAmount + anteType` | `null + null` | Engine config |
| 5 | `bomb_pot_amount` | `bombPotAmount` | `null` (with enabled=false) | Engine config |
| 6 | `run_it_times` | `runItTimes` | `null` (=1회) | Engine config |
| 7 | `seven_deuce_amount` | `sevenDeuceAmount` | `null` (with enabled=false) | Engine config |
| 8 | `straddle_seat` | `straddleSeat` | `null` (with enabled=false) | Engine config |
| 9 | `_blindsFormatOptions` | (미정의) | N/A | Frontend (team1) |

## 실측 출처 (옵션 A 근거)

```bash
$ curl -X POST http://localhost:18080/api/session \
    -H "Content-Type: application/json" \
    -d '{"variant":"nlh","seatCount":4,"stacks":[1000,1000,1000,1000],"blinds":{"sb":5,"bb":10}}'

# 응답 (2026-05-12 실측):
{
  "anteType": null,
  "anteAmount": null,
  "straddleEnabled": false,
  "straddleSeat": null,
  "bombPotEnabled": false,
  "bombPotAmount": null,
  "sevenDeuceEnabled": false,
  "sevenDeuceAmount": null,
  "runItTimes": null,
  "isAllInRunout": false
}
```

## 사용자 권고 — 옵션 A 채택

> 옵션 A: Engine harness 실제 default (POST /api/session response) 값을 spec 화
> 옵션 B: "default 없음 — 호출자 명시 필수" 정책 보존 (2 keys 와 일치)
> 옵션 C: 옵션 A + B 혼합
>
> **권고: 옵션 A (실제 코드 값 = 진실)** — 사용자 명령 2026-05-12

옵션 A 의 자연스러운 해석: **`null` = 기능 비활성 = 호출자 명시 필요**. 이는 기존 §5-2 `bomb_pot_amount` / §5-4 `seven_deuce_amount` 의 "필수, 기본값 없음 — 매 핸드 합의" 표현과 의미적 일치. 옵션 A + B 의 통합 결론이기도 함.

## Conductor mediator 진입 가능

| consumer | 작업 |
|----------|------|
| **Conductor (S0)** | 본 PR `## Meta Changes Requested` 본문을 그대로 Betting_System.md §7-5 신설로 적용 |
| **S10-W (Issue #270)** | 본 PR cross-link 후 pipeline:spec-patched broker publish → 후속 stream 신호 |

## 다음 cascade

본 PR ready 시 `cascade:engine-spec-aligned` republish (옵션 A 채택 ack). seq 누적.

## 참조

- Issue #265 (S8 Cycle 4): https://github.com/garimto81/ebs_github/issues/265
- Issue #270 (S10-W mediator): https://github.com/garimto81/ebs_github/issues/270
- Cycle 4 1차 PR (merged): #273
- Engine SSOT 코드: `team3-engine/ebs_game_engine/lib/core/state/game_state.dart`
- Engine 영역 contract: `docs/2. Development/2.3 Game Engine/Rules/Engine_Defaults.md` (PR #273 머지본)
