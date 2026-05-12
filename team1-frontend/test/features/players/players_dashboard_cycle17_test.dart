// Cycle 17 Player Dashboard cascade — 4 핵심 필드 widget golden test.
//
// 검증 대상: PlayersScreen 의 DataTable 에 Name + Country (국기+ISO) +
// Position (D/SB/BB chip) + Stack 4 필드가 모두 표시되는지.
//
// 정본 명세: docs/2. Development/2.1 Frontend/Lobby/Overview.md
//             §Player 독립 레이어 (Cycle 17 cascade 박스).
//
// Evidence 출력: test/features/players/goldens/cycle17-player-dashboard.png
//   → CI 후 integration-tests/evidence/cycle17-player-dashboard/ 로 복사.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/lobby/providers/player_provider.dart';
import 'package:ebs_lobby/features/players/screens/players_screen.dart';
import 'package:ebs_lobby/models/entities/player.dart';
import 'package:ebs_lobby/repositories/player_repository.dart';

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository(this._players);
  final List<Player> _players;

  @override
  Future<List<Player>> listPlayers({Map<String, dynamic>? params}) async =>
      _players;

  @override
  Future<Player> getPlayer(int id) async =>
      _players.firstWhere((p) => p.playerId == id);

  @override
  Future<List<Player>> searchPlayers(
    String query, {
    Map<String, dynamic>? params,
  }) async =>
      _players
          .where(
            (p) => '${p.firstName} ${p.lastName}'
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
}

Player _mkPlayer({
  required int id,
  required String first,
  required String last,
  required String? nationality,
  required String? country,
  required String? position,
  required int stack,
  required String? table,
  required int seat,
  String status = 'active',
}) {
  const ts = '2026-05-13T00:00:00Z';
  return Player(
    playerId: id,
    firstName: first,
    lastName: last,
    nationality: nationality,
    countryCode: country,
    playerStatus: status,
    source: 'wsop-live',
    createdAt: ts,
    updatedAt: ts,
    position: position,
    stack: stack,
    tableName: table,
    seatIndex: seat,
  );
}

void main() {
  testWidgets(
    'Cycle 17 — Player Dashboard 4 필드 (Name + Country + Position + Stack)',
    (tester) async {
      final mockPlayers = [
        _mkPlayer(
          id: 1,
          first: 'Daniel',
          last: 'Negreanu',
          nationality: 'Canadian',
          country: 'CA',
          position: 'D',
          stack: 1250000,
          table: 'Featured 1',
          seat: 1,
        ),
        _mkPlayer(
          id: 2,
          first: 'Phil',
          last: 'Ivey',
          nationality: 'American',
          country: 'US',
          position: 'SB',
          stack: 980000,
          table: 'Featured 1',
          seat: 2,
        ),
        _mkPlayer(
          id: 3,
          first: 'Hellmuth',
          last: 'Phil',
          nationality: 'American',
          country: 'US',
          position: 'BB',
          stack: 540000,
          table: 'Featured 1',
          seat: 3,
        ),
        _mkPlayer(
          id: 4,
          first: 'Masashi',
          last: 'Oya',
          nationality: 'Japanese',
          country: 'JP',
          position: 'UTG',
          stack: 320000,
          table: 'Featured 1',
          seat: 4,
        ),
        _mkPlayer(
          id: 5,
          first: 'Pius',
          last: 'Heinz',
          nationality: 'German',
          country: 'DE',
          position: 'CO',
          stack: 215000,
          table: 'Featured 1',
          seat: 5,
        ),
        _mkPlayer(
          id: 6,
          first: 'Hyun-Jin',
          last: 'Kim',
          nationality: 'Korean',
          country: 'KR',
          position: null,
          stack: 0,
          table: null,
          seat: 0,
          status: 'busted',
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(1280, 720));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(
              _FakePlayerRepository(mockPlayers),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: const PlayersScreen(),
          ),
        ),
      );

      // 1) Loading → Data 전이 대기.
      await tester.pumpAndSettle();

      // 2) DataTable 의 핵심 4 컬럼 헤더가 표시되는지.
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('Pos'), findsOneWidget);
      expect(find.text('Stack'), findsOneWidget);

      // 3) Position chip — D / SB / BB / UTG / CO 모두 렌더링.
      expect(find.text('D'), findsOneWidget);
      expect(find.text('SB'), findsOneWidget);
      expect(find.text('BB'), findsOneWidget);
      expect(find.text('UTG'), findsOneWidget);
      expect(find.text('CO'), findsOneWidget);

      // 4) Country code 텍스트 (ISO 2-letter).
      expect(find.text('CA'), findsOneWidget);
      expect(find.textContaining('US'), findsWidgets);
      expect(find.text('JP'), findsOneWidget);
      expect(find.text('DE'), findsOneWidget);
      expect(find.text('KR'), findsOneWidget);

      // 5) Stack 포맷 (콤마 separator).
      expect(find.text('1,250,000'), findsOneWidget);
      expect(find.text('980,000'), findsOneWidget);

      // 6) Position null → "—" fallback.
      expect(find.text('—'), findsWidgets);

      // 7) Player name 6명 모두 렌더 (busted 포함).
      // DataRow 는 widget 이 아니라 helper class 라 key 검색 불가 — 이름 텍스트로 검증.
      expect(find.text('Daniel Negreanu'), findsOneWidget);
      expect(find.text('Phil Ivey'), findsOneWidget);
      expect(find.text('Hellmuth Phil'), findsOneWidget);
      expect(find.text('Masashi Oya'), findsOneWidget);
      expect(find.text('Pius Heinz'), findsOneWidget);
      expect(find.text('Hyun-Jin Kim'), findsOneWidget);

      // 8) Golden screenshot 캡처 — evidence.
      // NOTE: golden 은 시스템 폰트/렌더링 차이로 픽셀 비교가 실패 가능.
      // CI 에서는 `--update-goldens` 로 baseline 갱신 후 비교.
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cycle17-player-dashboard.png'),
      );
    },
  );
}
