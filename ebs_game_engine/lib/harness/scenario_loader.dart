import 'dart:io';
import 'package:yaml/yaml.dart';
import '../core/cards/card.dart';
import '../core/actions/event.dart';
import '../core/actions/action.dart';
import '../core/state/game_state.dart';
import 'session.dart';

/// Parsed YAML scenario data.
class Scenario {
  final String variant;
  final List<Map<String, dynamic>> seats;
  final int dealer;
  final Map<String, int> blinds;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic>? expectations;

  const Scenario({
    required this.variant,
    required this.seats,
    required this.dealer,
    required this.blinds,
    required this.events,
    this.expectations,
  });
}

/// Loads and saves YAML scenario files.
class ScenarioLoader {
  ScenarioLoader._();

  /// Parse a YAML string into a [Scenario].
  static Scenario parseYaml(String content) {
    final doc = loadYaml(content) as YamlMap;

    final variant = doc['variant'] as String? ?? 'nlh';
    final dealer = (doc['dealer'] as num?)?.toInt() ?? 0;

    // Seats
    final seatsRaw = doc['seats'];
    final seats = <Map<String, dynamic>>[];
    if (seatsRaw is YamlList) {
      for (final s in seatsRaw) {
        if (s is YamlMap) {
          seats.add(_yamlMapToMap(s));
        }
      }
    }

    // Blinds
    final blindsRaw = doc['blinds'];
    final blinds = <String, int>{};
    if (blindsRaw is YamlMap) {
      blindsRaw.forEach((k, v) {
        blinds[k.toString()] = (v as num).toInt();
      });
    }

    // Events
    final eventsRaw = doc['events'];
    final events = <Map<String, dynamic>>[];
    if (eventsRaw is YamlList) {
      for (final e in eventsRaw) {
        if (e is YamlMap) {
          events.add(_yamlMapToMap(e));
        }
      }
    }

    // Expectations (optional)
    Map<String, dynamic>? expectations;
    final expectRaw = doc['expectations'];
    if (expectRaw is YamlMap) {
      expectations = _yamlMapToMap(expectRaw);
    }

    return Scenario(
      variant: variant,
      seats: seats,
      dealer: dealer,
      blinds: blinds,
      events: events,
      expectations: expectations,
    );
  }

  /// Read a YAML file and parse it.
  static Future<Scenario> loadFile(String path) async {
    final content = await File(path).readAsString();
    return parseYaml(content);
  }

  /// Convert scenario event maps to [Event] objects.
  static List<Event> buildEvents(Scenario scenario) {
    final result = <Event>[];

    for (final eventMap in scenario.events) {
      final event = _buildEvent(eventMap);
      if (event != null) result.add(event);
    }

    return result;
  }

