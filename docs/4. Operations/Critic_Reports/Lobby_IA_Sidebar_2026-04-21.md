---
title: Critic — Lobby 좌측 사이드바 IA + 5NF 확장성 검토
owner: conductor
tier: internal
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "Critic 리포트. 변경 제안은 SG 및 Backlog 로 승격, 본 문서는 판정 근거 SSOT"
related:
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md §공통 레이아웃
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃 (line 391~450)
  - docs/2. Development/2.1 Frontend/Settings/Overview.md §2 5탭 구조
  - docs/4. Operations/Spec_Gap_Registry.md SG-012 ~ SG-019 (승격 예고)
confluence-page-id: 3818848838
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818848838/EBS+Critic+Lobby+IA+5NF
---

# Critic — Lobby 좌측 사이드바 IA + 5NF 확장성 검토

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | 사용자 요청(ultrathink critic mode) — 5탭 적합성 + 탭별 필수 정보값 + 5NF 기반 자유 확장 설계 |
| 2026-04-21 | revision 1 | 사용자 추가 지시 — §7 권고안에서 **Insights 제거** + **Hand History 독립 섹션 승격**. §8 매트릭스, §9 SG-016, §12 판정 연동 갱신. EBS 고유 기능(Hand History) 을 Lobby 사이드바 공식 섹션으로 공식화 |

## 1. 검토 대상

사용자 제안 5탭: **lobby / staff / settings / gfx / reports**

추가 기준 (2026-04-21 보강): "5정규화 법칙에 의거하여 이후 발생할 가능성을 최대한 대비하여 목록이 자유롭게 추가 설계 가능하고, 요소들을 자유롭게 추가 설계 가능한 형태."

## 2. 현재 사이드바 SSOT (UI.md §공통 레이아웃, line 401~445)

```
■ Tournaments
  ├─ Tournaments (목록)            → Event 목록
  ├─ Create Tournament             → [+ New Event] 다이얼로그
  ├─ Templates / Blind             → Blind Structure 템플릿
  └─ Series Settings               → Settings 페이지 링크
■ Staff
  └─ Staff List                    → 사용자 관리 (Admin only)
■ Players
  ├─ Create Player
  └─ Player Verification
■ History
  └─ Staff Action History          → 감사 로그 뷰어
```

헤더 독립 버튼: `[Graphic Editor]`, `[Settings ⚙]`, `[CC ▼]`.
Settings 자체는 Lobby **내부 페이지** (Outputs / Graphics / Display / Rules / Stats 5탭).

## 3. 사용자 제안 vs SSOT 대조

| User 제안 탭 | SSOT 대응 | 일치도 | 비고 |
|:-----------:|-----------|:------:|------|
| **lobby** | Tournaments 섹션 | △ 용어 충돌 | 앱명(Lobby)과 섹션명이 동일어가 되어 혼동. WSOP LIVE 원어는 "Tournaments" |
| **staff** | Staff 섹션 | ○ | 용어 일치 |
| **settings** | 헤더 `[Settings ⚙]` + Series Settings 링크 | △ 위치 중복 | 사이드바 진입점 vs 헤더 진입점 병존 |
| **gfx** | 헤더 `[Graphic Editor]` + Settings/Graphics 탭 | △ 의미 분기 | "gfx" 가 스킨 편집(GE) 인지 런타임 그래픽(Settings) 인지 모호 |
| **reports** | History/Staff Action History | ✗ 성격 상이 | Reports = 집계/통계, History = 원본 이벤트. 동일시 불가 |
| (빠짐) | **Players** | — | 사용자 제안에 없음. Player 는 Event 독립 엔티티 |
| (빠짐) | **History** | — | Reports 로 흡수 시도 시 multi-valued dependency 발생 (§5 참조) |

## 4. Critic A — Information Architecture Taxonomy

### 4.1 용어 충돌 (lobby 라벨)

