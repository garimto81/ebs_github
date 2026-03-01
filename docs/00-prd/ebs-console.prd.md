---
doc_type: "prd"
doc_id: "EBS-CONSOLE-PRD"
version: "2.0.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-02-23"
last_updated: "2026-03-01"
phase: "phase-0"
priority: "critical"

depends_on:
  - "PRD-0003-EBS-Master"

related_docs:
  - "docs/01_PokerGFX_Analysis/ebs-console-feature-triage.md"
  - "docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md"
  - "docs/01_PokerGFX_Analysis/PokerGFX-Feature-Checklist.md"

stakeholders:
  - "방송팀"
  - "기술팀"
  - "운영팀"
---

# EBS console 기획서

> **BRACELET STUDIO** | EBS Project

---

## 1장: 제품 정의

### 1.1 제품명과 정의

> **EBS console** = 포커 방송 프로덕션 통제 소프트웨어

"console"은 오디오 믹싱 콘솔, 방송 제어 콘솔처럼 — 복잡한 시스템을 단일 인터페이스에서 통제하는 도구. PokerGFX Server가 그 역할을 했고, EBS console은 그것을 대체하는 자체 콘솔이다.

**기존 명칭과의 차이:**

| 기존 명칭 | 문제 | 새 명칭 |
|----------|------|--------|
| "Server" | PokerGFX 실행파일명 직역, 백엔드 서버와 혼동 | "console" |
| "UI Design" | 어떻게 그릴 것인가에 집중 | 기획서 (무엇을, 어떤 순서로) |
| "PRD-0004" | 종속 문서처럼 보임 | 독립 제품명 |

### 1.2 핵심 문제

**현재 설계의 3가지 문제:**

| 문제 | 현재 상태 | 새 접근 |
|------|----------|--------|
| 목표 모호 | "PokerGFX 100% 복제" (달성 기준 없음) | "v1.0에서 방송 가능하다" (검증 가능) |
| 배제 기준 없음 | Commentary만 배제, 나머지 전부 구현 | Keep/Drop/Defer로 149개 재분류 |
| 버전 없음 | P0/P1/P2만 있고 "언제 완성"이 없음 | v1.0/v2.0/v3.0 버전 범위 명확 정의 |
| 진실 공급원 분산 | PRD-0004 + 3개 부속 문서 파편화 | 본 문서가 단일 진실 공급원 |

### 1.3 달성 기준

각 버전의 성공은 다음 기준으로 판단한다:

| 버전 | 성공 기준 | 검증 방법 |
|------|----------|---------|
| **v1.0** | EBS console 단독으로 라이브 포커 방송 1회 성공 | 실제 방송 운영팀 검수 |
| **v2.0** | 통계/Equity 오버레이 ON 상태로 방송 가능 | 운영팀 + 방송팀 검수 |
| **v3.0** | RFID 자동 인식 + WSOP LIVE DB 연동 방송 | 전체 자동화 E2E 테스트 |

---

## 2장: 분석 자산 요약

### 2.1 PokerGFX 분석 완료 현황

Phase 0에서 수행한 PokerGFX 역설계 결과물. 이 분석이 EBS console 기획의 Input이다.

| 산출물 | 경로 | 내용 |
|-------|------|------|
| 기능 체크리스트 | `docs/01_PokerGFX_Analysis/PokerGFX-Feature-Checklist.md` | 149개 기능 |
| UI 화면 분석 | `docs/01_PokerGFX_Analysis/PokerGFX-UI-Analysis.md` | 11개 화면 구조 |
| Server UI 설계 | `docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` | v1.0 범위 화면별 UI 명세 |
| 역컴파일 아카이브 | `docs/01_PokerGFX_Analysis/07_Decompiled_Archive/` | C# 소스 (프로토콜 1차 소스) |
| OCR 분석 결과 | `docs/01_PokerGFX_Analysis/02_Annotated_ngd/` | 스크린샷별 텍스트/요소 추출 |

**분석 범위 (완료):**
- PokerGFX 3.111 스크린샷 11개 화면 분석
- 역컴파일 C# 소스 (ActionTracker, Server, Common, GFXUpdater)
- WebSocket 메시지 명세 (ActionTracker ↔ Server 프로토콜)
- 게임 상태 머신 (22개 게임 규칙)

### 2.2 문서 흐름

