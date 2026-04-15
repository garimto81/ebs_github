---
title: CR-conductor-20260411-ge-req-id-rework
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# CCR-DRAFT: GE 요구사항 ID prefix 재편 (범위 축소 반영)

- **제안팀**: conductor
- **제안일**: 2026-04-11
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/specs/BS-00-definitions.md (modify)
- **변경 유형**: modify
- **변경 근거**: 기존 BS-00에 `GEB-*` (Board, 15개) + `GEP-*` (Player, 15개) = 30개 요구사항이 존재하나, 편집 범위 축소(CCR `ge-ownership-move`)로 Transform/Animation 편집이 out-of-scope가 되어 이 30개가 **실제로는 편집 UI 대상이 아님**. 본 CCR은 GEB-/GEP-를 "참고 자산"으로 유지하고, 새 편집 scope에 맞는 prefix 4개(GEM-/GEI-/GEA-/GER-)를 신설한다.

## 변경 요약

1. GEB-/GEP- 30개는 "참고 자산"으로 유지 (PokerGFX 역설계 흔적 보존)
2. 신설 prefix 4개 (총 ~39개):
   - **GEM-** (Metadata): 25개 — skin.json 편집 가능 필드 (DATA-07 매트릭스)
   - **GEI-** (Import): 8개 — .gfskin ZIP 업로드, 검증, 프리뷰
   - **GEA-** (Activate): 6개 — Activate 요청, WS broadcast, 멀티 CC 동기화
   - **GER-** (RBAC): 5개 — Admin/Operator/Viewer gate (UI + API 이중)

## Diff 초안

### BS-00-definitions.md §요구사항 ID 체계 섹션

```diff
 ## GE (Graphic Editor) 요구사항 Prefix

 | Prefix | 범위 | 개수 | 상태 | 소유 |
 |--------|------|------|------|------|
-| GE- | 통합 30개 | 30 | active | team4 |
-| GEB- | Board 편집 | 15 | active | team4 |
-| GEP- | Player 편집 | 15 | active | team4 |
+| GEB- | Board 편집 (PokerGFX 역설계 참고) | 15 | reference-only | - |
+| GEP- | Player 편집 (PokerGFX 역설계 참고) | 15 | reference-only | - |
+| GEM- | Metadata 편집 (skin_name/version/colors/fonts/resolution/animations duration) | 25 | active | team1 |
+| GEI- | Import flow (.gfskin ZIP upload/validate/preview) | 8 | active | team1 |
+| GEA- | Activate + Broadcast (multi-CC sync) | 6 | active | team1 + team2 |
+| GER- | RBAC guards (Admin/Operator/Viewer) | 5 | active | team1 + team2 |
```

### GEM-* 요구사항 상세 (BS-00에 추가할 섹션)

```markdown
## GEM-* Metadata Editing Requirements

| ID | 설명 | skin.json path | 편집 UI | 검증 |
|----|------|---------------|---------|------|
| GEM-01 | Skin 이름 편집 | skin_name | text input (1~40) | non-empty |
| GEM-02 | 버전 편집 | version | text input | semver regex |
| GEM-03 | 작성자 편집 | author | text input (0~80) | - |
| GEM-04 | 해상도 선택 | resolution | dropdown (1080p/1440p/2160p) | enum |
| GEM-05 | 배경 타입 | background.type | dropdown (image/color/chromakey) | enum |
| GEM-06 | 배경색 (색상 타입) | colors.background | color picker | #hex |
| GEM-07 | Text primary 색상 | colors.text_primary | color picker | #hex |
| GEM-08 | Text secondary 색상 | colors.text_secondary | color picker | #hex |
| GEM-09 | Badge check 색상 | colors.badge_check | color picker | #hex |
| GEM-10 | Badge fold 색상 | colors.badge_fold | color picker | #hex |
| GEM-11 | Badge bet 색상 | colors.badge_bet | color picker | #hex |
| GEM-12 | Badge call 색상 | colors.badge_call | color picker | #hex |
| GEM-13 | Badge allin 색상 | colors.badge_allin | color picker | #hex |
| GEM-14 | Pot text 색상 | colors.pot_text | color picker | #hex |
| GEM-15 | Player name 폰트 | fonts.player_name | family+size+weight | - |
| GEM-16 | Chip stack 폰트 | fonts.chip_stack | family+size+weight | - |
| GEM-17 | Pot 폰트 | fonts.pot | family+size+weight | - |
| GEM-18 | Action badge 폰트 | fonts.action_badge | family+size+weight | - |
| GEM-19 | Equity 폰트 | fonts.equity | family+size+weight | - |
| GEM-20 | Hand rank 폰트 | fonts.hand_rank | family+size+weight | - |
| GEM-21 | Card fade duration | animations.card_fade_duration_ms | slider (0-5000) | integer |
| GEM-22 | Board slide duration | animations.board_slide_duration_ms | slider (0-5000) | integer |
| GEM-23 | Board stagger delay | animations.board_stagger_delay_ms | slider (0-1000) | integer |
| GEM-24 | Glint sequence duration | animations.glint_sequence_duration_ms | slider (0-5000) | integer |
| GEM-25 | Reset duration | animations.reset_duration_ms | slider (0-5000) | integer |
```

