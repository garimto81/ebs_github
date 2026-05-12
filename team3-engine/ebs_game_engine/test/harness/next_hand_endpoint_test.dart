import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ebs_game_engine/harness/server.dart';

/// Cycle 5 v02 — POST /api/session/:id/next-hand endpoint tests (issue #287).
///
/// Verifies:
///   - 200 OK on existing session with handNumber++ and dealer rotation
///   - 404 on unknown session
///   - 6-seat round-robin: 6 calls return dealer to origin
///   - Heads-up: dealer toggles between 2 active seats
void main() {
  group('POST /api/session/:id/next-hand', () {
    late HarnessServer server;
    late int port;
    late HttpClient client;

    setUp(() async {
      server = HarnessServer(port: 0, host: '127.0.0.1');
      // ignore: unawaited_futures
      server.start();
      port = await _waitForBind(server);
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.stop();
    });

    test('404 on unknown session', () async {
      final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:$port/api/session/no-such-id/next-hand'));
      final res = await req.close();
      expect(res.statusCode, equals(404));
      await res.drain<void>();
    });

    test('6-seat: dealer rotates +1, handNumber++', () async {
      final sessionId = await _createSession(client, port, seats: 6);

      // Initial state via GET
      final initialState = await _getSession(client, port, sessionId);
      expect(initialState['handNumber'], equals(0));
      expect(initialState['dealerSeat'], equals(0));

      // POST /next-hand
      final nextReq = await client.postUrl(Uri.parse(
          'http://127.0.0.1:$port/api/session/$sessionId/next-hand'));
      final nextRes = await nextReq.close();
      expect(nextRes.statusCode, equals(200));

      final body = await nextRes.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['handNumber'], equals(1),
          reason: 'handNumber must increment 0 -> 1');
      expect(json['dealerSeat'], equals(1),
          reason: 'dealer must rotate 0 -> 1');
    });

    test('6-seat round-robin: 6 calls return dealer to origin', () async {
      final sessionId = await _createSession(client, port, seats: 6);

      final dealers = <int>[];
      for (var i = 0; i < 6; i++) {
        final nextReq = await client.postUrl(Uri.parse(
            'http://127.0.0.1:$port/api/session/$sessionId/next-hand'));
        final nextRes = await nextReq.close();
        expect(nextRes.statusCode, equals(200));
        final body = await nextRes.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        dealers.add(json['dealerSeat'] as int);
      }

      // After 6 calls on 6 seats: 1, 2, 3, 4, 5, 0 (back to start)
      expect(dealers, equals([1, 2, 3, 4, 5, 0]));

      // Final state: handNumber should be 6
      final finalState = await _getSession(client, port, sessionId);
      expect(finalState['handNumber'], equals(6));
    });

    test('seat.isDealer flag follows dealer rotation', () async {
      final sessionId = await _createSession(client, port, seats: 6);
      // After 1 next-hand: dealer = 1, so seat[1].isDealer = true
      final nextReq = await client.postUrl(Uri.parse(
          'http://127.0.0.1:$port/api/session/$sessionId/next-hand'));
      final nextRes = await nextReq.close();
      final body = await nextRes.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final seats = json['seats'] as List;
      for (var i = 0; i < seats.length; i++) {
        final seat = seats[i] as Map<String, dynamic>;
        expect(seat['isDealer'], equals(i == 1),
            reason: 'seat $i isDealer should be ${i == 1}');
      }
    });
  });
}

Future<String> _createSession(HttpClient client, int port,
    {required int seats}) async {
  final req = await client
      .postUrl(Uri.parse('http://127.0.0.1:$port/api/session'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({'variant': 'nlh', 'seats': seats}));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body) as Map<String, dynamic>;
  return json['sessionId'] as String;
}

Future<Map<String, dynamic>> _getSession(
    HttpClient client, int port, String sessionId) async {
  final req = await client
      .getUrl(Uri.parse('http://127.0.0.1:$port/api/session/$sessionId'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<int> _waitForBind(HarnessServer server) async {
  for (var i = 0; i < 100; i++) {
    final p = server.boundPort;
    if (p != null) return p;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('HarnessServer failed to bind within 1s');
}
