import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebs_lobby/app.dart';
import 'package:ebs_lobby/features/auth/auth_provider.dart';
import 'package:ebs_lobby/models/models.dart';
import 'package:ebs_lobby/repositories/auth_repository.dart';
import 'package:ebs_lobby/repositories/series_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

/// AuthNotifier pre-seeded with authenticated state.
class _AuthenticatedNotifier extends AuthNotifier {
  _AuthenticatedNotifier(super.repo) {
    state = const AuthState(
      status: AuthStatus.authenticated,
      accessToken: 'test-jwt',
      user: SessionUser(
        userId: 1,
        email: 'test@ebs.local',
        displayName: 'Test User',
        role: 'admin',
      ),
    );
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockSeriesRepository mockSeriesRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockSeriesRepo = MockSeriesRepository();

    // Stub refreshToken to prevent unhandled Dio calls.
    when(() => mockAuthRepo.refreshToken())
        .thenThrow(Exception('No session'));
    // Stub listSeries to return an empty list.
    when(() => mockSeriesRepo.listSeries())
        .thenAnswer((_) async => <Series>[]);
  });

  testWidgets('EbsLobbyApp renders without error (unauthenticated)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepo),
        ],
        child: const EbsLobbyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EbsLobbyApp), findsOneWidget);
  });

  testWidgets('shows 5-nav shell when authenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authProvider
              .overrideWith((_) => _AuthenticatedNotifier(mockAuthRepo)),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepo),
        ],
        child: const EbsLobbyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The 5-nav shell should render NavigationRail labels.
    expect(find.text('Lobby'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('GFX'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
}
