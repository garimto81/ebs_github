// HandFSM states.
// Definitive source: docs/2. Development/2.2 Backend/Database/State_Machines.md §2 HandFSM.

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
