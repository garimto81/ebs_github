---
title: CR-team2-20260414-payout-structure-endpoints
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# CCR-DRAFT: PayoutStructure (PrizePool) 엔드포인트 추가 (WSOP LIVE 정렬)

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/api/API-01-backend-api.md, contracts/data/DATA-02-entities.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff App(Page 1603600679)은 PayoutStructure(상금 구조) 템플릿 + Flight별 적용 엔드포인트 7종을 제공. EBS API-01에 상금 관리 API 부재. `prize_pool_changed` WebSocket 이벤트(S0-05 CCR)의 소스 API 확립 필요.

## 변경 요약

WSOP LIVE PayoutStructure 엔드포인트 7종 반영. Entry 구간별 Payout 테이블 구조 준거.

## Diff 초안

```diff
+### 5.Y PayoutStructure — 상금 구조
+
+> **WSOP LIVE 대응**: `/Series/{sId}/PayoutStructures/*` + `/EventFlights/{efId}/PayoutStructure` (Page 1603600679).
+> **용어**: WSOP는 "PayoutStructure", 사용자 용어 "PrizePool". API는 PayoutStructure 통일.
+
+| Method | Path | 설명 | 역할 제한 |
+|:---:|---|---|:---:|
+| GET | `/series/:id/payout-structures` | 템플릿 목록 | 인증 사용자 |
+| POST | `/series/:id/payout-structures` | 템플릿 생성 | Admin |
+| GET | `/series/:id/payout-structures/:ps_id` | 템플릿 상세 | 인증 사용자 |
+| PUT | `/series/:id/payout-structures/:ps_id` | 템플릿 수정 (is_template=true는 creator만) | Admin |
+| DELETE | `/series/:id/payout-structures/:ps_id` | 템플릿 영구 제거 | Admin |
+| GET | `/flights/:id/payout-structure` | Flight 적용 Payout 조회 | 인증 사용자 |
+| PUT | `/flights/:id/payout-structure` | Flight 적용 Payout 수정 | Admin |
+
+**POST /series/:id/payout-structures — Request:**
+```json
+{
+  "name": "Standard Tournament Payout",
+  "is_template": true,
+  "entries": [
+    {
+      "entry_from": 10, "entry_to": 50,
+      "ranks": [
+        { "rank_from": 1, "rank_to": 1, "award_percent": 50.0 },
+        { "rank_from": 2, "rank_to": 2, "award_percent": 30.0 },
+        { "rank_from": 3, "rank_to": 3, "award_percent": 20.0 }
+      ]
+    },
+    {
+      "entry_from": 51, "entry_to": 100,
+      "ranks": [
+        { "rank_from": 1, "rank_to": 1, "award_percent": 35.0 },
+        { "rank_from": 2, "rank_to": 2, "award_percent": 22.0 },
+        { "rank_from": 3, "rank_to": 5, "award_percent": 10.0 },
+        { "rank_from": 6, "rank_to": 10, "award_percent": 4.3 }
+      ]
+    }
+  ]
+}
+```
+> `entries[]` 엔트리 구간(entry_from/entry_to)별 payout 배열. 총 award_percent 합 = 100.0 검증 필요.
+
+**PUT /flights/:id/payout-structure — Request:**
+```json
+{ "template_id": 7, "overrides": null }
+```
+> 적용 즉시 `prize_pool_changed` WebSocket 이벤트 발행 (API-05 §4.2.5).
+> `overrides` 제공 시 템플릿 값 위에 특정 rank 재정의.
```

### DATA-02 (PayoutStructure 엔티티)

```diff
+## PayoutStructure
+
+| Field | Type | Description |
+|---|---|---|
+| payout_structure_id | int | PK |
+| series_id | int | FK → series |
+| name | string | |
+| is_template | bool | Series 레벨 템플릿 여부 |
+| creator_user_id | int | 템플릿 수정 권한 제한용 |
+| entries | jsonb | PayoutEntry[] 배열 (entry_from/entry_to/ranks[]) |
+| created_at, updated_at | timestamp | |
```

## Divergence from WSOP LIVE (Why)

1. **URL kebab-case**: WSOP `/PayoutStructures` → EBS `/payout-structures`. 컨벤션.
2. **`award_percent` 합계 100.0 검증**: WSOP LIVE 문서에 명시 없음. EBS에서 비즈니스 규칙으로 강화.
   - **Why**: 불완전 payout 구조 방지. 통계 일관성.

## 영향 분석

- **Team 1 (Lobby)**: Payout 편집 UI (엔트리 구간 테이블 + rank 배열 편집). 약 2일.
- **Team 4 (CC)**: 최종 테이블 UI에 상위 N명 payout 표시 (1일).
- **Team 2**: 7 신규 엔드포인트 + JSON schema + percent 합 검증 + `prize_pool_changed` 이벤트 발행.

## 대안 검토

1. **payout curve를 공식(math formula)으로 저장**: 탈락. WSOP LIVE 원본은 테이블 기반. 유연성 우선.
2. **entries를 별도 테이블 분리**: 탈락. 전체 PUT 방식이라 단일 jsonb 충분.

## 검증

- percent 합계 != 100.0 → 400
- is_template=true + creator 아닌 유저 수정 → 403
- Flight 적용 후 prize_pool_changed 이벤트 payload 검증

## 승인 요청

- [ ] Team 1, 4 검토

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1603600679 | Staff App API / Payout Structure API (7 엔드포인트) |