```
  PokerGFX 역설계 (ebs_reverse)
       │
       ├─ 149개 기능 → ebs-console-feature-triage.md (Keep/Drop/Defer)
       │                        │
       │                        ▼
       └─ UI 분석    → PRD-0004-EBS-Server-UI-Design.md (v1.0 UI 명세)
                                │
                                ▼
                    ebs-console.prd.md ◄── 본 문서 (단일 진실 공급원)
                                │
                                ▼
                    ebs-console-v1.plan.md (v1.0 개발 계획)
```

**레포 관계**: 분석은 `ebs_reverse`에서, 기획은 `ebs`에서. 두 레포는 별개이며 `ebs`는 참조만 한다.

---

## 3장: 기능 트리아지 요약

> 상세 결정 내역: [`ebs-console-feature-triage.md`](../01_PokerGFX_Analysis/ebs-console-feature-triage.md)

### 3.1 분류 기준

세 질문으로 149개 기능을 분류한다:

```
  Q1: 이 기능 없이 라이브 방송 가능한가?
       NO → v1.0 Keep (방송 필수)

  Q2: 다른 도구(OBS, 수동)로 대체 가능한가?
       NO → v1.0 Keep (대체 불가)

  Q3: WSOP LIVE DB 또는 RFID 인프라가 전제 조건인가?
       YES → v3.0 Defer (인프라 전제)

  나머지 → v2.0 Defer (방송 품질 향상)
  사용 안 함 → Drop (배제)
```

### 3.2 트리아지 결과

| 카테고리 | 전체 | v1.0 | v2.0 | v3.0 | Drop |
|----------|:----:|:----:|:----:|:----:|:----:|
| Action Tracker | 26 | 22 | 4 | 0 | 0 |
| Pre-Start Setup | 13 | 10 | 0 | 3 | 0 |
| Viewer Overlay | 14 | 10 | 4 | 0 | 0 |
| GFX Console | 25 | 3 | 18 | 2 | 3 |
| Security | 11 | 7 | 3 | 1 | 0 |
| Equity & Stats | 19 | 1 | 15 | 0 | 3 |
| Hand History | 11 | 1 | 8 | 0 | 2 |
| Server 관리 | 30 | 14 | 3 | 2 | 11 |
| **합계** | **149** | **68** | **55** | **8** | **19** |

### 3.3 Drop 목록 (19개 배제 확정)

| ID | 기능 | 카테고리 | 배제 사유 |
|----|------|---------|---------|
| SV-002 | Auto Camera Control | Server 관리 | overlay annotation Drop 확정 |
| SV-004 | Board Sync / Crossfade | Server 관리 | overlay annotation Drop 확정 |
| SV-007 | Secure Delay 설정 | Server 관리 | overlay annotation Drop 확정. 보안 모드 자체는 SEC에서 관리 |
| SV-009 | Virtual Camera | Server 관리 | overlay annotation Drop 확정 |
| SV-011 | Twitch 연동 | Server 관리 | OBS에서 처리, EBS 범위 외 |
| SV-017 | Action Clock | Server 관리 | overlay annotation Drop 확정 |
| SV-021 | Commentary Mode | Server 관리 | 기존 운영팀 미사용 확정 |
| SV-022 | PIP (Commentary) | Server 관리 | SV-021 전제, 자동 배제 |
| SV-025 | MultiGFX | Server 관리 | overlay annotation Drop 확정 |
| SV-026 | Stream Deck 연동 | Server 관리 | overlay annotation Drop 확정 |
| SV-030 | Split Recording | Server 관리 | 편집 워크플로우, 방송 운영 범위 외 |
| GC-019 | Print Report | GFX Console | 방송 운영과 무관한 오프라인 기능. CSV Export로 충분 |
| GC-022 | 시스템 상태 | GFX Console | CPU/메모리 모니터링. OS 내장 도구로 대체 가능 |
| GC-024 | 다크/라이트 테마 | GFX Console | UI 편의 기능. 단일 테마(다크)로 고정 |
| EQ-009 | 핸드 레인지 인식 | Equity & Stats | AI/ML 분석 전제. EBS 범위 외 |
| EQ-011 | Short Deck Equity | Equity & Stats | 특수 게임타입 전용, 개발 ROI 불충분 |
| ST-005 | 누적 3Bet% | Equity & Stats | 고급 통계 누적 집계. v2.0 통계 완성 시 재검토 |
| HH-004 | 팟 사이즈 필터 | Hand History | 분석용 고급 필터. 플레이어/태그 필터로 충분 |
| HH-011 | 핸드 공유 | Hand History | 외부 서비스 연동 필요. EBS 단독 실행 범위 외 |

