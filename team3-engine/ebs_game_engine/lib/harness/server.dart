import 'dart:io';
import 'dart:convert';

import '../core/state/game_state.dart';
import '../core/state/seat.dart';
import '../core/state/card_reveal_config.dart';
import '../core/cards/card.dart';
import '../core/actions/event.dart';
import '../core/actions/action.dart';
import '../core/math/equity_calculator.dart';
import '../core/rules/showdown_order.dart';
import '../core/variants/variants.dart';
import '../engine.dart' show Engine;
import 'session.dart';
import 'scenario_loader.dart';

/// Engine harness version. Kept in sync with `pubspec.yaml`. Exposed via
/// `GET /engine/health` so CC (team4) Demo Mode fallback can inspect it
/// (Foundation §6.3, B-331).
const String engineHarnessVersion = '0.1.0';

/// HTTP harness server — REST API + static file serving.
class HarnessServer {
  final int port;
  final String webDir;
  final String scenariosDir;

  final String host;
  final Map<String, Session> _sessions = {};
  HttpServer? _server;
  DateTime? _startedAt;

  HarnessServer({
    required this.port,
    this.host = '0.0.0.0',
    this.webDir = 'lib/harness/web',
    this.scenariosDir = 'scenarios',
  });

  /// Session count accessor (test-only exposure; health endpoint uses
  /// `_sessions.length` directly).
  int get sessionsActive => _sessions.length;

  /// Actually bound port (differs from [port] when constructor receives 0,
  /// in which case the OS assigns an ephemeral port). Null before [start].
  int? get boundPort => _server?.port;

  Future<void> start() async {
    _server = await HttpServer.bind(host, port);
    _startedAt = DateTime.now();
    print('HarnessServer listening on http://$host:$port');
    await for (final req in _server!) {
      try {
        await _handle(req);
      } catch (e, st) {
        stderr.writeln('Error handling ${req.uri}: $e\n$st');
        _sendJson(req.response, 500, {'error': e.toString()});
      }
    }
  }

  Future<void> stop() async => await _server?.close(force: true);

  // ── Request router ──────────────────────────────────────────────────────────