- "Lobby" 는 앱 전체 명칭이면서 섹션명이 되면 Breadcrumb(`EBS > Series > Event`) 와 사이드바(`Lobby > ...`) 의 의미 레이어가 겹침.
- **WSOP LIVE 정렬 원칙 1**: 원어는 "Tournaments". "lobby" 는 앱 컨테이너 용어로 유지하고, 섹션은 **Tournaments** 로 명명해야 정렬 유지.
- 정정하지 않을 경우 원칙 1 divergence 로 `Why:` justify 필수.

### 4.2 Players / History 누락의 5NF 위반

"Reports" 로 "History" 를 흡수하면 다음 결합 의존이 발생한다:

| 항목 | 본질 속성 | 결합 시 발생하는 문제 |
|------|----------|---------------------|
| Reports | 집계(aggregation), schedule, template | History 원본 이벤트가 Reports 의 drill-down target 이 되면 Reports 테이블이 raw event 스키마에 종속 |
| History | 원본 이벤트, immutable append-only | Reports 쿼리 스펙이 History 변경과 coupling — JD(Report, Params) ⋈ JD(Event, Actor, Timestamp) 비자연 결합 |

→ 5NF 관점에서 **독립 탭 분리 유지** 가 정상. 사용자 제안의 "reports" 단일 탭은 결합 의존을 남긴다.

### 4.3 GFX 라벨 이중성

"gfx" 가 아래 두 개를 동시에 가리킬 수 있다:

| 의미 | 현재 위치 | 성격 |
|------|----------|------|
| Skin Editor (스킨 에셋 CRUD) | 헤더 `[Graphic Editor]` 독립 버튼 | Asset authoring — git 유사 version 관리 |
| Runtime Graphics (런타임 배치) | Settings 내 Graphics 탭 (12개 컨트롤) | Config — key/value 설정 |

→ 동일 라벨 "gfx" 는 **두 엔티티를 하나의 탭으로 통합** 하려는 신호일 수 있으나, 수명 주기가 다름 (에셋: 빌드/버전 vs 설정: 런타임 변경). 5NF 관점에서 분리 유지.

## 5. Critic B — 5NF 확장성 검토

### 5.1 사용자 요구 재해석

"목록이 자유롭게 추가 가능 + 요소들이 자유롭게 추가 가능" = 메타모델 (metamodel) 정규화:

| 차원 | 의미 | 구현 |
|------|------|------|
| 수평 확장 | 탭(섹션) 자체를 런타임에 추가 | `nav_sections` 테이블 |
| 수직 확장 | 탭 내부 항목을 런타임에 추가 | `nav_items` 테이블 |
| 속성 확장 | 각 entity 의 속성을 스키마 변경 없이 추가 | EAV 또는 `*_attributes` JSONB |

### 5.2 5NF 기반 메타모델 제안

```sql
-- 1) 사이드바 섹션 자체를 데이터로
CREATE TABLE nav_sections (
  section_id   UUID PRIMARY KEY,
  slug         TEXT UNIQUE NOT NULL,        -- 'tournaments', 'staff', ...
  label_key    TEXT NOT NULL,               -- i18n 키
  icon         TEXT,
  display_order INT NOT NULL,
  role_required TEXT[] NOT NULL,            -- ['admin','operator']
  feature_flag TEXT,                        -- nullable, NULL = always on
  deprecated_at TIMESTAMP
);

CREATE TABLE nav_items (
  item_id      UUID PRIMARY KEY,
  section_id   UUID NOT NULL REFERENCES nav_sections,
  slug         TEXT NOT NULL,               -- 'create-tournament'
  label_key    TEXT NOT NULL,
  route        TEXT NOT NULL,               -- '/tournaments/new'
  role_required TEXT[] NOT NULL,
  display_order INT NOT NULL,
  feature_flag TEXT,
  UNIQUE(section_id, slug)
);

-- 2) 각 섹션의 "자유 확장" 포인트를 정규화
CREATE TABLE report_templates (
  template_id  UUID PRIMARY KEY,
  name         TEXT NOT NULL,
  query_spec   JSONB NOT NULL,              -- DSL 또는 SQL 템플릿
  viz_type     TEXT NOT NULL,               -- 'table','chart','kpi'
  schedule_cron TEXT,                        -- nullable, 수동 실행
  created_by   UUID REFERENCES users
);

CREATE TABLE skin_modes (
  mode_id      UUID PRIMARY KEY,
  skin_id      UUID NOT NULL REFERENCES skins,
  mode_slug    TEXT NOT NULL,               -- 'hole-cards','winner',...
  rive_path    TEXT NOT NULL,
  schema_json  JSONB NOT NULL,              -- 바인딩 가능한 필드
  UNIQUE(skin_id, mode_slug)
);

CREATE TABLE setting_categories (
  category_id  UUID PRIMARY KEY,
  slug         TEXT UNIQUE NOT NULL,        -- 'outputs','graphics',...
  label_key    TEXT NOT NULL,
  schema_ref   TEXT NOT NULL,               -- JSON Schema file path
  scope        TEXT NOT NULL                -- 'global','series','event','table'
);

CREATE TABLE integration_providers (
  provider_id  UUID PRIMARY KEY,
  type         TEXT NOT NULL,               -- 'wsop-live','custom-sync'
  config       JSONB NOT NULL,
  status       TEXT NOT NULL,
  enabled      BOOLEAN NOT NULL DEFAULT FALSE
);
```

