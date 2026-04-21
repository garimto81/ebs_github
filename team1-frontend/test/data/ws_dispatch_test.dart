// WebSocket event dispatch routing tests.
//
// Verifies dispatchWsEvent routes events to the correct provider notifiers
// using ProviderContainer (team4 pattern).
//
// 2026-04-21 B-088 PR-6: event type PascalCase + payload camelCase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/data/remote/ws_dispatch.dart';
import 'package:ebs_lobby/features/graphic_editor/providers/ge_provider.dart';
import 'package:ebs_lobby/features/lobby/providers/series_provider.dart';
import 'package:ebs_lobby/features/settings/providers/settings_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/series_repository.dart';
import 'package:ebs_lobby/repositories/settings_repository.dart';
import 'package:ebs_lobby/repositories/skin_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSkinRepository extends Mock implements SkinRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _seriesPayload({int id = 1, String name = 'WSOP 2026'}) =>
    {
      'seriesId': id,
      'competitionId': 1,
      'seriesName': name,
      'year': 2026,
      'beginAt': '2026-05-01',
      'endAt': '2026-07-15',
      'timeZone': 'America/Los_Angeles',
      'currency': 'USD',
      'isCompleted': false,
      'isDisplayed': true,
      'isDemo': false,
      'source': 'manual',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    };

Map<String, dynamic> _skinPayload({
  int id = 1,
  String status = 'validated',
}) =>
    {
      'skinId': id,
      'name': 'Default Skin',
      'version': '1.0.0',
      'status': status,
      'metadata': {
        'title': 'Default',
        'description': 'Default skin',
        'tags': <String>[],
      },
      'fileSize': 1024,
      'uploadedAt': '2026-01-01T00:00:00Z',
    };

void main() {
  late ProviderContainer container;
  late MockSeriesRepository mockSeriesRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockSkinRepository mockSkinRepo;

  setUp(() {
    mockSeriesRepo = MockSeriesRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockSkinRepo = MockSkinRepository();

    container = ProviderContainer(overrides: [
      seriesRepositoryProvider.overrideWithValue(mockSeriesRepo),
      settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
      skinRepositoryProvider.overrideWithValue(mockSkinRepo),
    ]);
  });

  tearDown(() => container.dispose());

  // -------------------------------------------------------------------------
  // Series events — PascalCase (WSOP LIVE 준수)
  // -------------------------------------------------------------------------

  Future<void> seedSeries(List<Series> items) async {
    when(() => mockSeriesRepo.listSeries()).thenAnswer((_) async => items);
    await container.read(seriesListProvider.notifier).fetch();
  }

  group('series events', () {
    test('SeriesCreated appends to series list', () async {
      await seedSeries([Series.fromJson(_seriesPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'type': 'SeriesCreated',
        'payload': _seriesPayload(id: 2, name: 'WSOP Europe'),
        'seq': 1,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 2);
      expect(list.last.seriesName, 'WSOP Europe');
    });

    test('SeriesUpdated replaces matching series', () async {
      await seedSeries([Series.fromJson(_seriesPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'type': 'SeriesUpdated',
        'payload': _seriesPayload(id: 1, name: 'WSOP 2026 Updated'),
        'seq': 2,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 1);
      expect(list.first.seriesName, 'WSOP 2026 Updated');
    });

    test('SeriesDeleted removes series by id', () async {
      await seedSeries([
        Series.fromJson(_seriesPayload(id: 1)),
        Series.fromJson(_seriesPayload(id: 2, name: 'Europe')),
      ]);

      dispatchWsEventForTest(container, {
        'type': 'SeriesDeleted',
        'payload': {'seriesId': 1},
        'seq': 3,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 1);
      expect(list.first.seriesId, 2);
    });
  });

  // -------------------------------------------------------------------------
  // Settings events — unified ConfigChanged (legacy config.updated + config_changed removed)
  // -------------------------------------------------------------------------

  group('settings events', () {
    test('ConfigChanged routes to settingsSectionProvider', () {
      container
          .read(settingsSectionProvider(SettingsSection.outputs).notifier)
          .replaceAll({'volume': 80});

      dispatchWsEventForTest(container, {
        'type': 'ConfigChanged',
        'payload': {
          'section': 'outputs',
          'key': 'volume',
          'value': 95,
        },
        'seq': 10,
      });

      final state =
          container.read(settingsSectionProvider(SettingsSection.outputs));
      expect(state.committed['volume'], 95);
      expect(state.draft['volume'], 95);
    });

    test('ConfigChanged for gfx section', () {
      container
          .read(settingsSectionProvider(SettingsSection.gfx).notifier)
          .replaceAll({'brightness': 50});

      dispatchWsEventForTest(container, {
        'type': 'ConfigChanged',
        'payload': {
          'section': 'gfx',
          'key': 'brightness',
          'value': 75,
        },
        'seq': 11,
      });

      final state =
          container.read(settingsSectionProvider(SettingsSection.gfx));
      expect(state.committed['brightness'], 75);
    });
  });

  // -------------------------------------------------------------------------
  // Skin events — unified SkinUpdated + SkinActivated (legacy skin.updated + skin_updated removed)
  // -------------------------------------------------------------------------

  Future<void> seedSkins(List<Skin> items) async {
    when(() => mockSkinRepo.listSkins()).thenAnswer((_) async => items);
    await container.read(skinListProvider.notifier).fetch();
  }

  group('skin events', () {
    test('SkinUpdated updates skin in list', () async {
      await seedSkins([Skin.fromJson(_skinPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'type': 'SkinUpdated',
        'payload': _skinPayload(id: 1, status: 'active'),
        'seq': 20,
      });

      final list = container.read(skinListProvider).value!;
      expect(list.first.status, 'active');
      expect(container.read(activeSkinIdProvider), 1);
    });

    test('SkinActivated sets active skin id', () async {
      await seedSkins([Skin.fromJson(_skinPayload(id: 5))]);

      dispatchWsEventForTest(container, {
        'type': 'SkinActivated',
        'payload': _skinPayload(id: 5, status: 'active'),
        'seq': 21,
      });

      expect(container.read(activeSkinIdProvider), 5);
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------

  group('edge cases', () {
    test('unknown event is silently ignored', () {
      dispatchWsEventForTest(container, {
        'type': 'SomeFutureEvent',
        'payload': {'data': 1},
        'seq': 99,
      });
    });

    test('event with null payload is ignored when payload required', () {
      dispatchWsEventForTest(container, {
        'type': 'SeriesUpdated',
        'seq': 100,
      });
    });

    test('WsDispatchEnvelope.fromJson parses type field', () {
      final envelope = WsDispatchEnvelope.fromJson({
        'type': 'TestEvent',
        'payload': {'key': 'value'},
        'seq': 42,
      });
      expect(envelope.event, 'TestEvent');
      expect(envelope.payload?['key'], 'value');
      expect(envelope.seq, 42);
    });

    test('WsDispatchEnvelope.fromJson falls back to event field (legacy)', () {
      final envelope = WsDispatchEnvelope.fromJson({
        'event': 'LegacyEvent',
        'payload': {'a': 1},
      });
      expect(envelope.event, 'LegacyEvent');
      expect(envelope.payload?['a'], 1);
    });

    test('WsDispatchEnvelope handles missing fields gracefully', () {
      final envelope = WsDispatchEnvelope.fromJson({});
      expect(envelope.event, '');
      expect(envelope.payload, isNull);
      expect(envelope.seq, isNull);
    });
  });
}
