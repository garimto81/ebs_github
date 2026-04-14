// TableFSM from DATA-03 §1 and BS-05-00 §Table FSM vs HandFSM boundary (CCR-031).
//
// - EMPTY: no table assigned. CC cannot start.
// - CLOSED: operations ended. CC read-only.
// - SETUP: table being created. Seat editing allowed, hand start blocked.
// - LIVE: hand progression allowed. HandFSM active.
// - PAUSED: operations paused. HandFSM frozen. All action buttons disabled.
// - RESERVED_TABLE: table reserved for future use (DATA-03 §1).

enum TableFsm {
  empty,
  closed,
  setup,
  live,
  paused,
  reservedTable,
}
