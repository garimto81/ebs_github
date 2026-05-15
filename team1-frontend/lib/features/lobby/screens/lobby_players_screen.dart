// EBS Lobby — Players screen for a specific flight (chip-stack ranking).
//
// Distinct from the global `/players` route which lists all players. This
// screen shows the leaderboard within a flight context — chip stacks, BB,
// state filter (active / away / elim), and EBS-only stats (VPIP/PFR/AGR).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/theme/design_tokens.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../foundation/widgets/lobby_breadcrumb.dart';
import '../../../models/models.dart';
import '../providers/nav_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/lobby_kpi_strip.dart';

class LobbyPlayersScreen extends ConsumerStatefulWidget {
  const LobbyPlayersScreen({super.key, required this.flightId});
  final int flightId;

  @override
  ConsumerState<LobbyPlayersScreen> createState() =>
      _LobbyPlayersScreenState();
}

class _LobbyPlayersScreenState extends ConsumerState<LobbyPlayersScreen> {
  String _stateFilter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(playerListProvider.notifier).fetch();
      ref.read(currentFlightIdProvider.notifier).state = widget.flightId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncPlayers = ref.watch(playerListProvider);
    final seriesName = ref.watch(currentSeriesNameProvider) ?? 'Series';
    final eventName = ref.watch(currentEventNameProvider) ?? 'Event';

