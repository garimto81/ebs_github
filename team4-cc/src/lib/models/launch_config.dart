// CC launch configuration (BS-05-00 §7 Launch Flow).
//
// Lobby spawns CC as a separate Flutter process, passing identity
// and connection details via command-line arguments:
//   --table_id=1 --token=<jwt> --cc_instance_id=<uuid> --ws_url=ws://host/ws/cc

import 'package:freezed_annotation/freezed_annotation.dart';

part 'launch_config.freezed.dart';

@freezed
class LaunchConfig with _$LaunchConfig {
  const factory LaunchConfig({
    required int tableId,
    required String token, // JWT launch token
    required String ccInstanceId, // UUID
    required String wsUrl, // ws://host/ws/cc
    @Default('http://localhost:8000') String boBaseUrl, // REST API base URL
  @Default(false) bool demoMode, // --demo flag (Demo_Test_Mode.md §1)
  }) = _LaunchConfig;

  /// Parse from command-line args.
  ///
  /// Supports both `--key=value` and `--key value` formats.
  /// Returns null if any required arg is missing or invalid.
  static LaunchConfig? tryFromArgs(List<String> args) {
    final map = <String, String>{};

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) continue;

      final eqIndex = arg.indexOf('=');
      if (eqIndex > 0) {
        // --key=value
        final key = arg.substring(2, eqIndex);
        final value = arg.substring(eqIndex + 1);
        map[key] = value;
      } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        // --key value
        final key = arg.substring(2);
        map[key] = args[i + 1];
        i++;
      }
    }

    final tableIdStr = map['table_id'];
    final token = map['token'];
    final ccInstanceId = map['cc_instance_id'];
    final wsUrl = map['ws_url'];

    final hasDemoFlag = args.contains('--demo');

    // In demo mode, required args are optional (auto-filled with defaults).
    if (hasDemoFlag) {
      return LaunchConfig(
        tableId: int.tryParse(tableIdStr ?? '1') ?? 1,
        token: token ?? 'demo-token',
        ccInstanceId: ccInstanceId ?? 'demo-instance',
        wsUrl: wsUrl ?? 'ws://localhost:8000/ws/cc',
        boBaseUrl: map['bo_base_url'] ?? 'http://localhost:8000',
        demoMode: true,
      );
    }

    if (tableIdStr == null || token == null || ccInstanceId == null || wsUrl == null) {
      return null;
    }

    final tableId = int.tryParse(tableIdStr);
    if (tableId == null) return null;

    return LaunchConfig(
      tableId: tableId,
      token: token,
      ccInstanceId: ccInstanceId,
      wsUrl: wsUrl,
      boBaseUrl: map['bo_base_url'] ?? 'http://localhost:8000',
    );
  }
}
