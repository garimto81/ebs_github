---
id: B-team4-009
title: Foundation 재설계 P2 — MEDIUM 일괄 참조·주석 보강
backlog-status: open
source: docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md §3.3
mirror: none
---

# [B-team4-009] Foundation 재설계 MEDIUM — 참조·주석 보강 일괄 패치

- **등록일**: 2026-04-22
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.3 (M1~M8)

## 수락 기준

### M1. Command_Center_UI/Overview.md §1 — §8.5 참조

- [ ] "CC = Table = Overlay (1:1:1)" 표 하단에 "§8.5 복수 테이블 운영은 N PC 구조 — `docs/1. Product/Foundation.md §8.5` 참조" 주석 추가

### M2. Command_Center_UI/Overview.md §7.1 — 2 모드 각주

- [ ] "[CC 신규 프로세스]" 에 각주: "다중창 모드 = 신규 OS 프로세스 · 탭 모드 = 동일 프로세스 내 라우팅 (`Foundation §5.0` 참조)"

### M3. Command_Center_UI/Overview.md §7.2 — 실패 시나리오 분기

- [ ] "CC 프로세스 실행 실패" 각주 — 탭 모드에서는 "뷰 전환 실패" 로 해석

### M4. Overlay/Layer_Boundary.md §원칙 인용

- [ ] "Foundation (Confluence SSOT) Ch.4" 인용 문구를 Ch.2 (EBS 그리는 것 vs 안 그리는 것) + Ch.9 (EBS vs 포스트프로덕션) 로 재조정
- [ ] Ch.4 는 이제 "2 렌즈 (기능 6 ↔ 설치 4)" 설명이므로 인용 맥락 부적합

### M5. Overlay/Layer_Boundary.md §3.2 — API-04 전송 경로 명확화

- [ ] "in-process 계약" 문구를 "**API-04 = 논리적 계약 (sealed class exhaustiveness). 런타임 전송 경로는 Foundation §5.0 2 모드 — 탭: Dart Stream / 다중창: BO WS broadcast**" 로 보강
- [ ] Engine 이 별도 서비스임을 명확히 (현재 "team3 Game Engine 이 발행" 표현 유지 + 별도 서비스 주석)

### M6. Overlay/Engine_Dependency_Contract.md §7 — 참조 경로 갱신

- [ ] "Foundation Ch.7 (시스템 연결): ..." → "Foundation §6.3 (프로세스 경계) / §6.4 (실시간 동기화, SG-002 해소): ..."

### M7. Settings.md — 스코프 정합성 notify

- [ ] 개요 섹션에 주석: "Foundation §5.2 는 '모든 테이블에 일괄 적용' (global-only) 으로 요약 서술. 본 문서는 WSOP LIVE 원칙 1 정렬로 4단 스코프 (global/series/event/table) 확장 명세. 해석 차이 검토 — notify: conductor"
- [ ] 커밋 메시지 또는 PR 에 `notify: conductor` 태그

### M8. APIs/RFID_HAL_Interface.md — 런타임 모드 언급 검증

- [ ] 문서 내 "런타임 모드" 또는 "2 모드" 언급 확인
- [ ] 기존 서술이 단일 모드 전제라면 Foundation §5.0 주석 추가. 하드웨어 I/O 는 프로세스 모델 무관하면 변경 없음

### 공통

- [ ] 모든 변경 문서 `last-updated: 2026-04-22`
- [ ] 커밋: `docs(team4): B-team4-009 Foundation 재설계 참조·주석 일괄 보강 (M1~M8) 📝`

## 참조

- Foundation SSOT: `docs/1. Product/Foundation.md`
- Impact Review: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.3
