// HandFSM states from BS-05-01-hand-lifecycle.md and BS-06-01.
// Definitive source: contracts/specs/BS-06-game-engine/BS-06-01-holdem-lifecycle.md.

enum HandFsm {
  idle,
  setupHand,
  preFlop,
  flop,
  turn,
  river,
  showdown,
  handComplete,
}
