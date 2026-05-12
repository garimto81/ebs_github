---
id: SG-041
title: "기획-구현 drift: overlay/layer1 widget 3종 누락 — Branding STUB / Blind STUB / Field MISSING"
type: spec_drift
status: IN_PROGRESS
owner: conductor
created: 2026-05-13
affects_chapter:
  - team4-cc/src/lib/features/overlay/layer1/ (Flutter widget tree)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md (overlay widget spec)
  - docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md (OE-12~21 번호 정렬 — B-356 closure)
  - team2-backend/.../routers/field_status.py (신규, ITM/remaining/FT API)
protocol: Spec_Gap_Triage
audit_report: docs/4. Operations/Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md
cycle: 17
broker_topic: pipeline:gap-classified (Cycle 16 trigger, S10-W 수행)
related_sg:
  - SG-040 (Foundation/RIVE 9 카테고리 재편 — 본 SG 의 spec 진입 조건)
  - B-356 (OE-12~21 번호 매핑 — D-5 closure)
---

# SG-041 — overlay/layer1 widget 3종 누락 (Type D drift)

## 공백 서술

User 9 카테고리 중 **#6 이벤트 브랜딩 / #7 블라인드 정보 / #9 필드 현황판** 의 overlay/layer1 구현이 spec 과 drift 상태다. 이 3 widget 은 **사용자 시청자 화면 필수** 인데 현재 코드 기반에서 다음과 같이 부재 또는 STUB.

```
+---------------+---------+-------------------+---------------------+------------------------+
| User 9 cat #  | 명칭     | spec 위치           | 코드 상태             | drift 유형               |
+---------------+---------+-------------------+---------------------+------------------------+
| #6            | Branding | RIVE Ch.2 #10     | STUB                | scene_schema 파라미터만 |
| #7            | Blind    | RIVE Ch.2 #7      | STUB (overlay)      | backend 완전, widget 부재 |
| #9            | Field    | RIVE Ch.2 #8      | MISSING (overlay)   | DB total_entries만, API 없음 |
+---------------+---------+-------------------+---------------------+------------------------+
```

**Type D (기획-구현 drift) 5건 중 P0=3건 + P1=1건 + P0=1건 (OE 번호 inconsistency, B-356 carry-over).**

