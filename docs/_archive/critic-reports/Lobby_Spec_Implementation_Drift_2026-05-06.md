---
title: Lobby 기획-구현 정합성 점검 — 3000 포트 운영 현실 vs 정본 명세
owner: conductor
tier: internal
status: REVIEW
last-updated: 2026-05-06
version: 1.0.0

provenance:
  triggered_by: user_directive
  trigger_summary: "현재 3000 포트 Lobby 가 기획 문서와 맞지 않다는 사용자 지적 — drift 진단 보고서"
  user_directive: |
    "프로토타입 도메인 확인해줘 지금 실행가능한지 검토하고 보고"
    → 후속: "현재 3000 포트에 구현된 lobby 는 기획 문서와 맞지도 않아 문제 확인하고 보고서 제출"
  trigger_date: 2026-05-06
  precedent_incident: |
    2026-04-22 Type C 사건 두 건 (lobby-web 좀비 오판 + Desktop 단일 문구 문자 해석)
    → 동일 Type C 패턴 재발 (정본 문구 vs 운영 현실 괴리)

predecessors:
  - path: ./Docker_Runtime.md
    relation: stale_input
    reason: "§1 정규 컨테이너 맵에 lobby-web REMOVED [SG-022] 표기 — 운영은 살아있음"
  - path: ../../2. Development/2.1 Frontend/Lobby/Overview.md
    relation: stale_input
    reason: "line 75, 79 — 'Flutter Desktop 통일' 잔존 (2026-04-21 14b01bfa, 2026-04-27 SG-022 폐기 cascade 누락)"
  - path: ../../../team1-frontend/CLAUDE.md
    relation: source_content
    reason: "정답 SSOT — '독립 Docker 컨테이너 (Lobby:3000 / CC:3001), SG-022 폐기' 명시 (2026-04-27)"

related-docs:
  - ./Docker_Runtime.md
  - ../../2. Development/2.1 Frontend/Lobby/Overview.md
  - ../../1. Product/Lobby.md
  - ../../../team1-frontend/CLAUDE.md
confluence-page-id: 3819078366
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078366/EBS+Lobby+-+3000+vs
mirror: none
---

# Lobby 기획-구현 정합성 점검

> **운영은 4일째 healthy 한데 두 SSOT 문서가 "REMOVED"·"Desktop" 으로 stale.**

## Edit History

| 날짜 | 버전 | 트리거 | 변경 내용 | 직전 산출물 처리 |
|------|:----:|--------|-----------|-----------------|
| 2026-05-06 | 1.0.0 | 사용자 directive | 최초 작성 — 3000 포트 운영 현실 vs 정본 명세 drift 진단 | 해당 없음 |

---

<a id="ch-anchor"></a>
<!-- FB §Anchor · P2 Pair · Reader Anchor -->

## 이 보고서가 데려가는 곳

<table role="presentation" width="100%">
<tr>
<td width="50%" valign="middle" align="left">

**입구 (지금 상태)**

3000 포트 Lobby 는 4일+ healthy 한 Flutter Web 앱(`ebs_lobby v0.1.0`). 그런데 두 정본 문서는 "REMOVED" / "Flutter Desktop 통일" 로 stale. 사용자가 "기획 문서와 맞지 않다" 라고 지적한 본질.

</td>
<td width="50%" valign="middle" align="left">

**출구 (이 보고서를 끝까지 읽은 후)**

drift 가 정확히 어느 줄/어느 표에 있는지, Type C(기획↔운영 괴리) 분류 근거, 이미 자율 처리한 범위, 남은 사용자 인텐트 결정 영역을 안다. 외부 인계 PRD 무결성 위협 수준도 안다.

</td>
</tr>
</table>

---

<a id="ch-1-evidence"></a>

## 1. Act 1 — 운영 현실 (Setup)

```
  +-----------------------------------------------------------+
  |  3000 포트 = Flutter Web (ebs-lobby-web 컨테이너)          |
  +-----------------------------------------------------------+
  |  컨테이너    : ebs-lobby-web                              |
  |  이미지      : ebs/lobby-web:latest                       |
  |  Status      : Up 2 days (healthy)                        |
  |  앱 메타     : {"app_name":"ebs_lobby","version":"0.1.0"} |
  |  Title       : ebs_lobby                                  |
  |  엔진        : Flutter Web (main.dart.js 1.4MB)           |
  |  최근 접속   : 2026-05-06 09:05:55 (Edge 브라우저)         |
  +-----------------------------------------------------------+
```

