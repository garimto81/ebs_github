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
        'seriesId': 1,
        'competitionId': 1,
        'seriesName': '2026 WSOP',
        'year': 2026,
        'beginAt': '2026-05-27',
        'endAt': '2026-07-16',
        'timeZone': 'UTC',
        'currency': 'USD',
        'countryCode': null,
        'imageUrl': null,
        'isCompleted': false,
        'isDisplayed': true,
        'isDemo': false,
        'source': 'api',
        'createdAt': '2026-04-16T08:48:47.145018+00:00',
        'updatedAt': '2026-04-16T08:48:47.145018+00:00',
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
        'seriesId': 2,
        'competitionId': 2,
        'seriesName': 'Demo Series',
        'year': 2026,
        'beginAt': '2026-01-01',
        'endAt': '2026-01-02',
        'timeZone': 'UTC',
        'currency': 'USD',
        'isCompleted': false,
        'isDisplayed': true,
        'isDemo': true,
        'source': 'api',
        'createdAt': '2026-01-01T00:00:00+00:00',
        'updatedAt': '2026-01-01T00:00:00+00:00',
      };

      final series = Series.fromJson(json);
      expect(series.isDemo, true);
    });
  });

  group('EbsEvent.fromJson', () {
    test('parses real backend response', () {
      final json = {
        'eventId': 1,
        'seriesId': 1,
        'eventNo': 1,
        'eventName': r"$10,000 NL Hold'em Main Event",
        'buyIn': null,
        'gameType': 0,
        'betStructure': 0,
        'eventGameType': 0,
        'gameMode': 'single',
        'tableSize': 9,
        'totalEntries': 0,
        'playersLeft': 0,
        'status': 'created',
        'startTime': null,
        'source': 'api',
        'createdAt': '2026-04-16T08:48:47.146517+00:00',
        'updatedAt': '2026-04-16T08:48:47.146517+00:00',
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
        'eventFlightId': 1,
        'eventId': 1,
        'displayName': 'Day 1A',
        'startTime': null,
        'isTbd': false,
        'entries': 0,
        'playersLeft': 0,
        'tableCount': 0,
        'status': 'running',
        'playLevel': 1,
        'flightId': 1,
        'dayIndex': 0,
        'flightName': 'Day 1A',
        'source': 'api',
        'createdAt': '2026-04-16T08:48:47.147520+00:00',
        'updatedAt': '2026-04-16T08:48:47.147520+00:00',
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
        'tableId': 1,
        'eventFlightId': 1,
        'tableNo': 1,
        'name': 'Feature Table 1',
        'type': 'feature',
        'status': 'live',
        'maxPlayers': 9,
        'gameType': 0,
        'anteType': 0,
        'anteAmount': 0,
        'deckRegistered': false,
        'delaySeconds': 0,
        'isBreakingTable': false,
        'source': 'api',
        'createdAt': '2026-04-16T08:48:47.149540+00:00',
        'updatedAt': '2026-04-16T08:48:47.149540+00:00',
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
        'seatId': 1,
        'tableId': 1,
        'seatNo': 0,
        'playerId': 1,
        'playerName': 'D. Negreanu',
        'nationality': null,
        'chipCount': 85000,
        'status': 'new',
        'createdAt': '2026-04-16T08:48:47.151040+00:00',
        'updatedAt': '2026-04-16T08:48:47.151040+00:00',
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
        'playerId': 1,
        'wsopId': null,
        'firstName': 'Daniel',
        'lastName': 'Negreanu',
        'nationality': 'Canadian',
        'countryCode': 'CA',
        'playerStatus': 'active',
        'isDemo': false,
        'source': 'api',
        'createdAt': '2026-04-16T08:48:47.148535+00:00',
        'updatedAt': '2026-04-16T08:48:47.148535+00:00',
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
        'userId': 1,
        'email': 'admin@ebs.local',
        'displayName': 'System Admin',
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
        'userId': 1,
        'entityType': 'series',
        'entityId': 1,
        'action': 'create',
        'detail': 'Created series',
        'ipAddress': '127.0.0.1',
        'createdAt': '2026-04-16T09:00:00+00:00',
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
        'userId': 1,
        'email': 'admin@ebs.local',
        'displayName': 'System Admin',
        'role': 'admin',
        'isActive': true,
        'totpEnabled': false,
        'lastLoginAt': '2026-04-16T10:00:00+00:00',
        'createdAt': '2026-04-15T00:00:00+00:00',
        'updatedAt': '2026-04-16T10:00:00+00:00',
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
        'userId': 2,
        'email': 'operator@ebs.local',
        'displayName': 'Operator',
        'role': 'operator',
        'isActive': true,
        'totpEnabled': false,
        'lastLoginAt': null,
        'createdAt': '2026-04-15T00:00:00+00:00',
        'updatedAt': '2026-04-15T00:00:00+00:00',
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
        'skinId': 1,
        'name': 'Default WSOP Skin',
        'version': '1.0.0',
        'status': 'active',
        'metadata': {
          'title': 'Default WSOP',
          'description': 'Standard WSOP overlay skin',
          'author': 'EBS Team',
          'tags': ['wsop', 'default'],
        },
        'fileSize': 2048576,
        'uploadedAt': '2026-04-15T00:00:00+00:00',
        'activatedAt': '2026-04-15T01:00:00+00:00',
        'previewUrl': 'https://cdn.ebs.local/skins/1/preview.png',
      };

      final skin = Skin.fromJson(json);
      expect(skin.skinId, 1);
      expect(skin.name, 'Default WSOP Skin');
      expect(skin.version, '1.0.0');
      expect(skin.status, 'active');
      expect(skin.safeMetadata.title, 'Default WSOP');
      expect(skin.safeMetadata.description, 'Standard WSOP overlay skin');
      expect(skin.safeMetadata.author, 'EBS Team');
      expect(skin.safeMetadata.tags, ['wsop', 'default']);
      expect(skin.fileSize, 2048576);
      expect(skin.uploadedAt, isNotEmpty);
      expect(skin.activatedAt, isNotNull);
      expect(skin.previewUrl, contains('preview.png'));
    });

    test('parses skin with null optional fields', () {
      final json = {
        'skinId': 2,
        'name': 'Custom Skin',
        'version': '0.1.0',
        'status': 'draft',
        'metadata': {
          'title': 'Custom',
          'description': 'A custom skin',
        },
        'fileSize': 1024,
        'uploadedAt': '2026-04-16T00:00:00+00:00',
        'activatedAt': null,
        'previewUrl': null,
      };

      final skin = Skin.fromJson(json);
      expect(skin.skinId, 2);
      expect(skin.status, 'draft');
      expect(skin.activatedAt, isNull);
      expect(skin.previewUrl, isNull);
      expect(skin.safeMetadata.author, isNull);
      expect(skin.safeMetadata.tags, isEmpty);
    });
  });

  group('BlindStructure.fromJson', () {
    test('parses blind structure response', () {
      final json = {
        'blindStructureId': 1,
        'name': 'Standard NL Holdem',
        'createdAt': '2026-04-15T00:00:00+00:00',
        'updatedAt': '2026-04-15T00:00:00+00:00',
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
        'blindStructureId': 1,
        'levelNo': 1,
        'smallBlind': 100,
        'bigBlind': 200,
        'ante': 25,
        'durationMinutes': 30,
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
        'blindStructureId': 1,
        'levelNo': 10,
        'smallBlind': 5000,
        'bigBlind': 10000,
        'ante': 1000,
        'durationMinutes': 60,
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
        'competitionId': 1,
        'name': 'WSOP',
        'competitionType': 0,
        'competitionTag': 1,
        'createdAt': '2026-04-15T00:00:00+00:00',
        'updatedAt': '2026-04-15T00:00:00+00:00',
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
        'handId': 1,
        'tableId': 1,
        'handNumber': 1,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 3,
        'boardCards': 'Ah Kd Qc Js 10h',
        'potTotal': 150000,
        'sidePots': '[]',
        'currentStreet': 'river',
        'startedAt': '2026-04-16T10:00:00+00:00',
        'endedAt': '2026-04-16T10:05:00+00:00',
        'durationSec': 300,
        'createdAt': '2026-04-16T10:00:00+00:00',
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
        'handId': 2,
        'tableId': 1,
        'handNumber': 2,
        'gameType': 0,
        'betStructure': 0,
        'dealerSeat': 4,
        'boardCards': '',
        'potTotal': 300,
        'sidePots': '[]',
        'currentStreet': null,
        'startedAt': '2026-04-16T10:10:00+00:00',
        'endedAt': null,
        'durationSec': 0,
        'createdAt': '2026-04-16T10:10:00+00:00',
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