---

## 4장: 버전 로드맵

### 4.1 버전 정의

| 버전 | 코드명 | 목표 | 목표 시기 |
|------|-------|------|---------|
| **v1.0** | Broadcast Ready | EBS console로 라이브 방송 가능 | Q4 2026 |
| **v2.0** | Operational Excellence | 통계/분석 활용, 방송 품질 고도화 | Q4 2027 |
| **v3.0** | EBS Native | PokerGFX에 없는 EBS 고유 기능 | Q4 2028 |

### 4.2 버전별 범위

#### v1.0 Broadcast Ready (68개 기능)

> **목표**: EBS console 단독으로 라이브 포커 방송 운영 가능

**핵심 범위:**
- Action Tracker 22개 — 실시간 게임 진행 추적, 액션/베팅 입력
- Pre-Start Setup 10개 — 이벤트 설정, 플레이어/스택 입력
- Viewer Overlay 10개 — 홀카드, 칩카운트, 팟, 액션 OBS 오버레이
- Security 7개 — Realtime/Trustless Mode 토글, WebSocket TLS
- GFX Console 3개 — 플레이어 수, 남은 수, 평균 스택 기본 현황
- Server 관리 14개 — 해상도, 크로마키, 딜레이 출력, 레이아웃, 전환 애니메이션, 스폰서 로고, 9x16 세로 출력
- Equity & Stats 1개 — 핸드 수 카운터
- Hand History 1개 — 현재 세션 핸드 상세 뷰

**v1.0 제약사항:**
- RFID 미연결 시 수동 카드 입력 폴백으로 운영
- 통계/Equity 오버레이 없음 (수동 OBS 자막으로 대체)
- 기본 스킨 고정 (커스터마이징 없음)
- 단일 테이블만 지원

#### v2.0 Operational Excellence (55개 기능)

> **목표**: 통계/분석 활용, 방송 품질 고도화

**추가 범위:**
- GFX Console 완성 — VPIP/PFR/AGR 통계, 리더보드, 티커 메시지
- Equity & Stats — EQ-001~012 (승률 계산 엔진), 세션 통계
- Hand History 완성 — 핸드 목록, 필터, 리플레이, 내보내기
- Skin Editor + Graphic Editor — 커스텀 방송 그래픽
- 방송 연출 — 리더보드 옵션, PIP, Stats, 플레이어 사진 고급
- 보안 강화 — AES-128, DB 암호화
- 고급 출력 — ATEM 연동

#### v3.0 EBS Native (8개 + 신규)

> **목표**: PokerGFX에 없는 EBS 고유 기능, RFID/DB 완전 통합

**추가 범위:**
- RFID 완전 통합 — Register Deck (SV-023), Calibrate (SV-024), AUTO 모드 (PS-013)
- RFID 기반 보드 감지 — PS-007, PS-011, PS-013 완성
- WSOP LIVE DB 연동 — 플레이어 DB, 히스토리 API (EBS 고유, 6장 참조)
- 자동화 프로토콜 — 카드 인식 → 그래픽 전단계 자동화

### 4.3 성공 기준

| 버전 | 성공 기준 | 검증 주체 |
|------|----------|---------|
| v1.0 | 라이브 방송 1회 성공 (운영자 2명 이상 참여) | 운영팀 |
| v2.0 | 통계/Equity ON 상태 방송 + 운영팀 "전환 가치 있음" | 운영팀 + 방송팀 |
| v3.0 | RFID 자동 인식 오류율 < 1% + WSOP LIVE DB 연동 E2E | QA팀 |

---

## 5장: v1.0 개발 우선순위

> 상세 개발 계획: [`ebs-console-v1.plan.md`](../01-plan/ebs-console-v1.plan.md)

### 5.1 의존성 기반 개발 순서

v1.0 68개 기능을 의존성 순서로 6개 레이어로 분류한다.

