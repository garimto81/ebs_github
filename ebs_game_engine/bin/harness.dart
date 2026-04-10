import 'dart:io';
import 'package:ebs_game_engine/harness/server.dart';

void main(List<String> args) async {
  int port = 8080;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? 8080;
    } else if (args[i].startsWith('--port=')) {
      port = int.tryParse(args[i].substring(7)) ?? 8080;
    }
  }

  // Detect Docker: if /app/web exists, use it; otherwise default
  final webDir = Directory('/app/web').existsSync() ? '/app/web' : 'lib/harness/web';
  final server = HarnessServer(port: port, webDir: webDir);

  // Graceful shutdown on SIGINT
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    await server.stop();
    exit(0);
  });

  await server.start();
}
