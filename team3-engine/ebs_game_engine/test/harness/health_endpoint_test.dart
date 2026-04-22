import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ebs_game_engine/harness/server.dart';

/// B-331 — GET /engine/health endpoint tests.
///
/// Verifies the Demo Mode fallback probe contract (Foundation §6.3):
/// - 200 OK with expected JSON schema
/// - `status`, `version`, `uptime_seconds`, `sessions_active`, `timestamp`
/// - CORS headers present (reuses /api/* pipeline)
void main() {
  group('GET /engine/health', () {
    late HarnessServer server;
    late int port;
    late HttpClient client;

    setUp(() async {
      // port: 0 → OS assigns an ephemeral port; boundPort yields the real one
      server = HarnessServer(port: 0, host: '127.0.0.1');
      // start() awaits its request-loop forever; fire-and-forget and poll bind.
      // ignore: unawaited_futures
      server.start();
      port = await _waitForBind(server);
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.stop();
    });

    test('returns 200 with expected schema', () async {
      final req = await client.getUrl(Uri.parse(
          'http://127.0.0.1:$port/engine/health'));
      final res = await req.close();
      expect(res.statusCode, equals(200));

      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['status'], equals('ok'));
      expect(json['version'], equals(engineHarnessVersion));
      expect(json['uptime_seconds'], isA<int>());
      expect(json['uptime_seconds'], greaterThanOrEqualTo(0));
      expect(json['sessions_active'], equals(0));
      expect(json['timestamp'], isA<String>());
      // ISO-8601 UTC ends with 'Z'
      expect((json['timestamp'] as String).endsWith('Z'), isTrue);
    });

    test('reflects active session count', () async {
      // Create one session via /api/session
      final createReq = await client.postUrl(Uri.parse(
          'http://127.0.0.1:$port/api/session'));
      createReq.headers.contentType = ContentType.json;
      createReq.write(jsonEncode({
        'variant': 'nlh',
        'seatCount': 3,
        'stacks': 1000,
      }));
      final createRes = await createReq.close();
      expect(createRes.statusCode, equals(201));
      await createRes.drain<void>();

      // Health should now report sessions_active == 1
      final req = await client.getUrl(Uri.parse(
          'http://127.0.0.1:$port/engine/health'));
      final res = await req.close();
      final json = jsonDecode(await res.transform(utf8.decoder).join())
          as Map<String, dynamic>;
      expect(json['sessions_active'], equals(1));
    });

    test('includes CORS header', () async {
      final req = await client.getUrl(Uri.parse(
          'http://127.0.0.1:$port/engine/health'));
      final res = await req.close();
      expect(res.headers.value('access-control-allow-origin'), equals('*'));
      await res.drain<void>();
    });
  });
}

/// Polls `server.boundPort` until non-null. HarnessServer.start() binds
/// asynchronously before entering its request-loop, so a short poll suffices.
Future<int> _waitForBind(HarnessServer server) async {
  for (var i = 0; i < 100; i++) {
    final p = server.boundPort;
    if (p != null) return p;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('HarnessServer failed to bind within 1s');
}
