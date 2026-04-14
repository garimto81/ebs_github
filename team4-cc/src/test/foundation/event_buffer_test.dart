// LocalEventBuffer unit tests (CCR-031 BS-05-00 BO recovery).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/data/local/event_buffer.dart';

void main() {
  late LocalEventBuffer buffer;

  LocalEvent _event(String type) => LocalEvent(
        type: type,
        payload: {'key': type},
        localTimestamp: DateTime.now(),
      );

  group('LocalEventBuffer', () {
    setUp(() {
      buffer = LocalEventBuffer();
    });

    test('initial state is empty', () {
      expect(buffer.length, 0);
      expect(buffer.isFull, isFalse);
      expect(buffer.snapshot, isEmpty);
    });

    test('default capacity is 20', () {
      expect(buffer.capacity, 20);
    });

    test('tryAppend succeeds within capacity', () {
      for (var i = 0; i < 5; i++) {
        final ok = buffer.tryAppend(_event('e$i'));
        expect(ok, isTrue);
      }
      expect(buffer.length, 5);
    });

    test('tryAppend returns false when full (20)', () {
      for (var i = 0; i < 20; i++) {
        expect(buffer.tryAppend(_event('e$i')), isTrue);
      }
      expect(buffer.isFull, isTrue);
      expect(buffer.length, 20);

      // 21st event rejected
      final ok = buffer.tryAppend(_event('overflow'));
      expect(ok, isFalse);
      expect(buffer.length, 20);
    });

    test('drain returns all events and clears buffer', () {
      buffer.tryAppend(_event('a'));
      buffer.tryAppend(_event('b'));
      buffer.tryAppend(_event('c'));

      final drained = buffer.drain();
      expect(drained.length, 3);
      expect(drained[0].type, 'a');
      expect(drained[1].type, 'b');
      expect(drained[2].type, 'c');

      // Buffer is now empty
      expect(buffer.length, 0);
      expect(buffer.isFull, isFalse);
    });

    test('clear empties buffer', () {
      for (var i = 0; i < 10; i++) {
        buffer.tryAppend(_event('e$i'));
      }
      expect(buffer.length, 10);

      buffer.clear();
      expect(buffer.length, 0);
      expect(buffer.snapshot, isEmpty);
    });

    test('snapshot returns immutable copy', () {
      buffer.tryAppend(_event('x'));
      buffer.tryAppend(_event('y'));

      final snap = buffer.snapshot;
      expect(snap.length, 2);

      // Snapshot should not be affected by later changes
      buffer.tryAppend(_event('z'));
      expect(snap.length, 2); // still 2
      expect(buffer.length, 3);
    });

    test('custom capacity works', () {
      final smallBuffer = LocalEventBuffer(capacity: 3);
      expect(smallBuffer.tryAppend(_event('a')), isTrue);
      expect(smallBuffer.tryAppend(_event('b')), isTrue);
      expect(smallBuffer.tryAppend(_event('c')), isTrue);
      expect(smallBuffer.tryAppend(_event('d')), isFalse);
      expect(smallBuffer.length, 3);
    });

    test('drain after clear returns empty list', () {
      buffer.tryAppend(_event('a'));
      buffer.clear();
      final drained = buffer.drain();
      expect(drained, isEmpty);
    });

    test('tryAppend works after drain', () {
      for (var i = 0; i < 20; i++) {
        buffer.tryAppend(_event('e$i'));
      }
      expect(buffer.isFull, isTrue);

      buffer.drain();
      expect(buffer.isFull, isFalse);
      expect(buffer.tryAppend(_event('new')), isTrue);
      expect(buffer.length, 1);
    });
  });
}