## GEI-* Import Flow Requirements (예시)

| ID | 설명 |
|----|------|
| GEI-01 | `.gfskin` ZIP 파일 선택 UI (파일 다이얼로그 또는 드래그앤드롭) |
| GEI-02 | ZIP 구조 검증 (skin.json + skin.riv 필수) |
| GEI-03 | skin.json JSON 파싱 |
| GEI-04 | DATA-07 JSON Schema 클라이언트 검증 (ajv-js) |
| GEI-05 | skin.riv Rive 파싱 가능성 확인 |
| GEI-06 | Rive 프리뷰 렌더링 (rive-js @rive-app/canvas) |
| GEI-07 | POST /api/v1/skins multipart 업로드 |
| GEI-08 | 업로드 실패 시 에러 메시지 UI |

## GEA-* Activate + Broadcast Requirements (예시)

| ID | 설명 |
|----|------|
| GEA-01 | Activate 버튼 클릭 → ETag 포함 PUT 요청 |
| GEA-02 | GameState==RUNNING 감지 시 경고 다이얼로그 표시 |
| GEA-03 | 412 ETag 충돌 시 최신 상태 refetch 후 재시도 옵션 |
| GEA-04 | 성공 응답 후 UI에 "Activated" 토스트 |
| GEA-05 | 서버 `skin_updated` WS broadcast (seq 단조증가) |
| GEA-06 | 다중 CC 인스턴스 동시 리로드 (500ms 이내) |

## GER-* RBAC Requirements (예시)

| ID | 설명 |
|----|------|
| GER-01 | Admin 역할만 Upload/PATCH/Activate/Delete 버튼 표시 |
| GER-02 | Operator는 읽기 전용 (리스트/프리뷰/메타데이터 조회) |
| GER-03 | Viewer는 GE 탭 자체 접근 차단 |
| GER-04 | 서버 API gate (UI gate 우회 방지) |
| GER-05 | 403 응답 시 UI 안내 메시지 |

## 영향 분석

| 팀 | 영향 | 공수 |
|----|------|------|
| Team 1 | GEM-*/GEI-*/GEA-*/GER-* 구현 시 ID 참조. 변경 없음 (ID 체계 정의만) | 0 |
| Team 2 | GEA-* 구현 (Activate + broadcast) 시 ID 참조 | 0 |

## 대안 검토

1. **기존 GEB-/GEP- 재사용 (prefix 추가 없이)**: 의미 불일치 (Board/Player 편집 아님). ❌
2. **본 CCR (4개 신규 prefix)**: 의미 명확, scope 축소 반영. ✅

## 검증 방법

- BS-00 §요구사항 ID 체계 섹션 수정 완료
- BS-08 5파일이 GEM/GEI/GEA/GER 참조 포함
- Week 4 matrix `08-requirements-matrix.md`가 신규 ID로 정렬

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (ID 네이밍 수용)
- [ ] Team 2 기술 검토 (GEA 구현 시 ID 참조 가능성)

## 참고 사항

- **선행 조건**: CCR `ge-ownership-move` (팀 경계 확정)
- **후속 CCR**: 없음
- **Plan 파일**: `C:/Users/AidenKim/.claude/plans/floating-percolating-petal.md`