| 분류 | ID | 영역 | 갭 내용 |
|------|:--:|------|---------|
| Type D | D-1 | `team4-cc/.../overlay/layer1/` (Branding) | `scene_schema.dart` 에 `logoPath` 파라미터 + `BrandingOverrides` 선언만. 실제 로고 렌더링 위젯 / 전용 overlay 레이어 부재. spec(RIVE #10) ↔ 구현 zero. |
| Type D | D-2 | `team4-cc/.../overlay/layer1/` (Blind) | backend `blind_structures.py` CRUD + 레벨 API 완전, team1 `blind_structure_provider.dart` + `levels_strip.dart` 존재. **overlay layer1 에 blind/level 전용 위젯 없음** + `scene_schema` 미포함. spec(RIVE #7) ↔ overlay 구현 zero. |
| Type D | D-3 | `team4-cc/.../overlay/layer1/` (Field) | backend `models/competition.py` 의 `total_entries`, `entries` 필드만. **ITM / `remaining_players` / FT 전용 API 없음, overlay widget 전무.** spec(RIVE #8 "토너먼트 상태") ↔ 구현 zero. |
| Type D | D-4 | `team4-cc/.../overlay/layer1/equity_bar.dart` | `equity_bar.dart` (34 라인) 가 % 텍스트만 표시. RIVE #4 "Hand Strength + Equity **확률 시각화**" 와 drift. UI-02 명시. UX 약화. |
| Type D | D-5 | `OutputEvent_Serialization.md` OE-12~21 vs `Overlay_Output_Events.md §6.0` | publisher 실측 ↔ OutputEvent_Serialization.md 의 OE 번호 매핑 불일치. **B-356 PENDING P1 (carry-over Cycle 12+).** 외부 인계 팀 OE 매핑 오인 위험. |

## 발견 경위

- **트리거**: SG-040 의 사용자 인텐트 (9 카테고리) 와 4-source 매트릭스 (Cycle 16 audit) 에서 코드 구현 상태 점검 결과.
- **S10-A audit**: `Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md` (PR #395 merged) — §2 4-way 매핑 매트릭스 의 "team1~4 구현" 열 분석.
- **실패 분류**: Type D (기획-구현 drift) — spec 은 명시(RIVE Ch.2), 구현이 부재 또는 STUB. spec 진실 + code stale 정합 방향.
- **연결 ID**: SG-040 (Foundation/RIVE 9 카테고리 재편 — 본 SG 의 spec 진입 조건). B-356 carry-over (OE-12~21 번호 매핑, D-5 closure 함께).
- **rebase 노트**: 작업 당시 SG-039 등재 시도했으나 Cycle 15 audit (PR #392) 이 같은 ID 를 Settings IA migrate drift 로 먼저 점유 → SG-041 재할당. 작업 내용은 보존.

## 영향받는 챕터 / 구현

| 챕터 / 코드 | drift 내용 | Gap ID |
|------------|----------|:------:|
| `team4-cc/src/lib/features/overlay/layer1/branding_layer.dart` | **존재하지 않음** (신규 widget 필요). `scene_schema.dart logoPath` 만 declarative. | D-1 |
| `team4-cc/src/lib/features/overlay/layer1/blind_panel.dart` | **존재하지 않음** (신규 widget 필요). backend API + team1 provider 완전, overlay 부재. | D-2 |
| `team4-cc/src/lib/features/overlay/layer1/field_status.dart` | **존재하지 않음** (신규 widget 필요). DB `total_entries` 만, ITM/FT API 부재. | D-3 |
| `team4-cc/src/lib/features/overlay/layer1/equity_bar.dart` (34 라인) | % 텍스트만, progress bar 부재. RIVE #4 시각화 요구 미충족. | D-4 |
| `team2-backend/.../routers/field_status.py` | **존재하지 않음** (신규 API 필요). `models/competition.py` 의 `total_entries` 외 ITM/remaining/FT 노출 X. | D-3 |
| `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` | overlay widget 3종 spec 부재 — 외부 개발팀 인계 시 구현 진입점 없음. | D-1, D-2, D-3 |
| `docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md` | OE-12~21 번호 정렬 — `Overlay_Output_Events.md §6.0` 실측과 불일치. | D-5 |

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| **1. spec 정합 후 implementation cascade** (S10-A audit §6 권고) | SG-040 정합 후 SG-041 진입 — 구현팀 명세 단일 진입점 보장. 5 widget + 1 API 신규 (P0 3 + P1 2). | spec 후속 cycle 머지 대기 시간. | ✅ |
| 2. spec 갱신 없이 즉시 implementation | 구현 가속. | spec drift 영구화. 외부 인계 시 OE/widget 매핑 분실. | ❌ |
| 3. spec/구현 동시 PR (단일 PR scope) | 단일 PR 머지 한 번. | scope 폭증 — Reader Panel + qa-tester 동시 검증 부담. | △ |
| 4. SUPERSEDE: D-1~D-3 widget 을 RIVE 단일파일에 흡수 | 코드 양 감소. | RIVE 외부 (시계/Field) 인터랙션 미지원. Foundation §5.3 `.riv` 단일파일 정책 vs widget tree 정책 충돌. | ❌ |

## 결정

- **채택**: **대안 1** (spec 정합 후 implementation cascade).
- **이유**:
  1. SG-040 spec cascade 가 진입 조건. RIVE/Foundation/CC/UI 정합 없이 widget 만 만들면 spec drift 가 영구화.
  2. team4-cc widget tree 정책 (Foundation §5.3 `.riv` + Flutter widget 조합) 유지 — 시계/Field 등 RIVE 외부 인터랙션 (CC 명령 ↔ widget state) 보존.
  3. D-5 (OE 번호 정렬) 는 spec 정합 측 작업 — B-356 closure 와 함께 SG-040 cascade 에 흡수.
- **영향 챕터 업데이트 PR**: 본 PR (S10-W cycle 17, **카드+Registry 등재만**). SG-041 구현은 후속 S2 (Lobby/CC) + S7 (Backend) cascade.
- **후속 구현 Backlog 이전**: `../Implementation/B-CC-OVERLAY-WIDGETS-3.md` (team4 + team2 인계 매트릭스)

## 결정 후 follow-up

| 후속 항목 | 담당 stream | 우선순위 | trigger |
|----------|------------|:-------:|---------|
| `Command_Center_UI/Overview.md` overlay widget 3종 spec NEW sections | S10-W (후속 cycle) | **P0** | SG-040 Foundation 정합 후 |
| `OutputEvent_Serialization.md` OE-12~21 번호 정렬 (B-356 closure) | S10-W (후속 cycle) | **P0** | SG-040 RIVE 정합 후 |
| `team4-cc/.../overlay/layer1/branding_layer.dart` 신규 widget | S2 / S3 (CC) | **P0** | UI spec 후 |
| `team4-cc/.../overlay/layer1/blind_panel.dart` 신규 widget + `scene_schema` 통합 | S2 / S3 (CC) | **P0** | UI spec 후 |
| `team4-cc/.../overlay/layer1/field_status.dart` 신규 widget | S2 / S3 (CC) | **P0** | UI spec 후 |
| `team2-backend/.../routers/field_status.py` ITM/remaining/FT 전용 API 신규 | S7 (Backend) | P1 | UI spec 후 |
| `team4-cc/.../overlay/layer1/equity_bar.dart` progress bar 추가 (UI-02) | S2 / S3 (CC) | P1 | OE 매핑 후 |

## D-5 (B-356) 상세 — OE 번호 매핑 정렬

| 항목 | 값 |
|------|----|
| B-356 status | PENDING P1 (carry-over Cycle 12+) |
| Issue | (cycle 17 broker re-publish) |
| spec source A | `docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md` (선언 정의) |
| spec source B | `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md §6.0` (publisher 실측 catalog) |
| 정합 방향 | publisher 실측 (source B) 가 진실 — `OutputEvent_Serialization.md` 의 OE-12~21 번호 정렬 갱신. |
| closure trigger | SG-040 cascade 의 OutputEvent 정합 PR (S10-W 후속 cycle). |

---

## Edit History

| 날짜 | 작성자 | 변경 |
|------|--------|------|
| 2026-05-13 | S10-W | 초판 — Cycle 17 SG-041 신규 카드. Cycle 16 audit (PR #395) 의 §7 SG-041 신규 등재 권고 후속. Type D 5건 (P0 3 + P1 2) 분류. 대안 1 (spec 정합 후 implementation cascade) 채택. SG-040 spec 진입 조건 명시. B-356 carry-over 명시. |
