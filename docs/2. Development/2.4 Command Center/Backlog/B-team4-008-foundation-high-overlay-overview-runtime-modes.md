---
id: B-team4-008
title: Foundation 재설계 P1 — Overlay/Overview 2 런타임 모드 분기 + 배경 config flag
status: PENDING
source: docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md §3.2
mirror: none
---

# [B-team4-008] Foundation 재설계 HIGH — Overlay Overview 재작성

- **등록일**: 2026-04-22
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.2 (H1~H6)
- **Source Delta**: Foundation.md §5.0 2 런타임 모드 (D2) + §7.1 배경 config flag (D4) + §6.3 §6.4 (D5)

## 배경

`Overlay/Overview.md` 와 `Overlay/Sequences.md` 후속 섹션이 Foundation §5.0 / §7.1 / §6.3 / §6.4 재설계를 미반영. 주로:

- §1 앱 정의 — "동일한 Flutter 앱 내에서 in-process 실행 (API-04 §1.2 SSOT)" 단일 모드 서술
- §2 데이터 흐름 — Engine → Overlay 직접 ASCII (CC Orchestrator 반영 안 됨)
- §5 출력 채널 — 크로마키 색상만 언급, 배경 투명/단색 config flag 미반영
- 편집 이력 2026-04-14 "별도 프로세스 → in-process" 는 2026-04-22 Foundation §5.0 으로 재반전

## 수락 기준

### H1. §1 앱 정의 재작성

- [ ] `인스턴스 관계` 행 유지 (1:1:1)
- [ ] `실행 환경` 행 — "CC와 동일 머신 (NDI 네트워크 출력은 Overlay 합성기 단 출력)" 로 단순화 (Foundation §8.5 정렬)
- [ ] 본문 "동일한 Flutter 앱 내에서 in-process 실행" → "**런타임 모드에 따라 상이**: 탭 모드 (§5.0) = CC 와 in-process / 다중창 모드 = 독립 OS 프로세스 (§6.3)"
- [ ] "API-04 §1.2 SSOT" 문구는 "API-04 = 논리적 계약 (sealed class). 런타임 전송 경로는 §5.0/§6.3 참조" 로 조정

### H2. §2 데이터 흐름 재작성

- [ ] ASCII 다이어그램을 2 경로로 분리
  - (A) 탭 모드: RFID → CC → Engine (HTTP) → CC → Overlay (Dart Stream)
  - (B) 다중창 모드: RFID → CC (Orchestrator) → Engine (HTTP) → CC → BO (WS broadcast) → Overlay (WS consume)
- [ ] Foundation §6.3 §1.1.1 "병행 dispatch" 시퀀스와 정합 (Engine SSOT + BO audit)

### H3. §5 출력 채널 재작성

- [ ] §5 에 `배경 config flag` 신설 섹션 또는 표 행 추가
  - (a) **완전 투명** — 방송 송출 기본값, 스위처 합성용
  - (b) **단색 배경** — 아트 디자이너 외부 Rive Editor 검토 · QA 스크린샷 용도
- [ ] 기존 `크로마키 색상` 을 "단색 모드" 하위 옵션으로 재배치 (Green/Blue/Black/Custom)
- [ ] 용도 차이 명시 — 송출 vs 디자인 QA

### H4. 편집 이력 갱신

- [ ] 추가: `2026-04-22 | Foundation §5.0 2 런타임 모드 반영 — in-process 고정 서술 재조정, §7.1 배경 config flag 추가`
- [ ] `last-updated: 2026-04-22`

### H5~H6. Sequences.md 후속 섹션

- [ ] §1.1 "핵심 규칙" 을 탭/다중창 2 모드 분리 서술
- [ ] §1.2 지연 예산 표에 "모드" 컬럼 + 2 행 (탭 < 1ms / 다중창 < 100ms HTTP+WS)

### 공통

- [ ] `dart analyze team4-cc/src` 0 errors 유지
- [ ] 커밋: `docs(team4): B-team4-008 Overlay/Overview 2 런타임 모드 + 배경 config flag 반영 🎨`

## 참조

- Foundation SSOT: `docs/1. Product/Foundation.md` §5.0 / §6.3 / §6.4 / §7.1
- Impact Review: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.2
- 선행 작업: B-team4-007 (C1 C2 CRITICAL) 완료 권장
