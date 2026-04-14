// HandFSM states from DATA-03 §2 and BS-06-01.
// Definitive source: contracts/data/DATA-03-state-enums.md §2 HandFSM.

enum HandFsm {
  idle,
  setupHand,
  preFlop,
  flop,
  turn,
  river,
  showdown,
  handComplete,
  runItMultiple,
}
