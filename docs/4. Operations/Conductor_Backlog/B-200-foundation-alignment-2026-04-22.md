---
id: B-200
title: "Foundation 재설계(2026-04-22) 정렬 — Conductor 소유 문서 전수 수정"
status: PENDING
source: docs/4. Operations/Conductor_Backlog.md
priority: P0
related_plan: docs/4. Operations/Foundation_Alignment_Plan.md
---

# B-200 — Foundation 재설계 정렬 (Conductor 소유 문서)

## 배경

2026-04-22 `docs/1. Product/Foundation.md` 전면 재설계 (7 커밋 `b577130` → `027d15a`). Ch.4 2 렌즈 / §5.0 2 런타임 / §6.3 프로세스 모델 / §6.4 WS 동기화 / §7.1 Overlay flag / §8.5 복수 테이블. Conductor 소유 17 문서 중 P0 5건 + P1 5건에서 Delta 존재.

## 수용 기준

상세 분석: `Foundation_Alignment_Plan.md`

- [ ] C-1 Type C 모순 (Lobby 배포: Desktop vs Web) Conductor 판정 (α/β/γ)
- [ ] BS_Overview §1 Foundation §4.4/§5.0 정렬 재작성
- [ ] 1. Product.md "5-App" → "설치 4/기능 6" 프레임 전환 + CCR 잔재 제거
- [ ] Roadmap Ch.7 FAIL(B) → PASS, SG-002/005 DONE 전환
- [ ] Spec_Gap_Registry §4.4 SG-002/005 DONE 반영
- [ ] Network_Deployment §8.5 중앙 서버 아키텍처 반영
- [ ] SG-002/005 Backlog 파일 status DONE
- [ ] Risk_Matrix R-06 중앙 서버 SPOF 등재
- [ ] Docker_Runtime C-1 판정 반영

## 하위 태스크

| ID | 제목 | 우선순위 | 의존 |
|:---|------|:--------:|:----:|
| B-200-1 | C-1 Type C Lobby 배포 모순 판정 (α/β/γ) | P0 | — (gate) |
| B-200-2 | BS_Overview §1 재작성 | P0 | B-200-1 |
| B-200-3 | 1. Product.md §소프트웨어 컴포넌트 + CCR 제거 | P0 | — |
| B-200-4 | Roadmap + Spec_Gap_Registry SG-002/005 DONE 전환 | P0 | — |
| B-200-5 | Network_Deployment §8.5 반영 | P0 | B-200-1 |
| B-200-6 | SG-002/005 Backlog 파일 status 전환 | P1 | B-200-4 |
| B-200-7 | Risk_Matrix R-06 SPOF 추가 | P1 | — |
| B-200-8 | Docker_Runtime C-1 판정 반영 | P1 | B-200-1 |
| B-200-9 | SSOT_Alignment / Multi_Session / V5_Migration 검증 | P2 | — |

## 참조

- `docs/1. Product/Foundation.md` (SSOT)
- `docs/4. Operations/Foundation_Alignment_Plan.md` (상세 Delta 분석)
- `CLAUDE.md` §프로토타입 실패 대응 Type A/B/C
