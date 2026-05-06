// EBS Lobby — drilldown shell (TopBar + SideRail + body).
//
// Wraps the 5 lobby drilldown screens (Series / Events / Flights / Tables /
// Players) with the design source's TopBar + SideRail. Each screen embeds
// its own LobbyBreadcrumb at the top of [child] so the trail is path-aware.
//
// Used by go_router as a `ShellRoute` builder.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/theme/design_tokens.dart';
import '../../../foundation/widgets/lobby_side_rail.dart';
import '../../../foundation/widgets/lobby_top_bar.dart';
import '../../auth/auth_provider.dart';
import '../providers/cc_session_provider.dart';
import '../providers/event_provider.dart';
import '../providers/flight_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/series_provider.dart';
import '../providers/table_provider.dart';

/// Lobby sidebar destinations — drilldown 5 + tools 5 (단일 chrome, 2026-05-06).
enum LobbyRail {
  // ── Navigate / Drilldown ──
  series,
  events,
  flights,
  tables,
  players,
  // ── Tools ──
  handHistory,
  settings,
  gfx,
  reports,
  staff,
}

extension LobbyRailX on LobbyRail {
  String get id => name;
  IconData get icon {
    switch (this) {
      case LobbyRail.series:
        return Icons.workspace_premium_outlined;
      case LobbyRail.events:
        return Icons.event_outlined;
      case LobbyRail.flights:
        return Icons.flight_takeoff_outlined;
      case LobbyRail.tables:
        return Icons.grid_view_outlined;
      case LobbyRail.players:
        return Icons.people_outline;
      case LobbyRail.handHistory:
        return Icons.bolt_outlined;
      case LobbyRail.settings:
        return Icons.settings_outlined;
      case LobbyRail.gfx:
        return Icons.brush_outlined;
      case LobbyRail.reports:
        return Icons.assessment_outlined;
      case LobbyRail.staff:
        return Icons.badge_outlined;
    }
  }

  String get label {
    switch (this) {
      case LobbyRail.series:
        return 'Series';
      case LobbyRail.events:
        return 'Events';
      case LobbyRail.flights:
        return 'Flights';
      case LobbyRail.tables:
        return 'Tables';
      case LobbyRail.players:
        return 'Players';
      case LobbyRail.handHistory:
        return 'Hand History';
      case LobbyRail.settings:
        return 'Settings';
      case LobbyRail.gfx:
        return 'Graphic Editor';
      case LobbyRail.reports:
        return 'Reports';
      case LobbyRail.staff:
        return 'Staff';
    }
  }
}

class LobbyShell extends ConsumerStatefulWidget {
  const LobbyShell({super.key, required this.child});

  final Widget child;

  static LobbyRail railFromLocation(String location) {
    // Tools (top-level meta routes)
    if (location.startsWith('/staff')) return LobbyRail.staff;
    if (location.startsWith('/settings')) return LobbyRail.settings;
    if (location.startsWith('/graphic-editor')) return LobbyRail.gfx;
    if (location.startsWith('/reports/hand-history')) return LobbyRail.handHistory;
    if (location.startsWith('/reports')) return LobbyRail.reports;
    // Drilldown
    if (location.startsWith('/lobby/events')) return LobbyRail.events;
    if (location.startsWith('/lobby/flights')) return LobbyRail.flights;
    if (location.contains('/players')) return LobbyRail.players;
    if (location.contains('/tables')) return LobbyRail.tables;
    return LobbyRail.series;
  }

  @override
  ConsumerState<LobbyShell> createState() => _LobbyShellState();
}

class _LobbyShellState extends ConsumerState<LobbyShell> {
  bool _railCollapsed = false;
  late String _clock;

  @override
  void initState() {
    super.initState();
    _clock = _format(DateTime.now());
    _scheduleClock();
  }