### 5.3 확장 포인트 매트릭스

| 미래 확장 가능성 | 현재 대응 | 5NF 권장 | 우선순위 |
|----------------|----------|---------|:-------:|
| 새 게임 종목 (ex. Short Deck) | Rules 탭 하드코드 | `game_rules` 테이블 (현 Rules.md 11 컨트롤 동적화) | P1 |
| 새 리포트 유형 | Reports 미명세 | `report_templates` | P1 |
| 새 Overlay 스킨 모드 | GE 8모드 고정 | `skin_modes` | P1 |
| 새 운영자 역할 | Admin/Operator/Viewer 고정 | `roles` + `permissions` | P2 |
| 새 언어/통화 | 하드코드 | `locales`, `currencies` | P3 |
| 새 인증 제공자 | Google OAuth 고정 | `auth_providers` | P2 |
| 새 출력 프로토콜 | NDI/RTMP/SRT/DIRECT 고정 | `output_protocols` | P2 |
| 새 RFID 카드 타입 | 고정 | `card_types` (SG-011 OUT_OF_SCOPE 와 별개) | P3 |
| 새 알림 채널 (Slack/Email/…) | 없음 | `notification_channels` | P3 |
| 새 외부 API 통합 | WSOP LIVE 고정 | `integration_providers` | P2 |

## 6. Cross-adjudication

### 6.1 WSOP LIVE 정렬 (원칙 1)

WSOP LIVE Staff Page 사이드바 (UI.md §10 Divergence 정본):

```
Tournaments / Staff / Players / History
(EBS 제외: Cage, Cashier, Wallet, Payroll, Payout, Chip Master,
         Series Chips, Tournament Ticket, Player Rating)
```

User 제안 대비 원칙 1 divergence:

| User 제안 | WSOP LIVE 존재? | Justify |
|:---------:|:--------------:|---------|
| lobby | ✗ (Tournaments 가 원어) | 용어 수정 필요 |
| staff | ○ | — |
| settings | ✗ (WSOP 는 헤더 전용) | EBS 고유: 운영 빈도 높음 → 사이드바 승격 검토 가능 |
| gfx | ✗ (WSOP 에 GE 없음) | EBS 고유 (Rive Overlay 필수) |
| reports | ✗ (WSOP 는 History) | History 로 재명명 또는 병치 |

### 6.2 EBS Core 경계 (§1.2)

EBS Core = **실시간 라이브** (WSOP LIVE + RFID + CC → Overlay). Reports 는 집계/사후 분석 성격 → 포스트프로덕션 경계 위험.

