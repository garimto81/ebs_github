# PRD-0004 설계 시사점 전면 재검토 Work Plan

## 배경 (Background)

- **요청 내용**: PRD-0004 내 9개 `> **설계 시사점**` 블록의 일관성 및 품질 개선
- **해결하려는 문제**: 현재 시사점 블록이 3가지 패턴으로 혼재됨
  1. MVP 범위 외 항목이 시사점 블록에 끼어들어 역할 혼재 (Step 1)
  2. 빈약한 bullet 수 — 요소 수 대비 시사점 부족 (Step 4: 13개 요소 → 2개만)
  3. PokerGFX 특징 나열에 그치고 EBS 설계 결정이 부재 (Step 5, Step 6)
- **일관성 기준**: 모든 bullet은 `[PokerGFX 관찰/문제] → [EBS 설계 결정: 계승/변경/신규/제거]` 구조

## 구현 범위 (Scope)

### 포함 항목
- 수정 대상 4개 섹션 (Step 1, Step 4, Step 5, Step 6) 시사점 블록 수정
- 양호 판정 5개 섹션 (Step 2, Step 3, Step 7, Step 9 Skin, Step 9 Graphic) 원본 유지

### 제외 항목
- 요소 테이블(Element Catalog) 내용 수정 없음
- 설계 스펙, Design Decisions, Workflow 섹션 수정 없음
- 새 섹션 추가 없음

## 영향 파일 (Affected Files)

### 수정 예정 파일
- `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0004-EBS-Server-UI-Design.md`
  - L107~L111 (Step 1 Main Window 시사점)
  - L513~L515 (Step 4 Outputs 시사점)
  - L665~L669 (Step 5 GFX 1 시사점)
  - L827~L830 (Step 6 GFX 2 시사점)

### 신규 생성 파일
- 없음

## 위험 요소 (Risks)

1. **MVP 범위 외 bullet 제거 시 정보 손실**: Step 1 L111의 MVP 범위 외 항목은 요소 테이블(L103~L105)에 이미 `EBS MVP 범위 외 (추후 개발 예정)` 컬럼으로 표기되어 있으므로 제거해도 정보는 보존된다. 그러나 "Preview 항상 활성화 고정(토글 UI 제거)" 결정은 L131 설계 스펙에만 언급되어 있으므로 시사점 제거 후 별도 bullet로 반드시 보존해야 한다.

2. **Step 4 신규 bullet 출처 검증 필요**: Outputs 탭 요소 테이블(L500~L511) 기반으로 작성하며, 요소 ID O-18~O-20은 설계 스펙(L523)에서 확인된 신규 추가 항목. NDI/SDI 복잡성은 요소 테이블 내 Live/Delay 2열 구조에서 파생. 임의 추론 없이 문서 내 근거를 사용한다.

3. **Step 5, Step 6 — EBS 결정을 "없음"으로 잘못 표현 위험**: GFX 탭은 PokerGFX 구조를 직접 계승(설계 스펙 L679, L838)한다고 명시되어 있다. 시사점에서 "계승" 결정을 반드시 명시해야 하며, "EBS에서 미결정" 표현은 금지.

4. **줄 번호 드리프트**: 대상 파일이 1741줄이며 앞에서부터 순서대로 수정하면 뒤 섹션의 줄 번호가 변경된다. `old_string`/`new_string` 패턴 기반 Edit 도구 사용으로 줄 번호 의존을 피한다.

## 태스크 목록 (Tasks)

---

### Task 1: Step 1 Main Window — 시사점 정제

**수행 방법**: L107~L111 블록을 아래 내용으로 교체. Edit 도구 사용.

**현재 내용**:
```
> **설계 시사점**
> - Preview + 우측 컨트롤 패널 2-column 레이아웃은 운영 효율이 검증된 구조 → EBS 계승
> - RFID 상태(3번)가 CPU/GPU와 같은 행에 묻혀 존재감 약함 → EBS에서 독립 분리 (M-05)
> - 버튼 7개가 우선순위 구분 없이 균등 노출 (PokerGFX 관찰)
> - **EBS MVP 범위 외 (추후 개발 예정)**: Recording, Secure Delay(4번), Studio(8번), Split Recording(9번), Tag Player(10번) — Preview는 미리보기 항상 활성화 고정(토글 UI 제거)
```