  Future<void> _handle(HttpRequest req) async {
    _setCors(req.response);

    // Handle preflight
    if (req.method == 'OPTIONS') {
      req.response
        ..statusCode = 204
        ..close();
      return;
    }

    final path = req.uri.path;
    final method = req.method;

    // GET /health — liveness probe (Docker HEALTHCHECK + Compose 의존성 게이트)
    // 2026-04-28 — P2 추가. canonical 응답 = {"status":"ok","service":"ebs-game-engine"}.
    // 이전: docker-compose engine.healthcheck 가 `/` (200) 로 cosmetic fix → 본 commit
    // 으로 표준 `/health` 로 정렬. lobby-web/cc-web 의 `/healthz` 와 의도 동일.
    if (method == 'GET' && path == '/health') {
      _sendJson(req.response, 200, const {
        'status': 'ok',
        'service': 'ebs-game-engine',
      });
      return;
    }

    // POST /api/session
    if (method == 'POST' && path == '/api/session') {
      await _createSession(req);
      return;
    }

    // GET /api/session/:id
    final getSessionMatch = RegExp(r'^/api/session/([^/]+)$').firstMatch(path);
    if (method == 'GET' && getSessionMatch != null) {
      await _getSession(req, getSessionMatch.group(1)!);
      return;
    }

    // POST /api/session/:id/event
    final eventMatch =
        RegExp(r'^/api/session/([^/]+)/event$').firstMatch(path);
    if (method == 'POST' && eventMatch != null) {
      await _addEvent(req, eventMatch.group(1)!);
      return;
    }

    // POST /api/session/:id/next-hand
    // Convenience over POST /event with type=manual_next_hand. Triggers
    // button + SB/BB rotation, handNumber++, hole/community/pot reset.
    // Cycle 5 v02 issue #287.
    final nextHandMatch =
        RegExp(r'^/api/session/([^/]+)/next-hand$').firstMatch(path);
    if (method == 'POST' && nextHandMatch != null) {
      await _nextHand(req, nextHandMatch.group(1)!);
      return;
    }

    // POST /api/session/:id/undo
    final undoMatch = RegExp(r'^/api/session/([^/]+)/undo$').firstMatch(path);
    if (method == 'POST' && undoMatch != null) {
      await _undoEvent(req, undoMatch.group(1)!);
      return;
    }

    // POST /api/session/:id/save
    final saveMatch = RegExp(r'^/api/session/([^/]+)/save$').firstMatch(path);
    if (method == 'POST' && saveMatch != null) {
      await _saveSession(req, saveMatch.group(1)!);
      return;
    }

    // GET /api/scenarios
    if (method == 'GET' && path == '/api/scenarios') {
      await _listScenarios(req);
      return;
    }

    // POST /api/scenarios/:name/load
    final loadMatch =
        RegExp(r'^/api/scenarios/([^/]+)/load$').firstMatch(path);
    if (method == 'POST' && loadMatch != null) {
      await _loadScenario(req, loadMatch.group(1)!);
      return;
    }

    // GET /api/session/:id/equity
    final equityMatch =
        RegExp(r'^/api/session/([^/]+)/equity$').firstMatch(path);
    if (method == 'GET' && equityMatch != null) {
      await _getEquity(req, equityMatch.group(1)!);
      return;
    }

    // GET /api/session/:id/validate
    final validateMatch =
        RegExp(r'^/api/session/([^/]+)/validate$').firstMatch(path);
    if (method == 'GET' && validateMatch != null) {
      await _validateCards(req, validateMatch.group(1)!);
      return;
    }

    // GET /api/session/:id/showdown-order
    final showdownOrderMatch =
        RegExp(r'^/api/session/([^/]+)/showdown-order$').firstMatch(path);
    if (method == 'GET' && showdownOrderMatch != null) {
      await _getShowdownOrder(req, showdownOrderMatch.group(1)!);
      return;
    }

    // GET /api/session/:id/runout-check
    final runoutMatch =
        RegExp(r'^/api/session/([^/]+)/runout-check$').firstMatch(path);
    if (method == 'GET' && runoutMatch != null) {
      await _getRunoutCheck(req, runoutMatch.group(1)!);
      return;
    }

    // GET /api/variants
    if (method == 'GET' && path == '/api/variants') {
      _sendJson(req.response, 200, {'variants': variantRegistry.keys.toList()});
      return;
    }

    // GET /engine/health (B-331 — team4 Demo Mode fallback probe)
    if (method == 'GET' && path == '/engine/health') {
      _handleHealth(req);
      return;
    }

    // Static file serving
    await _serveStatic(req);
  }

  /// Health probe — used by team4 CC `engine_connection_provider` for
  /// 3-stage Demo Mode fallback (Foundation §6.3).
  void _handleHealth(HttpRequest req) {
    final now = DateTime.now();
    final uptime = _startedAt == null
        ? 0
        : now.difference(_startedAt!).inSeconds;
    _sendJson(req.response, 200, {
      'status': 'ok',
      'version': engineHarnessVersion,
      'uptime_seconds': uptime,
      'sessions_active': _sessions.length,
      'timestamp': now.toUtc().toIso8601String(),
    });
  }

  // ── API handlers ────────────────────────────────────────────────────────────

