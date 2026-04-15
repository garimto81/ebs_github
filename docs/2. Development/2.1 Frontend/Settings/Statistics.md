---
title: Statistics
owner: team1
tier: internal
legacy-id: BS-03-05
last-updated: 2026-04-15
---

# BS-03-05 Stats — 통계/승률 설정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Console PRD v9.7 §2.9b 기반 — Equity & Statistics/Leaderboard & Strip 2서브그룹, 15 컨트롤 |

---

## 개요

Stats 섹션은 Settings의 다섯 번째 탭으로, 에퀴티(승률), 아웃, 리더보드, 스코어 스트립 관련 **통계 설정**을 관리한다. 2-Column 구조: Equity & Statistics(에퀴티/아웃/래빗 헌팅) → Leaderboard & Strip(리더보드 컬럼/스트립 표시). 단축키: Ctrl+5. 방송 시작 전 세팅 원칙.

> 참조: Console PRD v9.7 §2.9b Stats 탭

---

## 1. 컨트롤 목록

### 1.1 Equity & Statistics 서브그룹 (ID 12~17)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 12 | Show Hand Equities | Select | Never | 에퀴티 표시 시점 | 에퀴티 바 표시/숨김 |
| 13 | Show Outs | Select | OFF | 아웃 카드 표시 위치 | 아웃 카드 시각 표시 |
| 14 | True Outs | Switch | ON | 순수 아웃만 계산 (러너 러너 제외) | 아웃 수 계산 방식 |
| 15 | Outs Position | Select | Stack | 아웃 표시 모드 | 아웃 수량 위치 |
| 16 | Allow Rabbit Hunting | Switch | OFF | 핸드 종료 후 미공개 커뮤니티 카드 확인 허용 | 래빗 카드 표시 |
| 17 | Ignore Split Pots | Switch | OFF | 에퀴티/아웃 계산 시 사이드팟 무시 | 에퀴티 계산 범위 |

**Show Hand Equities 4개 옵션**:

| 옵션 | 트리거 조건 |
|------|-----------|
| **Never** | 에퀴티 표시 안 함 |
| **Immediately** | 핸드 시작 시 즉시 (딜 직후) |
| **At showdown or winner All In** | 쇼다운 도달 시, 또는 올인 승자 확정 시 |
| **At showdown** | 쇼다운 도달 시에만 |

에퀴티 바는 Player Graphic 하단에 수평 프로그레스 바로 표시 (승률 %).

**Show Outs 옵션**:

| 옵션 | 설명 |
|------|------|
| Off | 아웃 표시 안 함 |
| Right | 헤즈업 시 Player Graphic 우측에 아웃 카드 표시 |
| Left | 헤즈업 올인 시 좌측에 표시 |

**Outs Position 옵션**:

| 옵션 | 위치 |
|------|------|
| Off | 아웃 수량 표시 안 함 |
| Stack | 스택 영역에 아웃 수 표시 |
| Winnings | 상금 영역에 아웃 수 표시 |

**True Outs**: 활성 시 현재 스트리트에서 즉시 핸드 완성하는 카드만 계산. 비활성 시 러너 러너(연속 2장 완성) 포함. 예: 플러시 드로우 4장 보유 시 True Outs = 9장.

### 1.2 Leaderboard & Strip 서브그룹 (ID 18~26)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 18 | Show Knockout Rank | Switch | OFF | 리더보드에 녹아웃 순위 컬럼 표시 | LB KO 컬럼 |
| 19 | Show Chipcount % | Switch | OFF | 리더보드에 칩카운트 비율(%) 컬럼 표시 | LB % 컬럼 |
| 20 | Show Eliminated in Stats | Switch | ON | 탈락 플레이어를 리더보드 통계에 포함 | LB 탈락자 회색+취소선 |
| 21 | Show Cumulative Winnings | Switch | OFF | 칩카운트와 누적 상금 함께 표시 | LB 누적 상금 컬럼 |
| 22 | Hide LB When Hand Starts | Switch | ON | 핸드 시작 시 리더보드 자동 숨김 | LB 자동 숨김 |
| 23 | Max BB Multiple in LB | Input[type=number] | 999 | 리더보드 최대 BB 배수 (1~9999) | 극단적 수치 필터링 |
| 24 | Score Strip | Select | Never | 스코어 스트립 표시 조건 | 스트립 표시/숨김 |
| 25 | Show Eliminated in Strip | Switch | OFF | 스트립에 탈락 플레이어 포함 표시 | 스트립 탈락자 표시 |
| 26 | Order Strip By | Select | Seating | 스트립 내 플레이어 정렬 (Seating/Chip Count) | 스트립 정렬 순서 |

