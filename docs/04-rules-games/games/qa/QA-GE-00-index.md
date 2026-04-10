# QA-GE-00: Game Engine QA 상세 테스트 케이스 — Index

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Game Engine QA 상세 TC Hub 문서 v1.0.0 |
| 2026-04-09 | §8 추가 | 코드 리뷰 발견사항 Known Issue 11건 + TC 추가 8건 |
| 2026-04-09 | §8 KI 추가 | Contract Test FAIL 기반 KI-12~14 추가 (Call enforcement, UNDO 제한, EventLog 미사용) |
| 2026-04-09 | §1 용어 정의 추가, §5 TC ID 범위 갱신 | doc-critic 무결성 검증: 용어 비약 해소 + 코드 리뷰 TC 범위 반영 |

---

## §1 목적과 범위

QA-EBS-Master-Plan §8의 전략적 TC를 **실행 수준**으로 확장한다. Master Plan의 각 TC ID에 대해 다음을 명시한다:

- **입력 세트**: players, stack, cards, board
- **사전 조건**: FSM 상태, 블라인드 구조, game_type
- **실행 단계**: 이벤트 시퀀스 (트리거 소스 포함)
- **기대 출력**: GameState, pots, winner, 상태변수
- **판정 기준**: Dart assertion 수준의 검증 조건

이 문서군의 결과물은 Dart 테스트 코드와 YAML 시나리오 파일의 직접적 입력이다.

### 용어 정의

| 약어 | 의미 |
|------|------|
| **TC** | Test Case — 개별 테스트 시나리오 |
| **KI** | Known Issue — 코드 리뷰에서 발견된 알려진 버그 |
| **FSM** | Finite State Machine — 게임 진행 상태를 관리하는 유한 상태 기계 |
| **BS-06** | Behavioral Specification 06 — 게임 엔진 행동 명세 문서군 |
| **Phase** | 개발 단계 (P0=핵심, P1=주요, P2=확장) |
| **NL/FL/PL** | No Limit / Fixed Limit / Pot Limit — 베팅 구조 유형 |
| **Hi/Lo** | High/Low — 최고핸드와 최저핸드가 팟을 나누는 게임 방식 |
| **RFID** | 카드 자동 인식 기술. 수동 폴백 = RFID 실패 시 수동 입력 전환 |
| **SB/BB** | Small Blind / Big Blind — 의무 베팅 (소액/대액) |
| **POC** | Proof of Concept — 시제품 검증 단계 |
| **fixture** | 미리 준비된 테스트용 예시 데이터 |
| **assertion** | 코드로 자동 확인하는 검증 조건 |
| **CC** | Command Center — 게임 관리 화면 (딜러 조작용) |

> 이 문서군은 개발팀/QA 엔지니어 대상 기술 문서입니다. §8 코드 리뷰 발견사항은 소프트웨어 개발 경험이 필요합니다.

---

## §2 TC Template 정의

모든 TC는 아래 형식을 따른다:

```markdown
### TC-G1-xxx-xx: 제목

| 항목 | 값 |
|------|:--|
| **Phase** | Phase N |
| **우선순위** | P0/P1/P2 |
| **Players** | 인원, stack, BB, SB, Dealer |
| **Hole Cards** | 각 플레이어 카드 |
| **Board** | 커뮤니티 카드 |
| **Actions** | 이벤트 시퀀스 (트리거 소스 명시) |
| **기대 결과** | GameState, pots, winner |
| **판정 기준** | 코드 수준 assertion |
| **참조** | BS-06-xx §N |
```

TC 확장 시 서브케이스: `TC-G1-xxx-xxa`, `TC-G1-xxx-xxb` 접미사.

---

## §3 Phase별 커버리지 매트릭스

