---
id: SG-003
title: "Settings 6탭 스키마 — Outputs / GFX / Display / Rules / Stats / Preferences"
type: spec_gap
sub_type: spec_gap_major
status: PARTIAL  # 마스터 인덱스 + 탭 개요만 확정, 필드 상세는 후속 task
owner: conductor
decision_owners_notified: [team1, team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.1 Frontend/Settings/**  (신규 작성 필요)
  - docs/2. Development/2.2 Backend/Database/Schema.md  (Settings 저장 테이블)
  - team1-frontend/lib/features/settings/**
protocol: Spec_Gap_Triage
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=PARTIAL — 마스터 인덱스 확정, 필드 상세는 후속 task"
---
# SG-003 — Settings 6탭 스키마 (마스터)

## 공백 서술

`team1-frontend/CLAUDE.md:11` 에 "Settings 6탭(Outputs / GFX / Display / Rules / Stats / Preferences)" 선언되어 있으나:

- 각 탭의 **입력 필드** 미정의
- **저장 경로** 미결정 (DB table / config file / 브라우저 localStorage 상응물)
- **검증 규칙** (필수/옵션, 범위, 포맷) 부재
- **에러 처리** 및 기본값 미정의
- **스코프 분리** (Series/Event/Table 계층 중 어느 레벨에 저장?) 미결정 — `feedback_settings_global.md` 메모리 2026-04-15 재검토 필요

## 결정 (default, Phase B-2 마스터 범위)

### Setting Scope 계층 (feedback_settings_global 2026-04-15 재검토 반영)

**채택**: **WSOP LIVE 패턴 동일 — Series / Event / Table 3-level override**

```
Global (Admin default)
  └─ Series level (series_settings)
      └─ Event level (event_settings)
          └─ Table level (table_settings, 최종 적용)
```

Resolution: 하위 레벨이 상위 재정의. 각 탭의 필드마다 scope flag 지정 (global / series / event / table).

**Why**: 원칙 1 (WSOP LIVE 정렬). WSOP LIVE Staff Page 의 Settings 체계와 동일.

### 저장 백엔드

**채택**: **BO DB 테이블 `settings_kv` (key-value store)** + `scope_level`/`scope_id` 필드

```sql
-- DATA-04 계열 스키마 추가 제안
CREATE TABLE settings_kv (
  id UUID PRIMARY KEY,
  scope_level VARCHAR(10) NOT NULL,  -- 'global'|'series'|'event'|'table'
  scope_id UUID,  -- series.id | event.id | table.id, global이면 NULL
  tab VARCHAR(20) NOT NULL,  -- 'outputs'|'gfx'|'display'|'rules'|'stats'|'preferences'
  key VARCHAR(100) NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES users(id),
  UNIQUE (scope_level, scope_id, tab, key)
);
```

**Why**: 각 탭을 별도 테이블로 만들면 schema migration 폭증. JSONB value + key-based lookup 이 유연. WSOP LIVE 패턴 유사.

**Alternatives**:
- 탭별 개별 테이블 (`settings_outputs`, `settings_gfx`, ...) — migration 복잡
- 파일 기반 (TOML/YAML) — 원격 동기화 불가

## 6탭 개요

각 탭의 **세부 필드 스키마는 SG-003-{tab}.md 후속 문서**로 분할. 이 마스터는 탭별 범위·소유·우선 필드만 정의.

### Tab 1: Outputs

**역할**: 방송 출력 구성 (SDI/NDI/Preview)

**우선 필드 (Phase 1)**:
- `output_targets`: list of {type: 'sdi'|'ndi'|'preview', name, resolution, format}
- `active_overlay_preset_id`: FK to overlay_presets
- `security_delay_ms`: 0~10000 (홀카드 공개 지연, BS-07)
- `watermark_enabled`, `watermark_text`

**Scope**: table primary, event override 가능
**참조**: API-01 `POST /tables/{id}/settings/outputs`, API-04 OutputPreset

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/Outputs.md`

### Tab 2: GFX (Graphic)

**역할**: Rive 스킨 선택 + 색상 테마 + 애니메이션 토글

**우선 필드**:
- `active_skin_id`: FK to gfskins (DATA-07)
- `color_theme`: enum(auto, light, dark)
- `animation_speed`: 0.5~2.0 (배속)
- `element_visibility`: {holecards, community, pot, equity, outs, player_info, position, action_badge} boolean 맵 (Foundation Ch.2 "8가지 요소")
- `language`: enum(ko, en, es)

**Scope**: event primary
**참조**: DATA-07 .gfskin, API-07 Graphic Editor, BS-07 Overlay

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/GFX.md`

### Tab 3: Display

**역할**: Lobby/CC 자체 UI 설정

**우선 필드**:
- `theme`: auto/light/dark
- `density`: comfortable/compact
- `font_size_scale`: 0.8~1.4
- `timezone`: IANA TZ string
- `show_debug_overlay`: boolean (개발자 전용)

**Scope**: user preference (global per user)
**참조**: Lobby UI 가이드

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/Display.md`

### Tab 4: Rules

**역할**: 게임 규칙 상세 (변종, 블라인드, 타임 뱅크, ante/straddle)

**우선 필드**:
- `game_variant`: enum(NLH, PLO, Mixed, 22 종 variants)
- `blind_structure_id`: FK to blind_structures
- `ante_schedule_id`: FK (optional)
- `time_bank_seconds`: integer
- `straddle_enabled`: boolean + `straddle_positions`: list
- `showdown_order`: enum(clockwise, first_bettor_first)
- `under_raise_rule`: enum(half_raise_reopens, no_reopen) — BS-06 Rule-95
- `short_all_in_rule`: enum — BS-06 Rule-96
- `dead_button_rule`: enum — BS-06

**Scope**: event primary, table override 가능
**참조**: BS-06 Game Engine Behavioral Specs, Game Rules

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/Rules.md`

### Tab 5: Stats

**역할**: 통계 표시 설정 (승률, 아웃츠, 플레이어 히스토리)

**우선 필드**:
- `equity_display_mode`: enum(percentage, outs_count, both)
- `history_window`: integer (최근 N hands)
- `hud_enabled`: boolean
- `hud_fields`: list (VPIP, PFR, AF, 3bet%)
- `player_photo_enabled`: boolean

**Scope**: event primary
**참조**: Reports API (team2 Backend B-037~050)

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/Stats.md`

### Tab 6: Preferences

**역할**: 개인화 설정 (단축키, 알림, 기본값)

**우선 필드**:
- `shortcuts`: map<action_name, key_combo>
- `notification_enabled`: boolean
- `default_table_view`: enum(grid, list)
- `auto_logout_minutes`: integer
- `rbac_preferences`: {show_admin_controls: bool based on role}

**Scope**: user (global per user)
**참조**: BS-01 Auth, RBAC

**후속 문서**: `docs/2. Development/2.1 Frontend/Settings/Preferences.md`

## 영향 챕터 업데이트

- [x] SG-003 마스터 (이 문서) — 6탭 개요 + scope + 저장 백엔드 확정
- [ ] 탭별 후속 문서 6개 신규 작성 (team1 세션 주도, 각 탭 full schema)
- [ ] team2 DATA-04 / Schema.md 에 `settings_kv` 테이블 추가 (team2 세션)
- [ ] API-01 Backend_HTTP 에 `GET/PUT /settings?scope=&tab=` 엔드포인트 명세 (team2)
- [x] Roadmap.md Settings 라인 — UNKNOWN 유지 (탭별 상세 진행 중)

## 수락 기준 (마스터)

- [ ] 6탭 각각 별도 `.md` (필드 schema 완전) 존재
- [ ] `settings_kv` 테이블 migration 존재 (team2)
- [ ] API-01 `GET/PUT /settings` 엔드포인트 contract 존재 (team2)
- [ ] team1 lib/features/settings/ 각 탭 Riverpod provider 존재 (team1)

## 재구현 가능성 재판정

- 이 마스터 문서: PASS
- 6 탭별 스펙: PENDING (UNKNOWN)
- 전체 Settings 재구현: 전체 탭별 문서 완성 후 PASS 도달
