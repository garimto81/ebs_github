import 'package:flutter_test/flutter_test.dart';
import 'package:ebs_lobby/models/entities/series.dart';
import 'package:ebs_lobby/models/entities/ebs_event.dart';
import 'package:ebs_lobby/models/entities/event_flight.dart';
import 'package:ebs_lobby/models/entities/table.dart';
import 'package:ebs_lobby/models/entities/table_seat.dart';
import 'package:ebs_lobby/models/entities/player.dart';
import 'package:ebs_lobby/models/entities/session_user.dart';
import 'package:ebs_lobby/models/entities/audit_log.dart';
import 'package:ebs_lobby/models/entities/user.dart';
import 'package:ebs_lobby/models/entities/config.dart';
import 'package:ebs_lobby/models/entities/skin.dart';
import 'package:ebs_lobby/models/entities/skin_metadata.dart';
import 'package:ebs_lobby/models/entities/blind_structure.dart';
import 'package:ebs_lobby/models/entities/blind_structure_level.dart';
import 'package:ebs_lobby/models/entities/competition.dart';
import 'package:ebs_lobby/models/entities/hand.dart';

/// Verifies that Freezed entity models correctly parse real backend JSON.
/// JSON samples captured from http://localhost:8000 with seed data.
void main() {
  group('Series.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'series_id': 1,
        'competition_id': 1,
        'series_name': '2026 WSOP',
        'year': 2026,
        'begin_at': '2026-05-27',
        'end_at': '2026-07-16',
        'time_zone': 'UTC',
        'currency': 'USD',
        'country_code': null,
        'image_url': null,
        'is_completed': false,
        'is_displayed': true,
        'is_demo': false,
        'source': 'api',
        'created_at': '2026-04-16T08:48:47.145018+00:00',
        'updated_at': '2026-04-16T08:48:47.145018+00:00',
      };

      final series = Series.fromJson(json);
      expect(series.seriesId, 1);
      expect(series.competitionId, 1);
      expect(series.seriesName, '2026 WSOP');
      expect(series.year, 2026);
      expect(series.beginAt, '2026-05-27');
      expect(series.endAt, '2026-07-16');
      expect(series.timeZone, 'UTC');
      expect(series.currency, 'USD');
      expect(series.countryCode, isNull);
      expect(series.imageUrl, isNull);
      expect(series.isCompleted, false);
      expect(series.isDisplayed, true);
      expect(series.isDemo, false);
      expect(series.source, 'api');
      expect(series.createdAt, isNotEmpty);
      expect(series.updatedAt, isNotEmpty);
    });

    test('parses with is_demo present', () {
      final json = {
        'series_id': 2,
        'competition_id': 2,
        'series_name': 'Demo Series',
        'year': 2026,
        'begin_at': '2026-01-01',
        'end_at': '2026-01-02',
        'time_zone': 'UTC',
        'currency': 'USD',
        'is_completed': false,
        'is_displayed': true,
        'is_demo': true,
        'source': 'api',
        'created_at': '2026-01-01T00:00:00+00:00',
        'updated_at': '2026-01-01T00:00:00+00:00',
      };

      final series = Series.fromJson(json);
      expect(series.isDemo, true);
    });
  });

  group('EbsEvent.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'event_id': 1,
        'series_id': 1,
        'event_no': 1,
        'event_name': r"$10,000 NL Hold'em Main Event",
        'buy_in': null,
        'game_type': 0,
        'bet_structure': 0,
        'event_game_type': 0,
        'game_mode': 'single',
        'table_size': 9,
        'total_entries': 0,
        'players_left': 0,
        'status': 'created',
        'start_time': null,
        'source': 'api',
        'created_at': '2026-04-16T08:48:47.146517+00:00',
        'updated_at': '2026-04-16T08:48:47.146517+00:00',
      };

      final event = EbsEvent.fromJson(json);
      expect(event.eventId, 1);
      expect(event.seriesId, 1);
      expect(event.eventNo, 1);
      expect(event.eventName, contains('Main Event'));
      expect(event.gameType, 0);
      expect(event.betStructure, 0);
      expect(event.eventGameType, 0);
      expect(event.gameMode, 'single');
      expect(event.tableSize, 9);
      expect(event.totalEntries, 0);
      expect(event.playersLeft, 0);
      expect(event.status, 'created');
      expect(event.source, 'api');
    });
  });

  group('EventFlight.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'event_flight_id': 1,
        'event_id': 1,
        'display_name': 'Day 1A',
        'start_time': null,
        'is_tbd': false,
        'entries': 0,
        'players_left': 0,
        'table_count': 0,
        'status': 'running',
        'play_level': 1,
        'flight_id': 1,
        'day_index': 0,
        'flight_name': 'Day 1A',
        'source': 'api',
        'created_at': '2026-04-16T08:48:47.147520+00:00',
        'updated_at': '2026-04-16T08:48:47.147520+00:00',
      };

      final flight = EventFlight.fromJson(json);
      expect(flight.eventFlightId, 1);
      expect(flight.eventId, 1);
      expect(flight.displayName, 'Day 1A');
      expect(flight.isTbd, false);
      expect(flight.entries, 0);
      expect(flight.playersLeft, 0);
      expect(flight.tableCount, 0);
      expect(flight.status, 'running');
      expect(flight.playLevel, 1);
      expect(flight.source, 'api');
    });
  });

  group('EbsTable.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'table_id': 1,
        'event_flight_id': 1,
        'table_no': 1,
        'name': 'Feature Table 1',
        'type': 'feature',
        'status': 'live',
        'max_players': 9,
        'game_type': 0,
        'ante_type': 0,
        'ante_amount': 0,
        'deck_registered': false,
        'delay_seconds': 0,
        'is_breaking_table': false,
        'source': 'api',
        'created_at': '2026-04-16T08:48:47.149540+00:00',
        'updated_at': '2026-04-16T08:48:47.149540+00:00',
      };

      final table = EbsTable.fromJson(json);
      expect(table.tableId, 1);
      expect(table.eventFlightId, 1);
      expect(table.tableNo, 1);
      expect(table.name, 'Feature Table 1');
      expect(table.type, 'feature');
      expect(table.status, 'live');
      expect(table.maxPlayers, 9);
      expect(table.gameType, 0);
      expect(table.delaySeconds, 0);
      expect(table.source, 'api');
      expect(table.anteType, 0);
      expect(table.anteAmount, 0);
      expect(table.deckRegistered, false);
      expect(table.isBreakingTable, false);
    });
  });

  group('TableSeat.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'seat_id': 1,
        'table_id': 1,
        'seat_no': 0,
        'player_id': 1,
        'player_name': 'D. Negreanu',
        'nationality': null,
        'chip_count': 85000,
        'status': 'new',
        'created_at': '2026-04-16T08:48:47.151040+00:00',
        'updated_at': '2026-04-16T08:48:47.151040+00:00',
      };

      final seat = TableSeat.fromJson(json);
      expect(seat.seatId, 1);
      expect(seat.tableId, 1);
      expect(seat.seatNo, 0);
      expect(seat.playerId, 1);
      expect(seat.playerName, 'D. Negreanu');
      expect(seat.chipCount, 85000);
      expect(seat.status, 'new');
    });
  });

  group('Player.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'player_id': 1,
        'wsop_id': null,
        'first_name': 'Daniel',
        'last_name': 'Negreanu',
        'nationality': 'Canadian',
        'country_code': 'CA',
        'player_status': 'active',
        'is_demo': false,
        'source': 'api',
        'created_at': '2026-04-16T08:48:47.148535+00:00',
        'updated_at': '2026-04-16T08:48:47.148535+00:00',
      };

      final player = Player.fromJson(json);
      expect(player.playerId, 1);
      expect(player.firstName, 'Daniel');
      expect(player.lastName, 'Negreanu');
      expect(player.nationality, 'Canadian');
      expect(player.countryCode, 'CA');
      expect(player.playerStatus, 'active');
      expect(player.isDemo, false);
      expect(player.source, 'api');
    });
  });

  group('SessionUser.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'user_id': 1,
        'email': 'admin@ebs.local',
        'display_name': 'System Admin',
        'role': 'admin',
      };

      final user = SessionUser.fromJson(json);
      expect(user.userId, 1);
      expect(user.email, 'admin@ebs.local');
      expect(user.displayName, 'System Admin');
      expect(user.role, 'admin');
      expect(user.permissions, isEmpty);
      expect(user.tableIds, isEmpty);
    });
  });

  group('AuditLog.fromJson', () {
    test('parses expected audit log structure', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'entity_type': 'series',
        'entity_id': 1,
        'action': 'create',
        'detail': 'Created series',
        'ip_address': '127.0.0.1',
        'created_at': '2026-04-16T09:00:00+00:00',
      };

      final log = AuditLog.fromJson(json);
      expect(log.id, 1);
      expect(log.userId, 1);
      expect(log.entityType, 'series');
      expect(log.entityId, 1);
      expect(log.action, 'create');
      expect(log.detail, 'Created series');
      expect(log.ipAddress, '127.0.0.1');
      expect(log.createdAt, isNotEmpty);
    });
  });

  // =========================================================================
  // New entity parse tests
  // =========================================================================

  group('User.fromJson', () {
    test('parses user response from /users', () {
      final json = {
        'user_id': 1,
        'email': 'admin@ebs.local',
        'display_name': 'System Admin',
        'role': 'admin',
        'is_active': true,
        'totp_enabled': false,
        'last_login_at': '2026-04-16T10:00:00+00:00',
        'created_at': '2026-04-15T00:00:00+00:00',
        'updated_at': '2026-04-16T10:00:00+00:00',
      };

      final user = User.fromJson(json);
      expect(user.userId, 1);
      expect(user.email, 'admin@ebs.local');
      expect(user.displayName, 'System Admin');
      expect(user.role, 'admin');
      expect(user.isActive, true);
      expect(user.totpEnabled, false);
      expect(user.lastLoginAt, isNotNull);
      expect(user.createdAt, isNotEmpty);
      expect(user.updatedAt, isNotEmpty);
    });

    test('parses with null last_login_at', () {
      final json = {
        'user_id': 2,
        'email': 'operator@ebs.local',
        'display_name': 'Operator',
        'role': 'operator',
        'is_active': true,
        'totp_enabled': false,
        'last_login_at': null,
        'created_at': '2026-04-15T00:00:00+00:00',
        'updated_at': '2026-04-15T00:00:00+00:00',
      };

      final user = User.fromJson(json);
      expect(user.userId, 2);
      expect(user.lastLoginAt, isNull);
      expect(user.isActive, true);
    });
  });

  group('EbsConfig.fromJson', () {
    test('parses config response from /configs/{section}', () {
      final json = {
        'id': 1,
        'key': 'output_resolution',
        'value': '1920x1080',
        'category': 'outputs',
        'description': 'Output resolution for overlay',
      };

      final config = EbsConfig.fromJson(json);
      expect(config.id, 1);
      expect(config.key, 'output_resolution');
      expect(config.value, '1920x1080');
      expect(config.category, 'outputs');
      expect(config.description, 'Output resolution for overlay');
    });

    test('parses with null description', () {
      final json = {
        'id': 2,
        'key': 'output_fps',
        'value': '60',
        'category': 'outputs',
        'description': null,
      };

      final config = EbsConfig.fromJson(json);
      expect(config.id, 2);
      expect(config.key, 'output_fps');
      expect(config.description, isNull);
    });
  });

  group('Skin.fromJson', () {
    test('parses skin response with nested metadata', () {
      final json = {
        'skin_id': 1,
        'name': 'Default WSOP Skin',
        'version': '1.0.0',
        'status': 'active',
        'metadata': {
          'title': 'Default WSOP',
          'description': 'Standard WSOP overlay skin',
          'author': 'EBS Team',
          'tags': ['wsop', 'default'],
        },
        'file_size': 2048576,
        'uploaded_at': '2026-04-15T00:00:00+00:00',
        'activated_at': '2026-04-15T01:00:00+00:00',
        'preview_url': 'https://cdn.ebs.local/skins/1/preview.png',
      };

      final skin = Skin.fromJson(json);
      expect(skin.skinId, 1);
      expect(skin.name, 'Default WSOP Skin');
      expect(skin.version, '1.0.0');
      expect(skin.status, 'active');
      expect(skin.metadata.title, 'Default WSOP');
      expect(skin.metadata.description, 'Standard WSOP overlay skin');
      expect(skin.metadata.author, 'EBS Team');
      expect(skin.metadata.tags, ['wsop', 'default']);
      expect(skin.fileSize, 2048576);
      expect(skin.uploadedAt, isNotEmpty);
      expect(skin.activatedAt, isNotNull);
      expect(skin.previewUrl, contains('preview.png'));
    });

    test('parses skin with null optional fields', () {
      final json = {
        'skin_id': 2,
        'name': 'Custom Skin',
        'version': '0.1.0',
        'status': 'draft',
        'metadata': {
          'title': 'Custom',
          'description': 'A custom skin',
        },
        'file_size': 1024,
        'uploaded_at': '2026-04-16T00:00:00+00:00',
        'activated_at': null,
        'preview_url': null,
      };

      final skin = Skin.fromJson(json);
      expect(skin.skinId, 2);
      expect(skin.status, 'draft');
      expect(skin.activatedAt, isNull);
      expect(skin.previewUrl, isNull);
      expect(skin.metadata.author, isNull);
      expect(skin.metadata.tags, isEmpty);
    });
  });

  group('BlindStructure.fromJson', () {
    test('parses blind structure response', () {
      final json = {
        'blind_structure_id': 1,
        'name': 'Standard NL Holdem',
        'created_at': '2026-04-15T00:00:00+00:00',
        'updated_at': '2026-04-15T00:00:00+00:00',
      };

      final bs = BlindStructure.fromJson(json);
      expect(bs.blindStructureId, 1);
      expect(bs.name, 'Standard NL Holdem');
      expect(bs.createdAt, isNotEmpty);
      expect(bs.updatedAt, isNotEmpty);
    });
  });

  group('BlindStructureLevel.fromJson', () {
    test('parses nested level within blind structure', () {
      final json = {
        'id': 1,
        'blind_structure_id': 1,
        'level_no': 1,
        'small_blind': 100,
        'big_blind': 200,
        'ante': 25,
        'duration_minutes': 30,
      };

      final level = BlindStructureLevel.fromJson(json);
      expect(level.id, 1);
      expect(level.blindStructureId, 1);
      expect(level.levelNo, 1);
      expect(level.smallBlind, 100);
      expect(level.bigBlind, 200);
      expect(level.ante, 25);
      expect(level.durationMinutes, 30);
    });

    test('parses higher level with larger blinds', () {
      final json = {
        'id': 10,
        'blind_structure_id': 1,
        'level_no': 10,
        'small_blind': 5000,
        'big_blind': 10000,
        'ante': 1000,
        'duration_minutes': 60,
      };

      final level = BlindStructureLevel.fromJson(json);
      expect(level.levelNo, 10);
      expect(level.smallBlind, 5000);
      expect(level.bigBlind, 10000);
      expect(level.ante, 1000);
      expect(level.durationMinutes, 60);
    });
  });

  group('Competition.fromJson', () {
    test('parses competition response', () {
      final json = {
        'competition_id': 1,
        'name': 'WSOP',
        'competition_type': 0,
        'competition_tag': 1,
        'created_at': '2026-04-15T00:00:00+00:00',
        'updated_at': '2026-04-15T00:00:00+00:00',
      };

      final comp = Competition.fromJson(json);
      expect(comp.competitionId, 1);
      expect(comp.name, 'WSOP');
      expect(comp.competitionType, 0);
      expect(comp.competitionTag, 1);
      expect(comp.createdAt, isNotEmpty);
      expect(comp.updatedAt, isNotEmpty);
    });
  });

  group('Hand.fromJson', () {
    test('parses hand response with table_id filter', () {
      final json = {
        'hand_id': 1,
        'table_id': 1,
        'hand_number': 1,
        'game_type': 0,
        'bet_structure': 0,
        'dealer_seat': 3,
        'board_cards': 'Ah Kd Qc Js 10h',
        'pot_total': 150000,
        'side_pots': '[]',
        'current_street': 'river',
        'started_at': '2026-04-16T10:00:00+00:00',
        'ended_at': '2026-04-16T10:05:00+00:00',
        'duration_sec': 300,
        'created_at': '2026-04-16T10:00:00+00:00',
      };

      final hand = Hand.fromJson(json);
      expect(hand.handId, 1);
      expect(hand.tableId, 1);
      expect(hand.handNumber, 1);
      expect(hand.gameType, 0);
      expect(hand.betStructure, 0);
      expect(hand.dealerSeat, 3);
      expect(hand.boardCards, contains('Ah'));
      expect(hand.potTotal, 150000);
      expect(hand.sidePots, '[]');
      expect(hand.currentStreet, 'river');
      expect(hand.startedAt, isNotEmpty);
      expect(hand.endedAt, isNotNull);
      expect(hand.durationSec, 300);
    });

    test('parses hand with null optional fields (in-progress)', () {
      final json = {
        'hand_id': 2,
        'table_id': 1,
        'hand_number': 2,
        'game_type': 0,
        'bet_structure': 0,
        'dealer_seat': 4,
        'board_cards': '',
        'pot_total': 300,
        'side_pots': '[]',
        'current_street': null,
        'started_at': '2026-04-16T10:10:00+00:00',
        'ended_at': null,
        'duration_sec': 0,
        'created_at': '2026-04-16T10:10:00+00:00',
      };

      final hand = Hand.fromJson(json);
      expect(hand.handId, 2);
      expect(hand.currentStreet, isNull);
      expect(hand.endedAt, isNull);
      expect(hand.durationSec, 0);
      expect(hand.boardCards, isEmpty);
    });
  });

  group('SkinMetadata.fromJson', () {
    test('parses metadata with all fields', () {
      final json = {
        'title': 'WSOP Main',
        'description': 'Official WSOP main event skin',
        'author': 'Design Team',
        'tags': ['official', 'wsop', 'main-event'],
      };

      final meta = SkinMetadata.fromJson(json);
      expect(meta.title, 'WSOP Main');
      expect(meta.description, 'Official WSOP main event skin');
      expect(meta.author, 'Design Team');
      expect(meta.tags, hasLength(3));
      expect(meta.tags, contains('official'));
    });

    test('parses metadata with minimal fields', () {
      final json = {
        'title': 'Minimal',
        'description': 'A minimal skin',
      };

      final meta = SkinMetadata.fromJson(json);
      expect(meta.title, 'Minimal');
      expect(meta.author, isNull);
      expect(meta.tags, isEmpty);
    });
  });
}
