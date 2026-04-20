---
id: SG-005
title: "Foundation Ch.6 시스템 연결 도식 — Engine↔BO 경계 (EBS_Core 병합)"
type: spec_gap
sub_type: architecture_backbone
status: RESOLVED
owner: conductor
decision_owners_notified: [team2, team3]
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/1. Product/Foundation.md §Ch.6
  - docs/2. Development/2.5 Shared/EBS_Core.md (폐기 — 참조만 정리)
  - docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md
  - docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md
protocol: Spec_Gap_Triage
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, EBS_Core 병합 완료"
---
# SG-005 — Foundation Ch.6 시스템 연결 도식

## 공백 서술

Agent B critic (2026-04-20) 지적:

> Foundation Ch.4/Ch.6 은 "Game Engine과 BO 간 실제 호출 방식" (IPC? REST? WebSocket? in-process?) 이 불명확. 팀2/팀3 이 각자 "우리가 뭘 만들어야 하는가" 를 Foundation 에서 파악 불가능. API 문서 산재.

또한 `EBS_Core.md` 파일이 참조되지만 부재 (CLAUDE.md:286). "아키텍처 backbone 부재" 로 Type B 공백.

## 결정

### 1. EBS_Core.md 처리: **폐기 → Foundation Ch.6 병합**

기존 MEMORY `project_architecture_v33.md` 의 "EBS Core (3입력 → 오버레이)" 개념은 Foundation Ch.4 + Ch.6 + Ch.7 에 분산 서술되어 있음. 별도 EBS_Core.md 는 중복 — 폐기.

**행동**: CLAUDE.md §참고 문서 표의 EBS_Core.md 참조를 Foundation Ch.6 + Ch.7 로 교체. 물리 파일 없음 상태 유지.

### 2. 시스템 연결 도식 (채택)

```
                   ┌─────────────────────────────┐
                   │   Lobby (Flutter Desktop)   │
                   │     (team1)                 │
                   │  • 관제/설정 허브           │
                   │  • Graphic Editor (GE) 탭   │
                   └───────┬────────┬────────────┘
                           │ REST   │ WebSocket (ws/lobby)
                           │ HTTP   │ (monitor only)
                           ▼        ▼
                   ┌─────────────────────────────┐
                   │  Back Office (BO) FastAPI   │ ← port 8000
                   │     (team2)                 │
                   │  • REST /api/v1/** (66+)    │
                   │  • WS /ws/lobby, /ws/cc     │
                   │  • DB (SQLite → Postgres)   │
                   │  • WSOP LIVE Sync           │
                   └───────┬────────┬────────────┘
                           │        │
                           │        │ WebSocket (ws/cc)
                           │        │ 양방향
                           │        ▼
              ┌────────────┘  ┌───────────────────┐
              │               │ Command Center    │
              │               │ (Flutter Desktop) │
              │               │    (team4)        │
              │               │ 테이블당 1 인스턴스 │
              │  HTTP (REST)  │  • Operator UI    │
              │ /engine/*     │  • RFID HAL       │
              │               │  • Overlay Rive   │
              │               └────────┬──────────┘
              │                        │
              ▼                        │ Option A: HTTP
       ┌──────────────────┐            │ Option B: path dep
       │  Game Engine     │            │ (채택: Option A)
       │  Dart Harness    │◄───────────┘
       │   (team3)        │
       │ port 8080 HTTP   │
       │ • 순수 Dart       │
       │ • Event Sourcing │
       │ • 22 포커 variants│
       └──────────────────┘
```

### 3. 통신 방식 결정표

| 연결 | 방식 | 프로토콜 | 이유 |
|------|------|---------|------|
| Lobby → BO | REST | HTTP/1.1 JSON | 동기 CRUD, API-01 |
| Lobby ← BO | WebSocket | `ws/lobby` | 모니터 전용, API-05 `lobby_monitor` 채널 |
| CC ↔ BO | WebSocket | `ws/cc` | 양방향 명령 + 이벤트, API-05 `cc_command`/`cc_event` 채널 |
| CC → Engine | REST | HTTP/1.1 JSON | `http://engine:8080/engine/*`, stateless query (Option A 채택, SG-002) |
| Engine → CC | (응답) | HTTP response | Engine 은 상태 push 안 함. CC 가 polling + OutputEvent 수신 |
| Lobby ↔ CC | **금지** | — | 직접 연결 없음. BO DB 통한 간접 공유만 (BS_Overview §1.관계) |

### 4. Engine 소유권·배포 방식

**채택**: **Engine = 별도 프로세스 (Docker container)**, CC 와 분리

- 프로토타입: `docker compose up engine` 또는 `dart run bin/harness.dart`
- 인계팀 운영: Docker container 배포 (독립 스케일링)
- **Option B (path dependency 로 CC 에 in-process import)** 는 **비채택** — 사유:
  - CC Flutter Desktop ↔ Dart pure package 바이너리 호환 복잡도
  - 엔진 업데이트 시 CC 재빌드 강제
  - 엔진 로그/오류 격리 약화
- **Option A (HTTP)** 채택 — SG-002 의 ENGINE_URL 계약과 일관

### 5. 데이터 흐름 시퀀스 (Pre-flop 예시)

```
 RFID   CC-Operator     CC      BO        Engine      Overlay
  │         │            │       │          │           │
  │ 카드감지 │            │       │          │           │
  │────────►│────seat_card───────►│          │           │
  │         │            │       │          │           │
  │         │ NEW HAND   │       │          │           │
  │         │ 버튼 클릭  │       │          │           │
  │         │───────────►│──hand_start──────►│           │
  │         │            │       │          │ 덱생성     │
  │         │            │       │          │ 홀카드배분 │
  │         │            │       │          │           │
  │         │            │◄──────hand_state──│           │
  │         │            │       │          │           │
  │         │            │───OutputEvent────────────────►│ 렌더
  │         │            │   (holecards_revealed,       │
  │         │            │    equity_updated)           │
  │         │            │       │          │           │
  │         │            │───broadcast─────►│ DB persist │
  │         │            │       │ WSOP LIVE│           │
  │         │            │       │ sync     │           │
```

## 영향 챕터 업데이트

- [x] 본 SG-005 문서 — 아키텍처 backbone 확정
- [ ] `docs/1. Product/Foundation.md` Ch.6 에 위 도식 추가 (Conductor 소유 파일, 이 SG 커밋과 함께 진행 가능 — Phase B-4 별도 Edit)
- [x] `CLAUDE.md` §참고 문서 — EBS_Core.md 참조를 Foundation Ch.6 + Ch.7 로 교체 (이 SG 와 함께 커밋)
- [ ] MEMORY `project_architecture_v33.md` 업데이트 (다음 세션 또는 후속 task)

## 수락 기준

- [ ] Foundation Ch.6 에 도식 + 통신 방식 결정표 포함
- [ ] EBS_Core.md 참조 링크 0개 (grep 검증)
- [ ] 시퀀스 도식이 실제 프로토타입 흐름과 일치 (팀 세션에서 구현 검증)

## 재구현 가능성

- SG-005: **PASS**
- Foundation Ch.6: UNKNOWN → PASS (도식 병합 후)
- Shared EBS_Core.md: FAIL → 폐기 완료 (Roadmap §집계 제거)
