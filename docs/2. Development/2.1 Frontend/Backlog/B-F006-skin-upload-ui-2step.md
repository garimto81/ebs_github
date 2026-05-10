---
id: B-F006
title: "Skin 업로드 UI를 2-step 플로우로 업데이트"
status: PENDING
priority: low
source: docs/2. Development/2.1 Frontend/Backlog.md
mirror: none
---

# B-F006 — GFX Skin 업로드 UI 2-step 전환

## 배경

B-084에서 `SkinRepository.uploadSkin` 단일-step을 제거하고 아래 2가지 메소드로 분리:
- `createSkin(metadata)` → POST /Skins (skin_id 반환)
- `uploadSkinFile(skinId, bytes, fileName)` → POST /Skins/:id/upload
- `createAndUploadSkin(...)` — 편의 래퍼

현재 GFX 화면에 업로드 UI가 연결되어 있지 않아 호출부 수정은 없었음. 향후 UI 추가 시 `createAndUploadSkin`을 사용하거나 2-step 명시 필요.

## 구현 방향

| 방식 | 사용처 | 비고 |
|------|--------|------|
| A. `createAndUploadSkin` | 단순 "업로드" 버튼 | 내부적으로 2번 호출, 중간 실패 시 orphan skin record 가능 |
| B. 2-step 명시적 UI | 메타데이터 입력 → 파일 업로드 단계 분리 | UX 더 자연스러움, 실패 복구 용이 |

기본 방향: B. 사용자가 skin name/version 입력 후 "다음" → 파일 선택 → "업로드"

## DoD

- GFX 화면 Upload 버튼 → 2-step 다이얼로그
- 중간 실패 시 사용자 안내 + 재시도 or 삭제 옵션
- 업로드 진행률 표시 (`onProgress` 콜백 활용)
