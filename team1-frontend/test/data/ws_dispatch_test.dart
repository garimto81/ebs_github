// WebSocket event dispatch routing tests.
//
// Verifies dispatchWsEvent routes events to the correct provider notifiers
// using ProviderContainer (team4 pattern).

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
      'series_id': id,
      'competition_id': 1,
      'series_name': name,
      'year': 2026,
      'begin_at': '2026-05-01',
      'end_at': '2026-07-15',
      'time_zone': 'America/Los_Angeles',
      'currency': 'USD',
      'is_completed': false,
      'is_displayed': true,
      'is_demo': false,
      'source': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

Map<String, dynamic> _skinPayload({
  int id = 1,
  String status = 'validated',
}) =>
    {
      'skin_id': id,
      'name': 'Default Skin',
      'version': '1.0.0',
      'status': status,
      'metadata': {
        'title': 'Default',
        'description': 'Default skin',
        'tags': <String>[],
      },
      'file_size': 1024,
      'uploaded_at': '2026-01-01T00:00:00Z',
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
  // Series events
  // -------------------------------------------------------------------------

  /// Seed the series list with data (notifier starts as loading, not data).
  Future<void> seedSeries(List<Series> items) async {
    when(() => mockSeriesRepo.listSeries()).thenAnswer((_) async => items);
    await container.read(seriesListProvider.notifier).fetch();
  }

  group('series events', () {
    test('series.created appends to series list', () async {
      await seedSeries([Series.fromJson(_seriesPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'event': 'series.created',
        'payload': _seriesPayload(id: 2, name: 'WSOP Europe'),
        'seq': 1,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 2);
      expect(list.last.seriesName, 'WSOP Europe');
    });

    test('series.updated replaces matching series', () async {
      await seedSeries([Series.fromJson(_seriesPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'event': 'series.updated',
        'payload': _seriesPayload(id: 1, name: 'WSOP 2026 Updated'),
        'seq': 2,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 1);
      expect(list.first.seriesName, 'WSOP 2026 Updated');
    });

    test('series.deleted removes series by id', () async {
      await seedSeries([
        Series.fromJson(_seriesPayload(id: 1)),
        Series.fromJson(_seriesPayload(id: 2, name: 'Europe')),
      ]);

      dispatchWsEventForTest(container, {
        'event': 'series.deleted',
        'payload': {'series_id': 1},
        'seq': 3,
      });

      final list = container.read(seriesListProvider).value!;
      expect(list.length, 1);
      expect(list.first.seriesId, 2);
    });
  });

  // -------------------------------------------------------------------------
  // Settings events
  // -------------------------------------------------------------------------

  group('settings events', () {
    test('config.updated routes to settingsSectionProvider', () {
      // Pre-populate the outputs section.
      container
          .read(settingsSectionProvider(SettingsSection.outputs).notifier)
          .replaceAll({'volume': 80});

      dispatchWsEventForTest(container, {
        'event': 'config.updated',
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
      expect(state.draft['volume'], 95); // not dirty, so draft updated too
    });

    test('config_changed is an alias that also routes correctly', () {
      container
          .read(settingsSectionProvider(SettingsSection.gfx).notifier)
          .replaceAll({'brightness': 50});

      dispatchWsEventForTest(container, {
        'event': 'config_changed',
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
  // Skin events
  // -------------------------------------------------------------------------

  /// Seed the skin list with data (notifier starts as loading, not data).
  Future<void> seedSkins(List<Skin> items) async {
    when(() => mockSkinRepo.listSkins()).thenAnswer((_) async => items);
    await container.read(skinListProvider.notifier).fetch();
  }

  group('skin events', () {
    test('skin.updated updates skin in list', () async {
      await seedSkins([Skin.fromJson(_skinPayload(id: 1))]);

      dispatchWsEventForTest(container, {
        'event': 'skin.updated',
        'payload': _skinPayload(id: 1, status: 'active'),
        'seq': 20,
      });

      final list = container.read(skinListProvider).value!;
      expect(list.first.status, 'active');
      expect(container.read(activeSkinIdProvider), 1);
    });

    test('skin.activated sets active skin id', () async {
      await seedSkins([Skin.fromJson(_skinPayload(id: 5))]);

      dispatchWsEventForTest(container, {
        'event': 'skin.activated',
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
      // Should not throw.
      dispatchWsEventForTest(container, {
        'event': 'some.future.event',
        'payload': {'data': 1},
        'seq': 99,
      });
    });

    test('event with null payload is ignored when payload required', () {
      // Should not throw.
      dispatchWsEventForTest(container, {
        'event': 'series.updated',
        'seq': 100,
      });
    });

    test('WsDispatchEnvelope.fromJson parses correctly', () {
      final envelope = WsDispatchEnvelope.fromJson({
        'event': 'test.event',
        'payload': {'key': 'value'},
        'seq': 42,
      });
      expect(envelope.event, 'test.event');
      expect(envelope.payload?['key'], 'value');
      expect(envelope.seq, 42);
    });

    test('WsDispatchEnvelope handles missing fields gracefully', () {
      final envelope = WsDispatchEnvelope.fromJson({});
      expect(envelope.event, '');
      expect(envelope.payload, isNull);
      expect(envelope.seq, isNull);
    });
  });
}
