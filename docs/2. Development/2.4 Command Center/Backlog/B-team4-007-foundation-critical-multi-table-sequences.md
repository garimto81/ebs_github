---
id: B-team4-007
title: Foundation 재설계 P0 — Multi_Table Pattern B 재정의 + Sequences 2 모드 다이어그램
status: PENDING
source: docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md §3.1
---

# [B-team4-007] Foundation 재설계 CRITICAL — Type C 기획 모순 해소

- **등록일**: 2026-04-22
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.1 (C1, C2)
- **Source Delta**: Foundation.md §8.5 신설 (D1) + §5.0 2 런타임 모드 (D2) + §6.3 프로세스 경계 (D5)
- **Type 분류**: Type C (기획 모순) — 2026-04-22 Foundation 재설계로 기존 서술이 무효화됨

## 배경

2026-04-22 Foundation.md 재설계로 다음 2 개 문서가 Foundation 과 **직접 모순** 상태:

1. `Command_Center_UI/Multi_Table_Operations.md` §1.2 Pattern B — "1명 = 2~4 테이블, **같은 머신 또는 인접 머신**에서 Alt+Tab 전환" → Foundation §8.5 "1 PC = 1 피처 테이블 고정, 방송 중 PC 간 이동 불가, 멀티 EBS 폐기" 와 충돌
2. `Overlay/Sequences.md` §1.1 프로세스 모델 다이어그램 — "단일 Flutter 앱 (in-process)" 박스에 CC+RFID+Engine+Overlay 전부 배치 → Foundation §5.0 2 런타임 모드 + §6.3 Engine 별도 프로세스 와 충돌

## 수락 기준

### C1. Multi_Table_Operations.md 재작성

- [ ] §1.2 Pattern B "같은 머신" 표현 제거. "인접 머신" = "N PC 순회 (각 PC 단일 테이블)" 로 재정의
- [ ] Foundation §8.5 참조 삽입 — "1 PC = 1 피처 테이블 고정, 방송 중 PC 간 이동 불가"
- [ ] 피처 테이블 (Pattern A 단일) vs 비피처 테이블 (Pattern B N PC 순회) 구분 명시
- [ ] §3.2 "다중 CC" 단축키 정책 — 같은 PC 에 다중 CC 창을 띄우는 전제 제거. OS 간 Alt+Tab (별도 PC) 또는 KVM 스위치 사용 고려
- [ ] §4 알림 정책 — "비활성 CC 창" → "다른 PC CC" 로 용어 정정
- [ ] 편집 이력 추가: "2026-04-22 | Foundation §8.5 반영 — 1 PC = 1 테이블 고정 정렬, Pattern B 재정의"

### C2. Overlay/Sequences.md 재작성

- [ ] §1.1 프로세스 모델 다이어그램을 **2 개**로 분리
  - (a) 탭 모드: 단일 Flutter 프로세스 내 CC/Overlay in-process
  - (b) 다중창 모드: Lobby/CC/Overlay 독립 OS 프로세스 + 공용 BO+DB
- [ ] Engine 은 **어느 모드에서도** 별도 서비스임을 다이어그램에 명시 (HTTP)
- [ ] §1.2 지연 예산 표에 "모드" 컬럼 추가 — 탭 (< 1ms Dart Stream) / 다중창 (< 100ms HTTP + WS push)
- [ ] 본문 규칙 서술 — "탭 모드: Dart Stream / 다중창 모드: BO WS broadcast 경유 (§6.3)" 로 분리
- [ ] 편집 이력 추가: "2026-04-22 | Foundation §5.0 §6.3 반영 — 2 모드 프로세스 다이어그램 분리"

### 공통

- [ ] 두 문서 frontmatter `last-updated: 2026-04-22`
- [ ] `dart analyze team4-cc/src` 0 errors 유지 (문서 only, 코드 영향 없음)
- [ ] 커밋 메시지: `docs(team4): B-team4-007 Foundation §8.5 §5.0 §6.3 정합 — Multi_Table 재정의 + Sequences 2 모드 다이어그램 🗂️`

## 참조

- Foundation SSOT: `docs/1. Product/Foundation.md` §5.0 / §6.3 / §8.5
- Impact Review: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.1
