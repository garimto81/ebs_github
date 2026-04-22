---
id: B-209
title: "회의 D3 GE 제거 결정 — 전체 전파 (Conductor + team1/team2/team4)"
status: IN_PROGRESS
source: docs/4. Operations/Conductor_Backlog.md
priority: P0
related_plan: docs/4. Operations/Foundation_Alignment_Plan.md
related_meeting: docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md §3 D3
supersedes: SG-004
last-updated: 2026-04-22
---

# B-209 — 회의 D3 "GE 제거" 결정 전파

## 배경

2026-04-22 회의 D3 결정:

> "사내 그래픽 에디터 제거. Rive 파일이 모든 메타데이터 정의. 별도 GE 앱 불필요."

Critic 판정: **GO-WITH-REVISION** — "별도 GE 앱 불필요" 확정, 단 Lobby Web 내 **Rive 파일 관리 섹션 (업로드/검증/활성화)** 최소 UI 는 유지.

원본 GE 범위: `Import (GEI) + Metadata (GEM) + Activate (GEA) + RBAC (GER)` (BS_Overview §7.4)
**축소 후**: `Import (GEI) + Activate (GEA) + RBAC (GER)` — GEM 25 항목 전부 SUPERSEDED, Rive 파일 내장으로 대체.

## 수용 기준 (Conductor 단계)

- [x] Foundation.md Ch.9 L610 "그래픽 편집기" 문장 D3 반영 (`7f85c0a` 예정)
- [x] 1. Product.md §2 렌즈 설치 단위 5 재분류 + GE → Rive 파일 관리
- [x] BS_Overview §1 Graphic Editor 행 → Rive Manager 축소
- [x] BS_Overview §7.4 GEM-* 25 Metadata SUPERSEDED 마킹 + 섹션 헤더 경고
- [x] SG-004 status: RESOLVED → SUPERSEDED (by B-209)
- [x] Spec_Gap_Registry §4.4 SG-004 SUPERSEDED 행 추가
- [ ] team-policy.json `contract_ownership.Graphic_Editor_API` 의 publisher/subscriber 재검토 (GE API 가 축소 범위만 유지되는지)
- [ ] Foundation_Alignment_Plan v1.2 에 D3 섹션 추가

## 팀 세션 위임 (Conductor 영역 밖)

| 대상 | 작업 | 소유 팀 | 상태 |
|------|------|:-------:|:----:|
| `docs/2. Development/2.1 Frontend/Graphic_Editor/` 7 문서 | archive 또는 축소 재작성 (Import/Activate/RBAC 만 유지, Metadata 관련 GEM 내용 제거) | **team1** | PENDING |
| `team1-frontend/` 코드 (GEM-* 관련 UI) | Metadata 편집 UI 제거 또는 기능 축소 | **team1** | PENDING |
| `docs/2. Development/2.2 Backend/APIs/Graphic_Editor_API.md` | GEM-* 관련 REST endpoint 축소 (있을 경우) | **team2** | PENDING |
| `docs/2. Development/2.4 Command Center/Overlay/` | `.gfskin` 컨테이너 소비 로직 — 포맷 재설계 반영 | **team4** | PENDING |

notify: team1, team2, team4 (v7 free_write + decision_owner)

## 미해결 설계 결정 (B-209 하위 Task)

### B-209-1: `.gfskin` 컨테이너 재설계

D3 로 메타데이터가 Rive 내장 → `manifest.json` 의 `skin_name`/`version`/`colors`/`fonts`/`animations` 필드가 **중복 또는 모순 소스** 가 됨. 선택지:

| 옵션 | 설명 |
|:---:|------|
| **α** | `.gfskin` ZIP 유지. `manifest.json` 을 최소화 (skin_id + preview 만). 메타데이터는 Rive 가 SSOT |
| **β** | `.gfskin` 컨테이너 폐기. `.riv` 파일 단일 업로드. preview.png 는 Lobby Web 이 runtime 생성 |
| **γ** | `.gfskin` ZIP 유지. `manifest.json` 과 Rive 내장 메타를 비교 검증 (drift 경고) |

default 안: **β** (컨테이너 단순화) — YAGNI. α 는 assets/ 외부 리소스 필요 시 부활 가능.
decision_owner: conductor + team1 publisher

### B-209-2: "Metadata 는 Rive 내장" 의 구체 범위

Rive 가 저장할 수 있는 것과 없는 것 경계:

- **Rive 가 다룰 수 있음**: 색상, 폰트 (embed), 애니메이션 duration, 이미지 asset
- **Rive 가 불편함**: 다국어 텍스트 (WSOP LIVE 선수 이름/메달 문자열), 조건 분기 (WSOP vs WSOPE 스킨 변형)
- **Rive 로 불가능**: 숫자 포맷 (통화/구분 기호, 한국어 vs 영문 숫자 표기), 테이블 별 설정

비-그래픽 데이터는 Lobby Settings 에서 관리되어야 함. 현재 Settings Display/Rules 탭과 경계 명확화 필요.

decision_owner: conductor + team1

### B-209-3: Lobby Web Rive Manager UI 최소 명세

- Upload (파일 선택 + ZIP 또는 .riv 구조 검증)
- Validate (Rive 파싱 가능성 + 필수 데이터 슬롯 존재 확인)
- Preview (Rive 런타임 프리뷰 — 동일 `.riv` 바이너리 Overlay 와 공유)
- Activate (`PUT /skins/{id}/activate` + 멀티 CC broadcast)
- RBAC gate (Admin only)

**Metadata 편집 UI 없음** (GEM-01~25 전부 삭제). 아트 디자이너가 외부 Rive Editor 로 편집 후 재업로드.

decision_owner: team1

## 의존 관계

- **Foundation §4.4 / §5.1** — γ 하이브리드 (2026-04-22) 확정 후 본 B-209 진행 가능 ✅
- **SG-004 SUPERSEDED** 전환 — B-209 와 동시에 수행 ✅
- **B-200 (Foundation 재설계 정렬)** — 상위 backlog

## 참조

- `docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md §3 D3`
- `docs/4. Operations/Plans/Redesign_Plan_2026_04_22.md`
- `docs/4. Operations/Conductor_Backlog/SG-004-gfskin-zip-format.md` (SUPERSEDED)
- `docs/2. Development/2.5 Shared/BS_Overview.md §1, §7.4`
- `docs/1. Product/Foundation.md §4.4, §9.3`