**교체 내용**:
```
> **설계 시사점**
> - Preview + 우측 컨트롤 패널 2-column 레이아웃은 운영 효율이 검증된 구조 → EBS 계승
> - RFID 상태(3번)가 CPU/GPU와 같은 행에 묻혀 존재감 약함 → EBS에서 독립 분리 (M-05)
> - 버튼 7개가 우선순위 구분 없이 균등 노출 (Reset Hand / Register Deck / Launch AT / Settings 등 혼재)
> - Preview Toggle(4번)이 실수로 꺼지면 방송 모니터링 공백 발생 → Drop 결정 (M-09 토글 제거)
```

**변경 근거**:
- MVP 범위 외 목록은 요소 테이블(L103~L105)에 이미 명시. 시사점 블록에서 제거.
- 버튼 우선순위 미구분은 PokerGFX 관찰 사항으로만 기술. EBS 재편 결정은 별도 설계 단계에서 결정.
- Preview Toggle Drop 결정은 설계 스펙(L131)에 언급되어 있으므로 별도 bullet 보존.

**Acceptance Criteria**:
- [ ] MVP 범위 외 항목 열거 bullet 제거됨
- [ ] 4개 bullet 유지 (레이아웃 계승 / RFID 분리 / 버튼 관찰 / Preview 고정)
- [ ] 각 bullet이 `[PokerGFX 관찰] → [EBS 결정]` 구조를 가짐
- [ ] 기존에 없던 정보가 추가되지 않음 (문서 내 근거만 사용)

---

### Task 2: Step 4 Outputs — 시사점 보강

**수행 방법**: L513~L515 블록을 아래 내용으로 교체. Edit 도구 사용.

**현재 내용**:
```
> **설계 시사점**
> - Live/Delay 2열 구조는 직관적이며 EBS 계승 가치 있음
> - Key & Fill(4~5번)의 DeckLink 포트 할당이 불명확 → EBS에서 O-18~O-20 Fill & Key 전용 섹션 신규
```

**교체 내용**:
```
> **설계 시사점**
> - Live/Delay 2열 구조가 동일 화면에서 두 파이프라인을 병렬 관리 → EBS에서 Live 단일 출력 우선 구현, Delay 파이프라인은 추후 개발
> - Key & Fill(4~5번)의 DeckLink 포트 할당이 불명확하고 Sources 탭과 설정 분리됨 → EBS에서 O-18~O-20 Fill & Key 전용 섹션 신규 추가
> - Recording(7번) / Auto Stream(10번) / Twitch ChatBot(13번)이 출력 설정과 혼재 → EBS에서 스트리밍/녹화는 별도 그룹 분리 (P2 통합)
> - Virtual Camera(6번)가 SDI/NDI와 동일 Priority로 배치 → EBS에서 P2로 내려 운영 필수 설정과 구분
```

**변경 근거**:
- L523 설계 스펙 "Live 단일 출력 구조, Delay 파이프라인은 추후 개발"에서 파생
- L503~L505 요소 테이블의 Live/Delay 구조 확인
- L507~L513 요소의 P1/P2 우선순위 패턴에서 분리 근거 도출
- O-18~O-20 Fill & Key는 L515, L523에서 신규 추가로 명시됨

**Acceptance Criteria**:
- [ ] 4개 bullet으로 확장 (기존 2개 → 4개)
- [ ] 각 bullet이 `[PokerGFX 관찰] → [EBS 결정]` 구조를 가짐
- [ ] 요소 ID (O-18~O-20) 참조 유지
- [ ] 설계 스펙과 충돌하는 내용 없음

---

### Task 3: Step 5 GFX 1 — 단순 나열에서 설계 결정으로 전환

**수행 방법**: L665~L669 블록을 아래 내용으로 교체. Edit 도구 사용.

**현재 내용**:
```
> **설계 시사점**
> - 스킨 시스템: 1.41GB "Titanium" 스킨 — 모든 그래픽 에셋이 단일 스킨으로 패키징
> - 3개 스폰서 슬롯: Leaderboard / Board / Strip 위치별 로고 배치
> - Transition Animation: Pop/Slide/Fade + 시간(초) 조합으로 세밀한 제어
> - Bounce Action Player: 액션 대기 플레이어에 바운스 시각 효과 (방송 UX 핵심)
```

**교체 내용**:
```
> **설계 시사점**
> - 단일 스킨 패키지(1.41GB)가 모든 그래픽 에셋을 포함 → EBS에서 계승, 스킨 단위 배포 구조 유지 (SK-01~SK-05)
> - 스폰서 슬롯 3개(Leaderboard / Board / Strip)가 위치별로 독립 관리 → EBS 계승 (G-10~G-12), P2 우선순위 유지
> - Transition Animation이 Pop/Slide/Fade + 시간 조합으로 세밀하게 제어됨 → EBS 계승 (G-22~G-24), 방송 연출 핵심 기능
> - Bounce Action Player가 액션 대기 플레이어의 바운스 시각 효과를 체크박스 하나로 제어 → EBS 계승 (G-25), 체크박스 On/Off 구조 동일 유지
```

