// TableStateNotifier — FSM transitions (BS-05-00 §Table FSM, CCR-031).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/table_state_provider.dart';
import 'package:ebs_cc/models/enums/table_fsm.dart';

void main() {
  late ProviderContainer c;

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  group('TableStateNotifier lifecycle', () {
    test('initial state is empty', () {
      expect(c.read(tableStateProvider), TableFsm.empty);
    });

    test('empty → setup via openTable', () {
      c.read(tableStateProvider.notifier).openTable();
      expect(c.read(tableStateProvider), TableFsm.setup);
    });

    test('setup → live via goLive', () {
      c.read(tableStateProvider.notifier).openTable();
      c.read(tableStateProvider.notifier).goLive();
      expect(c.read(tableStateProvider), TableFsm.live);
    });

    test('live → paused → live cycle', () {
      c.read(tableStateProvider.notifier).openTable();
      c.read(tableStateProvider.notifier).goLive();
      c.read(tableStateProvider.notifier).pause();
      expect(c.read(tableStateProvider), TableFsm.paused);

      c.read(tableStateProvider.notifier).resume();
      expect(c.read(tableStateProvider), TableFsm.live);
    });

    test('any → closed via closeTable', () {
      c.read(tableStateProvider.notifier).openTable();
      c.read(tableStateProvider.notifier).goLive();
      c.read(tableStateProvider.notifier).closeTable();
      expect(c.read(tableStateProvider), TableFsm.closed);
    });

    test('closed → empty via reset', () {
      c.read(tableStateProvider.notifier).closeTable();
      c.read(tableStateProvider.notifier).reset();
      expect(c.read(tableStateProvider), TableFsm.empty);
    });

    test('forceState overrides current state', () {
      c.read(tableStateProvider.notifier).forceState(TableFsm.paused);
      expect(c.read(tableStateProvider), TableFsm.paused);
    });
  });

  group('Derived providers', () {
    test('isTableLiveProvider true only when live', () {
      expect(c.read(isTableLiveProvider), false);

      c.read(tableStateProvider.notifier).openTable();
      expect(c.read(isTableLiveProvider), false);

      c.read(tableStateProvider.notifier).goLive();
      expect(c.read(isTableLiveProvider), true);

      c.read(tableStateProvider.notifier).pause();
      expect(c.read(isTableLiveProvider), false);
    });

    test('canEditSeatsProvider true for setup and live', () {
      expect(c.read(canEditSeatsProvider), false); // empty

      c.read(tableStateProvider.notifier).openTable();
      expect(c.read(canEditSeatsProvider), true); // setup

      c.read(tableStateProvider.notifier).goLive();
      expect(c.read(canEditSeatsProvider), true); // live

      c.read(tableStateProvider.notifier).pause();
      expect(c.read(canEditSeatsProvider), false); // paused
    });
  });
}
