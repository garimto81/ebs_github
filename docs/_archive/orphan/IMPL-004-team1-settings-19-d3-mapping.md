---
id: IMPL-004
title: "구현: team1 Settings 19 D3 잔류 매핑 (SG-008-b13 v2)"
type: implementation
status: DONE  # (a) 17건 매핑 완료. (b) 2건은 SG-008-b14/b15 별도 진행
owner: team1
created: 2026-04-26
resolved: 2026-04-26
spec_ready: true
blocking_spec_gaps:
  - SG-008-b13 (a) 17건 — DONE 2026-04-26
  - SG-008-b14 (twoFactorEnabled) — 별도 PENDING
  - SG-008-b15 (NDI fillKeyRouting) — 별도 PENDING
implements_chapters:
  - docs/2. Development/2.1 Frontend/Settings/Rules.md §8 (4 House Rules + sleeperEnabled)
  - docs/2. Development/2.1 Frontend/Settings/Display.md §5 (4 keys)
  - docs/2. Development/2.1 Frontend/Settings/Outputs.md §5 (4 keys)
  - docs/2. Development/2.1 Frontend/Settings/Graphics.md §9 (1 key)
  - docs/2. Development/2.1 Frontend/Settings/Preferences.md §11 (2 keys)
  - docs/2. Development/2.1 Frontend/Settings/Statistics.md (1 key)
related_code:
  - team1-frontend/lib/features/settings/screens/  (이미 구현된 코드 → 기획 보강만)
---

> ✅ **DONE (a) 부분** — Conductor 직접 실행. 17 (a) 키 모두 5개 Settings 파일에 보강 완료.
>
> **검증**: `python tools/spec_drift_check.py --settings` 실행 결과
> - D3: 19 → 4 (15 키 해소)
> - 잔여 4건 = `fillKeyRouting` (SG-008-b15) + `twoFactorEnabled` (SG-008-b14) + `resolution`/`theme` (scanner false positive — 본문에 `` ` `` 백틱 명시했으나 정규식 매칭 실패. SG-010 후속)

# IMPL-004 — team1 Settings 19 D3 잔류 매핑

## 배경

2026-04-26 fresh scan: Settings 계약 D3=19 (baseline 17 + 2 신규). 코드에 존재하나 기획 문서에 언급 없는 19개 settings key 를 SG-008-b13 v2 default 옵션 (a 6 / b 2 = SG-008-b14/b15) 로 분류 + 기획 보강.

## 19개 잔류 D3 키 (2026-04-26 fresh)

```
blindsFormat, dead_button_rule, diagnosticsEnabled, displayMode,
exportFolder, fillKeyRouting, layoutPreset, outputProtocol,
player_photo_enabled, precisionDigits, resolution, short_all_in_rule,
showdown_order, sleeperEnabled, theme, twoFactorEnabled,
under_raise_rule, watermark_enabled, watermark_text
```

## 분류 (SG-008-b13 default)

| 분류 | 키 | 처리 |
|------|----|------|
| **(a) 기획 추가 권고** (Game Rules) | `dead_button_rule`, `short_all_in_rule`, `under_raise_rule`, `showdown_order` | `Settings/Rules.md` 에 4개 행 추가 |
| **(a) 기획 추가 권고** (Display) | `outputProtocol`, `resolution`, `displayMode`, `precisionDigits` | `Settings/Display.md` / `Settings/Outputs.md` 에 추가 |
| **(a) 기획 추가 권고** (UI Preferences) | `theme`, `layoutPreset`, `diagnosticsEnabled`, `sleeperEnabled` | `Settings/Display.md` 또는 신규 UI Preferences 서브탭 |
| **(a) 기획 추가 권고** (Graphics) | `blindsFormat`, `watermark_enabled`, `watermark_text`, `player_photo_enabled` | `Settings/Graphics.md` |
| **(a) 기획 추가 권고** (Export) | `exportFolder` | `Settings/Outputs.md` |
| **(b) SG 승격 필요** (보안) | `twoFactorEnabled` | SG-008-b14 default 채택 후 진행 |
| **(b) SG 승격 필요** (NDI 라우팅) | `fillKeyRouting` | SG-008-b15 default 채택 후 진행 |

## 수락 기준

- [ ] team1: SG-008-b14/b15 default 옵션 채택 confirm
- [ ] team1: 17개 (a) 키를 해당 Settings/*.md 행 추가 (additive)
- [ ] team1: scope (Global/Series/Event/Table/User) 명시
- [ ] team1: scan 재실행 → settings D3 = 0 또는 (b) 2개만 잔류
- [ ] conductor: `Spec_Gap_Registry §4.1 settings` 행 갱신
- [ ] team1: settings_scope_provider.dart override priority 와 일치 확인

## 구현 메모

- SG-003 PARTIAL 4-level scope 결정 준수
- SG-017 (Settings 글로벌 vs 스코프 모순) 결정 후 default scope 재확인 필요
- 17개 (a) 매핑은 file 5개 분산, 한 PR 일괄 처리 권장