| 파일 | Phase 1 POC | Phase 2 Hold'em | Phase 3 22종 |
|------|:---:|:---:|:---:|
| QA-GE-01 FSM | P0: 기본 9상태 | 완전: 무효 전이 포함 | 동일 |
| QA-GE-02 Blinds | P0: std, bb 2종 | 완전: 7종 | 동일 |
| QA-GE-03 All-In | P0: 2인 | 완전: 2~10인 | 동일 |
| QA-GE-04 Eval | P0: High only | 완전: Hi/Lo 포함 | 동일 |
| QA-GE-05 Exceptions | P1: Miss Deal | 완전: 6종 | 동일 |
| QA-GE-06 Matrix | — | Hold'em 4종만 | 완전: 22종 |
| QA-GE-07 Mix | — | — | 완전 |
| QA-GE-08 Bet | P0: NL only | 완전: NL/FL/PL | 동일 |
| QA-GE-09 GameType | P0: Cash only | Cash+Regular | 완전: 8종 |

---

## §4 기존 자산 매핑표

| 자산 | 경로 | 재사용 방법 |
|------|------|-----------|
| Master Plan §8 | `docs/qa/QA-EBS-Master-Plan.md` | TC ID + 조건 유지, 입력/출력으로 확장 |
| TEST-03 Fixtures | `docs/testing/TEST-03-game-engine-fixtures.md` | Hold'em 32개 fixture 인라인 참조 |
| Engine Spec | `docs/04-rules-games/games/engine-spec/BS-06-*` | 각 TC 참조 필드에 명시 |
| Triggers | `docs/02-behavioral/BS-06-game-engine/BS-06-00-triggers.md` | TC 사전조건 트리거 소스 |
| Game PRD | `docs/04-rules-games/games/PRD-GAME-01~04.md` | 게임별 파라미터 원천 |

---

## §5 파일 매핑

| QA-GE 파일 | Master Plan 섹션 | TC ID 범위 |
|-----------|-----------------|-----------|
| QA-GE-01 FSM Transitions | §8.1, §8.2 | TC-G1-002-01~15 |
| QA-GE-02 Blinds & Ante | §8.3 | TC-G1-003-01~07 |
| QA-GE-03 All-In & Side Pot | §8.4 | TC-G1-004-01~08 |
| QA-GE-04 Hand Evaluation | §8.5, §8.5.1 | TC-G1-005-01~15 |
| QA-GE-05 Exceptions | §8.6 | TC-G1-006-01~06 |
| QA-GE-06 Game Matrix | §8.7, §8.7.1 | TC-G1-010~015 |
| QA-GE-07 Mix Game | §8.8 | TC-G1-020-01~07 |
| QA-GE-08 Bet Structure | §8.9 | TC-G1-007-01~03, 01d |
| QA-GE-09 Game Type | §8.10 | TC-G1-008-01~08 |
| **QA-GE-02-checklist** | **전체** | **GE-00~18 (BS-06 기반 196개 항목)** |
| **QA-GE-03-execution-report** | **실행 결과** | **1차 QA: 10 Fail / 3 Pass + 프로세스 Gap** |

---

## §6 TC ID 네임스페이스 규칙

### RFID 수동 폴백 TC 재명명

Master Plan §5의 TC-G1-015-01~04 (RFID 수동 폴백 시나리오)는 Game Engine TC와 ID 충돌을 방지하기 위해 재명명한다:

| 기존 ID | 신규 ID | 설명 |
|--------|--------|------|
| TC-G1-015-01 | TC-RFID-015-01 | RFID 실패 → CC 수동 카드 입력 전환 |
| TC-G1-015-02 | TC-RFID-015-02 | 수동 입력 중 RFID 복구 시 자동 복귀 |
| TC-G1-015-03 | TC-RFID-015-03 | 혼합 모드 (일부 자동 + 일부 수동) |
| TC-G1-015-04 | TC-RFID-015-04 | 수동 입력 검증 (유효하지 않은 카드 거부) |

§8.7.1의 TC-G1-015-01~07 (Draw 카드 교환)은 **TC-G1-015-xx 유지**.

### TEST-03 → Master Plan TC 매핑

