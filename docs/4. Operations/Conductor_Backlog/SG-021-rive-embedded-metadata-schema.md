---
id: SG-021
title: "Rive 내장 메타데이터 스키마 (B-209 후속, .gfskin SUPERSEDED 대체)"
type: spec_gap
status: PENDING
owner: conductor  # decision_owner (Foundation §5.3)
decision_owners_notified: [team1, team4]
created: 2026-04-26
affects_chapter:
  - docs/1. Product/Foundation.md §5.3 Rive Manager
  - docs/2. Development/2.4 Command Center/Overlay/  (.riv 소비)
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md (스킨 업로드/활성화 endpoint)
protocol: Spec_Gap_Triage §2 Type B (기획 공백)
related:
  - SG-004 SUPERSEDED (`.gfskin` ZIP 포맷 — B-209 결정으로 대체)
  - B-209 (회의 D3 GE 제거 결정 전파)
  - SG-014 SUPERSEDED (Graphic Editor 진입점 이중화)
  - docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md D3
---

# SG-021 — Rive 내장 메타데이터 스키마

## 공백 서술

회의 D3 (2026-04-22) 결정으로 사내 Graphic Editor 와 `.gfskin` ZIP 컨테이너의 `manifest.json` 이 폐기되었다. **모든 메타데이터** (skin_name, version, colors, fonts, animation triggers, data slots) 가 Rive 파일 자체에 내장되는 방향으로 전환되었으나, **내장 메타데이터의 정규 스키마 명세** 가 부재하다.

Foundation §5.3 Rive Manager 는 4 역할(Import / Validate / Preview / Activate)을 정의하지만, **Validate 단계** 의 검증 규칙 ("필수 데이터 슬롯 존재 여부") 이 어떤 메타데이터 위치/포맷을 기준으로 하는지 미정.

## 발견 경위

- 2026-04-22 회의 D3 결정으로 SG-004 SUPERSEDED
- SG-004 frontmatter `superseded: 2026-04-22` 의 reimplementability_notes: "후속 재설계는 B-209 에서 진행"
- 2026-04-26 audit (Spec_Gap_Audit_Phase1) 에서 후속 SG 미생성 확인
- Foundation §5.3 끝줄: "상세 스펙 진화 (컨테이너 포맷 α/β/γ, Rive 내장 범위, UI 최소 명세) 는 후속 논의: B-209-ge-d3-meeting-decision.md"

## 영향받는 챕터 / 구현

- `Foundation.md §5.3`: Validate 검증 규칙 placeholder
- `2.4 Command Center/Overlay/`: `.riv` 소비 시 메타데이터 추출 경로 부재
- `2.2 Backend/APIs/Backend_HTTP.md`: 스킨 업로드 endpoint validate 로직 미정
- `team1-frontend/lib/features/rive_manager/`: Validate UI 표시 항목 미정
- `tools/validate_gfskin.py`: 기존 ZIP 검증 스크립트 — Rive 내장 검증으로 재작성 필요

## 결정 방안 후보 (컨테이너 포맷)

| 대안 | 컨테이너 | 메타데이터 위치 | 장점 | 단점 |
|:----:|---------|----------------|------|------|
| α | `.riv` 단일 파일 | Rive Custom Property (artboard 레벨) | 단순, 최소 의존 | Custom Property 표준화 필요 |
| β | `.gfskin` ZIP (overlay.riv + preview.png + assets/) | manifest.json 폐기, Rive Custom Property | preview/assets 분리 | ZIP 파싱 로직 유지 |
| γ | `.riv` + sidecar `.json` | sidecar JSON | 메타데이터 편집 용이 | 두 파일 동기화 위험 |

> **default 권고**: **대안 α** (`.riv` 단일 파일) — 회의 D3 의도("Rive 파일 자체에 내장") 가장 직접적 반영. preview/assets 는 Rive 가 자체 지원.

## 결정 방안 후보 (필수 메타데이터)

| 항목 | 위치 | 검증 규칙 |
|------|------|----------|
| `skin_name` | Custom Property `skin/name` | 비어있지 않은 string |
| `skin_version` | Custom Property `skin/version` | semver 형식 (x.y.z) |
| 데이터 슬롯 (선수 이름) | Text Run 에 binding `player.name.{seat_id}` | seat_id 1~10 모두 존재 |
| 데이터 슬롯 (카드) | Trigger `card.{seat_id}.{rank}.{suit}` | 52장 모두 정의 |
| 데이터 슬롯 (팟) | Text Run binding `pot.total` | 존재 |
| 애니메이션 트리거 | State Machine "deal", "fold", "win", "lose" | 4 트리거 모두 존재 |

## 결정 (decision_owner conductor 판정 시 기입)

- **default 권고**: 대안 α + 필수 메타데이터 표 위 채택
- 이유: 회의 D3 직접 반영 + Rive 가 표준 지원 + 단일 파일 단순성
- decision_owners_notified: team1 (Rive Manager UI), team4 (Overlay 소비)

## 후속 작업

- [ ] conductor: Foundation §5.3 에 위 메타데이터 표 명시 (additive)
- [ ] team1: Rive Manager Validate 단계 검증 로직 구현 (`Custom Property` + `Text Run binding` + `State Machine` 검사)
- [ ] team4: Overlay 런타임에서 `Custom Property` 추출 + `data slot binding` 채우기
- [ ] team2: `POST /api/v1/skins` upload endpoint 의 file validation 으로 검증 함수 호출
- [ ] conductor: `tools/validate_gfskin.py` → `tools/validate_rive_skin.py` 재작성 또는 폐기
- [ ] conductor: SG-004 frontmatter 에 SG-021 cross-ref 추가

## 검증

```bash
# 향후 테스트:
python tools/validate_rive_skin.py path/to/skin.riv
# 출력: OK / FAIL (missing slot: player.name.5)
```

## 관련 SG / B

- SG-004 SUPERSEDED — `.gfskin` ZIP 포맷 (이전 설계)
- SG-014 SUPERSEDED — Graphic Editor 진입점 이중화
- B-209 — 회의 D3 GE 제거 결정 전파
