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
import '../providers/nav_provider.dart';

/// One of the five lobby drilldown sections.
enum LobbyRail { series, events, flights, tables, players }

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
    }
  }
}

class LobbyShell extends ConsumerStatefulWidget {
  const LobbyShell({super.key, required this.child});

  final Widget child;

  static LobbyRail railFromLocation(String location) {
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

    return Scaffold(
      backgroundColor: DesignTokens.lightBg,
      body: Column(
        children: [
          LobbyTopBar(
            collapsed: _railCollapsed,
            clusters: clusters,
            activeCcCount: 3, // TODO(B-091): wire to real CC session count
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
                  footerVersion: 'EBS v0.1.0',
                  items: [
                    LobbySideRailItem(
                      id: LobbyRail.series.id,
                      label: LobbyRail.series.label,
                      icon: LobbyRail.series.icon,
                      section: 'Navigate',
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.events.id,
                      label: LobbyRail.events.label,
                      icon: LobbyRail.events.icon,
                      section: 'Drilldown',
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.flights.id,
                      label: LobbyRail.flights.label,
                      icon: LobbyRail.flights.icon,
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.tables.id,
                      label: LobbyRail.tables.label,
                      icon: LobbyRail.tables.icon,
                    ),
                    LobbySideRailItem(
                      id: LobbyRail.players.id,
                      label: LobbyRail.players.label,
                      icon: LobbyRail.players.icon,
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

  /// Build the design's [SHOW · FLIGHT · LEVEL · NEXT] cluster from current
  /// selection. Missing values fall back to em-dash.
  List<LobbyTopBarCluster> _clusterFromSelection(WidgetRef ref) {
    final seriesName = ref.watch(currentSeriesNameProvider);
    final eventName = ref.watch(currentEventNameProvider);
    final tableName = ref.watch(currentTableNameProvider);
    return [
      LobbyTopBarCluster('SHOW', _short(seriesName) ?? '—'),
      if (eventName != null)
        LobbyTopBarCluster('EVENT', _short(eventName) ?? '—'),
      if (tableName != null)
        LobbyTopBarCluster('TABLE', _short(tableName) ?? '—'),
    ];
  }

  String? _short(String? s) {
    if (s == null) return null;
    if (s.length <= 22) return s;
    return '${s.substring(0, 21)}…';
  }
}