```
  Layer 1: 인프라 (방송 시작 전 필수)
  ├─ WebSocket 서버 기반 (SEC-009)
  ├─ Video Output 파이프라인 (SV-006, SV-008)
  └─ DB 기본 스키마 (카드, 핸드, 플레이어)

  Layer 2: 게임 설정 (방송 전 설정 화면)
  ├─ Pre-Start Setup 전체 (PS-001~006, PS-008, PS-010, PS-012)
  └─ 게임 타입/블라인드 구조 (AT-005, AT-006)

  Layer 3: 액션 추적 (방송 핵심)
  ├─ 좌석 레이아웃 + 상태 (AT-008~011)
  ├─ 액션 버튼 (AT-012, AT-013, AT-021, AT-023)
  └─ 베팅 입력 (AT-015, AT-016, AT-017, AT-018)

  Layer 4: 오버레이 출력 (시청자용)
  ├─ 보드 카드 (AT-019, AT-020, VO-009)
  ├─ 플레이어 정보 (VO-002~003, VO-005~007, VO-012~014)
  └─ GFX 설정 (SV-005, SV-010, SV-012, SV-013, SV-019, SV-020)

  Layer 5: 보안 + 딜레이
  ├─ Trustless Mode (SEC-001, SEC-002, SEC-003, SEC-010)
  ├─ Realtime Mode (SEC-004, SEC-005)
  └─ Secure Delay (SV-006 연동)

  Layer 6: 마무리 + 모니터링
  ├─ 상태 표시 (AT-001~004)
  ├─ 기본 현황 (GC-013~015, ST-007)
  ├─ 키보드 단축키 (AT-014)
  └─ 이벤트 정보 (VO-001, VO-010, VO-011)
```

### 5.2 레이어별 의존성 규칙

| 레이어 | 의존 레이어 | 개발 순서 |
|-------|-----------|---------|
| Layer 1 인프라 | 없음 | 1순위 (병렬 가능) |
| Layer 2 게임 설정 | Layer 1 | 2순위 |
| Layer 3 액션 추적 | Layer 1, 2 | 3순위 |
| Layer 4 오버레이 | Layer 1, 2, 3 | 4순위 (일부 병렬) |
| Layer 5 보안 | Layer 1, 4 | 5순위 |
| Layer 6 마무리 | Layer 1~5 | 6순위 (일부 병렬) |

**병렬 개발 가능 조합:**
- Layer 2 (설정 UI) + Layer 1 인프라 서버 코드 → 동시 개발 가능
- Layer 4 오버레이 UI + Layer 3 액션 엔진 → 동시 개발 가능
- Layer 6 모니터링 컴포넌트 → 어느 단계에서도 독립 개발 가능

---

## 6장: EBS 고유 기능

PokerGFX에 없는 EBS 고유 기능. v3.0에서 구현하거나, 필요 시 별도 로드맵을 수립한다.

### 6.1 WSOP LIVE DB 연동

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| 플레이어 DB 자동 로드 | WSOP LIVE DB에서 플레이어 이름/국적/사진 자동 가져오기 | v3.0 |
| 핸드 히스토리 자동 업로드 | 세션 종료 시 WSOP LIVE DB에 자동 동기화 | v3.0 |
| 실시간 순위표 연동 | WSOP LIVE의 Day/Level별 순위 실시간 반영 | v3.0 |
| API 인증 관리 | WSOP LIVE API 토큰 관리, 자동 갱신 | v3.0 |

### 6.2 RFID 자동화 (PokerGFX 대비 고도화)

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| 멀티 RFID 리더 지원 | 10개 좌석 × 2 홀카드 = 20개 동시 인식 | v3.0 |
| RFID 이상 감지 | 비정상 카드 UID, 중복 감지 자동 알림 | v3.0 |
| 덱 자동 재등록 | 새 카드 덱 교체 시 자동 UID 재매핑 | v3.0 |
| 감지율 대시보드 | 각 좌석별 RFID 인식 성공률 실시간 모니터링 | v3.0 |

### 6.3 운영 자동화 (EBS 고유 효율화)

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| Morning Automation 연동 | 방송 전일 브리핑 자동 생성 (현재 운영 중) | 기존 운영 중 |
| 하이라이트 핸드 자동 태깅 | 고팟 or 올인 상황 자동 TAG HAND | v3.0 |
| 방송 세션 자동 보고서 | 세션 종료 시 요약 통계 Slack 자동 전송 | v3.0 |
| 운영 인원 감소 자동화 | 30명 → 15~20명 목표 (EBS Master PRD 핵심 목표) | v3.0 |

