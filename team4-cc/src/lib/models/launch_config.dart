// CC launch configuration (BS-05-00 §7 Launch Flow).
//
// Lobby spawns CC as a separate Flutter process, passing identity
// and connection details via command-line arguments:
//   --table_id=1 --token=<jwt> --cc_instance_id=<uuid> --ws_url=ws://host/ws/cc

class LaunchConfig {
  const LaunchConfig({
    required this.tableId,
    required this.token,
    required this.ccInstanceId,
    required this.wsUrl,
    this.boBaseUrl = 'http://localhost:8000',
  });

  final int tableId;
  final String token; // JWT launch token
  final String ccInstanceId; // UUID
  final String wsUrl; // ws://host/ws/cc
  final String boBaseUrl; // REST API base URL

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
