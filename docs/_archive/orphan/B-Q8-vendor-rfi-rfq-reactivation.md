---
title: B-Q8 — vendor 모델 reactivate (RFI/RFQ 재개 여부) (사용자 명시 대기)
owner: conductor
tier: internal
status: PENDING
type: backlog-deferred-decision
linked-sg: SG-023
linked-decision-pending: user (외부 발송 destructive)
last-updated: 2026-04-27
confluence-page-id: 3819275005
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275005/EBS+B-Q8+vendor+reactivate+RFI+RFQ
---

## 개요

SG-023 (인텐트 = production 출시) 의 vendor 공급망 결정. **사용자 명시 결정 필요** — 외부 메일 발송 destructive.

## 배경

이전 [LEGACY/INACTIVE] 표시된 vendor 관리:
- memory MEMORY.md "[LEGACY/INACTIVE] 업체 선정 현황 (Phase 0, 2026-02 종료)" 섹션
- Category A (통합 파트너): Sun-Fly (회신 수신), Angel Playing Cards (전송 실패), 엠포플러스 (미발송)
- Category B (부품 공급): FEIG, GAO, Identiv, PONGEE, Waveshare, SparkFun, Adafruit, Faded Spade
- 백업 위치: `C:/claude/ebs-archive-backup/07-archive/06-operations/VENDOR-MANAGEMENT.md` (v6.0.0)

SG-023 채택으로 production 출시 = vendor 공급망 활성화 후보.

## 결정 사항

| 항목 | 사용자 결정 필요 |
|------|----------------|
| vendor 모델 reactivate 여부 | ㉠ Yes / ㉡ No (다른 공급 모델) / ㉢ 보류 |
| Category A 우선 처리 | Sun-Fly (회신 받은) 후속 / 신규 RFQ / 보류 |
| Angel Playing Cards 재시도 | 이메일 도메인 정정 후 재발송 / 다른 채널 / 제외 |
| 엠포플러스 발송 | RFI 발송 / 보류 |
| Category B 활용 | 백업 부품 공급망 / 무관 |

## 선택지

| 옵션 | 의미 |
|:----:|------|
| ㉠ 전면 reactivate | LEGACY 백업 메모 reactivate, RFI/RFQ 재발송, vendor 협상 재개 |
| ㉡ 부분 reactivate | Category A 만 (Sun-Fly 등), RFI 재발송, 협상 재개 |
| ㉢ 새 vendor 모델 | 이전 [LEGACY] 무효, 새 공급망 탐색 |
| ㉣ 보류 | timeline (B-Q6) 결정 후 결정 |

## 외부 발송 (destructive — 사용자 명시 승인 필수)

본 cascade 의 RFI/RFQ 메일 발송은 외부 영향 (vendor 응답, 비즈니스 컨택) 동반. 사용자 명시 승인 후에만 진행:

- 메일 본문 사전 검토 (사용자 승인)
- 회사명 노출 금지 룰 준수 (MEMORY 외부 커뮤니케이션 규칙)
- 기술 스펙 노출 금지 (주파수, 프로토콜, IC 칩명)

## 영향

- ㉠/㉡ 채택 시: vendor 공급망 가시화, 비용/일정 추정 가능, 외부 컨택 동반
- ㉢ 채택 시: 새 RFI 작업, 시간 비용 큼
- ㉣ 채택 시: B-Q6 timeline 결정 후 재검토

## 후속 cascade (사용자 결정 후)

- memory `project_2027_launch_strategy` 갱신 (LEGACY → ACTIVE)
- 메일 발송 사용자 승인 워크플로우
- vendor 응답 추적 시스템

## 참조

- memory MEMORY.md "[LEGACY/INACTIVE] 업체 선정 현황 (Phase 0, 2026-02 종료)"
- 백업: `C:/claude/ebs-archive-backup/07-archive/06-operations/VENDOR-MANAGEMENT.md`
- MEMORY 외부 커뮤니케이션 규칙 (본문)
- SG-023, SG-024 (선행 결정)
- B-Q6 (timeline — vendor 일정과 연동)
