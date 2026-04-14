// Hand action types from BS-05-02 and BS-06-00-REF Ch.1 Enum Registry.

/// Hand action type (BS-06-00-REF Ch.1 Enum Registry, 14 types).
enum ActionType {
  fold,
  check,
  bet,
  call,
  raise,
  allIn,
  boardCard,
  skip,
  showdown,
  eliminate,
  ante,
  blindPost,
  straddle,
  missDeal,
}
