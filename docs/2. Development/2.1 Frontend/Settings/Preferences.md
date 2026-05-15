---
title: Preferences
owner: team1
tier: internal
last-updated: 2026-04-22
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "신규 작성 (2026-04-20). SG-003 §Tab 6 Preferences 에 따른 개인화 설정"
sg_reference: SG-003
scope: user
confluence-page-id: 3832873186
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832873186/Preferences
---

# Preferences — 개인화 설정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-20 | 신규 작성 | SG-003 §Tab 6 기반 개인화 설정 (단축키·UI 환경) |
| 2026-04-22 | legacy-id 삭제 | 구 BS-03-06 (테이블 운영) 은 `../Lobby/Operations.md` 정본. 본 문서는 신규 SG-003 자료라 legacy-id 부적절 — 필드 제거 |

## 개요

사용자(Operator/Admin) 단위 개인화 설정. `scope: user` 로 저장되며 로그인 세션 복원 시 자동 적용. Table/Event 스코프는 이 탭에 없음.

## 1. 단축키 (Shortcuts)

**저장 키**: `preferences.shortcuts`  
**타입**: `Map<String, String>` — `action_name → key_combo`  
**기본값**:

| action_name | 기본 key_combo | 설명 |
|-------------|---------------|------|
| `new_hand` | `Ctrl+N` | 새 핸드 시작 |
| `fold` | `F` | 현재 플레이어 폴드 |
| `check_call` | `Space` | 체크/콜 |
| `bet_raise` | `R` | 베팅/레이즈 프롬프트 |
| `all_in` | `Ctrl+A` | 올인 |
| `undo` | `Ctrl+Z` | 최근 액션 취소 (1단계만) |
| `reveal_holecards` | `H` | 홀카드 강제 공개 (RBAC=admin 전용) |
| `toggle_overlay` | `Ctrl+O` | 오버레이 미러 프리뷰 토글 |

**검증**:
- 모든 키 조합은 유니크 (중복 시 에러)
- 단일 문자 / Ctrl+X / Alt+X / Shift+X / 조합 허용
- 예약어 금지: `F1-F12` (시스템 단축키)

**저장 경로**: `settings_kv (scope='user', scope_id=user.id, tab='preferences', key='shortcuts', value=JSON)`

## 2. 알림 (Notifications)

**저장 키**: `preferences.notification`

```json
{
  "enabled": true,
  "soundEnabled": true,
  "eventTypes": {
    "handStart": false,
    "rfidError": true,
    "engineOffline": true,
    "syncConflict": true,
    "newHandFromOperator": false
  },
  "volume": 0.7
}
```

**검증**:
- `volume` 범위: 0.0 ~ 1.0
- `event_types` 는 audit_events.event_type 카탈로그 서브셋 (NOTIFY-CCR-039 해소 후 확정)

## 3. 기본 뷰 (Default View)

**저장 키**: `preferences.default_view`

| 필드 | 타입 | 기본값 | 설명 |
|------|------|:-----:|------|
| `table_view` | enum(grid, list) | `grid` | Lobby Tables 화면 |
| `players_view` | enum(cards, table) | `cards` | Players 탭 |
| `expanded_series` | boolean | `true` | Series 기본 확장 여부 |

## 4. 자동 로그아웃 (Auto-logout)

**저장 키**: `preferences.auto_logout`

```json
{
  "enabled": true,
  "idleMinutes": 60,
  "warnBeforeSeconds": 30
}
```

**RBAC**:
- `admin`: `idle_minutes` 범위 15~240
- `operator`: 30~120
- `viewer`: 60~240

## 5. RBAC 기반 UI 가시성 (Preferences)

**저장 키**: `preferences.ui_visibility`  
**자동 계산** — 수동 설정 아님. BS-01 Auth 의 사용자 role 에 따라 Lobby/CC 가 자동 결정.

| UI 요소 | admin | operator | viewer |
|---------|:---:|:---:|:---:|
| Admin Controls (Decks/Users/Series 관리) | ✓ | — | — |
| CC 액션 버튼 (fold/bet/...) | ✓ | ✓ (할당 테이블만) | — |
| Overlay 미러 프리뷰 | ✓ | ✓ | ✓ (read-only) |
| Reports / Statistics | ✓ | ✓ (제한) | ✓ (자기 관련) |
| Graphic Editor (GE) | ✓ | — | — |