    return Column(
      children: [
        LobbyBreadcrumb(crumbs: [
          LobbyBreadcrumbCrumb(
            label: 'Home',
            onTap: () => context.go('/lobby/series'),
          ),
          LobbyBreadcrumbCrumb(
            label: seriesName,
            onTap: () => context.go('/lobby/series'),
          ),
          LobbyBreadcrumbCrumb(
            label: eventName,
            onTap: () {
              final eid = ref.read(currentEventIdProvider);
              if (eid != null) context.go('/lobby/flights/$eid');
            },
          ),
          const LobbyBreadcrumbCrumb(label: 'Players'),
        ]),
        Expanded(
          child: asyncPlayers.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () => ref.read(playerListProvider.notifier).fetch(),
            ),
            data: (players) {
              final filtered = _filter(players);
              return Column(
                children: [
                  LobbyKpiStrip(cards: _kpis(players)),
                  _Toolbar(
                    stateFilter: _stateFilter,
                    onState: (s) => setState(() => _stateFilter = s),
                    onQuery: (q) => setState(() => _query = q),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            message: 'No players match the filter',
                            icon: Icons.person_off_outlined,
                          )
                        : _PlayersTable(players: filtered),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Player> _filter(List<Player> list) {
    return list.where((p) {
      if (_stateFilter != 'all' && p.playerStatus != _stateFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.firstName.toLowerCase().contains(q) ||
          p.lastName.toLowerCase().contains(q) ||
          (p.countryCode ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<KpiCard> _kpis(List<Player> players) {
    final active =
        players.where((p) => p.playerStatus == 'active').length;
    return [
      KpiCard(label: 'PLAYERS', value: '${players.length}'),
      KpiCard(
        label: 'ACTIVE',
        value: '$active',
        tone: active > 0 ? KpiTone.live : KpiTone.neutral,
      ),
      const KpiCard(label: 'TOTAL STACK', value: '—', sub: 'pending'),
      const KpiCard(label: 'AVG STACK', value: '—', sub: 'pending'),
      const KpiCard(label: 'BB AVG', value: '—', sub: 'pending'),
    ];
  }
}

class _Toolbar extends StatefulWidget {
  const _Toolbar({
    required this.stateFilter,
    required this.onState,
    required this.onQuery,
  });

  final String stateFilter;
  final ValueChanged<String> onState;
  final ValueChanged<String> onQuery;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  static const _states = ['all', 'active', 'waiting', 'busted'];
  static const _labels = ['All', 'Active', 'Waiting', 'Busted'];

  @override
  Widget build(BuildContext context) {
    return Container(
      // HTML: `.toolbar { padding: 6px 16px }`
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            height: 28,
            child: TextField(
              onChanged: widget.onQuery,
              style: EbsTypography.formInput,
              decoration: const InputDecoration(
                hintText: 'Search player, country…',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StatePills(
            states: _states,
            labels: _labels,
            selected: widget.stateFilter,
            onSelect: widget.onState,
          ),
        ],
      ),
    );
  }
}

class _StatePills extends StatelessWidget {
  const _StatePills({
    required this.states,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> states;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.lightLineStrong),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < states.length; i++) MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSelect(states[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: states[i] == selected
                      ? DesignTokens.lightInk
                      : Colors.transparent,
                  border: Border(
                    right: i < states.length - 1
                        ? const BorderSide(color: DesignTokens.lightLine)
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamilyUi,
                    fontSize: 11.5,
                    fontWeight: states[i] == selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: states[i] == selected
                        ? DesignTokens.lightBg
                        : DesignTokens.lightInk3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayersTable extends StatelessWidget {
  const _PlayersTable({required this.players});
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final maxStack = players
        .map((p) => p.stack ?? 0)
        .fold<int>(0, (m, v) => v > m ? v : m);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            // HTML: compact table, `th 8px`, `td 10px`, `padding: 5px 4px`
            headingRowHeight: 28,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 28,
            horizontalMargin: 8,
            columnSpacing: 12,
            dividerThickness: 0.5,
            headingTextStyle: const TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF999999),
              letterSpacing: 0.8,
            ),
            columns: const [
              DataColumn(label: Text('#'), numeric: true),
              DataColumn(label: Text('PLAYER')),
              DataColumn(label: Text('CTRY')),
              DataColumn(label: Text('STACK'), numeric: true),
              DataColumn(label: Text('STATE')),
              DataColumn(label: Text('TABLE')),
              DataColumn(label: Text('SEAT'), numeric: true),
            ],
            rows: [
              for (var i = 0; i < players.length; i++) DataRow(
                cells: [
                  DataCell(Text('${i + 1}',
                      style: EbsTypography.tableNumeric)),
                  DataCell(Text(
                    '${players[i].firstName} ${players[i].lastName}',
                    style: EbsTypography.tableCell.copyWith(
                        fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    players[i].countryCode ?? '—',
                    style: EbsTypography.monoSmall.copyWith(
                        color: DesignTokens.lightInk3),
                  )),
                  DataCell(_StackCell(
                    stack: players[i].stack ?? 0,
                    max: maxStack,
                  )),
                  DataCell(_StatePill(state: players[i].playerStatus)),
                  DataCell(Text(players[i].tableName ?? '—',
                      style: EbsTypography.monoSmall)),
                  DataCell(Text(
                    players[i].seatIndex?.toString() ?? '—',
                    style: EbsTypography.tableNumeric,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackCell extends StatelessWidget {
  const _StackCell({required this.stack, required this.max});
  final int stack;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (stack / max).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 4,
          child: Stack(
            children: [
              Container(color: DesignTokens.lightLine),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(color: DesignTokens.lightInk),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(_fmt(stack), style: EbsTypography.tableNumeric),
      ],
    );
  }

  String _fmt(int v) => v == 0
      ? '—'
      : v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(state);
    return Container(
      // HTML: `.state-badge { padding: 1px 5px; font-size: 8px; font-weight: 700 }` — NO border-radius
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: spec.bg,
        // HTML state badges have NO border-radius (sharp rectangular)
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        state,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamilyUi,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: spec.ink,
          decoration:
              state == 'busted' ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  ({Color bg, Color ink}) _spec(String s) {
    switch (s) {
      case 'active':
        return (bg: DesignTokens.liveBg, ink: DesignTokens.liveInk);
      case 'waiting':
        return (bg: DesignTokens.warnBg, ink: DesignTokens.warnInk);
      case 'busted':
        return (bg: DesignTokens.dangerBg, ink: DesignTokens.dangerInk);
      default:
        return (
          bg: DesignTokens.lightBgSunken,
          ink: DesignTokens.lightInk3,
        );
    }
  }
}