`team1-frontend/lib/` 구조:

```
  lib/
   ├─ main.dart           → runApp(EbsLobbyApp)
   ├─ app.dart            → MaterialApp.router
   ├─ features/
   │   ├─ auth/
   │   ├─ lobby/screens/  → dashboard, events, flights, players, tables
   │   ├─ settings/
   │   ├─ graphic_editor/
   │   ├─ staff/
   │   ├─ players/
   │   └─ reports/
   └─ foundation/
       ├─ router/         → app_router.dart
       └─ theme/          → ebs_lobby_theme.dart
```

**구현은 정상. 7 features × 3계층 네비게이션 = Overview.md §개요와 일치.**

문제는 **배포 형태/플랫폼 표기** 가 SSOT 간 모순.

---

<a id="ch-2-incident"></a>

## 2. Act 2 — 두 stale 문서 (Incident)

### 2-A. `Docker_Runtime.md` §1 — 좌표 line 22

| 표기 | 운영 현실 |
|------|-----------|
| `~~ebs-lobby-web-1~~` **[REMOVED 2026-04-27, SG-022]** — 외부 포트 / 소유 = `—` | `ebs-lobby-web` Up 2 days (healthy), 포트 3000, team1 소유 |
| "Conductor 가 컨테이너/이미지 destroy 완료 (2026-04-27)" | destroy 안 됨. 4일+ healthy |
| "단일 Flutter Desktop 바이너리 (SG-022)" | SG-022 = **폐기됨** (team1 CLAUDE.md, 2026-04-27 같은 날 역전) |

### 2-B. `Overview.md` (정본 1273줄) — 좌표 line 75, 79

| 좌표 | 표기 | 실제 |
|------|------|------|
| line 75 | "Lobby 도 **Flutter Desktop** 으로 통일" | Flutter **Web** (Docker nginx 서빙) |
| line 79 | Lobby 기술 = "Flutter **Desktop** 앱 (Dart + Riverpod + Freezed + go_router + Rive)" | Flutter **Web** 빌드 (`flutter build web`) |
| line 88 | "Lobby 는 1개 (**Web 브라우저 탭**, LAN 다중 관찰 가능)" | ✅ 일치 |
| line 102 | "Lobby 는 **브라우저 기반** 이므로 여러 Windows/Mac 에서 동시 접속 가능" | ✅ 일치 |

> **Overview.md 자체가 내부 모순**: line 75/79 는 "Desktop", line 88/102 는 "Web 브라우저". 같은 문서 안에서 충돌.

### 2-C. 정답 SSOT — `team1-frontend/CLAUDE.md` (2026-04-27)

```
  배포 형태 (2026-04-27 재정의 — SG-022 폐기, Multi-Service Docker 채택):
  - 정규 배포: docker compose --profile web up -d lobby-web
              → 브라우저 http://<lan-ip>:3000/
  - 개발자 디버깅: flutter run -d chrome (배포 아님)

  "Flutter 단일 스택"의 의미:
   프레임워크 하나(Flutter)로 모든 팀(team1/team4) 통일 — Vue/Quasar 폐기.
   2026-04-22 "Desktop only" 로 확대 해석된 오류는
   2026-04-27 SG-022 공식 폐기로 정정 완료.
```

---

<a id="ch-3-build"></a>

## 3. Act 3 — Type 분류 + 근본 원인 (Build)

```
                  +---------------------------------+
                  | Type 분류 (Spec_Gap_Triage)     |
                  +-----------+---------------------+
                              |
                  +-----------+-----------+
                  |                       |
                  v                       v
          +---------------+      +-----------------+
          | Type B 아님   |      | Type C 맞음     |
          | (기획 공백 X) |      | (기획↔운영 괴리)|
          +---------------+      +--------+--------+
                                          |
                                          v
                              +-----------+-----------+
                              | 근본 원인:            |
                              | SG-022 폐기 cascade   |
                              | 일부 누락             |
                              +-----------------------+
```