| TEST-03 ID | Master Plan TC ID | 설명 |
|-----------|------------------|------|
| TC-01 | TC-G1-002-06 근접 | 6인 정상 핸드 Showdown |
| TC-02 | TC-G1-002-06 근접 | 2인 Heads-Up |
| TC-06 | TC-G1-007-01 근접 | NL 최소 레이즈 |
| TC-11 | TC-G1-004-01 | 2인 All-In 동일 스택 |
| TC-21 | TC-G1-005-01 | 핸드 평가 High Card 승리 |
| TC-07 | TC-G1-007-02 | FL 고정 레이즈 |
| TC-08 | TC-G1-007-03 | PL 팟 사이즈 레이즈 |
| TC-12 | TC-G1-004-02 | 2인 All-In 다른 스택 |
| TC-13 | TC-G1-004-03 | 3인 All-In 모두 다른 스택 |
| TC-16 | TC-G1-006-01 | Miss Deal 핸드 무효화 |
| TC-17 | TC-G1-006-02 | Run It Twice |
| TC-18 | TC-G1-006-03 | Bomb Pot |
| TC-22 | TC-G1-005-02 | Split Pot 동점 |
| TC-26 | TC-G1-003-01 | std 앤티 전원 공제 |
| TC-29 | TC-G1-002-09 | 전원 Fold 즉시 종료 |

> TEST-03의 TC-01~32는 Hold'em fixture로, 상세 TC에서 입력 데이터로 직접 참조한다.

---

## §7 우선순위 정의

| 우선순위 | 정의 | Phase | TC 예시 |
|---------|------|-------|--------|
| **P0** | 핵심 경로 — Phase 1 POC 필수 | Phase 1 | TC-G1-002-01~09, TC-G1-004-01, TC-G1-007-01 |
| **P1** | 주요 기능 — Phase 2 Hold'em 완전 검증 | Phase 2 | TC-G1-002-10~14, TC-G1-003-01~07, TC-G1-004-02~06 |
| **P2** | 확장 — Phase 3 22종 + Mix + 전체 game_type | Phase 3 | TC-G1-010~015, TC-G1-020-01~07, TC-G1-008-03~08 |

---

## §8 코드 리뷰 발견사항 (2026-04-09)

코드 리뷰에서 발견된 버그와 설계 Gap을 QA TC로 추가한다. 실제 코드 수정은 별도 세션에서 진행.

### Known Issue 매트릭스

| # | 심각도 | 대상 파일 | 설명 | 영향 QA 문서 | 상태 |
|:-:|:------:|----------|------|------------|:----:|
| KI-01 | **Critical** | `hand_evaluator.dart` L284 | Short Deck Wheel (A-6-7-8-9) 스트레이트 미인식 | QA-GE-04, QA-GE-06 | Open |
| KI-02 | **Critical** | `showdown.dart` L77 | Hi/Lo odd chip이 Lo에게 할당 (규칙: Hi에게) | QA-GE-04 | Open |
| KI-03 | **Critical** | `pot.dart` + `engine.dart` | `calculateSidePots()` 미호출, `seat.currentBet` Street마다 리셋으로 누적 기여액 소실 | QA-GE-03 | Open |
| KI-04 | **Major** | `engine.dart` L74-217 | Event Sourcing `apply()` 내부 copyWith 후 직접 mutation — 순수 함수 위반 | QA-GE-01 | Open |
| KI-05 | **Major** | `betting_rules.dart` L139 | `Raise(toAmount)` 스택 초과 시 음수 stack — public API 미방어 | QA-GE-08 | Open |
| KI-06 | **Major** | `server.dart` L379 | Path traversal 취약점 (`../../` 경로 미검증) | — (harness) | Open |
| KI-07 | **Major** | `courchevel.dart` L35 | Preflop 공개 카드 강제 사용 미구현 (`bestOmaha` C(5,3) 자유 선택) | QA-GE-06 | Open |
| KI-08 | **Major** | `server.dart` L435 | Session ID 충돌 위험 (`_newId()` entropy 부족) | — (harness) | Open |
| KI-09 | **Important** | `engine.dart` | `StreetAdvance` 무효 전이 미차단 (PRE_FLOP→RIVER 허용) | QA-GE-01 | Open |
| KI-10 | **Important** | 9개 lib 파일 | 테스트 파일 없음 (engine, game_state, seat, session, server 등) | QA-GE-00 | Open |
| KI-11 | **Important** | `betting_round.dart` L4 | `lastRaise` dead field — 읽히는 곳 없음 | QA-GE-08 | Open |
| KI-12 | **Critical** | `betting_rules.dart` L125 | Call.amount 외부값 그대로 적용 — 명세: 엔진 자동 계산 강제 (BS-06-02 §4) | QA-GE-02-06, QA-GE-10 GAP-003 | Open |
| KI-13 | **Major** | `session.dart` L37 | Session.undo() 무제한 — 명세: maxUndoDepth=5 (Ch7.6.7) | QA-GE-02-18, QA-GE-10 GAP-004 | Open |
| KI-14 | **Major** | `event_log.dart` | EventLog 클래스 미사용 (dead code) — Session이 직접 List 관리 | QA-GE-00-09, QA-GE-10 GAP-005 | Open |

