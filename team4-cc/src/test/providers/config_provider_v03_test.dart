// ConfigNotifier v03 — straddle + ante override unit tests (S3 cycle 7 #330).
//
// Validates ConfigNotifier additions introduced for v03 CC UI:
//   - toggleStraddleSeat(int seatNo): idempotent toggle add/remove
//   - clearStraddleSeats(): bulk reset
//   - setAnteOverride(int amount): manual ante edit with negative clamp

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/config_provider.dart';

void main() {
  late ProviderContainer container;
  late ConfigNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(configProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('ConfigNotifier — toggleStraddleSeat', () {
    test('initial straddleSeats is empty', () {
      expect(container.read(configProvider).straddleSeats, isEmpty);
    });

    test('toggle adds seat when absent', () {
      notifier.toggleStraddleSeat(3);
      expect(container.read(configProvider).straddleSeats, [3]);
    });

    test('toggle removes seat when present', () {
      notifier.toggleStraddleSeat(3);
      notifier.toggleStraddleSeat(3);
      expect(container.read(configProvider).straddleSeats, isEmpty);
    });

    test('toggle accumulates multiple seats', () {
      notifier.toggleStraddleSeat(2);
      notifier.toggleStraddleSeat(5);
      notifier.toggleStraddleSeat(7);
      expect(container.read(configProvider).straddleSeats, [2, 5, 7]);
    });

    test('toggle removes specific seat, others remain', () {
      notifier.toggleStraddleSeat(2);
      notifier.toggleStraddleSeat(5);
      notifier.toggleStraddleSeat(7);
      notifier.toggleStraddleSeat(5);
      expect(container.read(configProvider).straddleSeats, [2, 7]);
    });
  });

  group('ConfigNotifier — clearStraddleSeats', () {
    test('clear when empty is a no-op (no state mutation)', () {
      final before = container.read(configProvider);
      notifier.clearStraddleSeats();
      final after = container.read(configProvider);
      // Reference equality preserved (no copyWith call when already empty).
      expect(identical(before, after), isTrue);
    });

    test('clear removes all straddle seats', () {
      notifier.toggleStraddleSeat(2);
      notifier.toggleStraddleSeat(7);
      notifier.clearStraddleSeats();
      expect(container.read(configProvider).straddleSeats, isEmpty);
    });
  });

  group('ConfigNotifier — setAnteOverride', () {
    test('initial ante is 0', () {
      expect(container.read(configProvider).ante, 0);
    });

    test('setAnteOverride updates ante', () {
      notifier.setAnteOverride(50);
      expect(container.read(configProvider).ante, 50);
    });

    test('setAnteOverride clamps negative to 0', () {
      notifier.setAnteOverride(-100);
      expect(container.read(configProvider).ante, 0);
    });

    test('hasAnteProvider reflects override', () {
      expect(container.read(hasAnteProvider), isFalse);
      notifier.setAnteOverride(25);
      expect(container.read(hasAnteProvider), isTrue);
    });
  });
}