  Future<void> _createSession(HttpRequest req) async {
    final body = await _readBody(req);
    final data = jsonDecode(body) as Map<String, dynamic>;

    final variantName = data['variant'] as String? ?? 'nlh';
    final factory = variantRegistry[variantName];
    if (factory == null) {
      _sendJson(req.response, 400, {'error': 'Unknown variant: $variantName'});
      return;
    }
    final variant = factory();

    final seatCount = (data['seatCount'] as num?)?.toInt() ?? 6;
    final stacksRaw = data['stacks'];
    final blindsRaw = data['blinds'] as Map<String, dynamic>? ?? {};
    final dealerSeat = (data['dealerSeat'] as num?)?.toInt() ?? 0;
    final seed = (data['seed'] as num?)?.toInt();

    // Build stacks list
    final List<int> stacks;
    if (stacksRaw is List) {
      stacks = stacksRaw.map((e) => (e as num).toInt()).toList();
    } else {
      stacks = List.filled(seatCount, (stacksRaw as num?)?.toInt() ?? 1000);
    }

    // Build blinds map — supports both {sb:5, bb:10} and {"1":5, "2":10}
    final Map<int, int> blinds = {};
    final n = stacks.length;
    if (blindsRaw.containsKey('sb') || blindsRaw.containsKey('bb')) {
      final sbAmt = (blindsRaw['sb'] as num?)?.toInt() ?? 5;
      final bbAmt = (blindsRaw['bb'] as num?)?.toInt() ?? 10;
      final sbIdx = (dealerSeat + 1) % n;
      final bbIdx = (dealerSeat + 2) % n;
      blinds[sbIdx] = sbAmt;
      blinds[bbIdx] = bbAmt;
    } else if (blindsRaw.isNotEmpty) {
      blindsRaw.forEach((k, v) {
        final parsed = int.tryParse(k);
        if (parsed != null) blinds[parsed] = (v as num).toInt();
      });
    }

    if (blinds.isEmpty) {
      final sbIdx = (dealerSeat + 1) % n;
      final bbIdx = (dealerSeat + 2) % n;
      blinds[sbIdx] = 5;
      blinds[bbIdx] = 10;
    }

    final deck = variant.createDeck(seed: seed);
    final seats = List.generate(
      stacks.length,
      (i) => Seat(
        index: i,
        label: 'Seat ${i + 1}',
        stack: stacks[i],
        isDealer: i == dealerSeat,
      ),
    );

    // Read optional H2 config
    final config = data['config'] as Map<String, dynamic>? ?? {};

    final initial = GameState(
      sessionId: _newId(),
      variantName: variant.name,
      seats: seats,
      deck: deck,
      dealerSeat: dealerSeat,
      anteType: (config['anteType'] as num?)?.toInt(),
      anteAmount: (config['anteAmount'] as num?)?.toInt(),
      straddleEnabled: config['straddleEnabled'] as bool? ?? false,
      straddleSeat: (config['straddleSeat'] as num?)?.toInt(),
      bombPotEnabled: config['bombPotEnabled'] as bool? ?? false,
      bombPotAmount: (config['bombPotAmount'] as num?)?.toInt(),
      canvasType: _parseCanvasType(config['canvasType'] as String?),
      sevenDeuceEnabled: config['sevenDeuceEnabled'] as bool? ?? false,
      sevenDeuceAmount: (config['sevenDeuceAmount'] as num?)?.toInt(),
      actionTimeoutMs: (config['actionTimeoutMs'] as num?)?.toInt(),
    );

    final session = Session(id: initial.sessionId, variant: variant, initial: initial);
    _sessions[session.id] = session;

    // Auto-start: HandStart event
    session.addEvent(HandStart(dealerSeat: dealerSeat, blinds: blinds));

    // DealHoleCards — draw from deck
    final holeMap = <int, List<Card>>{};
    final state = session.currentState;
    for (final seat in state.seats) {
      if (seat.isActive || seat.isAllIn) {
        holeMap[seat.index] = [];
      }
    }
    // Deal one card at a time around the table twice
    for (var round = 0; round < variant.holeCardCount; round++) {
      for (final idx in holeMap.keys) {
        holeMap[idx]!.add(state.deck.draw());
      }
    }
    session.addEvent(DealHoleCards(holeMap));

    // Preflop community (Courchevel)
    if (variant.preflopCommunityCount > 0) {
      final community = <Card>[];
      for (var i = 0; i < variant.preflopCommunityCount; i++) {
        community.add(session.currentState.deck.draw());
      }
      session.addEvent(DealCommunity(community));
    }

    _sendJson(req.response, 201, session.toJson());
  }

