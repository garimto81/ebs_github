// Seat status from BS-05-03-seat-management.md §시각 규격 (CCR-032).

enum SeatFsm {
  vacant,
  occupied,
  reserved,
}

enum PlayerActivity {
  active,
  folded,
  sittingOut,
  allIn,
}
