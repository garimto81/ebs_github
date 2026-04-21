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
    if (p == '/auth/login' && method == 'POST') return _ok(_mockToken);
    if (p == '/auth/refresh' && method == 'POST') return _ok(_mockToken);
    if (p == '/auth/verify-2fa' && method == 'POST') return _ok(_mockToken);
    if (p == '/auth/forgot-password' && method == 'POST') {
      return _ok({'message': 'Password reset email sent.'});
    }
    if (p == '/auth/verify-reset-code' && method == 'POST') {
      return _ok({'reset_token': 'mock-reset-token'});
    }
    if (p == '/auth/reset-password' && method == 'POST') {
      return _ok({'message': 'Password updated.'});
    }
    if (p == '/auth/google' && method == 'GET') {
      return _ok({..._mockToken, 'user': MockData.sessionUser.toJson()});
    }
    if (p == '/auth/google/callback' && method == 'GET') {
      return _ok({..._mockToken, 'user': MockData.sessionUser.toJson()});
    }
    if (p == '/auth/session' && method == 'GET') {
      return _ok({
        'user': MockData.sessionUser.toJson(),
        'session': MockData.sessionPayload,
      });
    }
    if (p == '/auth/session' && method == 'DELETE') {
      return _ok({'message': 'Logged out successfully'});
    }
    if (p == '/auth/2fa/setup' && method == 'POST') {
      return _ok({'secret': 'JBSWY3DPEHPK3PXP', 'qr_code_url': ''});
    }
    if (p == '/auth/2fa/confirm' && method == 'POST') {
      return _ok({'enabled': true});
    }
    if (p == '/auth/2fa/disable' && method == 'POST') {
      return _ok({'disabled': true});
    }

    // ---- Competitions ----
    if (p == '/competitions' && method == 'GET') {
      return _ok(MockData.competitions.map((c) => c.toJson()).toList());
    }

    // ---- Series ----
    if (p == '/series' && method == 'GET') {
      return _ok(MockData.series.map((s) => s.toJson()).toList());
    }
    final seriesMatch = _match(r'/series/(\d+)', p);
    if (seriesMatch != null && method == 'GET') {
      final id = int.parse(seriesMatch);
      final s = MockData.series.where((x) => x.seriesId == id).firstOrNull;
      return s != null ? _ok(s.toJson()) : _notFound();
    }
    if (p == '/series' && method == 'POST') {
      return _ok(MockData.series.first.toJson());
    }

    // ---- Events ----
    // GET /events/:id/flights
    final eventFlightsMatch = _match(r'/events/(\d+)/flights', p);
    if (eventFlightsMatch != null && method == 'GET') {
      final eventId = int.parse(eventFlightsMatch);
      final filtered = MockData.flights.where((f) => f.eventId == eventId);
      return _ok(filtered.map((f) => f.toJson()).toList());
    }
    if (eventFlightsMatch != null && method == 'POST') {
      return _ok(MockData.flights.first.toJson());
    }
    // GET /events/:id
    final eventMatch = _match(r'/events/(\d+)', p);
    if (eventMatch != null && method == 'GET') {
      final id = int.parse(eventMatch);
      final e = MockData.events.where((x) => x.eventId == id).firstOrNull;
      return e != null ? _ok(e.toJson()) : _notFound();
    }
    if (p == '/events' && method == 'GET') {
      var filtered = MockData.events;
      final seriesId = queryParams['series_id'];
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
    final rebalanceMatch = _match(r'/flights/(\d+)/rebalance', p);
    if (rebalanceMatch != null && method == 'POST') {
      return _ok({'moved': 3});
    }
    final flightMatch = _match(r'/flights/(\d+)', p);
    if (flightMatch != null && method == 'GET') {
      final id = int.parse(flightMatch);
      final f = MockData.flights.where((x) => x.eventFlightId == id).firstOrNull;
      return f != null ? _ok(f.toJson()) : _notFound();
    }
    if (p == '/flights' && method == 'GET') {
      return _ok(MockData.flights.map((f) => f.toJson()).toList());
    }

    // ---- Tables ----
    // POST /tables/:id/launch-cc
    final launchCcMatch = _match(r'/tables/(\d+)/launch-cc', p);
    if (launchCcMatch != null && method == 'POST') {
      return _ok({'url': 'about:blank'});
    }
    // GET /tables/:id/seats & POST /tables/:id/seats
    final seatsMatch = _match(r'/tables/(\d+)/seats', p);
    if (seatsMatch != null) {
      final tid = int.parse(seatsMatch);
      if (method == 'GET') {
        final filtered = _seats.where((s) => s['table_id'] == tid);
        return _ok(filtered.toList());
      }
      if (method == 'POST') {
        final body = _bodyMap(options);
        final playerId = body['player_id'] as int;
        final seatNo = body['seat_no'] as int;
        final player = MockData.players.where((p) => p.playerId == playerId).firstOrNull;
        final newSeat = <String, dynamic>{
          'seat_id': _seats.length + 1,
          'table_id': tid,
          'seat_no': seatNo,
          'player_id': playerId,
          'wsop_id': player?.wsopId ?? 'P-${playerId.toString().padLeft(5, '0')}',
          'player_name': player != null ? '${player.firstName} ${player.lastName}' : 'Unknown',
          'nationality': player?.nationality ?? '',
          'country_code': player?.countryCode ?? '',
          'chip_count': 20000,
          'profile_image': null,
          'status': 'occupied',
          'player_move_status': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        _seats.add(newSeat);
        return _ok(newSeat);
      }
    }
    // PUT /tables/:id
    final tableUpdateMatch = _match(r'/tables/(\d+)', p);
    if (tableUpdateMatch != null && method == 'PUT') {
      final id = int.parse(tableUpdateMatch);
      final idx = _tables.indexWhere((t) => t['table_id'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      _tables[idx] = {
        ..._tables[idx],
        ...body,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      return _ok(_tables[idx]);
    }
    // GET /tables/:id
    if (tableUpdateMatch != null && method == 'GET') {
      final id = int.parse(tableUpdateMatch);
      final t = _tables.where((x) => x['table_id'] == id).firstOrNull;
      return t != null ? _ok(t) : _notFound();
    }
    // POST /tables
    if (p == '/tables' && method == 'POST') {
      final body = _bodyMap(options);
      final newTable = <String, dynamic>{
        'table_id': _tables.length + 1,
        'event_flight_id': body['event_flight_id'],
        'table_no': body['table_no'],
        'name': body['name'],
        'type': body['type'] ?? 'general',
        'status': 'setup',
        'max_players': body['max_players'] ?? 9,
        'game_type': 0,
        'small_blind': body['small_blind'],
        'big_blind': body['big_blind'],
        'ante_type': 0,
        'ante_amount': body['ante_amount'] ?? 0,
        'rfid_reader_id': null,
        'deck_registered': false,
        'output_type': null,
        'current_game': null,
        'delay_seconds': 0,
        'ring': null,
        'is_breaking_table': false,
        'source': 'manual',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      _tables.add(newTable);
      return _ok(newTable);
    }
    if (p == '/tables' && method == 'GET') {
      final flightId = queryParams['flight_id'];
      final filtered = flightId != null
          ? _tables.where((t) => t['event_flight_id'] == int.tryParse(flightId))
          : _tables;
      return _ok(filtered.toList());
    }

    // ---- Players ----
    if (p == '/players/search' && method == 'GET') {
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
    final playerMatch = _match(r'/players/(\d+)', p);
    if (playerMatch != null && method == 'GET') {
      final id = int.parse(playerMatch);
      final pl = MockData.players.where((x) => x.playerId == id).firstOrNull;
      return pl != null ? _ok(pl.toJson()) : _notFound();
    }
    if (p == '/players' && method == 'GET') {
      return _ok(MockData.players.map((p) => p.toJson()).toList());
    }

    // ---- Users ----
    // POST /users/:id/force-logout
    final forceLogoutMatch = _match(r'/users/(\d+)/force-logout', p);
    if (forceLogoutMatch != null && method == 'POST') {
      final id = int.parse(forceLogoutMatch);
      final u = _users.where((x) => x['user_id'] == id).firstOrNull;
      return u != null ? _ok({'message': 'User logged out'}) : _notFound();
    }
    final userMatch = _match(r'/users/(\d+)', p);
    if (userMatch != null && method == 'GET') {
      final id = int.parse(userMatch);
      final u = _users.where((x) => x['user_id'] == id).firstOrNull;
      return u != null ? _ok(u) : _notFound();
    }
    if (userMatch != null && method == 'PUT') {
      final id = int.parse(userMatch);
      final idx = _users.indexWhere((u) => u['user_id'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      _users[idx] = {
        ..._users[idx],
        ...body,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      return _ok(_users[idx]);
    }
    if (userMatch != null && method == 'DELETE') {
      final id = int.parse(userMatch);
      final idx = _users.indexWhere((u) => u['user_id'] == id);
      if (idx < 0) return _notFound();
      _users.removeAt(idx);
      return _ok(null);
    }
    if (p == '/users' && method == 'GET') {
      return _ok(_users);
    }
    if (p == '/users' && method == 'POST') {
      final body = _bodyMap(options);
      final newUser = <String, dynamic>{
        'user_id': _users.length + 1,
        'email': body['email'],
        'display_name': body['display_name'],
        'role': body['role'],
        'is_active': body['is_active'] ?? true,
        'totp_enabled': false,
        'last_login_at': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      _users.add(newUser);
      return _ok(newUser);
    }

    // ---- Blind Structures ----
    if (p == '/blind-structures' && method == 'GET') {
      return _ok(MockData.blindStructures.map((b) => b.toJson()).toList());
    }

    // ---- Configs ----
    if (p == '/configs' && method == 'GET') {
      return _ok(_configs);
    }
    final configMatch = _match(r'/configs/([a-zA-Z_-]+)', p);
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
    if (p == '/skins/upload' && method == 'POST') {
      return _ok(_skins[1]);
    }
    // PUT /skins/:id/metadata
    final skinMetaMatch = _match(r'/skins/(\d+)/metadata', p);
    if (skinMetaMatch != null && method == 'PUT') {
      final id = int.parse(skinMetaMatch);
      final idx = _skins.indexWhere((s) => s['skin_id'] == id);
      if (idx < 0) return _notFound();
      final body = _bodyMap(options);
      final meta = _skins[idx]['metadata'] as Map<String, dynamic>;
      _skins[idx]['metadata'] = {...meta, ...body};
      return _ok(_skins[idx]);
    }
    // POST /skins/:id/activate
    final skinActivateMatch = _match(r'/skins/(\d+)/activate', p);
    if (skinActivateMatch != null && method == 'POST') {
      final id = int.parse(skinActivateMatch);
      final idx = _skins.indexWhere((s) => s['skin_id'] == id);
      if (idx < 0) return _notFound();
      for (var i = 0; i < _skins.length; i++) {
        if (_skins[i]['skin_id'] == id) {
          _skins[i]['status'] = 'active';
        } else if (_skins[i]['status'] == 'active') {
          _skins[i]['status'] = 'validated';
        }
      }
      return _ok(_skins[idx]);
    }
    // POST /skins/:id/deactivate
    final skinDeactivateMatch = _match(r'/skins/(\d+)/deactivate', p);
    if (skinDeactivateMatch != null && method == 'POST') {
      final id = int.parse(skinDeactivateMatch);
      final idx = _skins.indexWhere((s) => s['skin_id'] == id);
      if (idx < 0) return _notFound();
      _skins[idx]['status'] = 'validated';
      return _ok(_skins[idx]);
    }
    // GET /skins/:id
    final skinMatch = _match(r'/skins/(\d+)', p);
    if (skinMatch != null && method == 'GET') {
      final id = int.parse(skinMatch);
      final s = _skins.where((x) => x['skin_id'] == id).firstOrNull;
      return s != null ? _ok(s) : _notFound();
    }
    if (p == '/skins' && method == 'GET') {
      return _ok(_skins);
    }

    // ---- Hands ----
    // GET /hands/:id/players
    final handPlayersMatch = _match(r'/hands/(\d+)/players', p);
    if (handPlayersMatch != null && method == 'GET') {
      final id = int.parse(handPlayersMatch);
      final filtered = MockData.handPlayers.where((hp) => hp.handId == id);
      return _ok(filtered.map((hp) => hp.toJson()).toList());
    }
    // GET /hands/:id/actions
    final handActionsMatch = _match(r'/hands/(\d+)/actions', p);
    if (handActionsMatch != null && method == 'GET') {
      final id = int.parse(handActionsMatch);
      final filtered = MockData.handActions.where((ha) => ha.handId == id);
      return _ok(filtered.map((ha) => ha.toJson()).toList());
    }
    // GET /hands/:id
    final handMatch = _match(r'/hands/(\d+)', p);
    if (handMatch != null && method == 'GET') {
      final id = int.parse(handMatch);
      final h = MockData.hands.where((x) => x.handId == id).firstOrNull;
      return h != null ? _ok(h.toJson()) : _notFound();
    }
    if (p == '/hands' && method == 'GET') {
      final tableId = queryParams['table_id'];
      var filtered = MockData.hands;
      if (tableId != null) {
        final tid = int.tryParse(tableId);
        filtered = filtered.where((h) => h.tableId == tid).toList();
      }
      return _ok(filtered.map((h) => h.toJson()).toList());
    }

    // ---- Audit Logs ----
    if (p == '/audit-logs' && method == 'GET') {
      return _ok(MockData.auditLogs.map((a) => a.toJson()).toList());
    }

    // ---- WS Replay (CCR-021 gap recovery) ----
    if (p == '/ws/replay' && method == 'POST') {
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
    'access_token': 'mock-access-token',
    'token_type': 'bearer',
    'requires_2fa': false,
    'expires_in': 900,
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
