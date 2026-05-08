---
title: Foundation Impact Review (2026-04-22 재설계)
owner: team4
tier: internal
last-updated: 2026-04-22
related-commits: 7aa1576, 30d009c, a756f6c, 32c0015, 133e5f5, 027d15a
confluence-page-id: 3819242053
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819242053/EBS+Foundation+Impact+Review+2026-04-22
---

# Foundation Impact Review — team4 기획 문서 전면 재검토

> 2026-04-22 Foundation.md 재설계 (F1 재작성 + Ch.4 2 렌즈 + §5.0 2 런타임 모드 + §6.3 프로세스 경계 + §6.4 실시간 동기화 + §7.1 배경 config flag + §8.5 복수 테이블 아키텍처) 에 따른 team4 소유 기획 문서 전면 재검토 및 수정 계획.

## 1. Foundation 재설계 핵심 변경 (Source Delta)

| ID | 영역 | 변경 요지 | team4 영향 채널 |
|----|------|----------|----------------|
| **D1** | §8.5 신설 | **1 PC = 1 피처 테이블** 고정. N PC + 중앙 서버(BO+DB) 필수. 멀티 EBS 폐기 | CC Multi-Table / Overview |
| **D2** | §5.0 신설 | **2 런타임 모드** — 탭/슬라이딩(단일 프로세스, 기본) · 다중창(독립 OS 프로세스, PC 옵션). 단일 Flutter 바이너리 | Overlay 전체 / CC Overview / Sequences |
| **D4** | §7.1 | **Overlay 배경 config flag** — (a) 완전 투명 (송출 기본) / (b) 단색 (디자이너 Rive Editor · QA 스크린샷) | Overlay Overview / Skin_Loading |
| **D5** | §6.3 · §6.4 신설 | **프로세스 경계** + **DB SSOT + WebSocket push**. 앱 간 직접 IPC 금지. Engine 응답 = 게임 상태 SSOT, BO WS = audit 참고값. SG-002 해소 | Engine_Dependency / CC Overview / Sequences |
| **Ch.4** | 전면 재작성 | **2 렌즈** (기능 6 ↔ 설치 4). team1+team4 = 동일 Flutter 바이너리 `EBS Desktop App` 공동 소유 | Overlay Layer_Boundary / Overview (참조·경계 서술) |
| **§6.3 §1.1.1** | 재작성 | CC = Orchestrator, BO/Engine 병행 dispatch, A(액션)/B(RFID) 시퀀스 | CC Overview §1.1.1 (이미 반영 ✅) |

## 2. 영향도 등급 정의

| 등급 | 의미 | 조치 |
|:---:|------|------|
| **CRITICAL** | Foundation 과 직접 모순 (Type C). 배포 시 오독 유발 | 즉시 재작성 PR |
| **HIGH** | 핵심 개념·다이어그램이 구식 가정 (단일 프로세스 전제 등) | 2 모드 분기 반영 재작성 |
| **MEDIUM** | 참조 경로·부분 서술 수정 | 섹션 삽입 또는 주석 추가 |
| **LOW** | 참조 갱신, 링크 문구 조정 | 간단 Edit |
| **N/A** | DEPRECATED, CI 생성, 또는 Foundation 변경 범위 밖 | 수정 불필요 |

## 3. 문서별 영향도 매트릭스

### 3.1 CRITICAL (Type C — Foundation 직접 모순)

| # | 문서 | 현재 서술 | Foundation 재설계 | 수정 방향 |
|:-:|------|----------|------------------|----------|
| C1 | `Command_Center_UI/Multi_Table_Operations.md` §1.2 Pattern B | "1명 = 2~4 테이블 관리, **같은 머신 또는 인접 머신**에서 Alt+Tab 전환" | §8.5 "1 PC = 1 피처 테이블 고정, 방송 중 PC 간 이동 불가, 멀티 EBS 폐기" | **Pattern B 재정의** — "같은 머신 다중 CC 창" 시나리오 제거. "N PC 순회 (각 PC 단일 테이블)" 모델로 치환. 피처/비피처 테이블 구분 명시 |
| C2 | `Overlay/Sequences.md` §1.1 프로세스 모델 다이어그램 | "단일 Flutter 앱 (in-process)" 박스 안에 CC+RFID+Engine+Overlay 전부 배치 | §5.0 2 모드 분기 · §6.3 Engine 별도 프로세스 · §6.4 다중창 모드 = 앱 간 BO 경유 | 다이어그램 2개로 분리: (a) 탭 모드 (단일 프로세스), (b) 다중창 모드 (Lobby/CC/Overlay 독립 프로세스 + 공용 BO+DB). Engine 은 어느 모드에서도 별도 서비스 |

