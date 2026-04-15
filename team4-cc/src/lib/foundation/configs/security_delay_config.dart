// Security Delay runtime configuration.
// See BS-07-07-security-delay.md (CCR-036).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityDelayConfig {
  const SecurityDelayConfig({
    required this.enabled,
    required this.delaySeconds,
    required this.holecardsOnly,
  });

  final bool enabled;
  final int delaySeconds;
  final bool holecardsOnly;

  /// Max delay accepted from ConfigChanged payload (BS-07-07 §delay range
  /// 0~600 seconds). Values outside this range are clamped + logged.
  static const int minDelaySeconds = 0;
  static const int maxDelaySeconds = 600;

  static const disabled = SecurityDelayConfig(
    enabled: false,
    delaySeconds: 0,
    holecardsOnly: false,
  );

  /// Parse a `ConfigChanged` WebSocket payload (API-05 §5) into a
  /// SecurityDelayConfig. Unknown / missing fields fall back to [disabled]
  /// semantics so a malformed event never crashes the renderer.
  ///
  /// Expected shape (subset):
  /// ```
  /// {
  ///   "security_delay": {
  ///     "enabled": true,
  ///     "delay_seconds": 30,
  ///     "holecards_only": false
  ///   }
  /// }
  /// ```
  /// Also accepts the flat form where the three keys live directly at
  /// the root of the payload (older publishers / unit tests).
  factory SecurityDelayConfig.fromConfigChanged(Map<String, dynamic> payload) {
    final nested = payload['security_delay'];
    final source = nested is Map<String, dynamic> ? nested : payload;

    final enabled = source['enabled'] as bool? ?? false;
    final rawDelay = source['delay_seconds'];
    int delay = 0;
    if (rawDelay is int) {
      delay = rawDelay;
    } else if (rawDelay is num) {
      delay = rawDelay.toInt();
    } else if (rawDelay is String) {
      delay = int.tryParse(rawDelay) ?? 0;
    }
    if (delay < minDelaySeconds || delay > maxDelaySeconds) {
      debugPrint(
        '[SecurityDelayConfig] delay_seconds $delay out of range '
        '[$minDelaySeconds, $maxDelaySeconds]; clamping.',
      );
      delay = delay.clamp(minDelaySeconds, maxDelaySeconds);
    }
    final holecardsOnly = source['holecards_only'] as bool? ?? false;

    return SecurityDelayConfig(
      enabled: enabled,
      delaySeconds: delay,
      holecardsOnly: holecardsOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'delay_seconds': delaySeconds,
        'holecards_only': holecardsOnly,
      };

  SecurityDelayConfig copyWith({
    bool? enabled,
    int? delaySeconds,
    bool? holecardsOnly,
  }) =>
      SecurityDelayConfig(
        enabled: enabled ?? this.enabled,
        delaySeconds: delaySeconds ?? this.delaySeconds,
        holecardsOnly: holecardsOnly ?? this.holecardsOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is SecurityDelayConfig &&
      other.enabled == enabled &&
      other.delaySeconds == delaySeconds &&
      other.holecardsOnly == holecardsOnly;

  @override
  int get hashCode => Object.hash(enabled, delaySeconds, holecardsOnly);
}

/// Live Security Delay configuration — updated by ws_provider on
/// `ConfigChanged` events. Starts [SecurityDelayConfig.disabled]; the
/// Overlay renderer watches this to switch delay buffer on/off.
final securityDelayConfigProvider =
    StateProvider<SecurityDelayConfig>((_) => SecurityDelayConfig.disabled);