  Future<void> _getSession(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }
    final cursorParam = req.uri.queryParameters['cursor'];
    final cursor = cursorParam != null ? int.tryParse(cursorParam) : null;
    _sendJson(req.response, 200, session.toJson(cursor: cursor));
  }

  Future<void> _addEvent(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }

    final body = await _readBody(req);
    final data = jsonDecode(body) as Map<String, dynamic>;

    final type = data['type'] as String? ?? '';
    final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
    final amount = (data['amount'] as num?)?.toInt() ?? 0;

    Event event;
    switch (type) {
      case 'fold':
        event = PlayerAction(seatIndex, const Fold());
      case 'check':
        event = PlayerAction(seatIndex, const Check());
      case 'call':
        event = PlayerAction(seatIndex, Call(amount));
      case 'bet':
        event = PlayerAction(seatIndex, Bet(amount));
      case 'raise':
        event = PlayerAction(seatIndex, Raise(amount));
      case 'allin':
        event = PlayerAction(seatIndex, AllIn(amount));
      case 'street_advance':
        final next = _parseStreet(data['next'] as String? ?? 'flop');
        event = StreetAdvance(next);
      case 'deal_community':
        final cardsRaw = (data['cards'] as List).cast<String>();
        event = DealCommunity(cardsRaw.map(Card.parse).toList());
      case 'deal_hole':
        final cardsRaw = data['cards'] as Map<String, dynamic>;
        final holeMap = <int, List<Card>>{};
        cardsRaw.forEach((k, v) {
          holeMap[int.parse(k)] =
              (v as List).map((c) => Card.parse(c as String)).toList();
        });
        event = DealHoleCards(holeMap);
      case 'pot_awarded':
        final awardsRaw = data['awards'] as Map<String, dynamic>;
        final awards = <int, int>{};
        awardsRaw.forEach((k, v) => awards[int.parse(k)] = (v as num).toInt());
        event = PotAwarded(awards);
      case 'hand_end':
        event = const HandEnd();
      case 'misdeal':
        event = const MisDeal();
      case 'bomb_pot_config':
        event = BombPotConfig((data['amount'] as num).toInt());
      case 'run_it_choice':
        event = RunItChoice((data['times'] as num).toInt());
      case 'manual_next_hand':
        event = const ManualNextHand();
      case 'ante_override':
        // amount: 변경할 ante 금액, anteType: optional ante type (0-6)
        // 주의: top-level 'type' 은 event routing 용이므로 안티 타입은 'anteType' 필드로 받는다.
        final overrideAmount = (data['amount'] as num).toInt();
        final t = data['anteType'];
        event = AnteOverride(
          amount: overrideAmount,
          type: t == null ? null : (t as num).toInt(),
        );
      case 'timeout_fold':
        event = TimeoutFold(seatIndex);
      case 'muck':
        final show = data['showCards'] as bool? ?? true;
        event = MuckDecision(seatIndex, showCards: show);
      case 'pineapple_discard':
        event = PineappleDiscard(seatIndex, Card.parse(data['card'] as String));
      default:
        _sendJson(req.response, 400, {'error': 'Unknown event type: $type'});
        return;
    }

    session.addEvent(event);
    _sendJson(req.response, 200, session.toJson());
  }

  /// POST /api/session/:id/next-hand — convenience wrapper that emits a
  /// ManualNextHand event. Triggers dealer/SB/BB rotation, handNumber++,
  /// and per-hand state reset (community/hole/pot). The response is the
  /// post-rotation session JSON.
  ///
  /// Returns 404 if session not found, 200 with full session state on
  /// success.
  ///
  /// Spec: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_State.md
  /// Cycle 5 v02 issue #287.
  Future<void> _nextHand(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }
    session.addEvent(const ManualNextHand());
    _sendJson(req.response, 200, session.toJson());
  }

  Future<void> _undoEvent(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }
    session.undo();
    _sendJson(req.response, 200, session.toJson());
  }

  Future<void> _saveSession(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }
    final dir = Directory(scenariosDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = '$scenariosDir/$id.yaml';
    await ScenarioLoader.save(session, path);
    _sendJson(req.response, 200, {'saved': path});
  }

  Future<void> _listScenarios(HttpRequest req) async {
    final dir = Directory(scenariosDir);
    final files = <String>[];
    if (dir.existsSync()) {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.endsWith('.yaml')) {
          files.add(entity.uri.pathSegments.last.replaceAll('.yaml', ''));
        }
      }
    }
    _sendJson(req.response, 200, {'scenarios': files});
  }

  Future<void> _loadScenario(HttpRequest req, String name) async {
    final path = '$scenariosDir/$name.yaml';
    final file = File(path);
    if (!file.existsSync()) {
      _sendJson(req.response, 404, {'error': 'Scenario not found: $name'});
      return;
    }

    final scenario = await ScenarioLoader.loadFile(path);
    final variantName = scenario.variant;
    final factory = variantRegistry[variantName];
    if (factory == null) {
      _sendJson(req.response, 400, {'error': 'Unknown variant: $variantName'});
      return;
    }
    final variant = factory();

    final dealer = scenario.dealer;
    final seatCount = scenario.seats.length;
    final seats = List.generate(seatCount, (i) {
      final seatData = scenario.seats[i];
      return Seat(
        index: i,
        label: seatData['label'] as String? ?? 'Seat ${i + 1}',
        stack: (seatData['stack'] as num?)?.toInt() ?? 1000,
        isDealer: i == dealer,
      );
    });

    final sb = scenario.blinds['sb'] ?? 5;
    final bb = scenario.blinds['bb'] ?? 10;
    final sbIdx = (dealer + 1) % seatCount;
    final bbIdx = (dealer + 2) % seatCount;
    final blinds = {sbIdx: sb, bbIdx: bb};

    final deck = variant.createDeck();
    final initial = GameState(
      sessionId: _newId(),
      variantName: variant.name,
      seats: seats,
      deck: deck,
      dealerSeat: dealer,
    );

    final session = Session(id: initial.sessionId, variant: variant, initial: initial);
    _sessions[session.id] = session;

    // Apply HandStart
    session.addEvent(HandStart(dealerSeat: dealer, blinds: blinds));

    // Apply all scenario events
    final events = ScenarioLoader.buildEvents(scenario);
    for (final event in events) {
      session.addEvent(event);
    }

    _sendJson(req.response, 201, session.toJson());
  }

  // ── H2 API handlers ─────────────────────────────────────────────────────────

  Future<void> _getEquity(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }

    final state = session.currentState;
    final hands = <int, List<Card>>{};
    for (final seat in state.seats) {
      if ((seat.isActive || seat.isAllIn) && seat.holeCards.length == 2) {
        hands[seat.index] = seat.holeCards;
      }
    }

    if (hands.length < 2) {
      _sendJson(req.response, 200, {'equity': <String, dynamic>{}});
      return;
    }

    final equity = EquityCalculator.calculate(
      hands: hands,
      board: state.community,
      iterations: 5000,
    );

    _sendJson(req.response, 200, {
      'equity': equity.map((k, v) => MapEntry(k.toString(), v)),
    });
  }

  Future<void> _validateCards(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }

    final issues = Engine.validateCards(session.currentState);
    _sendJson(req.response, 200, {
      'valid': issues.isEmpty,
      'issues': issues,
    });
  }

  Future<void> _getShowdownOrder(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }

    final order = ShowdownOrder.getRevealOrder(session.currentState);
    _sendJson(req.response, 200, {'revealOrder': order});
  }

  Future<void> _getRunoutCheck(HttpRequest req, String id) async {
    final session = _sessions[id];
    if (session == null) {
      _sendJson(req.response, 404, {'error': 'Session not found: $id'});
      return;
    }

    _sendJson(req.response, 200, {
      'isAllInRunout': Engine.isAllInRunout(session.currentState),
    });
  }

  // ── Static file serving ─────────────────────────────────────────────────────

  Future<void> _serveStatic(HttpRequest req) async {
    var filePath = req.uri.path;
    if (filePath == '/') filePath = '/index.html';
    final file = File('$webDir$filePath');

    if (!file.existsSync()) {
      req.response
        ..statusCode = 404
        ..write('Not found')
        ..close();
      return;
    }

    final ext = filePath.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'html' => 'text/html; charset=utf-8',
      'css' => 'text/css; charset=utf-8',
      'js' => 'application/javascript; charset=utf-8',
      'json' => 'application/json',
      'png' => 'image/png',
      'svg' => 'image/svg+xml',
      _ => 'application/octet-stream',
    };

    req.response
      ..statusCode = 200
      ..headers.contentType = ContentType.parse(contentType);
    await req.response.addStream(file.openRead());
    await req.response.close();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setCors(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type');
  }

  void _sendJson(HttpResponse response, int status, Map<String, dynamic> data) {
    final body = jsonEncode(data);
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    response.close();
  }

  Future<String> _readBody(HttpRequest req) async {
    final bytes = await req.fold<List<int>>(
      [],
      (buf, chunk) => [...buf, ...chunk],
    );
    return utf8.decode(bytes);
  }

  String _newId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      (DateTime.now().microsecond).toRadixString(36);

  Street _parseStreet(String s) => switch (s) {
        'setupHand' => Street.setupHand,
        'preflop' => Street.preflop,
        'flop' => Street.flop,
        'turn' => Street.turn,
        'river' => Street.river,
        'showdown' => Street.showdown,
        'runItMultiple' => Street.runItMultiple,
        _ => Street.flop,
      };

  CanvasType _parseCanvasType(String? s) => switch (s) {
        'venue' => CanvasType.venue,
        'broadcast' => CanvasType.broadcast,
        _ => CanvasType.broadcast,
      };
}
