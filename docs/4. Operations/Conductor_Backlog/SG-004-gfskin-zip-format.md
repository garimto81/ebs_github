---
id: SG-004
title: ".gfskin ZIP 포맷 (DATA-07) — manifest + .riv + assets 구조 명세"
type: spec_gap
status: RESOLVED
owner: conductor
decision_owners_notified: [team1, team2, team4]
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/Database/  (DATA-07 신규)
  - docs/2. Development/2.1 Frontend/Graphic_Editor/  (Import/Activate 플로우)
  - docs/2. Development/2.4 Command Center/Overlay/  (.riv 소비)
protocol: Spec_Gap_Triage
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, ZIP 포맷 + manifest 확정"
---
# SG-004 — .gfskin ZIP 포맷 명세 (DATA-07)

## 공백 서술

`CCR-012` (2026-04 이전) 에 "gfskin ZIP 포맷 단일화 및 DATA-07 신설" 이 검토 요청되었으나 폐기됨(거버넌스 v7). 실제 포맷 명세는 미작성 상태:

- ZIP 내부 구조 미정
- `.riv` 와 메타데이터 관계 불명
- 버전 관리·호환성 정책 부재
- 업로드 검증 규칙 미정
- 다국어 텍스트 리소스 포함 여부 미정

## 결정 (default)

### ZIP 내부 구조 (채택)

```
<skin_name>.gfskin  (ZIP container, .zip 확장자 대신 .gfskin)
├── manifest.json         (필수, 최상위)
├── overlay.riv           (필수, Rive 바이너리 단일 파일)
├── preview.png           (필수, 512×288 썸네일)
├── assets/               (선택, Rive 가 참조하는 외부 리소스)
│   ├── fonts/*.ttf
│   ├── images/*.png
│   └── audio/*.ogg  (BS-07 오디오 레이어, CCR-033 참조)
├── i18n/                 (선택, 다국어 문자열)
│   ├── ko.json
│   ├── en.json
│   └── es.json
└── CHANGELOG.md          (선택, 스킨 버전 이력)
```

### manifest.json 필수 필드

```json
{
  "$schema": "https://ebs.local/schemas/gfskin-manifest-v1.json",
  "spec_version": "1.0",
  "skin_id": "uuid-v4",
  "name": {"ko": "기본 스킨", "en": "Default Skin", "es": "Tema Predeterminado"},
  "version": "1.2.3",
  "author": "artist name",
  "created_at": "2026-04-20T12:00:00Z",
  "rive_file": "overlay.riv",
  "rive_artboard": "MainOverlay",
  "supported_output_events": [
    "holecards_revealed", "community_board_updated", "pot_updated",
    "equity_updated", "action_badge", "player_info_updated",
    "position_indicator", "outs_updated", "...21종 중 지원 목록"
  ],
  "element_mapping": {
    "holecards": "layer:holecards",
    "community": "layer:community",
    "pot": "text:pot_value",
    "equity": "text:equity_percent"
  },
  "audio_layers": [
    {"event": "card_dealt", "file": "assets/audio/card-flip.ogg"},
    {"event": "chip_bet", "file": "assets/audio/chip-push.ogg"}
  ],
  "security_delay_compatible": true,
  "min_ebs_version": "0.1.0",
  "license": "proprietary",
  "tags": ["wsop-style", "dark-theme"]
}
```

### 버전 관리

- **`spec_version`** (manifest schema 버전): semver. Breaking change 시 major 증가
- **`version`** (스킨 콘텐츠 버전): semver. 재업로드 시 이전 버전 보존 (히스토리)
- **`min_ebs_version`**: 이 스킨이 요구하는 최소 EBS 버전. 미달 시 업로드 거부

### 업로드 검증 규칙

업로드 시 BO 가 순차 검증:

1. ZIP 유효성 (파일 개수 ≤ 200, 총 크기 ≤ 50MB)
2. `manifest.json` 존재 + JSON Schema 검증
3. `overlay.riv` 존재 + Rive magic bytes 확인
4. `preview.png` 존재 + 512×288 해상도
5. `element_mapping` 의 모든 layer/text 가 `overlay.riv` 에 실존 (Rive parser)
6. `audio_layers.file` 참조 파일 실존
7. `supported_output_events` 가 API-04 OutputEvent 21종 카탈로그의 부분집합
8. `min_ebs_version` ≤ 현재 EBS 버전

실패 시 구체적 에러 반환 (`{"error_code": "GFSKIN_MISSING_ARTBOARD", "detail": "..."}`).

### .riv 와 .gfskin 관계

- `.riv` = Rive 원본 바이너리 (디자이너가 Rive 에디터에서 export)
- `.gfskin` = `.riv` + manifest + assets + i18n 을 묶은 **배포 패키지**
- Rive 에디터 기능 재구현 금지 (team4 CLAUDE.md:110) — `.riv` 는 읽기 전용 소비

### i18n 구조 (선택)

```json
// i18n/ko.json
{
  "player.folded": "폴드",
  "overlay.pot": "팟",
  "overlay.allin": "올인"
}
```

Rive 파일 내 text run 에 `key:player.folded` 형식으로 참조. Lobby `Settings > GFX > language` 와 연동.

## 영향 챕터 업데이트

- [x] 본 SG-004 문서 — 포맷 명세 확정
- [ ] `docs/2. Development/2.2 Backend/Database/DATA-07-gfskin-schema.md` 신규 작성 (team2 세션, 이 SG 를 SSOT 로 복사)
- [ ] `docs/2. Development/2.1 Frontend/Graphic_Editor/Import_Flow.md` Import 플로우에서 검증 단계 반영 (team1)
- [ ] `docs/2. Development/2.4 Command Center/Overlay/Skin_Consumer.md` 의 .riv 로드 로직에서 manifest 파싱 반영 (team4)
- [ ] API-07 Graphic Editor 엔드포인트 `POST /skins` multipart/form-data 계약 업데이트 (team2)

## 수락 기준

- [ ] manifest JSON Schema (`schemas/gfskin-manifest-v1.json`) 작성
- [ ] sample `.gfskin` 파일 1개 생성 (`docs/examples/default.gfskin`)
- [ ] BO 업로드 검증 스크립트 7단계 구현 + 7 error code 정의
- [ ] team4 Skin Consumer 가 manifest 파싱 + element_mapping 준수

## 재구현 가능성

- SG-004: **PASS** (본 문서 단독 자립)
- DATA-07 통합 후 Roadmap `.gfskin ZIP 포맷` UNKNOWN → PASS
