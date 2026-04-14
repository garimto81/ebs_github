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
  /// `contracts/api/API-05-websocket-events.md`:
  /// the JSON envelope is defined, but the `?format=msgpack` query param
  /// negotiation section is missing.
  ///
  /// Phase 2 action: Team 2 FastAPI + Dart `messagepack` package PoC,
  /// then re-submit CCR to API-05 with full negotiation spec, then flip
  /// this flag. See `qa/commandcenter/spec-gap.md` GAP-CC-001.
  static const enableMsgpack = false;

  /// Enable Security Delay Dual Output (BS-07-07, CCR-036).
  /// Disabled by default; Admin enables via BS-03-02 Settings.
  static const securityDelayEnabledDefault = false;

  /// Default Security Delay seconds when enabled (CCR-036).
  static const securityDelayDefaultSeconds = 30;
}
