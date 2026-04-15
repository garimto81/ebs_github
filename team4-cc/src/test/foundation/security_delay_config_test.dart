// SecurityDelayConfig.fromConfigChanged — parses ConfigChanged WS payload
// per BS-07-07 + API-05 §5. Clamps out-of-range delay, handles nested
// and flat shapes.

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/foundation/configs/security_delay_config.dart';

void main() {
  group('SecurityDelayConfig.fromConfigChanged', () {
    test('nested shape parses correctly', () {
      final cfg = SecurityDelayConfig.fromConfigChanged({
        'security_delay': {
          'enabled': true,
          'delay_seconds': 30,
          'holecards_only': true,
        },
      });
      expect(cfg.enabled, true);
      expect(cfg.delaySeconds, 30);
      expect(cfg.holecardsOnly, true);
    });

    test('flat shape parses correctly', () {
      final cfg = SecurityDelayConfig.fromConfigChanged({
        'enabled': true,
        'delay_seconds': 10,
        'holecards_only': false,
      });
      expect(cfg.enabled, true);
      expect(cfg.delaySeconds, 10);
    });

    test('missing fields fall back to disabled defaults', () {
      final cfg = SecurityDelayConfig.fromConfigChanged({});
      expect(cfg.enabled, false);
      expect(cfg.delaySeconds, 0);
      expect(cfg.holecardsOnly, false);
    });

    test('delay below 0 clamps to 0', () {
      final cfg = SecurityDelayConfig.fromConfigChanged({'delay_seconds': -5});
      expect(cfg.delaySeconds, 0);
    });

    test('delay above 600 clamps to 600', () {
      final cfg =
          SecurityDelayConfig.fromConfigChanged({'delay_seconds': 1200});
      expect(cfg.delaySeconds, 600);
    });

    test('delay as string is coerced', () {
      final cfg =
          SecurityDelayConfig.fromConfigChanged({'delay_seconds': '45'});
      expect(cfg.delaySeconds, 45);
    });

    test('unparsable delay becomes 0', () {
      final cfg =
          SecurityDelayConfig.fromConfigChanged({'delay_seconds': 'abc'});
      expect(cfg.delaySeconds, 0);
    });

    test('toJson round-trips via fromConfigChanged', () {
      const original = SecurityDelayConfig(
        enabled: true,
        delaySeconds: 120,
        holecardsOnly: true,
      );
      final parsed = SecurityDelayConfig.fromConfigChanged(original.toJson());
      expect(parsed, original);
    });
  });
}
