import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ebs_game_engine/harness/server.dart';

/// Cycle 6 v03 — POST /api/session/:id/next-hand response 검증 (issue #310).
///
/// v02 (issue #287) 검증 위에 v03 신규 필드 정합 추가:
///   - handNumber, dealerSeat, sbSeat, bbSeat (rotation 정합)
///   - straddleEnabled, straddleSeat (활성 시 회전, heads-up 무효화)
///   - anteAmount, anteType (AnteOverride 적용 후 반영)
///   - runItTimes, runItBoard2Cards (RIT 미적용 시 null)
void main() {
  group('POST /api/session/:id/next-hand v03 response', () {
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

    test('response 에 v03 신규 필드 (sbSeat / bbSeat / runItBoard2Cards) 포함', () async {
      final sessionId = await _createSession(client, port, seats: 6);
      final json = await _postNextHand(client, port, sessionId);
      expect(json.containsKey('sbSeat'), isTrue);
      expect(json.containsKey('bbSeat'), isTrue);
      expect(json.containsKey('runItBoard2Cards'), isTrue);
      expect(json['runItBoard2Cards'], isNull,
          reason: 'RIT 미적용 시 runItBoard2Cards = null');
    });

    test('AnteOverride 후 next-hand response.anteAmount 반영', () async {
      final sessionId = await _createSession(client, port, seats: 6);

      // dispatch AnteOverride via POST /event
      final ev = await _postEvent(client, port, sessionId, {
        'type': 'ante_override',
        'amount': 100,
      });
      expect(ev['anteAmount'], 100,
          reason: 'AnteOverride 직후 anteAmount=100');

      // next-hand 후에도 유지
      final next = await _postNextHand(client, port, sessionId);
      expect(next['anteAmount'], 100,
          reason: 'next-hand 이후에도 anteAmount=100 유지 (영구 override)');
    });

    test('handNumber + dealer/sb/bb 정합 (v02 회귀)', () async {
      final sessionId = await _createSession(client, port, seats: 6);
      final next = await _postNextHand(client, port, sessionId);
      expect(next['handNumber'], 1);
      expect(next['dealerSeat'], 1);
      expect(next['sbSeat'], 2,
          reason: '6-seat: SB = dealer+1 = 2');
      expect(next['bbSeat'], 3,
          reason: '6-seat: BB = dealer+2 = 3');
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

Future<Map<String, dynamic>> _postNextHand(
    HttpClient client, int port, String sessionId) async {
  final req = await client.postUrl(Uri.parse(
      'http://127.0.0.1:$port/api/session/$sessionId/next-hand'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _postEvent(HttpClient client, int port,
    String sessionId, Map<String, dynamic> data) async {
  final req = await client.postUrl(Uri.parse(
      'http://127.0.0.1:$port/api/session/$sessionId/event'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(data));
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
