---
title: CR-team2-20260414-blindstructure-endpoints
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-blindstructure-endpoints
---

# CCR-DRAFT: BlindStructure 관리 엔드포인트 추가 (WSOP LIVE 정렬)

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team3]
- **변경 대상 파일**: contracts/api/`Backend_HTTP.md` (legacy-id: API-01), contracts/data/DATA-02-entities.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff App(Page 1603666061)은 BlindStructure 템플릿 기반 CRUD + Flight별 적용 엔드포인트 8종을 제공. EBS API-01에 BlindStructure 편집 API 부재. 정식 전체 개발에서 WSOP LIVE 패턴 준거.

## 변경 요약

WSOP LIVE BlindStructure 엔드포인트 8종 EBS에 반영 (URL 경로 EBS 컨벤션 적용).

## Diff 초안

```diff
+### 5.X BlindStructure — 블라인드 구조
+
+> **WSOP LIVE 대응**: `/Series/{sId}/BlindStructures/*` + `/EventFlights/{efId}/BlindStructure` (Page 1603666061).
+> **템플릿 기반**: Series 레벨에서 템플릿 관리, EventFlight 레벨에서 템플릿 적용/수정.
+
+| Method | Path | 설명 | 역할 제한 |
+|:---:|---|---|:---:|
+| GET | `/series/:id/blind-structures` | 템플릿 목록 | 인증 사용자 |
+| GET | `/series/:id/blind-structures/templates/:blind_type` | 타입별 샘플 템플릿 | 인증 사용자 |
+| GET | `/series/:id/blind-structures/:bs_id` | 템플릿 상세 (레벨 배열 포함) | 인증 사용자 |
+| POST | `/series/:id/blind-structures` | 템플릿 생성 | Admin |
+| PUT | `/series/:id/blind-structures/:bs_id` | 템플릿 수정 (구조 전체 PUT, creator만) | Admin |
+| DELETE | `/series/:id/blind-structures/:bs_id` | 템플릿 영구 제거 | Admin |
+| GET | `/flights/:id/blind-structure` | Flight 적용 구조 조회 | 인증 사용자 |
+| PUT | `/flights/:id/blind-structure` | Flight 적용 구조 수정 (즉시 반영) | Admin |
+
+**POST /series/:id/blind-structures — Request:**
+```json
+{
+  "name": "Standard NL Holdem 60min",
+  "blind_type": "no_limit_holdem",
+  "is_auto_renaming": true,
+  "details": [
+    { "level": 1, "type": 0, "sb": 100, "bb": 200, "ante": 0, "duration_sec": 3600, "active_group": "A", "inactive_group": null },
+    { "level": 2, "type": 0, "sb": 200, "bb": 400, "ante": 50, "duration_sec": 3600, "active_group": "A", "inactive_group": null },
+    { "level": 3, "type": 1, "sb": null, "bb": null, "ante": null, "duration_sec": 900, "active_group": null, "inactive_group": null }
+  ]
+}
+```
+> `type`: BlindDetailType enum (0=Blind, 1=Break, 2=DinnerBreak, 3=HalfBlind, 4=HalfBreak). `is_auto_renaming`: 중복 이름 자동 번호 접미사.
+
+**PUT /flights/:id/blind-structure — Request:**
+```json
+{ "template_id": 42, "overrides": { "3": { "duration_sec": 1200 } } }
+```
+> 템플릿 적용 후 특정 레벨 override. `blind_structure_changed` WebSocket 이벤트 발행 (API-05 §4.2.4).
```

### DATA-02 (BlindStructure 엔티티)

```diff
+## BlindStructure
+
+| Field | Type | Description |
+|---|---|---|
+| blind_structure_id | int | PK |
+| series_id | int | FK → series |
+| name | string | 템플릿 이름 |
+| blind_type | enum | no_limit_holdem / pot_limit_omaha / mixed 등 |
+| is_template | bool | Series 레벨 템플릿 여부 |
+| creator_user_id | int | 생성자 (template 수정 권한 제한용) |
+| is_auto_renaming | bool | 중복 이름 자동 접미사 |
+| details | jsonb | BlindStructureDetail 배열 (레벨별) |
+| created_at, updated_at | timestamp | |
+
+## BlindStructureDetail (jsonb 내부 구조)
+
+| Field | Type | Description |
+|---|---|---|
+| level | int | 레벨 순번 |
+| type | enum | BlindDetailType (0-4) |
+| sb, bb, ante | int | null if type != 0,3 |
+| duration_sec | int | |
+| active_group, inactive_group | string | half-break 구분용 |
```

## Divergence from WSOP LIVE (Why)

1. **URL snake_case**: WSOP `/BlindStructures` → EBS `/blind-structures`. EBS 컨벤션.
2. **details를 JSON 컬럼 저장**: WSOP LIVE BlindStructureDetailList 별도 테이블일 가능성.
   - **Why**: 레벨 편집이 전체 PUT 방식이므로 분리 테이블 이득 낮음. 쿼리 요구 발생 시 재설계.

## 영향 분석

- **Team 1 (Lobby)**: BlindStructure 편집 화면 신설 (2일). Flight 설정에서 템플릿 선택 드롭다운.
- **Team 3 (Engine)**: `blind_structure_changed` 수신 시 엔진 내부 BlindStructureChanged 이벤트 발행 (1시간).
- **Team 2**: 8 신규 엔드포인트 + JSON schema 검증 + template creator 권한 가드.

## 대안 검토

1. **레벨별 개별 CRUD**: 탈락. 구조 전체 PUT이 WSOP LIVE 원본 + 트랜잭션 단순.
2. **blind_type을 자유 문자열**: 탈락. 게임 타입과 연계(Team 3 엔진)이므로 enum.

## 검증

- 템플릿 creator 외 수정 시 403
- blind_type별 sample 템플릿 GET 결과 (WSOP LIVE 원본 sample 교차 확인)
- Flight 적용 후 `blind_structure_changed` 이벤트 수신 확인

## 승인 요청

- [ ] Team 1, 3 검토
- [ ] Team 3 엔진 이벤트 수신 구조 검토

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1603666061 | Staff App API / Blind Structure API (8 엔드포인트) |
| 1960411325 | Enum (BlindDetailType, BlindType) |
