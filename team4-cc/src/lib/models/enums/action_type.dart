// Hand action types.
//
// 권위: docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md §1.7 ActionType Enum (6 core types).
// (구 BS-05-02 + BS-06-00-REF Ch.1 — 2026-04-27 Triggers 도메인 마스터로 통합, B-349.)

/// Hand action type. 권위: Triggers 도메인 §1.7 (fold/check/bet/call/raise/allIn).
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
