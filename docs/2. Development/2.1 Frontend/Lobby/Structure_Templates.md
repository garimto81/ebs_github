---
title: Structure Templates (Blind & Payout)
owner: team1
tier: feature
last-updated: 2026-04-16
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "Blind/Payout 템플릿 기획 완결"
---
# Structure Templates — Blind & Payout

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "5. Blind Structure" (Confluence p1784479843) + "6. Prize Structure" (Confluence p1597833440) 기반 |

---

## 개요

Series 레벨에서 Blind Structure 와 Payout Structure 템플릿을 관리하는 CRUD 화면. 템플릿을 생성/복사/편집한 뒤 Flight에 적용한다. WSOP LIVE Staff App §05 Blind Structure + §06 Prize Structure 를 통합한 화면이다.

---

## 1. 기능 범위

### 1.1 Blind Structure

| 기능 | 설명 |
|------|------|
| **템플릿 목록** | Series 내 Blind Structure 목록. 이름/BlindType/Creator 검색 |
| **생성 (Step 1)** | Blind Type 선택: Standard(NLH) / HORSE / Limits / DealerChoice / Round / PLO / Stud / MixedGame |
| **생성 (Step 2)** | 타입별 컬럼 레이아웃으로 Level 편집. CSV Load 지원 |
| **편집** | 본인 생성 템플릿만 수정 가능 |
| **복사** | `Create New by using this Structure` — 이름 비우고 값 복사 |
| **삭제** | Admin만 |
| **Flight 적용** | Flight에 템플릿 연결 + 레벨별 override (duration 등) |

### 1.2 Payout Structure

| 기능 | 설명 |
|------|------|
| **템플릿 목록** | Series 내 Payout Structure 목록 |
| **생성** | Entry 구간별 Rank/Award% 테이블. 합계 100% 검증 |
| **편집** | Creator만 수정 |
| **CSV Upload/Download** | WSOP LIVE 호환 CSV 포맷 (Rank, Award%) |
| **Flight 적용** | Flight에 템플릿 연결 |

---

## 2. 화면 구조

### 2.1 Blind Structure 목록

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| No. | 읽기 전용 | 자동 번호 |
| Name | 링크 | 클릭 시 상세/편집 |
| Blind Type | Badge | 8종 타입 |
| Created By | 읽기 전용 | Staff 이름 |

필터: Blind Type Dropdown, Search by Name/Creator

### 2.2 Blind Structure 편집 — 타입별 컬럼

| BlindType | 컬럼 |
|-----------|------|
| Standard (NLH) | Level, SB, BB, Ante |
| HORSE | Level, Limit Flop (SB/BB/SmallBet/BigBet), Stud (Ante/BringIn/Completion/SmallBets/BigBets) |
| Limits | Level, SB, BB, SmallBet, BigBet |
| DealerChoice | Level, NL&PL (PLAnte/NLAnte/SB/BB), LimitFlop (SB/BB/SmallBets/BigBets), Stud (Ante/BringIn/Completion/SmallBet/BigBet) |
| Round | Level, Ante, SB, BB (Round별 독립 행 추가/삭제) |
| PLO | Level, Ante, SB, BB, Open-to (Call/MakeIt) |
| Stud | Level, Ante, BringIn, Completion, SmallBets, BigBets |
| MixedGame | Level, NLH (Ante/SB/BB), PLO-PLO8-BigO (Ante/SB/BB), NLFCD&2-7NL (Ante/SB/BB) |

공통: `Add More Row`, `Delete Last Row`, `Load from CSV`, `Save`

### 2.3 Payout Structure 편집

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Entry From/To | Input (number) | 참가자 구간 |
| Rank From/To | Input (number) | 순위 구간 |
| Award % | Input (decimal) | 소수점 9자리까지 |
| Sum | 읽기 전용 | 100% 검증 |

---

## 3. 데이터 흐름

| 동작 | API | 비고 |
|------|-----|------|
| Blind 목록 | `GET /Series/:id/blind-structures` | Backend_HTTP §5.13 |
| Blind 생성 | `POST /Series/:id/blind-structures` | |
| Blind 수정 | `PUT /Series/:id/blind-structures/:bs_id` | Creator만 |
| Blind 삭제 | `DELETE /Series/:id/blind-structures/:bs_id` | Admin |
| Blind Flight 적용 | `PUT /Flights/:id/blind-structure` | `blind_structure_changed` WS |
| Payout 목록 | `GET /Series/:id/payout-structures` | Backend_HTTP §5.13.1 |
| Payout 생성 | `POST /Series/:id/payout-structures` | 합계 100% 검증 |
| Payout 수정 | `PUT /Series/:id/payout-structures/:ps_id` | Creator만 |
| Payout Flight 적용 | `PUT /Flights/:id/payout-structure` | `prize_pool_changed` WS |

---

## 4. RBAC

| 동작 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| 목록/상세 조회 | O | O | O |
| 생성 | O | X | X |
| 수정 (본인 생성분) | O | X | X |
| 삭제 | O | X | X |
| Flight 적용/수정 | O | X | X |
| CSV Upload/Download | O | O (Download만) | X |

---

## 5. WSOP LIVE Parity

| WSOP LIVE 기능 | EBS 적용 | 비고 |
|---------------|:-------:|------|
| 8종 BlindType 템플릿 | Apply | EBS BlindType enum 매핑 (Backend_HTTP §5.13) |
| Series Permission (시리즈별 노출) | Remove | EBS는 Series-scoped 경로로 자동 필터 |
| CSV Load | Apply | |
| Payout Structure CSV Upload (소수점 9자리) | Apply | |
| Payout 합계 100% 검증 | Apply | 400 `PAYOUT_PERCENT_INVALID` |
| Copy Structure | Apply | |

---

## 6. 미결 사항

- 미결: CCR 필요 — Blind Structure CSV 포맷 정의 (타입별 컬럼 차이)
- 미결: CCR 필요 — Round 타입 라운드 추가/삭제 UI 상세 (최소 2라운드 제약)
