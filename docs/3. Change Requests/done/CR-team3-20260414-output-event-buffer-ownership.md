---
title: CR-team3-20260414-output-event-buffer-ownership
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team3-20260414-output-event-buffer-ownership
confluence-page-id: 3819275424
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275424/EBS+CR-team3-20260414-output-event-buffer-ownership
---

# CCR-DRAFT: OutputEventBuffer 구현 소유팀 명시 (API-04 §3)

- **제안팀**: team3
- **제안일**: 2026-04-14
- **영향팀**: [team4]
- **변경 대상 파일**: contracts/api/`Overlay_Output_Events.md` (legacy-id: API-04)
- **변경 유형**: modify
- **변경 근거**: GAP-GE-009 — API-04 §3이 OutputEventBuffer 의사코드(Security Delay 0~120초)를 제공하나 **구현 소유팀**이 미명시. Team 3 harness 측(서버 버퍼링) vs Team 4 CC Flutter 앱 측(클라이언트 버퍼링) 중 어느 쪽이 책임인지 contracts에 없어 양 팀 모두 구현 진입 불가. 2026-04-14 Critic 감사에서 확인됨 (QA-GE-CRITIC-2026-04-14.md §6 BLOCKER 리스트).
- **리스크 등급**: MEDIUM

## 변경 요약

API-04 §3 Security Delay 섹션에 "구현 소유팀" 필드를 명시하여 OutputEventBuffer 구현 주체를 확정한다. 현재 §3.6에는 2026-04-14 추가된 "⚠️ 구현 소유팀 미결 (Conductor 결정 필요)" 경고만 존재.

## 배경

- API-04 §1.2: "CC와 Overlay는 동일 Flutter 앱, in-process 통신"
- API-04 §3.5: "Backstage는 buffer를 우회하고 즉시 송출" (Broadcast만 delay 대상)
- Team 3 (Pure Dart harness)는 HTTP 엔드포인트에서 OutputEvent를 즉시 emit
- Team 4 (Flutter/Dart + Rive)는 harness로부터 OutputEvent 수신 후 Rive overlay 렌더링

**양 팀 구현 가능성**:

| 후보 | 장점 | 단점 |
|------|------|------|
| **Team 3 (harness 서버 측)** | 단일 소스에서 delay 제어, 보안 정책 중앙화 용이 | Backstage는 buffer 우회 필요 → 이중 스트림을 harness가 직접 관리해야 함. Pure Dart 패키지 원칙(순수 계산 엔진)에서 벗어남 |
| **Team 4 (CC Flutter 앱 측)** | harness는 단일 스트림으로 단순화. Backstage↔Broadcast 분기를 Flutter 앱이 자연스럽게 처리 (UI와 같은 프로세스) | 각 CC 인스턴스가 독립 buffer 관리 → 정책 변경 시 N개 배포 필요 |

**Team 3 의견**: Team 4 소유가 아키텍처적으로 일관(§1.2 in-process 통신 + §3.5 Backstage 즉시 송출). 그러나 **Team 4의 작업 범위를 Team 3가 단독 결정할 수 없음**이 명확해져 CCR로 제출.

## Diff 초안 (예시)

```diff
 ## 3. Security Delay — OutputEventBuffer
 
+### 3.0 구현 소유팀
+
+| 항목 | 소유팀 |
+|------|--------|
+| OutputEventBuffer 클래스 구현 | **Team X** (Conductor 결정) |
+| Security Delay 파라미터 적용 | 동일 |
+| Backstage/Broadcast 분기 | 동일 |
+
+Team 3 harness는 buffer 없이 즉시 emit. 소유팀이 수신 후 delay 적용.
+
 ### 3.1 목적
 ...
```

(실제 Diff는 Conductor가 선택한 소유팀에 따라 §3.6의 "미결 경고"를 제거하고 §3.0을 신설하는 형태로 반영)

## 영향 분석

- **Team 3 (harness)**: 소유팀이 Team 4로 결정되면 변경 없음 (현재 즉시 emit 유지). 소유팀이 Team 3로 결정되면 `lib/core/actions/output_event_buffer.dart` 신설 + `lib/harness/server.dart` 이중 스트림 분기 추가 필요 (~3-5일).
- **Team 4 (CC Flutter)**: 소유팀이 Team 4로 결정되면 CC Flutter 앱에 OutputEventBuffer 구현 필요 (~3-5일). 소유팀이 Team 3로 결정되면 변경 없음.
- **마이그레이션**: 없음 (현재 어느 팀도 구현하지 않은 상태).

## 대안 검토

1. **Team 3 단독 결정 (거부됨)**: 2026-04-14 시도했으나 Team 3 publisher 권한은 자기 출력 스펙 범위이며 타 팀 작업 배정은 범위 초과 → 즉시 롤백.
2. **보류 (거부)**: BLOCKER로 남아 Team 3/Team 4 양쪽 구현 진입 불가. Critic 점수 C6 지속 악화.
3. **CCR 제출 (채택)**: 이 draft.

## 검증 방법

- 결정 반영 후 소유팀 세션에서 OutputEventBuffer 구현 완료 (Security Delay 0~120초 파라미터 적용 가능)
- harness/CC 통합 테스트에서 Backstage 즉시 송출 + Broadcast delay 분기 확인
- QA-GE-10-spec-gap.md GAP-GE-009 → RESOLVED 처리

## 승인 요청

- [ ] Conductor 결정 (Team 3 harness vs Team 4 CC Flutter)
- [ ] Team 4 기술 검토 (Team 4 소유 결정 시)
- [ ] Team 3 harness 범위 확인 (Team 3 소유 결정 시 Pure Dart 원칙 위배 여부)