### 3.2 HIGH (핵심 개념 업데이트)

| # | 문서 | 현재 서술 | Foundation 재설계 | 수정 방향 |
|:-:|------|----------|------------------|----------|
| H1 | `Overlay/Overview.md` §1 앱 정의 | "Overlay 는 CC 와 **동일한 Flutter 앱 내에서 in-process 로 실행** (API-04 §1.2 SSOT)" | §5.0 2 모드 분기. 탭 모드 = in-process / 다중창 모드 = 독립 OS 프로세스 | §1 표에 "런타임 모드" 행 추가. 본문에 "탭 모드에서는 in-process, 다중창 모드에서는 독립 OS 프로세스 (§6.3 참조)" 설명. `실행 환경` 필드 "CC와 동일 머신 또는 별도 머신 (NDI)" 은 Foundation §8.5 "동일 PC 내" 로 단순화 |
| H2 | `Overlay/Overview.md` §2 데이터 흐름 | "Game Engine → Overlay 직접" ASCII 다이어그램 | §6.3 §1.1.1 CC = Orchestrator. Engine → CC → Overlay. 또는 DB/WS 경유 (다중창) | 다이어그램 재작성: 2 경로. (A) 탭 모드 in-process Dart Stream. (B) 다중창 모드 WS push (Engine→CC→BO→Overlay) |
| H3 | `Overlay/Overview.md` §5 출력 채널 | "크로마키 색상: Green/Blue/Black/Custom. 크로마키 모드만 언급" | §7.1 **배경 config flag (완전 투명 / 단색)**. 투명 = 송출 기본, 단색 = 디자이너 Rive Editor · QA 스크린샷 | §5 에 `배경 config flag` 행 신설. 투명/단색 2 모드 명시. 크로마키 색상은 단색 모드의 하위 옵션으로 재배치. 용도 차이 (송출 vs 디자인 QA) 설명 |
| H4 | `Overlay/Overview.md` 편집 이력 `2026-04-14 프로세스 모델 정합` | "§1 '별도 프로세스' → '동일 Flutter 앱 in-process' 수정 (API-04 §1.2 SSOT 정렬)" | 2026-04-22 Foundation §5.0 2 런타임 모드 도입 (기존 in-process 고정 서술 무효화) | 편집 이력에 **2026-04-22 행 추가** — "Foundation §5.0 2 런타임 모드 반영, in-process 고정 서술 → 모드 분기 재작성". `last-updated: 2026-04-22` |
| H5 | `Overlay/Sequences.md` §1.2 지연 예산 | "Game Engine → Backstage Stream: Stream.add < 1ms" | 다중창 모드에서는 Engine 응답 → CC → BO WS → Overlay 까지 **HTTP + WS 지연** 포함 필요 | §1.2 표에 "모드" 컬럼 추가. 탭 모드 (Dart Stream < 1ms) / 다중창 모드 (HTTP + WS push < 100ms) 2 행 분리. 총 예산 재산정 |
| H6 | `Overlay/Sequences.md` §1.1 "**핵심 규칙**: CC와 Overlay는 **같은 Flutter 프로세스**에서 실행 (API-04 §1.2). 네트워크 통신 없음" | 위 단일 모드 고정 서술 | §5.0 2 모드 | 규칙을 "탭 모드 — 같은 프로세스, Dart Stream / 다중창 모드 — 독립 프로세스, WS push 경유" 로 분리 서술 |

### 3.3 MEDIUM (보완·참조 추가)

