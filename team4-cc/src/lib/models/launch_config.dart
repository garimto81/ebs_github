// CC launch configuration (BS-05-00 §7 Launch Flow).
//
// Lobby spawns CC with identity + connection details:
//   - Desktop: command-line args (--table_id=1 --token=<jwt> ...)
//   - Web (SG-008-b11 v1.3): URL query params (?table_id=1&token=<jwt>&cc_instance_id=...)

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
    @Default('http://localhost:8080') String engineUrl, // Game Engine harness
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
        engineUrl: map['engine_url'] ?? 'http://localhost:8080',
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
      engineUrl: map['engine_url'] ?? 'http://localhost:8080',
    );
  }

  /// SG-008-b11 v1.3 (2026-05-03 — Web variant) — Parse from URL query map.
  ///
  /// Lobby launch-cc response cc_url is `http://<host>:3001/?table_id=N&token=...&cc_instance_id=...`.
  /// In Flutter Web, `Uri.base.queryParameters` exposes these. CC main() falls back to
  /// this when CLI args are empty (web build).
  ///
  /// Returns null if any required param is missing (preserving existing dev standalone
  /// flow where CC opens at http://cc-web:3001/ without query → manual login form).
  static LaunchConfig? tryFromQuery(Map<String, String> query) {
    final tableIdStr = query['table_id'];
    final token = query['token'];
    final ccInstanceId = query['cc_instance_id'];
    if (tableIdStr == null || token == null || ccInstanceId == null) {
      // Demo flag fallback (mirrors tryFromArgs semantics).
      if (query['demo'] == 'true' || query['demo'] == '1') {
        return LaunchConfig(
          tableId: int.tryParse(tableIdStr ?? '1') ?? 1,
          token: token ?? 'demo-token',
          ccInstanceId: ccInstanceId ?? 'demo-instance',
          wsUrl: query['ws_url'] ?? 'ws://localhost:8000/ws/cc',
          boBaseUrl: query['bo_base_url'] ?? 'http://localhost:8000',
          engineUrl: query['engine_url'] ?? 'http://localhost:8080',
          demoMode: true,
        );
      }
      return null;
    }

    final tableId = int.tryParse(tableIdStr);
    if (tableId == null) return null;

    // ws_url 미지정 시 BO host 추론 — bo_base_url 또는 호환 default.
    final boBase = query['bo_base_url'] ?? 'http://localhost:8000';
    final wsBase = boBase.replaceFirst(RegExp(r'^http'), 'ws');
    final wsUrl = query['ws_url'] ??
        '$wsBase/ws/cc?table_id=$tableId&token=$token&cc_instance_id=$ccInstanceId';

    return LaunchConfig(
      tableId: tableId,
      token: token,
      ccInstanceId: ccInstanceId,
      wsUrl: wsUrl,
      boBaseUrl: boBase,
      engineUrl: query['engine_url'] ?? 'http://localhost:8080',
    );
  }
}