  void _scheduleClock() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _clock = _format(DateTime.now()));
      _scheduleClock();
    });
  }

  String _format(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final selected = LobbyShell.railFromLocation(loc);

    final auth = ref.watch(authProvider);
    final user = auth.user;
    final initials = _initialsOf(user?.displayName ?? 'EBS');
    final userLabel = user == null
        ? 'Sign in'
        : '${user.displayName} · ${user.role[0].toUpperCase()}${user.role.substring(1)}';

    final clusters = _clusterFromSelection(ref);
    final badges = _badgesFromProviders(ref);

    return Scaffold(
      backgroundColor: DesignTokens.lightBg,
      body: Column(
        children: [
          LobbyTopBar(
            collapsed: _railCollapsed,
            clusters: clusters,
            activeCcCount: ref.watch(activeCcCountProvider),
            clock: _clock,
            userInitials: initials,
            userLabel: userLabel,
            onBrandTap: () =>
                setState(() => _railCollapsed = !_railCollapsed),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LobbySideRail(
                  collapsed: _railCollapsed,
                  selectedId: selected.id,
                  onSelect: (id) => _onRailSelect(context, id),
                  footerVersion: 'EBS v0.1.0 · ${const String.fromEnvironment('BUILD_ID', defaultValue: 'dev')}',
                  items: [
                    // ── Navigate ──
                    LobbySideRailItem(
                      id: LobbyRail.series.id,
                      label: LobbyRail.series.label,
                      icon: LobbyRail.series.icon,
                      badge: badges[LobbyRail.series],
                      section: 'Navigate',
                    ),
                    // ── Drilldown (current series context) ──
                    LobbySideRailItem(
                      id: LobbyRail.events.id,
                      label: LobbyRail.events.label,
                      icon: LobbyRail.events.icon,
                      badge: badges[LobbyRail.events],
                      section: ref.watch(currentSeriesNameProvider) != null
                          ? '${ref.watch(currentSeriesNameProvider)} · Drilldown'
                          : 'Drilldown',
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.flights.id,
                      label: LobbyRail.flights.label,
                      icon: LobbyRail.flights.icon,
                      badge: badges[LobbyRail.flights],
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.tables.id,
                      label: LobbyRail.tables.label,
                      icon: LobbyRail.tables.icon,
                      badge: badges[LobbyRail.tables],
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.players.id,
                      label: LobbyRail.players.label,
                      icon: LobbyRail.players.icon,
                      badge: badges[LobbyRail.players],
                    ),
                    // ── Tools (always-on meta) ──
                    LobbySideRailItem(
                      id: LobbyRail.handHistory.id,
                      label: LobbyRail.handHistory.label,
                      icon: LobbyRail.handHistory.icon,
                      section: 'Tools',
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.settings.id,
                      label: LobbyRail.settings.label,
                      icon: LobbyRail.settings.icon,
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.gfx.id,
                      label: LobbyRail.gfx.label,
                      icon: LobbyRail.gfx.icon,
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.reports.id,
                      label: LobbyRail.reports.label,
                      icon: LobbyRail.reports.icon,
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.staff.id,
                      label: LobbyRail.staff.label,
                      icon: LobbyRail.staff.icon,
                    ),
                  ],
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onRailSelect(BuildContext context, String id) {
    final rail = LobbyRail.values.firstWhere((e) => e.id == id);
    final seriesId = ref.read(currentSeriesIdProvider);
    final eventId = ref.read(currentEventIdProvider);
    final flightId = ref.read(currentFlightIdProvider);

    switch (rail) {
      // ── Drilldown ──
      case LobbyRail.series:
        context.go('/lobby/series');
      case LobbyRail.events:
        context.go(seriesId != null
            ? '/lobby/events/$seriesId'
            : '/lobby/series');
      case LobbyRail.flights:
        context.go(eventId != null
            ? '/lobby/flights/$eventId'
            : '/lobby/series');
      case LobbyRail.tables:
        context.go(flightId != null
            ? '/lobby/flight/$flightId/tables'
            : '/lobby/series');
      case LobbyRail.players:
        context.go(flightId != null
            ? '/lobby/flight/$flightId/players'
            : '/lobby/series');
      // ── Tools ──
      case LobbyRail.handHistory:
        context.go('/reports/hand-history');
      case LobbyRail.settings:
        context.go('/settings');
      case LobbyRail.gfx:
        context.go('/graphic-editor');
      case LobbyRail.reports:
        context.go('/reports');
      case LobbyRail.staff:
        context.go('/staff');
    }
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Build the design's [SHOW · FLIGHT · LEVEL · NEXT] cluster — 4 columns fixed
  /// per shell.jsx:43-51. SHOW/FLIGHT 는 nav state, LEVEL/NEXT 는 flight
  /// levels provider (Phase 3 backend 연결 시 자동 갱신).
  List<LobbyTopBarCluster> _clusterFromSelection(WidgetRef ref) {
    final seriesName = ref.watch(currentSeriesNameProvider);
    final flightId = ref.watch(currentFlightIdProvider);
    final eventId = ref.watch(currentEventIdProvider);
    String? flightLabel;
    if (flightId != null && eventId != null) {
      final flights =
          ref.watch(flightListProvider(eventId)).valueOrNull ?? const [];
      final f = flights.cast<dynamic>().firstWhere(
            (x) => x?.eventFlightId == flightId,
            orElse: () => null,
          );
      flightLabel = f?.displayName as String?;
    }
    final levelsAsync = flightId != null
        ? ref.watch(flightLevelsProvider(flightId))
        : const AsyncValue<LobbyLevelsSnapshot?>.data(null);
    final levels = levelsAsync.valueOrNull;
    final levelText = levels != null
        ? '${levels.now.role.split(' · ').last} · ${levels.now.blinds}'
        : '—';
    final nextText = levels?.countdown ?? '—';
    return [
      LobbyTopBarCluster('SHOW', _short(seriesName) ?? '—'),
      LobbyTopBarCluster('FLIGHT', _short(flightLabel) ?? '—'),
      LobbyTopBarCluster('LEVEL', _short(levelText) ?? '—'),
      LobbyTopBarCluster('NEXT', nextText),
    ];
  }

  /// Sidebar item badge counts pulled from Riverpod providers when the
  /// underlying list has been fetched. Returns null per-item until the list
  /// loads — `_Badge` widget hides nulls.
  Map<LobbyRail, int?> _badgesFromProviders(WidgetRef ref) {
    final seriesCount = ref.watch(seriesListProvider).valueOrNull?.length;
    final seriesId = ref.watch(currentSeriesIdProvider);
    final eventCount = seriesId != null
        ? ref.watch(eventListProvider(seriesId)).valueOrNull?.length
        : null;
    final eventId = ref.watch(currentEventIdProvider);
    final flightCount = eventId != null
        ? ref.watch(flightListProvider(eventId)).valueOrNull?.length
        : null;
    final flightId = ref.watch(currentFlightIdProvider);
    final tables = flightId != null
        ? ref.watch(tableListProvider(flightId)).valueOrNull
        : null;
    final tableCount = tables?.length;
    final playerCount = tables?.fold<int>(0, (s, t) => s + (t.seatedCount ?? 0));
    return {
      LobbyRail.series: seriesCount,
      LobbyRail.events: eventCount,
      LobbyRail.flights: flightCount,
      LobbyRail.tables: tableCount,
      LobbyRail.players: playerCount,
    };
  }

  String? _short(String? s) {
    if (s == null) return null;
    if (s.length <= 22) return s;
    return '${s.substring(0, 21)}…';
  }
}
