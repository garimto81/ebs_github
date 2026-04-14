// Seat status from DATA-03 §3 SeatFSM (9-state, WSOP LIVE codes).
// Player activity from BS-05-03 §visual spec (CCR-032).

/// WSOP LIVE Seat Status codes (DATA-03 §3 SeatFSM, 9 states).
enum SeatStatus {
  empty,    // E — empty seat
  newSeat,  // N — newly assigned (10min elapsed or hand participation → playing)
  playing,  // P — actively participating
  moved,    // M — arrived via move (10min elapsed or hand participation → playing)
  busted,   // B — eliminated (FM/TD confirm → empty)
  reserved, // R — reserved (excluded from seating)
  waiting,  // W — Auto Seating waitlist
  occupied, // O — BreakTable reassignment reserved
  hold,     // H — Seat Draw pre-emption
}

/// In-hand player activity state (BS-05-03 visual spec).
enum PlayerActivity {
  active,
  folded,
  sittingOut,
  allIn,
}

/// Backward-compatible alias for SeatFsm.
/// @deprecated Use [SeatStatus] instead.
typedef SeatFsm = SeatStatus;
