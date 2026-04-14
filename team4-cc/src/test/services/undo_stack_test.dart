// UndoStack unit tests (BS-05-05).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/services/undo_stack.dart';

void main() {
  late UndoStack stack;

  UndoableEvent _event(String type, {String desc = ''}) => UndoableEvent(
        eventType: type,
        payload: {'action': type},
        timestamp: DateTime.now(),
        description: desc.isEmpty ? type : desc,
      );

  group('UndoStack', () {
    setUp(() {
      stack = UndoStack();
    });

    test('initial state is empty', () {
      expect(stack.canUndo, isFalse);
      expect(stack.length, 0);
      expect(stack.all, isEmpty);
      expect(stack.pageCount, 0);
    });

    test('push reversible event succeeds', () {
      final ok = stack.push(_event('ActionPerformed'));
      expect(ok, isTrue);
      expect(stack.length, 1);
      expect(stack.canUndo, isTrue);
    });

    test('push irreversible StartHand returns false', () {
      final ok = stack.push(_event('StartHand'));
      expect(ok, isFalse);
      expect(stack.length, 0);
    });

    test('push irreversible BlindsPosted returns false', () {
      final ok = stack.push(_event('BlindsPosted'));
      expect(ok, isFalse);
      expect(stack.length, 0);
    });

    test('push reversible types accepted', () {
      const types = [
        'ActionPerformed',
        'CardDetected',
        'BoardCardDealt',
        'SeatStatusChanged',
        'PlayerStackChanged',
        'DealerMoved',
        'StraddlePosted',
      ];
      for (final t in types) {
        expect(stack.push(_event(t)), isTrue, reason: '$t should be accepted');
      }
      expect(stack.length, types.length);
    });

    test('pop returns most recent event (LIFO)', () {
      stack.push(_event('ActionPerformed', desc: 'first'));
      stack.push(_event('CardDetected', desc: 'second'));
      stack.push(_event('BoardCardDealt', desc: 'third'));

      final popped = stack.pop();
      expect(popped, isNotNull);
      expect(popped!.description, 'third');
      expect(stack.length, 2);

      final second = stack.pop();
      expect(second!.description, 'second');
    });

    test('pop on empty returns null', () {
      expect(stack.pop(), isNull);
    });

    test('clear empties stack', () {
      stack.push(_event('ActionPerformed'));
      stack.push(_event('CardDetected'));
      stack.push(_event('BoardCardDealt'));

      stack.clear();
      expect(stack.length, 0);
      expect(stack.canUndo, isFalse);
      expect(stack.all, isEmpty);
    });

    test('getPage pagination (10 per page)', () {
      // Push 25 events
      for (var i = 0; i < 25; i++) {
        stack.push(_event('ActionPerformed', desc: 'event_$i'));
      }

      // Page 0 = most recent 10 (events 24..15)
      final page0 = stack.getPage(0);
      expect(page0.length, 10);
      expect(page0.first.description, 'event_24');
      expect(page0.last.description, 'event_15');

      // Page 1 = next 10 (events 14..5)
      final page1 = stack.getPage(1);
      expect(page1.length, 10);
      expect(page1.first.description, 'event_14');
      expect(page1.last.description, 'event_5');

      // Page 2 = remaining 5 (events 4..0)
      final page2 = stack.getPage(2);
      expect(page2.length, 5);
      expect(page2.first.description, 'event_4');
      expect(page2.last.description, 'event_0');

      // Page 3 = empty (beyond range)
      final page3 = stack.getPage(3);
      expect(page3, isEmpty);
    });

    test('getPage with negative page returns empty', () {
      stack.push(_event('ActionPerformed'));
      expect(stack.getPage(-1), isEmpty);
    });

    test('pageCount calculation', () {
      expect(stack.pageCount, 0);

      // 1 event = 1 page
      stack.push(_event('ActionPerformed'));
      expect(stack.pageCount, 1);

      // 10 events = 1 page
      for (var i = 1; i < 10; i++) {
        stack.push(_event('ActionPerformed'));
      }
      expect(stack.pageCount, 1);

      // 11 events = 2 pages
      stack.push(_event('ActionPerformed'));
      expect(stack.pageCount, 2);

      // 20 events = 2 pages
      for (var i = 0; i < 9; i++) {
        stack.push(_event('ActionPerformed'));
      }
      expect(stack.pageCount, 2);

      // 21 events = 3 pages
      stack.push(_event('ActionPerformed'));
      expect(stack.pageCount, 3);
    });

    test('unlimited undo (push 100 events, pop all)', () {
      for (var i = 0; i < 100; i++) {
        stack.push(_event('ActionPerformed', desc: 'e$i'));
      }
      expect(stack.length, 100);

      for (var i = 99; i >= 0; i--) {
        final popped = stack.pop();
        expect(popped, isNotNull);
        expect(popped!.description, 'e$i');
      }
      expect(stack.length, 0);
      expect(stack.pop(), isNull);
    });

    test('all returns unmodifiable list oldest-first', () {
      stack.push(_event('ActionPerformed', desc: 'first'));
      stack.push(_event('CardDetected', desc: 'second'));

      final all = stack.all;
      expect(all.length, 2);
      expect(all.first.description, 'first');
      expect(all.last.description, 'second');

      // Verify unmodifiable
      expect(() => all.add(_event('x')), throwsUnsupportedError);
    });
  });
}
