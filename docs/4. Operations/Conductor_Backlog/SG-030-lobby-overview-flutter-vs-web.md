---
id: SG-030
title: "기획 모순 (Type C): Lobby/Overview.md Flutter Desktop vs Web 양립 supersede 누락"
type: spec_gap
status: DONE
owner: conductor
created: 2026-05-04
resolved: 2026-05-04
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md §"Lobby-Command Center 관계" L73 + 표
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §개요 L26
  - docs/1. Product/Foundation.md §5.1 (참조)
protocol: Spec_Gap_Triage
related:
  - docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md §F1
  - memory: project_multi_service_docker_2026_04_27
  - memory: project_decision_2026_04_27_phase1
---

# SG-030 — Lobby/Overview.md Flutter Desktop vs Web 양립 supersede 누락

## 공백 서술

`docs/2. Development/2.1 Frontend/Lobby/Overview.md` 가 동일 문서 내에서 두 가지 상충하는 사실을 동시에 진술:

| 위치 | 진술 | 시점 인용 |
|------|------|-----------|
| L73 | "Lobby 도 Flutter Desktop 으로 통일" | Foundation §5.1 (2026-04-21) |
| L86 + L100 | "Lobby 는 1개 (Web 브라우저 탭)", "브라우저 기반이므로 여러 Windows/Mac 에서 동시 접속 가능" | (인용 없음) |

또한 동일 문서 §데이터 공유 표는 Lobby = web, CC = Flutter 가정으로 작성됨. UI.md L26 도 "Flutter 앱으로 구현되어 **Docker Web 으로 배포**" (2026-04-22 재정의) 로 이미 Web 방향 인정 흔적. 즉 Overview.md L73 만 stale.

## 발견 경위

- 트리거: 사용자가 2026-04-29 제공한 design SSOT (HTML/React/CSS) 자산 → 2026-05-03 R8 cascade 로 `Lobby/References/EBS_Lobby_Design/` 등재
- 갭 노출: 2026-05-04 Conductor 가 design ↔ SSOT ↔ 코드 3-way 분석 (`docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md`)
- 분류: Type C (기획 모순) — 동일 문서 내 양립 + 외부 SSOT (multi-service Docker) cascade 와 stale 진술 충돌

## 영향받는 챕터 / 구현

- **Lobby/Overview.md L73 + 기술 표 행**: SUPERSEDE 갱신 필요
- **Foundation §5.1 (2026-04-21)**: 향후 cascade 시 본 SG-030 cross-ref
- **Flutter 구현**: team1 web 빌드 (`flutter build web`) + lobby-web Docker 컨테이너 (이미 운영 중)

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| **A. SUPERSEDE 인정 — Overview L73 Web 정정** | reversible 작은 cascade · design SSOT + multi-service Docker SSOT 와 정합 · 사용자 의사결정 (2026-05-04 §F1) | Foundation §5.1 (2026-04-21) cross-ref 명시 갱신 별도 필요 | ✅ WSOP LIVE = Staff Page Web + WSOP LIVE Flutter 분리 패턴 |
| **B. 재해석 — design 자산을 Desktop 가정으로 다시 그림** | Foundation §5.1 보존 | 큰 cascade · design SSOT (HTML/React 230KB) 와 multi-service Docker SSOT 양쪽 모두 폐기 · production 인텐트 (SG-023) 와 충돌 | ❌ WSOP LIVE 패턴 이탈 |

## 결정 (2026-05-04 사용자 의사결정 + Conductor 자율 해석)

- **채택**: 대안 A — SUPERSEDE 인정
- **이유**: ① 사용자 명시 단어 "**SUPERSEDE 권한 인정**" ② design SSOT (5/3 R8 cascade 등재) 가 이미 Web 가정 ③ multi-service Docker (lobby-web :3000) 가 production 운영 자산으로 동작 중 ④ UI.md L26 가 이미 "Docker Web" 으로 일부 정정된 흔적 ⑤ 반대 옵션 ("재해석 큰 cascade") 은 사용자 응답에 함께 적힌 것이 옵션 description 의 잘못된 복사로 추정 — 더 보수적/reversible 해석 = A
- **영향 챕터 업데이트 PR**: 본 cascade 의 Overview.md edit (L73 + Edit History row 2026-05-04 추가) — 이미 적용
- **Type 모호성**: 2026-05-04 사용자 응답 "SUPERSEDE 권한 인정" + "재해석 필요 (큰 cascade)" 동시 명시는 모순. Conductor 가 더 명시적 단어 ("인정") + reversible 옵션 우선으로 해석 (V9.4 AI-Centric default — 단, 사용자가 본 결정 거부권 행사 가능. 거부 시 본 SG-030 reopen)
- **후속 구현 Backlog**: 없음 (문서 정정만, 코드 변경 불필요 — Lobby 는 이미 web 운영 중)

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-05-04 | 신규 작성 + 즉시 해소 (대안 A 채택, Overview.md L73 정정 완료, UI.md 는 기존 정렬됨) |
