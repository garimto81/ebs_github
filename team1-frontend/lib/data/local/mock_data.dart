// lib/data/local/mock_data.dart — In-memory mock fixtures.
// Ported from _archive-quasar/src/mocks/data.ts.
// 1 Competition / 2 Series / 5 Events / 10 Flights / 20 Tables / 100 Players /
// 9 Seats / 4 Users / 3 Blind Structures / 3 Skins / 10 Hands / 9 HandPlayers /
// 11 HandActions / 15 AuditLogs / 6 Config sections.

import 'package:ebs_lobby/models/models.dart';

const _now = '2026-04-09T12:00:00';

class MockData {
  MockData._();

  // ---- Competition ----
  static final List<Competition> competitions = [
    const Competition(
      competitionId: 1,
      name: 'WSOP',
      competitionType: 1,
      competitionTag: 1,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  // ---- Series ----
  static final List<Series> series = [
    const Series(
      seriesId: 1,
      competitionId: 1,
      seriesName: 'WSOP Europe 2026',
      year: 2026,
      beginAt: '2026-04-01T12:00:00',
      endAt: '2026-04-20T12:00:00',
      timeZone: 'Europe/Paris',
      currency: 'EUR',
      countryCode: 'FR',
      isCompleted: false,
      isDisplayed: true,
      isDemo: false,
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
    const Series(
      seriesId: 2,
      competitionId: 1,
      seriesName: '58th Annual WSOP',
      year: 2026,
      beginAt: '2026-05-28T12:00:00',
      endAt: '2026-07-17T12:00:00',
      timeZone: 'America/Los_Angeles',
      currency: 'USD',
      countryCode: 'US',
      isCompleted: false,
      isDisplayed: true,
      isDemo: false,
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  // ---- Events ----
  static final List<EbsEvent> events = [
    const EbsEvent(
      eventId: 1,
      seriesId: 1,
      eventNo: 1,
      eventName: '#1 \u20ac1,100 Mystery Bounty NLH',
      buyIn: 1100,
      displayBuyIn: '\u20ac1,100',
      gameType: 0,
      betStructure: 0,
      eventGameType: 0,
      gameMode: 'tournament',
      startingChip: 30000,
      tableSize: 9,
      totalEntries: 542,
      playersLeft: 87,
      startTime: '2026-04-05T14:00:00',
      status: 'running',
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
    const EbsEvent(
      eventId: 2,
      seriesId: 1,
      eventNo: 2,
      eventName: '#2 \u20ac600 PLO/PLO8/Big O',
      buyIn: 600,
      displayBuyIn: '\u20ac600',
      gameType: 21,
      betStructure: 1,
      eventGameType: 21,
      gameMode: 'mix',
      allowedGames: '2,3,11',
      rotationOrder: '2,3,11',
      rotationTrigger: 'level',
      startingChip: 20000,
      tableSize: 9,
      totalEntries: 0,
      playersLeft: 0,
      startTime: '2026-04-10T14:00:00',
      status: 'registering',
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
    const EbsEvent(
      eventId: 3,
      seriesId: 1,
      eventNo: 3,
      eventName: '#3 \u20ac550 Deepstack NLH',
      buyIn: 550,
      displayBuyIn: '\u20ac550',
      gameType: 0,
      betStructure: 0,
      eventGameType: 0,
      gameMode: 'tournament',
      startingChip: 40000,
      tableSize: 9,
      totalEntries: 388,
      playersLeft: 0,
      startTime: '2026-04-03T14:00:00',
      status: 'completed',
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
    const EbsEvent(
      eventId: 5,
      seriesId: 1,
      eventNo: 5,
      eventName: '#5 \u20ac5,300 Main Event NLH',
      buyIn: 5300,
      displayBuyIn: '\u20ac5,300',
      gameType: 0,
      betStructure: 0,
      eventGameType: 0,
      gameMode: 'tournament',
      startingChip: 50000,
      tableSize: 9,
      totalEntries: 1486,
      playersLeft: 918,
      startTime: '2026-04-07T12:00:00',
      status: 'running',
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
    const EbsEvent(
      eventId: 6,
      seriesId: 1,
      eventNo: 6,
      eventName: '#6 \u20ac600 Turbo NLH',
      buyIn: 600,
      displayBuyIn: '\u20ac600',
      gameType: 0,
      betStructure: 0,
      eventGameType: 0,
      gameMode: 'tournament',
      startingChip: 15000,
      tableSize: 9,
      totalEntries: 0,
      playersLeft: 0,
      startTime: '2026-04-12T18:00:00',
      status: 'announced',
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  // ---- Flights ----
  static final List<EventFlight> flights = _buildFlights();

  static List<EventFlight> _buildFlights() {
    const raw = <_RawFlight>[
      _RawFlight(1, 5, 'Day 1A', '2026-04-07T12:00:00', 336, 0, 136, 'completed', 12, null),
      _RawFlight(2, 5, 'Day 1B', '2026-04-07T17:00:00', 269, 0, 140, 'completed', 12, null),
      _RawFlight(3, 5, 'Day 1C', '2026-04-08T12:00:00', 299, 0, 154, 'completed', 12, null),
      _RawFlight(4, 5, 'Day 2', '2026-04-09T12:00:00', 918, 918, 124, 'running', 3, 3240),
      _RawFlight(5, 5, 'Day 3', '2026-04-10T12:00:00', 0, 0, 0, 'announced', 0, null),
      _RawFlight(6, 5, 'Day 4', '2026-04-11T12:00:00', 0, 0, 0, 'announced', 0, null),
      _RawFlight(7, 1, 'Day 1', '2026-04-05T14:00:00', 542, 87, 60, 'running', 8, 900),
      _RawFlight(8, 3, 'Day 1', '2026-04-03T14:00:00', 388, 0, 0, 'completed', 20, null),
      _RawFlight(9, 2, 'Day 1', '2026-04-10T14:00:00', 0, 0, 0, 'announced', 0, null),
      _RawFlight(10, 6, 'Day 1', '2026-04-12T18:00:00', 0, 0, 0, 'announced', 0, null),
    ];

    final dayCounters = <int, int>{};
    return raw.map((f) {
      dayCounters[f.eventId] = (dayCounters[f.eventId] ?? 0) + 1;
      return EventFlight(
        eventFlightId: f.id,
        eventId: f.eventId,
        displayName: f.displayName,
        startTime: f.startTime,
        isTbd: false,
        entries: f.entries,
        playersLeft: f.playersLeft,
        tableCount: f.tableCount,
        status: f.status,
        playLevel: f.playLevel,
        remainTime: f.remainTime,
        source: 'manual',
        createdAt: _now,
        updatedAt: _now,
      );
    }).toList();
  }

  // ---- Tables ----
  static final List<EbsTable> tables = List.generate(20, (i) {
    final tableNo = i + 1;
    final String status;
    if (i < 15) {
      status = 'live';
    } else if (i < 18) {
      status = 'setup';
    } else {
      status = 'empty';
    }
    return EbsTable(
      tableId: i + 1,
      eventFlightId: 4,
      tableNo: tableNo,
      name: 'Table-${tableNo.toString().padLeft(3, '0')}',
      type: tableNo <= 2 ? 'feature' : 'general',
      status: status,
      maxPlayers: 9,
      gameType: 0,
      smallBlind: status == 'empty' ? null : 1200,
      bigBlind: status == 'empty' ? null : 2400,
      anteType: 1,
      anteAmount: 2400,
      rfidReaderId: tableNo <= 2 ? tableNo : null,
      deckRegistered: tableNo == 1,
      outputType: tableNo <= 2 ? 'NDI' : null,
      currentGame: status == 'live' ? 47 : null,
      delaySeconds: tableNo <= 2 ? 30 : 0,
      isBreakingTable: false,
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    );
  });

  // ---- Famous player templates ----
  static const _famous = <List<String>>[
    ['Phil', 'Hellmuth', 'US', 'American'],
    ['Daniel', 'Negreanu', 'CA', 'Canadian'],
    ['Doyle', 'Brunson', 'US', 'American'],
    ['Johnny', 'Chan', 'US', 'American'],
    ['Stu', 'Ungar', 'US', 'American'],
    ['Erik', 'Seidel', 'US', 'American'],
    ['Chris', 'Moneymaker', 'US', 'American'],
    ['Vanessa', 'Selbst', 'US', 'American'],
    ['Fedor', 'Holz', 'DE', 'German'],
    ['Justin', 'Bonomo', 'US', 'American'],
  ];

  // ---- Players ----
  static final List<Player> players = List.generate(100, (i) {
    final t = _famous[i % _famous.length];
    return Player(
      playerId: i + 1,
      wsopId: 'P-${(i + 1).toString().padLeft(5, '0')}',
      firstName: t[0],
      lastName: i < 10 ? t[1] : '${t[1]}-${i + 1}',
      nationality: t[3],
      countryCode: t[2],
      playerStatus: 'active',
      isDemo: false,
      source: 'manual',
      createdAt: _now,
      updatedAt: _now,
    );
  });

  // ---- Seats (Table 1, 9 seats) ----
  static final List<TableSeat> seats = List.generate(9, (i) {
    return TableSeat(
      seatId: i + 1,
      tableId: 1,
      seatNo: i + 1,
      playerId: i + 1,
      wsopId: 'P-${(i + 1).toString().padLeft(5, '0')}',
      playerName: '${_famous[i][0]} ${_famous[i][1]}',
      nationality: _famous[i][3],
      countryCode: _famous[i][2],
      chipCount: (i + 1) * 25000,
      status: 'occupied',
      createdAt: _now,
      updatedAt: _now,
    );
  });

  // ---- Session user (admin) ----
  static const sessionUser = SessionUser(
    userId: 1,
    email: 'admin@ebs.local',
    displayName: 'Admin',
    role: 'admin',
    permissions: {
      'Lobby': 7,
      'Settings': 7,
      'GraphicEditor': 7,
    },
    tableIds: [],
  );

  static const sessionPayload = <String, dynamic>{
    'last_series_id': 1,
    'last_event_id': 5,
    'last_flight_id': 4,
    'last_table_id': 1,
  };

  // ---- Users (Staff) ----
  static final List<User> users = [
    const User(userId: 1, email: 'admin@ebs.local', displayName: 'Admin', role: 'admin', isActive: true, totpEnabled: false, lastLoginAt: _now, createdAt: _now, updatedAt: _now),
    const User(userId: 2, email: 'operator1@ebs.local', displayName: 'Operator 1', role: 'operator', isActive: true, totpEnabled: false, lastLoginAt: '2026-04-09T10:00:00', createdAt: _now, updatedAt: _now),
    const User(userId: 3, email: 'operator2@ebs.local', displayName: 'Operator 2', role: 'operator', isActive: true, totpEnabled: false, lastLoginAt: '2026-04-08T18:00:00', createdAt: _now, updatedAt: _now),
    const User(userId: 4, email: 'viewer@ebs.local', displayName: 'Viewer', role: 'viewer', isActive: false, totpEnabled: false, createdAt: _now, updatedAt: _now),
  ];

  // ---- Blind Structures ----
  static final List<BlindStructure> blindStructures = [
    const BlindStructure(blindStructureId: 1, name: 'Standard 20min', createdAt: _now, updatedAt: _now),
    const BlindStructure(blindStructureId: 2, name: 'Turbo 12min', createdAt: _now, updatedAt: _now),
    const BlindStructure(blindStructureId: 3, name: 'Deep Stack 30min', createdAt: _now, updatedAt: _now),
  ];

  // ---- Skins ----
  static final List<Skin> skins = [
    const Skin(
      skinId: 1,
      name: 'Default WSOP',
      version: '1.0.0',
      status: 'active',
      metadata: SkinMetadata(
        title: 'Default WSOP',
        description: 'Standard WSOP broadcast overlay',
        author: 'EBS Team',
        tags: ['wsop', 'default'],
      ),
      fileSize: 2457600,
      uploadedAt: _now,
      activatedAt: _now,
    ),
    const Skin(
      skinId: 2,
      name: 'Neon Nights',
      version: '0.9.1',
      status: 'validated',
      metadata: SkinMetadata(
        title: 'Neon Nights',
        description: 'Vibrant neon theme for late-night broadcasts',
        author: 'Design Team',
        tags: ['neon', 'dark'],
      ),
      fileSize: 3145728,
      uploadedAt: _now,
    ),
    const Skin(
      skinId: 3,
      name: 'Classic Green',
      version: '1.2.0',
      status: 'draft',
      metadata: SkinMetadata(
        title: 'Classic Green',
        description: 'Traditional felt green theme',
        tags: ['classic'],
      ),
      fileSize: 1843200,
      uploadedAt: _now,
    ),
  ];

  // ---- Hands ----
  static final List<Hand> hands = List.generate(10, (i) {
    const baseMs = 1744200000000; // approximate 2026-04-09T12:00:00 UTC
    final startedMs = baseMs - (10 - i) * 600000;
    final endedMs = startedMs + 120000;
    return Hand(
      handId: i + 1,
      tableId: 1,
      handNumber: 1001 + i,
      gameType: 0,
      betStructure: 0,
      dealerSeat: (i % 9) + 1,
      boardCards: i < 8 ? 'Ah Kd 7c 2s 9h' : 'Jc Td 5s',
      potTotal: (i + 1) * 12000,
      sidePots: '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true).toIso8601String(),
      endedAt: DateTime.fromMillisecondsSinceEpoch(endedMs, isUtc: true).toIso8601String(),
      durationSec: 120,
      createdAt: _now,
    );
  });

  // ---- Hand Players (Hand 1, 9 players) ----
  static final List<HandPlayer> handPlayers = List.generate(9, (i) {
    return HandPlayer(
      id: i + 1,
      handId: 1,
      seatNo: i + 1,
      playerId: i + 1,
      playerName: '${_famous[i][0]} ${_famous[i][1]}',
      holeCards: i == 0 ? 'As Ks' : i == 1 ? 'Qh Jh' : '',
      startStack: 50000 + i * 5000,
      endStack: i == 0 ? 74000 : 50000 + i * 5000 - (i < 3 ? 8000 : 0),
      finalAction: i == 0 ? 'win' : i < 3 ? 'fold' : null,
      isWinner: i == 0,
      pnl: i == 0 ? 24000 : i < 3 ? -8000 : 0,
      handRank: i == 0 ? 'Flush' : null,
      vpip: i < 4,
      pfr: i < 2,
    );
  });

  // ---- Hand Actions (Hand 1) ----
  static const List<HandAction> handActions = [
    HandAction(id: 1, handId: 1, seatNo: 3, actionType: 'post_sb', actionAmount: 1200, potAfter: 1200, street: 'Preflop', actionOrder: 1),
    HandAction(id: 2, handId: 1, seatNo: 4, actionType: 'post_bb', actionAmount: 2400, potAfter: 3600, street: 'Preflop', actionOrder: 2),
    HandAction(id: 3, handId: 1, seatNo: 1, actionType: 'raise', actionAmount: 6000, potAfter: 9600, street: 'Preflop', actionOrder: 3),
    HandAction(id: 4, handId: 1, seatNo: 2, actionType: 'call', actionAmount: 6000, potAfter: 15600, street: 'Preflop', actionOrder: 4),
    HandAction(id: 5, handId: 1, seatNo: 3, actionType: 'fold', actionAmount: 0, potAfter: 15600, street: 'Preflop', actionOrder: 5),
    HandAction(id: 6, handId: 1, seatNo: 1, actionType: 'bet', actionAmount: 8000, potAfter: 23600, street: 'Flop', actionOrder: 6, boardCards: 'Ah Kd 7c'),
    HandAction(id: 7, handId: 1, seatNo: 2, actionType: 'call', actionAmount: 8000, potAfter: 31600, street: 'Flop', actionOrder: 7),
    HandAction(id: 8, handId: 1, seatNo: 1, actionType: 'check', actionAmount: 0, potAfter: 31600, street: 'Turn', actionOrder: 8, boardCards: '2s'),
    HandAction(id: 9, handId: 1, seatNo: 2, actionType: 'check', actionAmount: 0, potAfter: 31600, street: 'Turn', actionOrder: 9),
    HandAction(id: 10, handId: 1, seatNo: 1, actionType: 'bet', actionAmount: 16000, potAfter: 47600, street: 'River', actionOrder: 10, boardCards: '9h'),
    HandAction(id: 11, handId: 1, seatNo: 2, actionType: 'fold', actionAmount: 0, potAfter: 47600, street: 'River', actionOrder: 11),
  ];

  // ---- Audit Logs ----
  static final List<AuditLog> auditLogs = List.generate(15, (i) {
    const entityTypes = ['table', 'event', 'user', 'skin', 'config'];
    const actions = ['create', 'update', 'delete', 'activate', 'login'];
    const baseMs = 1744200000000;
    return AuditLog(
      id: i + 1,
      userId: (i % 3) + 1,
      entityType: entityTypes[i % 5],
      entityId: i + 1,
      action: actions[i % 5],
      detail: 'Mock audit action ${i + 1}',
      ipAddress: '192.168.1.${10 + i}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(baseMs - i * 3600000, isUtc: true).toIso8601String(),
    );
  });

  // ---- Configs (per-section map) ----
  static final Map<String, Map<String, dynamic>> configs = {
    'outputs': {
      'primary_output': 'NDI',
      'ndi_port': 5960,
      'hdmi_enabled': false,
      'delay_seconds': 30,
    },
    'gfx': {
      'theme': 'default',
      'overlay_position': 'bottom',
      'font_size': 'medium',
    },
    'display': {
      'language': 'en',
      'timezone': 'Europe/Paris',
      'date_format': 'YYYY-MM-DD',
    },
    'rules': {
      'late_registration_minutes': 180,
      'break_interval_hours': 2,
      'break_duration_minutes': 15,
    },
    'stats': {
      'show_vpip': true,
      'show_pfr': true,
      'show_chip_count': true,
    },
    'preferences': {
      'auto_refresh': true,
      'refresh_interval_seconds': 5,
      'confirm_destructive': true,
    },
  };
}

// ---- Internal helper for flight construction ----
class _RawFlight {
  final int id;
  final int eventId;
  final String displayName;
  final String startTime;
  final int entries;
  final int playersLeft;
  final int tableCount;
  final String status;
  final int playLevel;
  final int? remainTime;

  const _RawFlight(
    this.id,
    this.eventId,
    this.displayName,
    this.startTime,
    this.entries,
    this.playersLeft,
    this.tableCount,
    this.status,
    this.playLevel,
    this.remainTime,
  );
}
