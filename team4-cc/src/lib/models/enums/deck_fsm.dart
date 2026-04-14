// Deck FSM from DATA-03 §4 DeckFSM.

/// Deck registration state (DATA-03 §4 DeckFSM).
enum DeckFsm {
  unregistered,
  registering,
  registered,
  partial,
  mock,
}