### 6.4 로드맵 배치

```
  v1.0                v2.0                v3.0
  ──────              ──────              ──────
  PokerGFX            PokerGFX            EBS 고유
  기능 핵심           기능 완성           기능 추가

  68개 기능           55개 기능           8개+신규

  방송 가능           방송 고품질         자동화 완성
```

EBS 고유 기능은 v3.0에서 집중 구현한다. v1.0/v2.0은 PokerGFX 벤치마크를 따라가되, v3.0부터 차별화한다.

---

## Appendix A: v1.0 스코프 최종 확정 (2026-02-23)

> 2026-02-23 트리아지 v1.1.0 기준 확정. 상세: `ebs-console-feature-triage.md`

### A.1 v1.0 개발 대상 (68개)

| 카테고리 | v1.0 개수 |
|----------|:---------:|
| Action Tracker | 22 |
| Pre-Start Setup | 10 |
| Viewer Overlay | 10 |
| GFX Console | 3 |
| Security | 7 |
| Equity & Stats | 1 |
| Hand History | 1 |
| Server 관리 | 14 |
| **합계** | **68** |

### A.2 Drop 확정 (19개)

완전 배제 확정. 재검토 없이 EBS console 범위 외로 처리.

| ID | 기능 | 카테고리 | 배제 사유 |
|----|------|---------|---------|
| SV-002 | Auto Camera Control | Server 관리 | overlay annotation Drop 확정 |
| SV-004 | Board Sync / Crossfade | Server 관리 | overlay annotation Drop 확정 |
| SV-007 | Secure Delay 설정 | Server 관리 | overlay annotation Drop 확정. 보안 모드 자체는 SEC에서 관리 |
| SV-009 | Virtual Camera | Server 관리 | overlay annotation Drop 확정 |
| SV-011 | Twitch 연동 | Server 관리 | OBS 처리, EBS 범위 외 |
| SV-017 | Action Clock | Server 관리 | overlay annotation Drop 확정 |
| SV-021 | Commentary Mode | Server 관리 | 기존 운영팀 미사용 확정 |
| SV-022 | PIP (Commentary) | Server 관리 | SV-021 전제, 자동 배제 |
| SV-025 | MultiGFX | Server 관리 | overlay annotation Drop 확정 |
| SV-026 | Stream Deck 연동 | Server 관리 | overlay annotation Drop 확정 |
| SV-030 | Split Recording | Server 관리 | 편집 워크플로우, 방송 운영 범위 외 |
| GC-019 | Print Report | GFX Console | 방송 운영과 무관, CSV Export로 충분 |
| GC-022 | 시스템 상태 | GFX Console | OS 내장 도구로 대체 가능 |
| GC-024 | 다크/라이트 테마 | GFX Console | 단일 테마(다크) 고정 |
| EQ-009 | 핸드 레인지 인식 | Equity & Stats | AI/ML 분석 전제, EBS 범위 외 |
| EQ-011 | Short Deck Equity | Equity & Stats | 특수 타입, 개발 ROI 불충분 |
| ST-005 | 누적 3Bet% | Equity & Stats | 고급 통계, v2.0 재검토 |
| HH-004 | 팟 사이즈 필터 | Hand History | 분석용, 기본 필터로 충분 |
| HH-011 | 핸드 공유 | Hand History | 외부 서비스 연동 필요 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-23 | 최초 작성 |
| 1.1.0 | 2026-02-23 | 트리아지 v1.1.0 동기화: v1.0=66개, Drop=12개, Appendix A(스코프 요약) 추가 |
| 1.2.0 | 2026-02-27 | PRD-0004 v22.0.0 5탭 구조 반영 (6탭→5탭), N/A 6개 재분류 동기화 |
| 1.3.0 | 2026-02-27 | Drop 12→13 수정 (GC-019 누락), Appendix A 중복 제거, SV-014/015/016 v1.0 복원 동기화 (v1.0: 66→69, v2.0: 62→59) |
| 2.0.0 | 2026-03-01 | overlay annotation 기반 전면 재검토: Drop 13→19 확대, SV-010 Keep 복원, v1.0 69→68, v2.0 59→55, v3.0 9→8 |

---
**Version**: 2.0.0 | **Updated**: 2026-03-01
