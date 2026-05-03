---
id: SG-019
title: "Reports/Insights 탭 ↔ 포스트프로덕션 경계 정의 부재"
type: spec_gap
sub_type: scope_boundary
status: PENDING
owner: conductor  # decision_owner (Foundation §1.2 scope)
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/1. Product/Foundation.md §1.2 (EBS Core 정의)
  - docs/2. Development/2.1 Frontend/Reports/Overview.md
  - docs/2. Development/2.1 Frontend/Lobby/UI.md (Reports 섹션)
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §6.2
  - memory: project_architecture_v33.md (시간축 경계: EBS = 실시간 라이브)
reimplementability: UNKNOWN
reimplementability_checked: 2026-05-03
reimplementability_notes: "status=PENDING — Reports/Insights vs 포스트프로덕션 경계 미정"
---
# SG-019 — Reports/Insights 탭 ↔ 포스트프로덕션 경계 미정의

## 공백 서술

EBS 의 시간축 경계 (Foundation §1.2 + MEMORY) 는 "실시간 라이브" 이며 포스트프로덕션 (Adobe 영역) 과 구분된다. 그러나 Reports/Insights 탭이 실시간 운영 지표만 다루는지, 포스트프로덕션 종합 분석을 포함하는지 명문화되지 않음.

명문화 부재 시 외부 개발팀이 "왜 EBS Reports 가 [feature X] 를 안 하는가?" 질문에 답할 수 없다.

## 발견 경위

- 2026-04-21 critic 보고 §6.2 — Reports 정의 분석 중 시간축 경계 누락 식별
- MEMORY `project_architecture_v33.md` 의 "EBS = 실시간 라이브" 원칙과 Reports/Overview.md 본문 사이 cross-ref 부재

## 영향받는 챕터 / 구현

- `Foundation.md §1.2`: EBS Core 정의에 Reports 시간축 경계 미명시
- `Reports/Overview.md`: 다루는 지표 범위 모호 (실시간 vs 포스트프로덕션)
- `Lobby/UI.md` Reports 섹션: 진입 시 사용자 기대치 부재

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. "실시간 운영 지표만" 명문화 + 포스트프로덕션 cross-ref | 시간축 경계 명확, MEMORY 일치 | Reports 기대치 축소 | ✅ EBS Core 일치 |
| 2. Reports = 실시간 + 종합 분석 (포스트프로덕션 일부 포함) | 사용자 기능 범위 ↑ | EBS Core 정의 위반, Adobe 영역 침범 | ✗ |
| 3. Reports 폐기, Lobby 통계만 | 단순화 | 보고서 출력 use case 상실 | ✗ |

## 결정 (decision_owner conductor 판정 시 기입)

- **default 권고**: 대안 1 (실시간 운영 지표만 명문화)
- 이유: Foundation §1.2 EBS Core 정의 (실시간 라이브) 와 일치
- 영향: Foundation §1.2 + Reports/Overview.md cross-ref

## 후속 작업

- [ ] conductor: Foundation §1.2 EBS Core 에 "Reports = 실시간 운영 지표 한정" 추가
- [ ] team1: Reports/Overview.md 첫 단락에 시간축 경계 + 포스트프로덕션 cross-ref 명시
- [ ] team1: Lobby/UI.md Reports 섹션 hover/tooltip 에 경계 안내 (선택)
- [ ] conductor: BS_Overview §1 용어 표에 "Reports (EBS) ≠ 포스트프로덕션 분석" 추가

## 관련 SG

- 원칙: Foundation §1.2 EBS Core
- MEMORY: project_architecture_v33.md