### WSOP 공식 규정 검증 결과 (2026-04-09)

`2025-WSOP-Tournament-Rules.pdf` + `2025-WSOP-Event73-DealersChoice.pdf` 교차 검증.

| # | 항목 | QA 기존 내용 | WSOP 공식 | 수정 |
|:-:|------|-----------|----------|:----:|
| W-01 | 8-Game 전환 트리거 | "레벨당 전환" | **"Games change after every six hands"** (6핸드마다) | ✅ 수정 완료 |
| W-02 | HORSE bet_structure | NL → PL → FL → FL → FL | **전부 FL** (PRD-GAME-04 확인) | ✅ 수정 완료 |
| W-03 | 8-Game 게임 순서 | 2-7TD→NLH→O8→Razz→Stud→Stud8→NLH→PLO | PRD-GAME-04 기준: **2-7TD→LH→O8→Razz→Stud→Stud8→NLH→PLO** | ✅ 수정 완료 |
| W-04 | Mixed Game 버튼 freeze | 없음 | Flop→Stud 전환 시 **버튼 freeze**, Stud→Flop 복귀 시 해제 (Rule 67b) | ✅ 추가 완료 |
| W-05 | Odd chip (Hi/Lo) | KI-02에서 발견 | **"odd chip in the total pot goes to the high side"** (Rule 73) | ✅ WSOP 근거 확인 |
| W-06 | NL/PL ante 구조 | 없음 | NL ante=1.5×BB, PL ante=BB (FLOP 후에만 pot 포함) | ✅ QA-GE-07에 추가 |
| W-07 | Dealer's Choice 핸드 수 | "다음 핸드부터" | **1~최대 테이블 인원 수 핸드** 유지 (구조표 결정) | ✅ 수정 완료 |

### 추가 TC 목록 (코드 리뷰 기반)

| TC ID | 추가 대상 | 설명 | 우선순위 |
|-------|----------|------|:--------:|
| TC-G1-005-13 | QA-GE-04 | Short Deck Wheel (A-6-7-8-9) 스트레이트 검증 | P0 |
| TC-G1-005-14 | QA-GE-04 | Short Deck Steel Wheel (A-6-7-8-9 동일 수트) 스트레이트 플러시 검증 | P0 |
| TC-G1-005-15 | QA-GE-04 | Hi/Lo odd pot (101칩) Hi에게 odd chip 할당 검증 | P0 |
| TC-G1-004-07 | QA-GE-03 | Side Pot 통합 E2E: All-In → calculateSidePots → Showdown 자동 연결 | P0 |
| TC-G1-004-08 | QA-GE-03 | Sub-call All-In (25 vs 50+50) Side Pot eligible set 검증 | P1 |
| TC-G1-007-01d | QA-GE-08 | Raise toAmount > stack 시 거부/clamp 검증 | P0 |
| TC-G1-002-15 | QA-GE-01 | StreetAdvance 무효 전이 (PRE_FLOP→RIVER 직행) 거부 검증 | P1 |
| TC-G1-012-12a | QA-GE-06 | Courchevel preflop 카드 강제 사용 — community[0] 미포함 조합 거부 | P2 |
