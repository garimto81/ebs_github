// Game type, bet structure, and position enums.
//
// 권위:
//   - GameType 25 게임: docs/2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md §2.1 25 게임 마스터 테이블
//   - game Enum: Behavioral_Specs/Lifecycle_and_State_Machine.md §2.5
//   - Position: Behavioral_Specs/Lifecycle_and_State_Machine.md §1.4 포지션 정의
// (구 BS-06-00-REF §1.1 — 2026-04-27/04-28 Lifecycle + Variants 도메인 마스터로 통합, B-349.)

/// Game type. 권위: Variants 도메인 §2.1 (25 게임 마스터). 본 enum 은 10 핵심 variant.
enum GameType {
  holdem,      // 0
  omaha,       // 1
  omahaHiLo,   // 2
  stud,        // 3
  studHiLo,    // 4
  razz,        // 5
  drawTriple,  // 6
  drawSingle,  // 7
  drawBadugi,  // 8
  shortDeck,   // 9
}

/// Bet structure. 권위: Betting & Pots 도메인 §1.2.2 (NL/PL/FL 정의) + Variants §2.1 컬럼.
enum BetStructure {
  noLimit,    // NL
  potLimit,   // PL
  fixedLimit, // FL
}

/// Seat position (10-seat layout). 권위: Lifecycle 도메인 §1.4 포지션 정의 (BTN/SB/BB/UTG/HJ/CO).
enum Position {
  btn,  // 0 — Dealer Button
  sb,   // 1 — Small Blind
  bb,   // 2 — Big Blind
  utg,  // 3
  utg1, // 4
  utg2, // 5
  mp,   // 6 — Middle Position
  mp1,  // 7
  hj,   // 8 — Hijack
  co,   // 9 — Cutoff
}
