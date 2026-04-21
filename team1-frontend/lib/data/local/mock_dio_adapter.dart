// lib/data/local/mock_dio_adapter.dart — Dio HttpClientAdapter that returns
// mock responses. Replaces MSW from the Quasar codebase.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'mock_data.dart';

/// A [HttpClientAdapter] that intercepts all Dio requests and returns
/// canned responses from [MockData]. Attach to a Dio instance via
/// `dio.httpClientAdapter = MockDioAdapter();`.
class MockDioAdapter implements HttpClientAdapter {
  /// Simulated network delay.
  final Duration delay;

  /// Monotonically increasing mock WebSocket sequence counter.
  int _seq = 100;

  MockDioAdapter({this.delay = const Duration(milliseconds: 100)});

  // -- Mutable copies so POST/PUT/DELETE can mutate mock state --
  final List<Map<String, dynamic>> _tables =
      MockData.tables.map((t) => t.toJson()).toList();
  final List<Map<String, dynamic>> _seats =
      MockData.seats.map((s) => s.toJson()).toList();
  final List<Map<String, dynamic>> _users =
      MockData.users.map((u) => u.toJson()).toList();
  final List<Map<String, dynamic>> _skins =
      MockData.skins.map((s) => s.toJson()).toList();
  final Map<String, Map<String, dynamic>> _configs =
      Map<String, Map<String, dynamic>>.from(
    MockData.configs.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(delay);

    final path = options.path;
    final method = options.method.toUpperCase();

    final result = _route(method, path, options);
    final statusCode = result.$1;
    final body = result.$2;

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  (int, Map<String, dynamic>) _route(
    String method,
    String path,
    RequestOptions options,
  ) {
    // Strip base URL prefix if present (e.g. http://localhost:8000/api/v1/...)
    final uri = Uri.parse(path);
    var p = uri.path;
    // Normalise: remove trailing slash, collapse /api/v1 prefix
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    final prefixIdx = p.indexOf('/api/v1');
    if (prefixIdx >= 0) p = p.substring(prefixIdx + '/api/v1'.length);
    if (p.isEmpty) p = '/';

    final queryParams = uri.queryParameters.isNotEmpty
        ? uri.queryParameters
        : options.queryParameters.map((k, v) => MapEntry(k, v.toString()));

    // ---- Auth ----
    if (p == '/Auth/Login' && method == 'POST') return _ok(_mockToken);
    if (p == '/Auth/Refresh' && method == 'POST') return _ok(_mockToken);
    if (p == '/Auth/Verify2FA' && method == 'POST') return _ok(_mockToken);
    if (p == '/Auth/ForgotPassword' && method == 'POST') {
      return _ok({'message': 'Password reset email sent.'});
    }
    if (p == '/Auth/VerifyResetCode' && method == 'POST') {
      return _ok({'resetToken': 'mock-reset-token'});
    }
    if (p == '/Auth/ResetPassword' && method == 'POST') {
      return _ok({'message': 'Password updated.'});
    }
    if (p == '/Auth/Google' && method == 'GET') {
      return _ok({..._mockToken, 'user': MockData.sessionUser.toJson()});
    }
    if (p == '/Auth/Google/Callback' && method == 'GET') {
      return _ok({..._mockToken, 'user': MockData.sessionUser.toJson()});
    }
    if (p == '/Auth/Session' && method == 'GET') {
      return _ok({
        'user': MockData.sessionUser.toJson(),
        'session': MockData.sessionPayload,
      });
    }
    if (p == '/Auth/Session' && method == 'DELETE') {
      return _ok({'message': 'Logged out successfully'});
    }
    if (p == '/Auth/2FA/Setup' && method == 'POST') {
      return _ok({'secret': 'JBSWY3DPEHPK3PXP', 'qrCodeUrl': ''});
    }
    if (p == '/Auth/2FA/Confirm' && method == 'POST') {
      return _ok({'enabled': true});
    }
    if (p == '/Auth/2FA/Disable' && method == 'POST') {
      return _ok({'disabled': true});
    }

    // ---- Competitions ----
    if (p == '/Competitions' && method == 'GET') {
      return _ok(MockData.competitions.map((c) => c.toJson()).toList());
    }

    // ---- Series ----
    if (p == '/Series' && method == 'GET') {
      return _ok(MockData.series.map((s) => s.toJson()).toList());
    }
    final seriesMatch = _match(r'/Series/(\d+)', p);
    if (seriesMatch != null && method == 'GET') {
      final id = int.parse(seriesMatch);
      final s = MockData.series.where((x) => x.seriesId == id).firstOrNull;
      return s != null ? _ok(s.toJson()) : _notFound();
    }
    if (p == '/Series' && method == 'POST') {
      return _ok(MockData.series.first.toJson());
    }

    // ---- Events ----
    // GET /events/:id/flights
    final eventFlightsMatch = _match(r'/Events/(\d+)/Flights', p);
    if (eventFlightsMatch != null && method == 'GET') {
      final eventId = int.parse(eventFlightsMatch);
      final filtered = MockData.flights.where((f) => f.eventId == eventId);
      return _ok(filtered.map((f) => f.toJson()).toList());
    }
    if (eventFlightsMatch != null && method == 'POST') {
      return _ok(MockData.flights.first.toJson());
    }
    // GET /events/:id
    final eventMatch = _match(r'/Events/(\d+)', p);
    if (eventMatch != null && method == 'GET') {
      final id = int.parse(eventMatch);
      final e = MockData.events.where((x) => x.eventId == id).firstOrNull;
      return e != null ? _ok(e.toJson()) : _notFound();
    }
    if (p == '/Events' && method == 'GET') {
      var filtered = MockData.events;
      final seriesId = queryParams['seriesId'];
      if (seriesId != null) {
        final sid = int.tryParse(seriesId);
        filtered = filtered.where((e) => e.seriesId == sid).toList();
      }
      final status = queryParams['status'];
      if (status != null) {
        filtered = filtered.where((e) => e.status == status).toList();
      }
      return _ok(filtered.map((e) => e.toJson()).toList());
    }

    // ---- Flights ----
    // POST /flights/:id/rebalance
    final rebalanceMatch = _match(r'/Flights/(\d+)/Rebalance', p);
    if (rebalanceMatch != null && method == 'POST') {
      return _ok({'moved': 3});
    }
    final flightMatch = _match(r'/Flights/(\d+)', p);
    if (flightMatch != null && method == 'GET') {
      final id = int.parse(flightMatch);
      final f = MockData.flights.where((x) => x.eventFlightId == id).firstOrNull;
      return f != null ? _ok(f.toJson()) : _notFound();
    }
    if (p == '/Flights' && method == 'GET') {
      return _ok(MockData.flights.map((f) => f.toJson()).toList());
    }

    // ---- Tables ----
    // POST /tables/:id/launch-cc
    final launchCcMatch = _match(r'/Tables/(\d+)/LaunchCc', p);
    if (launchCcMatch != null && method == 'POST') {
      return _ok({'url': 'about:blank'});
    }
    // GET /tables/:id/seats & POST /tables/:id/seats
    final seatsMatch = _match(r'/Tables/(\d+)/Seats', p);
    if (seatsMatch != null) {
      final tid = int.parse(seatsMatch);
      if (method == 'GET') {
        final filtered = _seats.where((s) => s['tableId'] == tid);
        return _ok(filtered.toList());
      }
      if (method == 'POST') {
        final body = _bodyMap(options);
        final playerId = body['playerId'] as int;
        final seatNo = body['seatNo'] as int;
        final player = MockData.players.where((p) => p.playerId == playerId).firstOrNull;
        final newSeat = <String, dynamic>{
          'seatId': _seats.length + 1,
          'tableId': tid,
          'seatNo': seatNo,
          'playerId': playerId,
          'wsopId': player?.wsopId ?? 'P-${playerId.toString().padLeft(5, '0')}',
          'playerName': player != null ? '${player.firstName} ${player.lastName}' : 'Unknown',
          'nationality': player?.nationality ?? '',
          'countryCode': player?.countryCode ?? '',
          'chipCount': 20000,
          'profileImage': null,
          'status': 'occupied',
          'playerMoveStatus': null,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        _seats.add(newSeat);
        return _ok(newSeat);
      }
    }
    // PUT /tables/:id
    final tableUpdateMatch = _match(r'/Tables/(\d+)', p);
    if (tableUpdateMatch != null && method == 'PUT') {
      final id = int.parse(tableUpdateMatch);
      final idx = _tables.indexWhere((t) => t['tableId'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      _tables[idx] = {
        ..._tables[idx],
        ...body,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      return _ok(_tables[idx]);
    }
    // GET /tables/:id
    if (tableUpdateMatch != null && method == 'GET') {
      final id = int.parse(tableUpdateMatch);
      final t = _tables.where((x) => x['tableId'] == id).firstOrNull;
      return t != null ? _ok(t) : _notFound();
    }
    // POST /tables
    if (p == '/Tables' && method == 'POST') {
      final body = _bodyMap(options);
      final newTable = <String, dynamic>{
        'tableId': _tables.length + 1,
        'eventFlightId': body['eventFlightId'],
        'tableNo': body['tableNo'],
        'name': body['name'],
        'type': body['type'] ?? 'general',
        'status': 'setup',
        'maxPlayers': body['maxPlayers'] ?? 9,
        'gameType': 0,
        'smallBlind': body['smallBlind'],
        'bigBlind': body['bigBlind'],
        'anteType': 0,
        'anteAmount': body['anteAmount'] ?? 0,
        'rfidReaderId': null,
        'deckRegistered': false,
        'outputType': null,
        'currentGame': null,
        'delaySeconds': 0,
        'ring': null,
        'isBreakingTable': false,
        'source': 'manual',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      _tables.add(newTable);
      return _ok(newTable);
    }
    if (p == '/Tables' && method == 'GET') {
      final flightId = queryParams['flightId'];
      final filtered = flightId != null
          ? _tables.where((t) => t['eventFlightId'] == int.tryParse(flightId))
          : _tables;
      return _ok(filtered.toList());
    }

    // ---- Players ----
    if (p == '/Players/Search' && method == 'GET') {
      final q = (queryParams['q'] ?? '').toLowerCase();
      if (q.isEmpty) {
        return _ok(MockData.players.map((p) => p.toJson()).toList());
      }
      final filtered = MockData.players.where(
        (p) =>
            p.firstName.toLowerCase().contains(q) ||
            p.lastName.toLowerCase().contains(q),
      );
      return _ok(filtered.map((p) => p.toJson()).toList());
    }
    final playerMatch = _match(r'/Players/(\d+)', p);
    if (playerMatch != null && method == 'GET') {
      final id = int.parse(playerMatch);
      final pl = MockData.players.where((x) => x.playerId == id).firstOrNull;
      return pl != null ? _ok(pl.toJson()) : _notFound();
    }
    if (p == '/Players' && method == 'GET') {
      return _ok(MockData.players.map((p) => p.toJson()).toList());
    }

    // ---- Users ----
    // POST /users/:id/force-logout
    final forceLogoutMatch = _match(r'/Users/(\d+)/ForceLogout', p);
    if (forceLogoutMatch != null && method == 'POST') {
      final id = int.parse(forceLogoutMatch);
      final u = _users.where((x) => x['userId'] == id).firstOrNull;
      return u != null ? _ok({'message': 'User logged out'}) : _notFound();
    }
    final userMatch = _match(r'/Users/(\d+)', p);
    if (userMatch != null && method == 'GET') {
      final id = int.parse(userMatch);
      final u = _users.where((x) => x['userId'] == id).firstOrNull;
      return u != null ? _ok(u) : _notFound();
    }
    if (userMatch != null && method == 'PUT') {
      final id = int.parse(userMatch);
      final idx = _users.indexWhere((u) => u['userId'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      _users[idx] = {
        ..._users[idx],
        ...body,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      return _ok(_users[idx]);
    }
    if (userMatch != null && method == 'DELETE') {
      final id = int.parse(userMatch);
      final idx = _users.indexWhere((u) => u['userId'] == id);
      if (idx < 0) return _notFound();
      _users.removeAt(idx);
      return _ok(null);
    }
    if (p == '/Users' && method == 'GET') {
      return _ok(_users);
    }
    if (p == '/Users' && method == 'POST') {
      final body = _bodyMap(options);
      final newUser = <String, dynamic>{
        'userId': _users.length + 1,
        'email': body['email'],
        'displayName': body['displayName'],
        'role': body['role'],
        'isActive': body['isActive'] ?? true,
        'totpEnabled': false,
        'lastLoginAt': null,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      _users.add(newUser);
      return _ok(newUser);
    }

    // ---- Blind Structures ----
    if (p == '/BlindStructures' && method == 'GET') {
      return _ok(MockData.blindStructures.map((b) => b.toJson()).toList());
    }

    // ---- Configs ----
    if (p == '/Configs' && method == 'GET') {
      return _ok(_configs);
    }
    final configMatch = _match(r'/Configs/([a-zA-Z_-]+)', p);
    if (configMatch != null && method == 'GET') {
      return _ok(_configs[configMatch] ?? <String, dynamic>{});
    }
    if (configMatch != null && method == 'PUT') {
      final body = _bodyMap(options);
      _configs[configMatch] = {
        ...(_configs[configMatch] ?? <String, dynamic>{}),
        ...body,
      };
      return _ok(_configs[configMatch]!);
    }

    // ---- Skins ----
    // POST /skins/upload
    if (p == '/Skins/Upload' && method == 'POST') {
      return _ok(_skins[1]);
    }
    // PUT /skins/:id/metadata
    final skinMetaMatch = _match(r'/Skins/(\d+)/Metadata', p);
    if (skinMetaMatch != null && method == 'PUT') {
      final id = int.parse(skinMetaMatch);
      final idx = _skins.indexWhere((s) => s['skinId'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      final meta = _skins[idx]['metadata'] as Map<String, dynamic>;
      _skins[idx]['metadata'] = {...meta, ...body};
      return _ok(_skins[idx]);
    }
    // POST /skins/:id/activate
    final skinActivateMatch = _match(r'/Skins/(\d+)/Activate', p);
    if (skinActivateMatch != null && method == 'POST') {
      final id = int.parse(skinActivateMatch);
      final idx = _skins.indexWhere((s) => s['skinId'] == id);
      if (idx < 0) return _notFound();
      for (var i = 0; i < _skins.length; i++) {
        if (_skins[i]['skinId'] == id) {
          _skins[i]['status'] = 'active';
        } else if (_skins[i]['status'] == 'active') {
          _skins[i]['status'] = 'validated';
        }
      }
      return _ok(_skins[idx]);
    }
    // POST /skins/:id/deactivate
    final skinDeactivateMatch = _match(r'/Skins/(\d+)/Deactivate', p);
    if (skinDeactivateMatch != null && method == 'POST') {
      final id = int.parse(skinDeactivateMatch);
      final idx = _skins.indexWhere((s) => s['skinId'] == id);
      if (idx < 0) return _notFound();
      _skins[idx]['status'] = 'validated';
      return _ok(_skins[idx]);
    }
    // GET /skins/:id
    final skinMatch = _match(r'/Skins/(\d+)', p);
    if (skinMatch != null && method == 'GET') {
      final id = int.parse(skinMatch);
      final s = _skins.where((x) => x['skinId'] == id).firstOrNull;
      return s != null ? _ok(s) : _notFound();
    }
    if (p == '/Skins' && method == 'GET') {
      return _ok(_skins);
    }

    // ---- Hands ----
    // GET /hands/:id/players
    final handPlayersMatch = _match(r'/Hands/(\d+)/Players', p);
    if (handPlayersMatch != null && method == 'GET') {
      final id = int.parse(handPlayersMatch);
      final filtered = MockData.handPlayers.where((hp) => hp.handId == id);
      return _ok(filtered.map((hp) => hp.toJson()).toList());
    }
    // GET /hands/:id/actions
    final handActionsMatch = _match(r'/Hands/(\d+)/Actions', p);
    if (handActionsMatch != null && method == 'GET') {
      final id = int.parse(handActionsMatch);
      final filtered = MockData.handActions.where((ha) => ha.handId == id);
      return _ok(filtered.map((ha) => ha.toJson()).toList());
    }
    // GET /hands/:id
    final handMatch = _match(r'/Hands/(\d+)', p);
    if (handMatch != null && method == 'GET') {
      final id = int.parse(handMatch);
      final h = MockData.hands.where((x) => x.handId == id).firstOrNull;
      return h != null ? _ok(h.toJson()) : _notFound();
    }
    if (p == '/Hands' && method == 'GET') {
      final tableId = queryParams['tableId'];
      var filtered = MockData.hands;
      if (tableId != null) {
        final tid = int.tryParse(tableId);
        filtered = filtered.where((h) => h.tableId == tid).toList();
      }
      return _ok(filtered.map((h) => h.toJson()).toList());
    }

    // ---- Audit Logs ----
    if (p == '/AuditLogs' && method == 'GET') {
      return _ok(MockData.auditLogs.map((a) => a.toJson()).toList());
    }

    // ---- WS Replay (CCR-021 gap recovery) ----
    if (p == '/Ws/Replay' && method == 'POST') {
      return _ok({'events': <dynamic>[]});
    }

    // ---- Fallback for unmatched mutations ----
    if (method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE') {
      return _ok(null);
    }

    return _notFound('No mock handler for $method $p');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static const _mockToken = <String, dynamic>{
    'accessToken': 'mock-access-token',
    'tokenType': 'bearer',
    'requires2fa': false,
    'expiresIn': 900,
  };

  /// Wrap data in the standard API envelope.
  (int, Map<String, dynamic>) _ok(Object? data) {
    return (200, {'data': data, 'error': null});
  }

  (int, Map<String, dynamic>) _notFound([String message = 'Not found']) {
    return (
      404,
      {
        'data': null,
        'error': {'code': 'NOT_FOUND', 'message': message},
      }
    );
  }

  /// Extract the first regex capture group from [path], or null.
  String? _match(String pattern, String path) {
    final re = RegExp('^$pattern\$');
    final m = re.firstMatch(path);
    return m?.group(1);
  }

  /// Extract body map from request options (Dio stores it in `options.data`).
  Map<String, dynamic> _bodyMap(RequestOptions options) {
    final data = options.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  /// Generate a mock WS event frame (used for rebalance simulation if needed).
  Map<String, dynamic> makeWsFrame(String event, Object? payload) {
    return {
      'seq': ++_seq,
      'channel': 'lobby',
      'event': event,
      'payload': payload,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