**Type C 근거**:
- 기획 공백 아님 (정답 SSOT 가 team1 CLAUDE.md 에 명시)
- 기획 모순도 아님 (이미 SG-022 폐기로 정합 결정 완료)
- **결정 cascade 누락** = 기획 ↔ 운영 사이 stale 표기 잔존

**2026-04-22 사건 두 건과 동일 패턴**:

| 시점 | 사건 | 패턴 |
|------|------|------|
| 2026-04-22 1차 | lobby-web 좀비 오판 (5일 옛 이미지 서빙) | 운영 정리 누락 |
| 2026-04-22 2차 | "Desktop only" 문구 문자 해석 → 파괴 | 기획 표기 ↔ 운영 요구 괴리 |
| **2026-05-06 (본건)** | **lobby-web "REMOVED" 표기 stale, Overview "Desktop 통일" 잔존** | **결정 cascade 누락** |

3회 연속 같은 패턴 = **circuit breaker 시그널** (룰 17). SG-022 처럼 큰 결정의 cascade 추적 도구 필요 (룰 20 doc-discovery 가 이를 위해 신설됨 — 본 사건은 도구 효력 검증).

---

<a id="ch-4-resolution"></a>

## 4. Act 4 — 자율 처리 + 잔여 (Resolution)

### 4-A. 자율 처리 완료 (본 보고서 작성과 동시)

| 항목 | 처리 |
|------|------|
| 좀비 컨테이너 `ebs-lobby-prototype` (port 18080, Exited 4d) | `docker rm` + `docker rmi` 완료 |
| `Docker_Runtime.md` §1 line 23 — CC-Web 포트 3100→3001 | Edit 완료 |

### 4-B. 자율 처리 가능 (SSOT 따라 stale 정정)

| 항목 | 좌표 | 정답 SSOT |
|------|------|----------|
| `Docker_Runtime.md` §1 — lobby-web 행 "REMOVED" 표기 | line 22 | team1 CLAUDE.md (Multi-Service Docker, 3000 포트, team1 소유) |
| `Overview.md` line 75 "Flutter Desktop 으로 통일" | line 75 | team1 CLAUDE.md ("Flutter 단일 스택 의미 = 프레임워크 통일") |
| `Overview.md` line 79 "Flutter Desktop 앱" | line 79 | 실제 = Flutter Web (배포 형태), Flutter Desktop (개발자 디버깅) |

> 자율 처리 진행 — SSOT 가 명확하므로 사용자 인텐트 영역 아님 (CLAUDE.md 의 "전문 영역 질문 = 시스템 실패 신호" 적용).

### 4-C. 사용자 인텐트 영역 (자율 결정 보류)

없음. SG-022 폐기 결정이 이미 2026-04-27 에 완료되어 있어 추가 인텐트 결정 불필요.

### 4-D. 외부 인계 PRD 무결성 영향

| PRD | 영향 |
|-----|------|
| `Lobby.md` v2.0.1 (external) | 기술 스택 추상화 ("관제탑" 메타포만), **직접 영향 없음** |
| `Command_Center.md` (external) | 무관 |
| `Back_Office.md` (external) | 무관 |

> 외부 인계 위협 수준 = **낮음**. 정본 기술 명세(internal) 내부 drift 만 있고 external tier 로 leak 안 됨.

---

## 5. 결론

```
  +-------------------------------------------------------+
  |  진단 결과                                             |
  +-------------------------------------------------------+
  |  실행 가능 여부 : ✅ 5개 도메인 모두 healthy           |
  |  Lobby 구현    : ✅ 7 features × 3계층 정상 동작      |
  |  Drift 분류    : Type C (기획↔운영 괴리)              |
  |  Drift 좌표    : 2 파일 × 3 좌표 (Docker_Runtime.md   |
  |                  line 22 / Overview.md line 75, 79)   |
  |  자율 처리     : 진행 중 (보고서 작성 직후)            |
  |  외부 PRD 위협 : 낮음 (external tier leak 없음)       |
  |  사용자 결정   : 불필요 (SSOT 가 이미 결정되어 있음)  |
  +-------------------------------------------------------+
```

다음 turn 에서 4-B 항목 자율 정정 + 결과 보고.