**계산 시점**: 로그인 직후. role 변경 시 재로그인 요구.

## 6. 언어/로케일 (Locale Override)

**저장 키**: `preferences.locale`  
**타입**: enum(`auto`, `ko`, `en`, `es`) — `auto` 는 OS locale 사용  
**기본값**: `auto`

> `GFX.language` (Overlay 방송 그래픽 언어) 와 **별개**. Preferences.locale 은 Lobby/CC UI 언어만 결정.

## 7. 데이터 내보내기 기본값 (Export Defaults)

**저장 키**: *preferences.export_defaults* — backend env-driven default (정본: `../../2.2 Backend/Settings.md` §3.3, env **EXPORT_DEFAULTS**)

```json
{
  "format": "csv",  // csv | json | xlsx
  "includeHeaders": true,
  "timezoneMode": "local",  // local | utc
  "filenamePattern": "{type}_{date}_{user}"
}
```

> **2026-05-12 Cycle 4 (#264)**: 본 키의 권위 정본을 `../../2.2 Backend/Settings.md` 로 이전. 위 JSON 은 사용자 override UI 표현이고, default 는 backend **EXPORT_DEFAULTS** env var 가 결정한다.

B-051 (CSV/JSON 내보내기 Backlog) 과 연동.

## 8. API 계약 (PUT/GET)

```
GET  /api/v1/Users/{me}/Preferences
  → 200 {shortcuts, notification, default_view, auto_logout, locale, export_defaults, ui_visibility}

PUT  /api/v1/Users/{me}/Preferences
  body: partial 업데이트 허용
  → 200 (갱신된 전체 객체)
  → 400 validation 실패 시 필드별 error 반환
```

RBAC: 자기 preferences 만 GET/PUT. Admin 은 다른 사용자 preferences 조회 가능하나 수정 불가 (관리자는 권한 부여로 제어).

## 9. Storage 저장 방식

`settings_kv` 단일 테이블 (SG-003 마스터 결정):

```sql
INSERT INTO settings_kv (scope_level, scope_id, tab, key, value)
VALUES ('user', '{user.id}', 'preferences', 'shortcuts', '{"newHand":"Ctrl+N",...}');
```

## 10. 수락 기준

- [ ] Lobby 설정 다이얼로그에 Preferences 탭 존재
- [ ] 모든 필드 저장/복원 동작
- [ ] 단축키 중복 검증
- [ ] RBAC 기반 UI 가시성 즉시 반영 (role 변경 후 재로그인 강제)
- [ ] 로케일 변경 시 flutter_localizations 재로드 (app restart 없이)

## 관련 문서

- `docs/2. Development/2.5 Shared/BS_Overview.md` §2 RBAC
- `docs/4. Operations/Conductor_Backlog/SG-003-settings-6tabs-schema.md`
- `docs/2. Development/2.1 Frontend/Settings/Overview.md`

---

## 11. SG-008-b13 D3 추가 매핑 (2026-04-26 — IMPL-004)

`team1-frontend/lib/features/settings/screens/preferences_screen.dart` 에 이미 구현된 2개 키를 기획에 편입.

| 코드 키 | UI | 타입 | 기본값 | 비고 |
|---------|-----|------|--------|------|
| `diagnosticsEnabled` | Switch | Bool | `false` | 진단 로그 수집 + 익명 텔레메트리 활성. 운영 전 OFF 권장, 디버그 시 ON |
| `exportFolder` | TextFormField | String | `''` | 내보내기 (스킨/리포트) 기본 디렉토리. 빈 값 시 OS Documents 폴더 |

**스코프**: 두 키 모두 `user` 레벨 (개인 환경설정). RBAC: 자기 preferences 만 변경 가능.

**적용 시점**: 즉시 (재시작 불필요).

**보안**: `exportFolder` 가 절대 경로 입력 시 path traversal 방지 검증 필요 (TODO 후속).

**코드 참조**: `preferences_screen.dart` line 120-135.