| 탭 | Core 위치 | 경계 판정 |
|----|----------|-----------|
| Tournaments | Core (운영 준비) | ✓ |
| Staff | Core 인접 (RBAC) | ✓ |
| Players | Core (오버레이 표시 소스) | ✓ |
| Settings | Core (오버레이 런타임 제어) | ✓ |
| Graphics (GE) | Core (오버레이 에셋) | ✓ |
| Reports | **Core 외곽** | △ — "실시간 지표" 만 허용, 장기 통계는 포스트프로덕션 경계 |
| History | Core 인접 (감사) | ✓ |

→ Reports 탭 신설 시 **"실시간 운영 지표" 만 scope** 명문화 필요. VPIP/PFR 등 핸드 통계도 "당일 라이브 범위" 로 제한.

## 7. 권고 — 사이드바 v2 (수정안, revision 1)

```
■ Tournaments                 (= Lobby 메인 drill-down)
  ├─ Series List
  ├─ Create Tournament
  ├─ Templates (Blind / Payout / Rules)
  └─ Series Settings
■ Tables                      (NEW — 활성 테이블 바로가기)
  ├─ Active Tables Grid
  └─ Feature Tables
■ Players                     (KEEP — user 제안에 빠졌으나 필수)
  ├─ Create Player
  ├─ Player Verification
  └─ Player Search
■ Staff                       (= user 제안)
  ├─ Staff List
  └─ Roles & Permissions
■ Graphics                    (= user "gfx" 명확화 — 에셋)
  ├─ Skin Editor (GE)
  ├─ Skin Library
  └─ Rive Assets
■ Settings                    (사이드바 병치 + 헤더 ⚙ 유지)
  ├─ Outputs
  ├─ Graphics (런타임 배치)
  ├─ Display
  ├─ Rules
  └─ Stats
■ Hand History                (NEW — EBS 고유 기능, 사용자 2026-04-21 지시)
  ├─ Hand Browser             (Event/Day/Table 필터)
  ├─ Hand Detail              (액션 타임라인 + 카드 + 팟 전개)
  └─ Player Hand Stats        (VPIP / PFR / AGR)
■ History                     (KEEP — 감사 로그 분리)
  ├─ Staff Actions
  └─ Config Changes
■ Integrations                (NEW — 외부 API / 미래 확장)
  └─ WSOP LIVE Sync
```

섹션 수 **9개 (revision 1 유지)** — Insights 제거, Hand History 독립 섹션 승격. 런타임에 `nav_sections.feature_flag` 로 가시성 제어.

### 7.1 변경 근거 (revision 1, 2026-04-21)

| 항목 | 이전 (v1) | 이후 (v2) | 근거 |
|------|----------|----------|------|
| Insights | 실시간 한정 리포트 섹션 | **제거** | EBS Core §1.2 위반 위험 (포스트프로덕션 경계). 실시간 지표는 Tables/CC 화면에 inline 충분 |
| Hand History | — | **독립 섹션 신설** | Foundation §Ch.6 · Overview.md `hands`/`hand_actions` 테이블 · Schema.md line 389+ · WebSocket HandStarted/HandEnded. 25개 문서에 분산되어 있으나 사이드바 진입점 없음 (SG-016 revised) |

### 7.2 Hand History 섹션 상세

| 서브메뉴 | Primary Entity | Essential View |
|----------|---------------|----------------|
| Hand Browser | `hands` | Event/Day/Table/Player/Date 필터 + Hand # 리스트 (시작시각, 승자, 팟) |
| Hand Detail | `hand_actions` + `hand_seats` | Preflop/Flop/Turn/River 타임라인 + hole card 공개(권한별) + 액션 시퀀스 + 팟 전개 |
| Player Hand Stats | `hand_actions` 집계 | 플레이어별 VPIP/PFR/AGR/WTSD 등. **실시간 당일 한정** (포스트프로덕션 경계 준수) |

EBS Core §1.2 경계: Hand History = 라이브 운영 + 당일 기록 조회 범위. 장기 아카이브/편집은 포스트프로덕션 책임. `docs/mockups/ebs-flow-hand-history.html` 목업 이미 존재.

## 8. 탭별 필수 정보값 매트릭스

각 탭은 Primary Entity + Essential Attributes + Extensibility Point 로 구성한다.