  static Event? _buildEvent(Map<String, dynamic> map) {
    // deal_hole: {0: [As, Kh], 1: [Qd, Qc]}
    if (map.containsKey('deal_hole')) {
      final raw = map['deal_hole'];
      final holeMap = <int, List<Card>>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          final idx = int.parse(k.toString());
          final cards = <Card>[];
          if (v is List) {
            for (final c in v) {
              cards.add(Card.parse(c.toString()));
            }
          }
          holeMap[idx] = cards;
        });
      }
      return DealHoleCards(holeMap);
    }

    // deal_community: [Qs, Jd, Th]
    if (map.containsKey('deal_community')) {
      final raw = map['deal_community'];
      final cards = <Card>[];
      if (raw is List) {
        for (final c in raw) {
          cards.add(Card.parse(c.toString()));
        }
      }
      return DealCommunity(cards);
    }

    // action: {seat: 0, type: raise, amount: 30}
    if (map.containsKey('action')) {
      final actionMap = map['action'];
      if (actionMap is Map) {
        final seat = (actionMap['seat'] as num?)?.toInt() ?? 0;
        final type = actionMap['type'] as String? ?? '';
        final amount = (actionMap['amount'] as num?)?.toInt() ?? 0;
        final action = _parseAction(type, amount);
        if (action != null) return PlayerAction(seat, action);
      }
      return null;
    }

    // street_advance: flop
    if (map.containsKey('street_advance')) {
      final streetName = map['street_advance'] as String? ?? 'flop';
      final street = _parseStreet(streetName);
      return StreetAdvance(street);
    }

    // pot_awarded: {0: 300}
    if (map.containsKey('pot_awarded')) {
      final raw = map['pot_awarded'];
      final awards = <int, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          awards[int.parse(k.toString())] = (v as num).toInt();
        });
      }
      return PotAwarded(awards);
    }

    // hand_end
    if (map.containsKey('hand_end')) {
      return const HandEnd();
    }

    return null;
  }

  static Action? _parseAction(String type, int amount) => switch (type) {
        'fold' => const Fold(),
        'check' => const Check(),
        'call' => Call(amount),
        'bet' => Bet(amount),
        'raise' => Raise(amount),
        'allin' => AllIn(amount),
        _ => null,
      };

  static Street _parseStreet(String s) => switch (s) {
        'preflop' => Street.preflop,
        'flop' => Street.flop,
        'turn' => Street.turn,
        'river' => Street.river,
        'showdown' => Street.showdown,
        _ => Street.flop,
      };

  /// Save a session to YAML file.
  static Future<void> save(Session session, String path) async {
    final state = session.currentState;
    final buf = StringBuffer();

    buf.writeln('# EBS Game Engine — Saved Session');
    buf.writeln('variant: ${session.variant.name}');
    buf.writeln('dealer: ${state.dealerSeat}');
    buf.writeln();

    buf.writeln('blinds:');
    buf.writeln('  sb: ${state.sbSeat >= 0 ? state.bbAmount ~/ 2 : 5}');
    buf.writeln('  bb: ${state.bbAmount > 0 ? state.bbAmount : 10}');
    buf.writeln();

    buf.writeln('seats:');
    for (final seat in state.seats) {
      buf.writeln('  - index: ${seat.index}');
      buf.writeln('    label: "${seat.label}"');
      buf.writeln('    stack: ${seat.stack}');
    }
    buf.writeln();

    buf.writeln('events:');
    for (final event in session.events) {
      _writeEvent(buf, event);
    }

    await File(path).writeAsString(buf.toString());
  }

  static void _writeEvent(StringBuffer buf, Event event) {
    switch (event) {
      case HandStart():
        // HandStart is auto-generated, skip to avoid double-apply on load
        break;
      case DealHoleCards(cards: final cards):
        buf.writeln('  - deal_hole:');
        cards.forEach((idx, cardList) {
          final notation = cardList.map((c) => c.notation).join(', ');
          buf.writeln('      $idx: [$notation]');
        });
      case DealCommunity(cards: final cards):
        final notation = cards.map((c) => c.notation).join(', ');
        buf.writeln('  - deal_community: [$notation]');
      case PlayerAction(seatIndex: final s, action: final a):
        buf.writeln('  - action:');
        buf.writeln('      seat: $s');
        buf.writeln('      type: ${_actionType(a)}');
        final amt = _actionAmount(a);
        if (amt != null) buf.writeln('      amount: $amt');
      case StreetAdvance(next: final n):
        buf.writeln('  - street_advance: ${n.name}');
      case PotAwarded(awards: final a):
        buf.writeln('  - pot_awarded:');
        a.forEach((k, v) => buf.writeln('      $k: $v'));
      case HandEnd():
        buf.writeln('  - hand_end: true');
      case PineappleDiscard(seatIndex: final s, discarded: final c):
        buf.writeln('  - pineapple_discard:');
        buf.writeln('      seat: $s');
        buf.writeln('      card: ${c.notation}');
    }
  }

  static String _actionType(Action a) => switch (a) {
        Fold() => 'fold',
        Check() => 'check',
        Call() => 'call',
        Bet() => 'bet',
        Raise() => 'raise',
        AllIn() => 'allin',
      };

  static int? _actionAmount(Action a) => switch (a) {
        Fold() => null,
        Check() => null,
        Call(:final amount) => amount,
        Bet(:final amount) => amount,
        Raise(:final toAmount) => toAmount,
        AllIn(:final amount) => amount,
      };

  // ── YAML conversion helpers ──────────────────────────────────────────────────

  static Map<String, dynamic> _yamlMapToMap(YamlMap m) {
    final result = <String, dynamic>{};
    m.forEach((k, v) {
      result[k.toString()] = _convertYaml(v);
    });
    return result;
  }

  static dynamic _convertYaml(dynamic v) {
    if (v is YamlMap) return _yamlMapToMap(v);
    if (v is YamlList) return v.map(_convertYaml).toList();
    return v;
  }
}