| # | 문서 | 조치 |
|:-:|------|------|
| M1 | `Command_Center_UI/Overview.md` §1 `CC = Table = Overlay (1:1:1)` | 표 하단에 "§8.5 복수 테이블 운영은 N PC 구조 — `Foundation.md §8.5` 참조" 추가 |
| M2 | `Command_Center_UI/Overview.md` §7.1 Launch 시퀀스 "[CC 신규 프로세스]" | 주석 추가: "다중창 모드에서는 신규 OS 프로세스. 탭 모드에서는 동일 프로세스 내 라우팅 (`Foundation.md §5.0` 참조)" |
| M3 | `Command_Center_UI/Overview.md` §7.2 "CC 프로세스 실행 실패" | 탭 모드에서는 "뷰 전환 실패" 로 해석. 2 모드 분기 각주 추가 |
| M4 | `Overlay/Layer_Boundary.md` §원칙 인용 | "Foundation Ch.4" 인용 문구를 Foundation Ch.2/Ch.9 (EBS vs 포스트프로덕션 시간축) 로 재조정. Ch.4 는 이제 "2 렌즈" 설명으로 재작성됨 |
| M5 | `Overlay/Layer_Boundary.md` §3.2 "team3 ↔ team4 내부 계약 (API-04) · **in-process 계약**" | "**API-04 는 논리적 계약 (sealed class). 런타임 전송 경로는 §5.0 2 모드 — 탭: in-process / 다중창: BO WS broadcast**" 로 보강. Engine 이 별도 서비스임을 명확히 |
| M6 | `Overlay/Engine_Dependency_Contract.md` §7 참조 | "Foundation Ch.7 (시스템 연결)" → "Foundation §6.3 (프로세스 경계) / §6.4 (실시간 동기화, SG-002 해소)" 로 참조 경로 업데이트 |
| M7 | `Settings.md` 개요 | Foundation §5.2 는 "모든 테이블에 일괄 적용" (global-only) 로 서술. 본 문서는 4단 스코프 명세 — **Foundation 요약과 실제 명세의 해석 차이**에 대한 주석 추가. notify: conductor (Foundation §5.2 정합성 확인 요청) |
| M8 | `APIs/RFID_HAL_Interface.md` | 문서 내 "런타임 모드" 언급 확인 — 있다면 §5.0 정렬, 없다면 추가 불요. (grep 결과 1 hit — 별도 확인 필요) |

### 3.4 LOW (참조 갱신 only)

| # | 문서 | 조치 |
|:-:|------|------|
| L1 | `Overlay/Overview.md` §3 "Foundation Ch.4 Layer 1 참조" | Foundation Ch.4 재작성으로 Layer 1/2/3 개념은 §4 에 이동. 참조 섹션 `Ch.4 §4.1~§4.3` 으로 업데이트 |
| L2 | `Command_Center_UI/Overview.md` 편집 이력 | 2026-04-22 회의 결정 반영 항목이 이미 있음. Foundation §6.3 재작성 cross-reference 한 줄 추가 |
| L3 | `Overlay/Skin_Loading.md` | 배경 config flag 관련 언급 검증 (grep 미발견, 변경 없을 가능성 높음) |
| L4 | `Overlay/Security_Delay.md` | 2 모드 분기 하에 Security Delay 위치 재확인. 특히 다중창 모드에서 버퍼가 어디에 있는지 (CC 프로세스 or Overlay 프로세스) |

### 3.5 N/A (수정 불필요)

| # | 문서 | 사유 |
|:-:|------|------|
| X1 | `Command_Center_UI/Demo_Test_Mode.md` | 2026-04-21 DEPRECATED. 역사 참조용 |
| X2 | `2.4 Command Center.md` | CI 자동 생성 (`owner: ci`, `tier: generated`) |
| X3 | `APIs/RFID_HAL.md` | Foundation §7.2 RFID 정의 변경 없음 |
| X4 | `RFID_Cards/**` (5 파일) | Foundation §7.2 유지 — Mock HAL 포함 문구도 그대로 |
| X5 | `Backlog/_archived-2026-04/**` | 아카이브 |
| X6 | `Integration_Test_Plan/automation/s11/**` (코드/스크립트) | 테스트 자동화 asset — 기획 문서 아님 |

## 4. 수정 우선순위 & 공수 예측