| 탭 | Primary Entity | Essential Attributes | Extensibility Point (5NF) |
|----|----------------|---------------------|--------------------------|
| Tournaments | Series | id, name, start/end, timezone, status, venue, bookmarked | `series_attributes` (EAV) |
| Tables | Table | id, event_id, seat_count, rfid_reader_id, output_channel, state | `table_attributes` |
| Players | Player | id, display_name, country, avatar, verification_status | `player_attributes` |
| Staff | User | id, email, role_id, status_flags (bitfield), 2fa_enabled | `user_attributes` |
| Graphics | Skin | id, name, version, rive_bundle_url, modes[] | `skin_modes` (§5.2) |
| Settings | Config | category_id, key, value, scope_id, applied_at | `setting_categories` (§5.2) |
| Hand History | Hand (+ HandAction, HandSeat) | hand_id, hand_number, table_id, start_ts, end_ts, winner_seats, pot_total, blind_level | `hand_actions` (PK hand_id+seq), `hand_seats` (PK hand_id+seat_no). ~~`report_templates`~~ 제거 |
| History | AuditEvent | id, actor_id, action, target_ref, delta_json, timestamp | event_type 카탈로그 테이블 |
| Integrations | Provider | id, type, config_json, status, last_sync_at | `integration_providers` (§5.2) |

## 9. Spec Gaps 승격

본 critic 에서 식별한 gaps 는 Spec_Gap_Registry 로 승격한다 (Conductor 등재).

| SG ID | 유형 | 대상 | 요약 |
|-------|------|------|------|
| SG-012 | doc_ssot | 2.1 Frontend/Lobby/UI.md §공통 레이아웃 | 사이드바 SSOT 가 ASCII 예시만 존재. `nav_sections`/`nav_items` 스펙 테이블 부재 |
| SG-013 | nomenclature | 2.1 Frontend/Lobby | "lobby" 앱명 vs 섹션명 용어 충돌. WSOP LIVE 원어 "Tournaments" 정렬 |
| SG-014 | ia_overlap | 2.1 Frontend/Lobby, Settings | Graphic Editor 진입점 이중화 (헤더 버튼 + Settings/Graphics 탭) — 스킨 에셋 vs 런타임 설정 구분 명시 |
| SG-015 | ia_missing | 2.1 Frontend/Lobby | Players 섹션 현 존재하나 사용자 제안에 없음 — 유지 결정 근거 문서화 필요 |
| SG-016 | ia_missing | 2.1 Frontend/Lobby | **revision 1 (2026-04-21)**: ~~Insights~~ 제거. Hand History 사이드바 섹션 공식화 — 25개 문서에 분산된 hands/hand_actions/HandStarted 참조 + `ebs-flow-hand-history.html` 목업을 독립 섹션 SSOT 로 통합 (후속 계획: `Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md`) |
| SG-017 | scope_inconsistency | 2.1 Frontend/Settings/Overview.md §개요 | "글로벌 단위" 서술 vs MEMORY feedback_settings_global 역전(Series/Event/Table 분리) 모순 |
| SG-018 | data_model | 2.2 Backend/Database | 5NF 메타모델 테이블 부재 (`nav_sections`, `report_templates`, `skin_modes`, `setting_categories`, `integration_providers`, `game_rules`, `roles/permissions`) |
| SG-019 | scope_boundary | 1. Product/Foundation §1.2 | Reports/Insights 탭과 포스트프로덕션 경계 정의 (실시간 범위 명시) |

## 10. 자기반박 (Counter-evidence)

본 critic 의 약점을 공개한다:

1. **"User 의 lobby ≠ Tournaments 이다"** 라고 단정 — 사용자가 섹션명 "lobby" 를 의도했다면 WSOP LIVE divergence 도 의도일 수 있다. 결정은 사용자 확인 후.
2. **"5NF 를 IA 에 직접 적용"** — 5NF 는 DB 이론. IA 에서는 facet classification 이 더 정확. 본 리포트는 DB 스키마 제안(§5.2) + IA 재구성(§7) 을 분리함으로써 양쪽 모두 커버.
3. **"섹션 9개"** 권고 — 확장성 우선으로 사이드바가 비대해질 위험. 권고 §7 의 `nav_sections.feature_flag` + `role_required` 로 role 별 노출 축소가 완화. 그러나 기본 9개도 많다는 반론 가능 — 대안: "Integrations" 를 Settings 하위 탭으로 흡수하면 8개.
4. **"Reports = 실시간만"** 판정 — 오버엔지니어링 위험. "실시간 지표 + 당일 종료 후 요약" 까지 포함으로 완화 가능. 결정은 team2 Backend + Conductor. **(revision 1 2026-04-21: Insights 섹션 자체를 제거하여 본 반박 해소. Hand History 가 실시간 + 당일 기록 역할 대행)**
5. **SG-017 Settings 스코핑 모순** — MEMORY 근거가 2026-04-15 역전이지만, 이후 Overview.md §개요 는 갱신되지 않았음. MEMORY 자체가 stale 인지 Overview.md 가 stale 인지 재확인 필요. (feedback_memory_label_vs_reality 규율 적용)
6. **EBS 는 기획서 레포** (project_intent_spec_validation) — 5NF DB 스키마 제안이 프로토타입 범위를 넘을 수 있음. 본 리포트는 "권장" 수준이며, team2 publisher 가 채택 여부 결정.

## 11. 후속 Backlog 제안

본 critic 해소 작업을 Conductor_Backlog 및 team1 Backlog 에 등재 권고:

| Backlog ID | 소유 | 내용 |
|-----------|------|------|
| C-new | Conductor | SG-012~SG-019 Registry 등재 + 해소 추적 |
| team1-new | team1 | UI.md §공통 레이아웃 사이드바 SSOT 표 신설 (9-section 권고 기반 v2 초안) |
| team1-new | team1 | Lobby/Overview.md 에 Players/History 유지 근거 섹션 추가 |
| team2-new | team2 (publisher) | `nav_sections`/`nav_items`/`report_templates`/`skin_modes`/`setting_categories` DB 설계 — §5.2 참조 |
| conductor-new | Conductor | Foundation.md §1.2 에 Reports/Insights 실시간 경계 문장 추가 |
| conductor-new | Conductor | Settings 스코핑 모순 해소 (MEMORY vs Overview.md §개요) — decision_owner 판정 |

## 12. 판정 요약

| 질문 | 판정 |
|------|------|
| User 제안 5탭(lobby/staff/settings/gfx/reports) 구조적 적합? | **✗ 부적합** — Players/History 누락, gfx/lobby 용어 모호, reports 단독이면 multi-valued dependency |
| 각 탭 필수 정보값 명확? | **△ 부분** — §8 매트릭스로 보강 가능하나 SSOT 테이블 부재 (SG-012) |
| 5NF 기반 자유 확장 가능? | **✗ 현재 불가** — 메타모델 테이블 부재 (SG-018). §5.2 권고 채택 시 가능 |
| 권고안 채택 시 원칙 1 유지? | **○** — 용어 정렬 (lobby→Tournaments) + Players/History 유지로 WSOP LIVE 정렬 강화 |

**결론**: User 제안 5탭 구조 그대로 채택하지 말 것. §7 의 9-section v2 + §5.2 메타모델 표 채택 권고. 미채택 시 Foundation §1.2 의 원칙 1 + EBS Core 경계 명시적 divergence `Why:` 기록 필요.

## 관련 문서

- [Lobby/UI.md §공통 레이아웃](../../2.%20Development/2.1%20Frontend/Lobby/UI.md)
- [Lobby/Overview.md](../../2.%20Development/2.1%20Frontend/Lobby/Overview.md)
- [Settings/Overview.md](../../2.%20Development/2.1%20Frontend/Settings/Overview.md)
- [Foundation.md §1.2](../../1.%20Product/Foundation.md)
- [Spec_Gap_Registry.md](../Spec_Gap_Registry.md) — SG-012 ~ SG-019 승격