**변경 근거**:
- L679 설계 스펙 "PokerGFX GFX 1 탭 구조 직접 계승" 명시
- 요소 테이블 L650~L663의 각 항목 ID(G-10~G-12, G-22~G-25) 확인
- 단순 특징 나열 → EBS 설계 결정(계승 명시) 전환

**Acceptance Criteria**:
- [ ] 4개 bullet 유지
- [ ] 각 bullet에 PokerGFX 특징 + EBS 결정(계승/변경) 명시
- [ ] 요소 ID (G-xx) 참조 추가
- [ ] "단순 나열" bullet 없음 — 모든 bullet이 EBS 결정을 포함

---

### Task 4: Step 6 GFX 2 — 단순 나열에서 설계 결정으로 전환

**수행 방법**: L827~L830 블록을 아래 내용으로 교체. Edit 도구 사용.

**현재 내용**:
```
> **설계 시사점**
> - Bomb Pot / Rabbit Hunting / Sleeper Straddle: 방송에서 사용되는 다양한 특수 규칙 지원 필요
> - Equity 표시 시점: "After 1st betting round" 등 정밀 제어 가능
> - Secure Mode 깜빡임: 보안 모드에서 미확인 카드의 시각적 피드백
```

**교체 내용**:
```
> **설계 시사점**
> - Bomb Pot / Rabbit Hunting / Sleeper Straddle 등 특수 규칙이 별도 체크박스로 독립 노출 → EBS 계승 (G-52~G-57), 규칙 변경이 그래픽 표시에 직접 영향을 미쳐 GFX 2 탭 배치 유지
> - Equity 표시 시점이 "After 1st betting round" 등 정밀 드롭다운으로 제어 → EBS 계승 (G-37), 방송 긴장감에 직결되어 P0 유지
> - 보안 모드에서 미확인 카드 깜빡임(Unknown cards blink)이 별도 체크박스로 제어 → EBS 계승 (G-56), RFID 미인식 카드의 시각적 경보 기능
```

**변경 근거**:
- L838 설계 스펙 "PokerGFX GFX 2 탭 구조 직접 계승", G-52~G-57 게임 규칙 그룹 명시
- L848 Design Decision 1 "원본 구조 유지" 명시
- L850 Design Decision 2 "Equity 표시 시점 P0" 명시
- 요소 테이블 L815~L825에서 G-37, G-56 대응 항목 확인

**Acceptance Criteria**:
- [ ] 3개 bullet 유지 (항목 수 변경 없음)
- [ ] 각 bullet에 EBS 결정(계승 + 요소 ID) 명시
- [ ] "단순 나열" bullet 없음
- [ ] 요소 ID (G-37, G-52~G-57) 참조 추가

---

## 실행 순서

```
  +---------------------------+
  | Task 1: Step 1 Main       |
  | L107 시사점 교체           |
  | (old_string 패턴 기반)     |
  +-------------+-------------+
                |
                v
  +---------------------------+
  | Task 2: Step 4 Outputs    |
  | L513 시사점 교체           |
  +-------------+-------------+
                |
                v
  +---------------------------+
  | Task 3: Step 5 GFX 1      |
  | L665 시사점 교체           |
  +-------------+-------------+
                |
                v
  +---------------------------+
  | Task 4: Step 6 GFX 2      |
  | L827 시사점 교체           |
  +---------------------------+
```

순서 이유: 앞 섹션 수정 시 뒤 섹션 줄 번호가 변경될 수 있으나, Edit 도구는 `old_string` 패턴 기반이므로 순서 무관. 그러나 순차 처리로 충돌을 방지한다.

## 커밋 전략 (Commit Strategy)

```
docs(prd-0004): 설계 시사점 4개 섹션 품질 개선

- Step 1: MVP 범위 외 항목 제거, Preview 고정 결정 bullet 신규
- Step 4: 2개 → 4개 bullet 보강 (Delay/스트리밍/Virtual Camera 분리 명시)
- Step 5: 단순 나열 → 계승 결정 + 요소 ID 참조로 전환
- Step 6: 단순 나열 → 계승 결정 + 요소 ID 참조로 전환
```

---

**Version**: 1.0.0 | **Created**: 2026-02-26 | **Target**: PRD-0004-EBS-Server-UI-Design.md
