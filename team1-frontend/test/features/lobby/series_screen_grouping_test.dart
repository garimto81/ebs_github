// SeriesScreen Month/Year grouping + Hide completed widget tests.
// B-LOBBY-SERIES-001 — design SSOT 정렬 (Lobby/References/EBS_Lobby_Design/screens.jsx:18-50).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/features/lobby/providers/series_provider.dart';
import 'package:ebs_lobby/features/lobby/screens/series_screen.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/series_repository.dart';

class MockSeriesRepository extends Mock implements SeriesRepository {}

Series _series({
  required int id,
  required String name,
  required int year,
  required String beginAt,
  bool completed = false,
}) =>
    Series.fromJson({
      'seriesId': id,
      'competitionId': 1,
      'seriesName': name,
      'year': year,
      'beginAt': beginAt,
      'endAt': beginAt,
      'timeZone': 'UTC',
      'currency': 'USD',
      'isCompleted': completed,
      'isDisplayed': true,
      'isDemo': false,
      'source': 'manual',
      'createdAt': '$year-01-01T00:00:00Z',
      'updatedAt': '$year-01-01T00:00:00Z',
    });

void main() {
  late MockSeriesRepository repo;
  late List<Series> seed;

  setUp(() {
    repo = MockSeriesRepository();
    seed = [
      _series(id: 1, name: 'WPS 2026 EU', year: 2026, beginAt: '2026-03-15'),
      _series(id: 2, name: 'WPS 2026 Vegas', year: 2026, beginAt: '2026-05-27'),
      _series(id: 3, name: 'Circuit Sydney', year: 2026, beginAt: '2026-04-01'),
      _series(
          id: 4, name: 'WPS 2025 Old', year: 2025, beginAt: '2025-05-28', completed: true),
    ];
    when(() => repo.listSeries(params: any(named: 'params')))
        .thenAnswer((_) async => seed);
    when(() => repo.listSeries()).thenAnswer((_) async => seed);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [seriesRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(body: SeriesScreen()),
      ),
    );
  }

  testWidgets('Year mode shows year bands (default)', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Bands: "2026" + "2025"
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('3 series'), findsOneWidget); // 2026 has 3
    expect(find.text('1 series'), findsOneWidget); // 2025 has 1
  });

  testWidgets('Month mode shows month-year bands', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Toggle to Month
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    // Bands: "May 2026", "April 2026", "March 2026", "May 2025"
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('May 2025'), findsOneWidget);
    // Each month band has exactly 1 series in this seed
    expect(find.text('1 series'), findsNWidgets(4));
  });

  testWidgets('Hide completed filters out 2025 series', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Confirm baseline: 2025 series present.
    expect(find.text('WPS 2025 Old'), findsOneWidget);

    // Tick Hide completed (Checkbox itself — Text has no onTap handler).
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // The 2025 completed series + its band should be gone.
    expect(find.text('WPS 2025 Old'), findsNothing);
    // Year band "2026" still visible (3 series intact).
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('3 series'), findsOneWidget);
    // No "1 series" band remaining (was 2025).
    expect(find.text('1 series'), findsNothing);
  });

  testWidgets('Toggle Year ↔ Month preserves visible series', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Year mode (default) — see all 4 series cards
    expect(find.text('WPS 2026 EU'), findsOneWidget);
    expect(find.text('WPS 2025 Old'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('WPS 2026 EU'), findsOneWidget);
    expect(find.text('WPS 2025 Old'), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('WPS 2026 EU'), findsOneWidget);
    expect(find.text('WPS 2025 Old'), findsOneWidget);
  });
}