| 우선순위 | 묶음 | 문서 수 | 예상 공수 | 근거 |
|:-------:|------|:-------:|:--------:|------|
| **P0** | C1 · C2 (CRITICAL) | 2 | 2~3h | Type C 기획 모순 해소 — 운영·개발팀 오독 직결. Multi_Table Pattern B 재정의 + Sequences 다이어그램 2 모드 분리 |
| **P1** | H1~H6 (HIGH) | 2 (Overview + Sequences) | 3~4h | 2 런타임 모드 분기 반영 + 배경 config flag 표 삽입. Overlay Overview 는 §1, §2, §5, 편집 이력 4 섹션 동시 수정 |
| **P2** | M1~M8 (MEDIUM) | 7 | 2h | §8.5/§5.0/§6.3/§6.4 참조 한 줄씩 추가 + Settings.md conductor notify |
| **P3** | L1~L4 (LOW) | 4 | 30m | 참조 문구 단순 수정 |

**총 예상 공수**: ~8h (1 working day).

## 5. Decision Owner / Notify 매핑

Foundation §5.0/§6.3/§6.4/§8.5 는 **Conductor 소유** (publisher: conductor). team4 는 소비자로서 본 문서들만 수정. Notify 필요 항목:

| Notify 대상 | 항목 | 사유 |
|------------|------|------|
| **conductor** | M7 (Settings.md 스코프 정합성) | Foundation §5.2 "일괄 적용" 표현이 Settings.md 4단 스코프와 해석 차이 존재 — Foundation 보강 여부 판단 필요 |
| **team1** | D2 (2 런타임 모드) | team1 Lobby 도 `EBS Desktop App` 공동 소유 (Ch.4 §4.4). Lobby Settings 에서 런타임 모드 선택 UI 구현 주체. team4 는 CC/Overlay 측 구현만 |
| **team2** | D5 (§6.4 WebSocket push 실시간 동기화 policy) | "DB polling endpoint 실제 스키마 · WS push payload 상세는 team2 Wave 2 에서 발행" 이라고 Foundation 명시. team4 는 consumer 인터페이스 대기 |
| **team3** | M5 (API-04 in-process 용어 명확화) | Engine 은 별도 서비스임을 API-04 명세에도 재확인 — publisher 가 team3 |

## 6. 실행 순서 (권장)

1. **Phase 1 (P0)** — `Multi_Table_Operations.md` 재작성 + `Sequences.md §1.1/§1.2` 재작성 → 커밋 분리
2. **Phase 2 (P1)** — `Overlay/Overview.md` 재작성 + `Sequences.md` 후속 섹션 정합 검토 → 커밋
3. **Phase 3 (P2)** — MEDIUM 문서들 일괄 패치 (M1~M8) → 커밋. M7 notify: conductor 포함
4. **Phase 4 (P3)** — LOW 참조 갱신 → 커밋
5. **최종** — `Backlog.md` 에 B-team4 항목 등재 (본 review 기반)

## 7. 수락 기준

- [ ] Multi_Table_Operations.md 에서 "같은 머신 다중 CC" 표현 0 건
- [ ] Overlay 문서 (Overview + Sequences) 에 "2 런타임 모드" 또는 "§5.0" 참조 최소 1 건
- [ ] Overlay/Overview.md §5 에 "배경 config flag (완전 투명/단색)" 행 존재
- [ ] Engine_Dependency_Contract.md §7 참조 `Foundation §6.3/§6.4` 포함
- [ ] `dart analyze team4-cc/src` 0 errors 유지 (본 작업은 문서 only, 코드 영향 없음)
- [ ] `spec_drift_check` 회귀 없음

## 8. 참조

- Foundation.md: `docs/1. Product/Foundation.md` (v2026-04-22, `confluence-page-id: 3625189547`)
- 2026-04-22 회의 결정 (D1~D7): Foundation Changelog 참조
- SG-002 해소 문서: `docs/4. Operations/Conductor_Backlog/SG-002-engine-dependency-contract.md`
- SG-005 §6.3 재작성: `docs/4. Operations/Conductor_Backlog/SG-005-foundation-ch6-system-connections.md`
- 본 review 는 후속 수정 PR 의 **기준 스냅샷**. 수정 진행 중 Foundation 이 추가 변경되면 본 문서도 동반 업데이트 필요

## Changelog

| 날짜 | 버전 | 변경 | 작성 |
|------|------|------|------|
| 2026-04-22 | v1.0 | Foundation 재설계 (F1/Ch.4/§5.0/§6.3/§6.4/§7.1/§8.5) 에 대한 team4 기획 문서 전면 재검토 최초 작성 | team4 |
