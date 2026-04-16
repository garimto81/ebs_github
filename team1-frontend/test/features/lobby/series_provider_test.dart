// SeriesListNotifier unit tests — fetch + remote CRUD.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/features/lobby/providers/series_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/series_repository.dart';

class MockSeriesRepository extends Mock implements SeriesRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Series _makeSeries({required int id, String name = 'WSOP 2026'}) =>
    Series.fromJson({
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
    });

void main() {
  late ProviderContainer container;
  late MockSeriesRepository mockRepo;

  setUp(() {
    mockRepo = MockSeriesRepository();
    container = ProviderContainer(overrides: [
      seriesRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  SeriesListNotifier notifier() =>
      container.read(seriesListProvider.notifier);

  AsyncValue<List<Series>> state() => container.read(seriesListProvider);

  // -------------------------------------------------------------------------
  // fetch
  // -------------------------------------------------------------------------

  group('fetch', () {
    test('loads series from repository', () async {
      final list = [_makeSeries(id: 1), _makeSeries(id: 2, name: 'Europe')];
      when(() => mockRepo.listSeries()).thenAnswer((_) async => list);

      await notifier().fetch();

      expect(state().value?.length, 2);
      expect(state().value?.first.seriesId, 1);
      expect(state().value?.last.seriesName, 'Europe');
    });

    test('sets error state on failure', () async {
      when(() => mockRepo.listSeries()).thenThrow(Exception('Network error'));

      await notifier().fetch();

      expect(state().hasError, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // applyRemoteUpdate
  // -------------------------------------------------------------------------

  group('applyRemoteUpdate', () {
    test('replaces matching series by id', () async {
      final list = [
        _makeSeries(id: 1, name: 'Original'),
        _makeSeries(id: 2, name: 'Other'),
      ];
      when(() => mockRepo.listSeries()).thenAnswer((_) async => list);
      await notifier().fetch();

      notifier().applyRemoteUpdate(_makeSeries(id: 1, name: 'Updated'));

      final result = state().value!;
      expect(result.length, 2);
      expect(result.first.seriesName, 'Updated');
      expect(result.last.seriesName, 'Other');
    });

    test('does nothing when series not in list', () async {
      when(() => mockRepo.listSeries())
          .thenAnswer((_) async => [_makeSeries(id: 1)]);
      await notifier().fetch();

      notifier().applyRemoteUpdate(_makeSeries(id: 999, name: 'Ghost'));

      // No match, list unchanged.
      expect(state().value?.length, 1);
      expect(state().value?.first.seriesId, 1);
    });
  });

  // -------------------------------------------------------------------------
  // applyRemoteAdd
  // -------------------------------------------------------------------------

  group('applyRemoteAdd', () {
    test('appends new series', () async {
      when(() => mockRepo.listSeries())
          .thenAnswer((_) async => [_makeSeries(id: 1)]);
      await notifier().fetch();

      notifier().applyRemoteAdd(_makeSeries(id: 2, name: 'Europe'));

      final list = state().value!;
      expect(list.length, 2);
      expect(list.last.seriesName, 'Europe');
    });
  });

  // -------------------------------------------------------------------------
  // applyRemoteDelete
  // -------------------------------------------------------------------------

  group('applyRemoteDelete', () {
    test('removes series by id', () async {
      when(() => mockRepo.listSeries()).thenAnswer((_) async => [
            _makeSeries(id: 1),
            _makeSeries(id: 2, name: 'Keep'),
            _makeSeries(id: 3, name: 'Also keep'),
          ]);
      await notifier().fetch();

      notifier().applyRemoteDelete(1);

      final list = state().value!;
      expect(list.length, 2);
      expect(list.every((s) => s.seriesId != 1), isTrue);
    });

    test('does nothing when id not found', () async {
      when(() => mockRepo.listSeries())
          .thenAnswer((_) async => [_makeSeries(id: 1)]);
      await notifier().fetch();

      notifier().applyRemoteDelete(999);

      expect(state().value?.length, 1);
    });
  });
}
