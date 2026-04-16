// LaunchConfig.tryFromArgs — CLI argument parsing (BS-05-00 §7).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/models/launch_config.dart';

void main() {
  group('LaunchConfig.tryFromArgs', () {
    test('parses --key=value format', () {
      final config = LaunchConfig.tryFromArgs([
        '--table_id=1',
        '--token=jwt-abc',
        '--cc_instance_id=uuid-123',
        '--ws_url=ws://localhost/ws/cc',
      ]);

      expect(config, isNotNull);
      expect(config!.tableId, 1);
      expect(config.token, 'jwt-abc');
      expect(config.ccInstanceId, 'uuid-123');
      expect(config.wsUrl, 'ws://localhost/ws/cc');
      expect(config.boBaseUrl, 'http://localhost:8000'); // default
    });

    test('parses --key value format', () {
      final config = LaunchConfig.tryFromArgs([
        '--table_id', '5',
        '--token', 'tok',
        '--cc_instance_id', 'uid',
        '--ws_url', 'ws://host/ws',
      ]);

      expect(config, isNotNull);
      expect(config!.tableId, 5);
    });

    test('accepts optional bo_base_url', () {
      final config = LaunchConfig.tryFromArgs([
        '--table_id=1',
        '--token=t',
        '--cc_instance_id=u',
        '--ws_url=ws://h',
        '--bo_base_url=http://custom:9000',
      ]);

      expect(config!.boBaseUrl, 'http://custom:9000');
    });

    test('returns null when required arg missing', () {
      // Missing --ws_url
      final config = LaunchConfig.tryFromArgs([
        '--table_id=1',
        '--token=t',
        '--cc_instance_id=u',
      ]);
      expect(config, isNull);
    });

    test('returns null when table_id is not a number', () {
      final config = LaunchConfig.tryFromArgs([
        '--table_id=abc',
        '--token=t',
        '--cc_instance_id=u',
        '--ws_url=ws://h',
      ]);
      expect(config, isNull);
    });

    test('returns null for empty args', () {
      expect(LaunchConfig.tryFromArgs([]), isNull);
    });

    test('mixed format args work', () {
      final config = LaunchConfig.tryFromArgs([
        '--table_id=3',
        '--token', 'mixed-token',
        '--cc_instance_id=uid',
        '--ws_url', 'ws://mixed',
      ]);

      expect(config, isNotNull);
      expect(config!.tableId, 3);
      expect(config.token, 'mixed-token');
      expect(config.wsUrl, 'ws://mixed');
    });
  });

  group('LaunchConfig equality (Freezed)', () {
    test('same args produce equal configs', () {
      final a = LaunchConfig.tryFromArgs([
        '--table_id=1', '--token=t', '--cc_instance_id=u', '--ws_url=ws://h',
      ]);
      final b = LaunchConfig.tryFromArgs([
        '--table_id=1', '--token=t', '--cc_instance_id=u', '--ws_url=ws://h',
      ]);
      expect(a, equals(b));
    });
  });
}
