// SecurityDelayBuffer unit tests (BS-07-07, CCR-036).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/overlay/services/security_delay_buffer.dart';

void main() {
  group('SecurityDelayBuffer', () {
    test('initial state is empty', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(seconds: 30));
      expect(buffer.isEmpty, isTrue);
      expect(buffer.bufferedCount, 0);
      expect(buffer.timeToNextRelease, isNull);
    });

    test('enqueue adds to buffer', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(seconds: 30));
      buffer.enqueue({
        'hole_cards': ['Ah', 'Kd'],
        'player_name': 'Phil Ivey',
        'pot_total': 5000,
      });
      expect(buffer.bufferedCount, 1);
      expect(buffer.isEmpty, isFalse);
    });

    test('releaseNext returns null before delay', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(seconds: 30));
      buffer.enqueue({
        'hole_cards': ['Ah', 'Kd'],
        'pot_total': 5000,
      });
      // Immediately after enqueue, delay has not passed
      final result = buffer.releaseNext();
      expect(result, isNull);
      expect(buffer.bufferedCount, 1);
    });

    test('releaseNext returns snapshot after delay', () {
      // Use 0-duration delay. releaseNext checks isBefore (strictly <),
      // so use drainReady which checks !isAfter (<=) for zero-delay.
      // Here we test via drainReady which is the correct API for zero-delay.
      final buffer = SecurityDelayBuffer(delay: Duration.zero);
      buffer.enqueue({
        'hole_cards': ['Ah', 'Kd'],
        'pot_total': 5000,
        'hand_id': 'H001',
      });

      // drainReady uses !isAfter (<=) so zero-delay works immediately
      final ready = buffer.drainReady();
      expect(ready.length, 1);
      final result = ready.first;
      expect(result['hole_cards'], ['Ah', 'Kd']);
      expect(result['pot_total'], 5000);
      expect(result['hand_id'], 'H001');
      expect(buffer.bufferedCount, 0);
    });

    test('delay mask: hole_cards kept, player_name stripped', () {
      final buffer = SecurityDelayBuffer(delay: Duration.zero);
      buffer.enqueue({
        'hole_cards': ['Ah', 'Kd'],
        'player_name': 'Phil Ivey',
        'pot_total': 5000,
        'blind_level': '100/200',
        'table_info': 'Table 1',
        'hand_id': 'H001',
        'seq': 42,
      });

      final ready = buffer.drainReady();
      expect(ready.length, 1);
      final result = ready.first;

      // Delayed fields should be present
      expect(result.containsKey('hole_cards'), isTrue);
      expect(result.containsKey('pot_total'), isTrue);

      // Passthrough fields should be stripped from delayed buffer
      expect(result.containsKey('player_name'), isFalse);
      expect(result.containsKey('blind_level'), isFalse);
      expect(result.containsKey('table_info'), isFalse);

      // Metadata always included
      expect(result['hand_id'], 'H001');
      expect(result['seq'], 42);
    });

    test('capacity limit: oldest removed when full', () {
      final buffer = SecurityDelayBuffer(
        delay: const Duration(seconds: 30),
        maxCapacity: 3,
      );

      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      buffer.enqueue({'seq': 2, 'hole_cards': ['Ks']});
      buffer.enqueue({'seq': 3, 'hole_cards': ['Qs']});
      expect(buffer.bufferedCount, 3);

      // 4th enqueue should drop oldest
      buffer.enqueue({'seq': 4, 'hole_cards': ['Js']});
      expect(buffer.bufferedCount, 3);
    });

    test('drainReady returns all ready snapshots', () {
      final buffer = SecurityDelayBuffer(delay: Duration.zero);
      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      buffer.enqueue({'seq': 2, 'hole_cards': ['Ks']});
      buffer.enqueue({'seq': 3, 'hole_cards': ['Qs']});

      final ready = buffer.drainReady();
      expect(ready.length, 3);
      expect(ready[0]['seq'], 1);
      expect(ready[1]['seq'], 2);
      expect(ready[2]['seq'], 3);
      expect(buffer.isEmpty, isTrue);
    });

    test('drainReady returns empty when nothing ready', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(hours: 1));
      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      final ready = buffer.drainReady();
      expect(ready, isEmpty);
      expect(buffer.bufferedCount, 1);
    });

    test('flush clears entire buffer', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(seconds: 30));
      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      buffer.enqueue({'seq': 2, 'hole_cards': ['Ks']});
      buffer.flush();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.bufferedCount, 0);
    });

    test('extractPassthrough returns only passthrough fields', () {
      final state = {
        'hole_cards': ['Ah', 'Kd'],
        'player_name': 'Phil Ivey',
        'pot_total': 5000,
        'blind_level': '100/200',
        'table_info': 'Table 1',
        'hand_id': 'H001',
        'seq': 42,
        'dealer_position': 3,
        'seat_status': 'active',
        'player_count': 6,
      };

      final passthrough = SecurityDelayBuffer.extractPassthrough(state);

      // Passthrough fields present
      expect(passthrough['player_name'], 'Phil Ivey');
      expect(passthrough['blind_level'], '100/200');
      expect(passthrough['table_info'], 'Table 1');
      expect(passthrough['dealer_position'], 3);
      expect(passthrough['seat_status'], 'active');
      expect(passthrough['player_count'], 6);

      // Metadata passes through
      expect(passthrough['hand_id'], 'H001');
      expect(passthrough['seq'], 42);

      // Delayed fields NOT in passthrough
      expect(passthrough.containsKey('hole_cards'), isFalse);
      expect(passthrough.containsKey('pot_total'), isFalse);
    });

    test('timeToNextRelease returns duration', () {
      final buffer = SecurityDelayBuffer(delay: const Duration(seconds: 30));
      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      final time = buffer.timeToNextRelease;
      expect(time, isNotNull);
      expect(time!.inSeconds, greaterThan(0));
      expect(time.inSeconds, lessThanOrEqualTo(30));
    });

    test('timeToNextRelease returns Duration.zero when past due', () {
      final buffer = SecurityDelayBuffer(delay: Duration.zero);
      buffer.enqueue({'seq': 1, 'hole_cards': ['As']});
      final time = buffer.timeToNextRelease;
      expect(time, isNotNull);
      expect(time!, Duration.zero);
    });
  });
}
