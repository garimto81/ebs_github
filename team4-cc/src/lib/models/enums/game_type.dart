// Game type, bet structure, and position enums from BS-06-00-REF §1.1.

/// Game type (BS-06-00-REF §1.1, 10 variants).
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

/// Bet structure (BS-06-00-REF §1.1).
enum BetStructure {
  noLimit,    // NL
  potLimit,   // PL
  fixedLimit, // FL
}

/// Seat position (10-seat layout, BS-06-00-REF).
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
