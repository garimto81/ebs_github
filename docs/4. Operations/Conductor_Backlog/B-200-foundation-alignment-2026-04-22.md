---
id: B-200
title: "Foundation 재설계(2026-04-22) 정렬 — Conductor 소유 문서 전수 수정"
status: IN_PROGRESS
source: docs/4. Operations/Conductor_Backlog.md
priority: P0
related_plan: docs/4. Operations/Foundation_Alignment_Plan.md
last-updated: 2026-04-22
---

# B-200 — Foundation 재설계 정렬 (Conductor 소유 문서)

## 배경

2026-04-22 `docs/1. Product/Foundation.md` 전면 재설계 (7 커밋 `b577130` → `027d15a`). Ch.4 2 렌즈 / §5.0 2 런타임 / §6.3 프로세스 모델 / §6.4 WS 동기화 / §7.1 Overlay flag / §8.5 복수 테이블. Conductor 소유 17 문서 중 P0 5건 + P1 5건에서 Delta 존재.

## 수용 기준

상세 분석: `Foundation_Alignment_Plan.md`

- [x] C-1 Type C 모순 (Lobby 배포: Desktop vs Web) Conductor 판정 (α/β/**γ**) — team1 PR#11/#13/#14 자발 γ 이행 + Foundation §5.1/§4.4 γ 확정 (`093d6b4`)
- [x] BS_Overview §1 Foundation §4.4/§5.0 정렬 재작성 — `1b6be8f`
- [x] 1. Product.md "5-App" → "설치 4/기능 6" 프레임 전환 + CCR 잔재 제거 — `16fe828`
- [x] Roadmap Ch.7 FAIL(B) → PASS, SG-002/005 DONE 전환 — `9313c2e`
- [x] Spec_Gap_Registry §4.4 SG-002/005 DONE 반영 — `9313c2e`
- [ ] Network_Deployment §8.5 중앙 서버 아키텍처 반영 — **PENDING (팀 세션 처리 중 — team2 Phase C `e78b924` 일부 반영, Conductor 보완 필요 여부 재검증)**
- [x] SG-002/005 Backlog 파일 status DONE — 개별 파일 이미 `RESOLVED` (2026-04-20), Registry 집계도 동기화됨 (`9313c2e`)
- [x] Risk_Matrix R-06 중앙 서버 SPOF 등재 — `5d4c50a`
- [ ] Docker_Runtime C-1 판정 반영 — **PENDING (γ 확정 이후 재확인 필요, team1 PR#11-14 로 부분 반영)**

## 하위 태스크

| ID | 제목 | 우선순위 | 의존 | 상태 | 커밋 |
|:---|------|:--------:|:----:|:----:|------|
| B-200-1 | C-1 Type C Lobby 배포 모순 판정 (α/β/**γ**) | P0 | — (gate) | ✅ DONE | `093d6b4` + team1 PR#11-14 |
| B-200-2 | BS_Overview §1 재작성 | P0 | B-200-1 | ✅ DONE | `1b6be8f` |
| B-200-3 | 1. Product.md §소프트웨어 컴포넌트 + CCR 제거 | P0 | — | ✅ DONE | `16fe828` |
| B-200-4 | Roadmap + Spec_Gap_Registry SG-002/005 DONE 전환 | P0 | — | ✅ DONE | `9313c2e` |
| B-200-5 | Network_Deployment §8.5 반영 | P0 | B-200-1 | ⏸ PENDING | 팀 세션 병행 |
| B-200-6 | SG-002/005 Backlog 파일 status 전환 | P1 | B-200-4 | ✅ DONE | 개별 파일 2026-04-20 + Registry `9313c2e` |
| B-200-7 | Risk_Matrix R-06 SPOF 추가 | P1 | — | ✅ DONE | `5d4c50a` |
| B-200-8 | Docker_Runtime C-1 판정 반영 | P1 | B-200-1 | ⏸ PENDING | team1 PR#11-14 로 부분 반영, 재확인 필요 |
| B-200-9 | SSOT_Alignment / Multi_Session / V5_Migration 검증 | P2 | — | 🔄 PARTIAL | Multi_Session_Handoff `ceedfe9` |

**추가 항목 (v1.1)**:

| ID | 제목 | 우선순위 | 상태 | 커밋 |
|:---|------|:--------:|:----:|------|
| B-206 | 4. Operations.md "2027 런칭" 문구 제거 | P0 | ✅ DONE | `023f226` |
| B-207 | Redesign_Plan vs Alignment_Plan 관계 정리 | P1 | ⏸ PENDING | — |
| B-208 | Aggregate-vs-Source 자동 갱신 tool (root-cause) | P1 | ⏸ PENDING | — |

## 참조

- `docs/1. Product/Foundation.md` (SSOT)
- `docs/4. Operations/Foundation_Alignment_Plan.md` (상세 Delta 분석)
- `CLAUDE.md` §프로토타입 실패 대응 Type A/B/C