**Score Strip 표시 조건**:

| 옵션 | 트리거 |
|------|--------|
| **Never** | 스코어 스트립 숨김 |
| **Heads Up or All In Showdown** | 헤즈업 또는 올인 쇼다운 시 표시 |
| **All In Showdown** | 올인 쇼다운 시에만 표시 |

**리더보드 컬럼 구성** (설정 조합에 따른 변화):

- Show Knockout Rank (18): KO 컬럼 추가
- Show Chipcount % (19): 전체 칩 대비 비율(%) 컬럼 추가
- Show Eliminated in Stats (20): 탈락 플레이어를 회색+취소선으로 포함
- Show Cumulative Winnings (21): 칩카운트 옆에 누적 상금 컬럼 추가
- Hide LB When Hand Starts (22): 핸드 시작 신호 수신 시 자동 숨김
- Max BB Multiple (23): BB 배수 초과 시 해당 행 필터링

---

## 2. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 변경 | Admin 수동 | 방송 시작 전 세팅 |
| `ConfigChanged` | 시스템 자동 | BO DB 갱신 후 WebSocket 이벤트 발행 |
| 올인/쇼다운 | 게임 엔진 자동 | Show Hand Equities / Score Strip 트리거 |
| 헤즈업 전환 | 게임 엔진 자동 | Show Outs 트리거 |
| 핸드 시작 | 게임 엔진 자동 | Hide LB When Hand Starts 트리거 |

---

## 3. 경우의 수 매트릭스

| 조건 | Equity 설정 변경 | Leaderboard 설정 변경 | Strip 설정 변경 |
|------|:---------------:|:-------------------:|:--------------:|
| CC IDLE | 즉시 적용 | 즉시 적용 | 즉시 적용 |
| CC 핸드 진행 중 | 다음 핸드 (CONFIRM) | 즉시 적용 (FREE) | 즉시 적용 (FREE) |
| BO 서버 미실행 | 변경 불가 | 변경 불가 | 변경 불가 |
| Show Outs OFF | Outs Position 비활성 | — | — |
| 플레이어 3인+ | — | — | Show Outs 동작 안 함 (헤즈업 전용) |
| BB = 0 | — | Max BB Multiple 무의미 | — |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| T-1 | Admin | Show Hand Equities를 "Immediately"로 설정 | 딜 직후 에퀴티 바 표시 | "Never": 에퀴티 숨김 |
| T-2 | Admin | Show Outs를 "Right"로 변경 | 헤즈업 시 아웃 카드 우측 표시 | 3인+: 아웃 숨김 |
| T-3 | Admin | True Outs OFF | 러너 러너 포함 아웃 계산 | ON: 순수 아웃만 |
| T-4 | Admin | Allow Rabbit Hunting ON | 핸드 종료 후 남은 커뮤니티 카드 공개 가능 | — |
| T-5 | Admin | Show Knockout Rank + Chipcount % ON | 리더보드에 KO 순위 + % 컬럼 추가 | — |
| T-6 | Admin | Score Strip을 "Heads Up or All In Showdown"으로 설정 | 해당 상황에서 스코어 스트립 표시 | Never: 스트립 숨김 |
| T-7 | Admin | Hide LB When Hand Starts ON | 핸드 시작 시 리더보드 자동 숨김 | OFF: 리더보드 수동 닫기 필요 |
| T-8 | Admin | Order Strip By를 "Chip Count"로 변경 | 스트립 내 칩량 내림차순 정렬 | 동점: 좌석 순 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Stats 탭 접근 불가 |
| CC LIVE + 핸드 진행 중 | Equity 설정: CONFIRM 분류 |
| BO 서버 미실행 | 읽기 전용 |
