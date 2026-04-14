// Security Delay runtime configuration.
// See BS-07-07-security-delay.md (CCR-036).

class SecurityDelayConfig {
  const SecurityDelayConfig({
    required this.enabled,
    required this.delaySeconds,
    required this.holecardsOnly,
  });

  final bool enabled;
  final int delaySeconds;
  final bool holecardsOnly;

  static const disabled = SecurityDelayConfig(
    enabled: false,
    delaySeconds: 0,
    holecardsOnly: false,
  );

  // TODO(BS-07-07): implement serialization from BS-03-02 gfx ConfigChanged event
}
