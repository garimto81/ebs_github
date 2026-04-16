// Feature flags for ebs_cc.
//
// Runtime toggles for experimental or Phase 2 features. Defaults reflect
// the Phase 1 operational baseline.

class Features {
  Features._();

  /// Use MockRfidReader instead of real hardware (BS-04 §Mock Priority).
  /// Default true in Phase 1 (hardware not yet available).
  static const useMockRfid = true;

  /// Enable MessagePack WebSocket envelope (CCR-023).
  ///
  /// **Currently false**. CCR-023 was only partially applied to
  /// `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`:
  /// the JSON envelope is defined, but the `?format=msgpack` query param
  /// negotiation section is missing — team2 must extend the doc before
  /// this flag is flipped.
  ///
  /// Phase 2 action: Team 2 FastAPI + Dart `messagepack` package PoC,
  /// then extend WebSocket_Events.md with a full negotiation spec, then
  /// flip this flag.
  static const enableMsgpack = false;

  /// Enable Security Delay Dual Output (BS-07-07, CCR-036).
  /// Disabled by default; Admin enables via BS-03-02 Settings.
  static const securityDelayEnabledDefault = false;

  /// Default Security Delay seconds when enabled (CCR-036).
  static const securityDelayDefaultSeconds = 30;

  /// Enable Demo & Test Mode (Demo_Test_Mode.md §1).
  /// Allows game progression verification without RFID or WebSocket.
  /// Activated at runtime via `--demo` CLI flag or Toolbar menu toggle.
  static bool enableDemoMode = false;
}
