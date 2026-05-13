// EBS Lobby — Tables screen (KPI + Levels + tables grid + Waitlist drawer).

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
import '../providers/cc_session_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/table_provider.dart';
import '../widgets/levels_strip.dart';
import '../widgets/lobby_kpi_strip.dart';
import '../widgets/lobby_status_badge.dart';
import '../widgets/seat_dot_cell.dart';
import '../widgets/waitlist_drawer.dart';

class LobbyTablesScreen extends ConsumerStatefulWidget {
  const LobbyTablesScreen({super.key, required this.flightId});
  final int flightId;

  @override
  ConsumerState<LobbyTablesScreen> createState() =>
      _LobbyTablesScreenState();
}

class _LobbyTablesScreenState extends ConsumerState<LobbyTablesScreen> {
  String _query = '';
  String _view = 'grid'; // grid | map | cc

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tableListProvider(widget.flightId).notifier).fetch();
      ref.read(currentFlightIdProvider.notifier).state = widget.flightId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncTables = ref.watch(tableListProvider(widget.flightId));
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
          const LobbyBreadcrumbCrumb(label: 'Tables'),
        ]),
        Expanded(
          child: asyncTables.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () => ref
                  .read(tableListProvider(widget.flightId).notifier)
                  .fetch(),
            ),
            data: (tables) {
              if (tables.isEmpty) {
                return const EmptyState(
                  message: 'No tables for this flight',
                  icon: Icons.table_restaurant_outlined,
                );
              }
              final filtered = tables
                  .where((t) =>
                      _query.isEmpty ||
                      t.name.toLowerCase().contains(_query.toLowerCase()))
                  .toList();
              final levelsAsync = ref.watch(flightLevelsProvider(widget.flightId));
              final levels = levelsAsync.valueOrNull;
              return Column(
                children: [
                  LobbyKpiStrip(cards: _kpis(tables)),
                  LevelsStrip(
                    now: LobbyLevel(
                      role: levels?.now.role ?? '—',
                      blinds: levels?.now.blinds ?? '—',
                      meta: levels?.now.meta ?? '—',
                    ),
                    next: LobbyLevel(
                      role: levels?.next.role ?? '—',
                      blinds: levels?.next.blinds ?? '—',
                      meta: levels?.next.meta ?? '—',
                    ),
                    after: LobbyLevel(
                      role: levels?.after.role ?? '—',
                      blinds: levels?.after.blinds ?? '—',
                      meta: levels?.after.meta ?? '—',
                    ),
                    countdownLabel: levels?.countdownLabel ?? '—',
                    countdown: levels?.countdown ?? '—',
                  ),
                  _Toolbar(
                    query: _query,
                    view: _view,
                    onQuery: (q) => setState(() => _query = q),
                    onView: (v) => setState(() => _view = v),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TablesGrid(
                            tables: filtered,
                            onOpen: (t) =>
                                context.go('/tables/${t.tableId}'),
                          ),
                        ),
                        const WaitlistDrawer(names: _waitlistMock),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<KpiCard> _kpis(List<EbsTable> tables) {
    final totalSeats =
        tables.fold<int>(0, (s, t) => s + t.maxPlayers);
    final live = tables.where((t) => t.status == 'live').length;
    return [
      KpiCard(label: 'TABLES', value: '${tables.length}'),
      KpiCard(label: 'SEATS', value: '$totalSeats'),
      KpiCard(
        label: 'LIVE',
        value: '$live',
        tone: live > 0 ? KpiTone.live : KpiTone.neutral,
      ),
      const KpiCard(label: 'WAITING', value: '12', tone: KpiTone.danger),
      const KpiCard(label: 'AVG STACK', value: '164,553', sub: '27.4 BB'),
    ];
  }
}

const _waitlistMock = [
  'Christopher Kearin',
  'Bence Fist',
  'Yuval Frome',
  'Ravi Guerin',
  'Paul Ephremsen',
  'Benedetta Šudice',
  'Ernest Grenier',
  'Naomi Dato',
  'Mirsha Mitev',
  'Tomáš Havel',
  'Karine Lévesque',
  'Adebayo Okafor',
];

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.view,
    required this.onQuery,
    required this.onView,
  });

  final String query;
  final String view;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: DesignTokens.lightBg,
        border: Border(bottom: BorderSide(color: DesignTokens.lightLine)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            height: 28,
            child: TextField(
              onChanged: onQuery,
              style: EbsTypography.formInput,
              decoration: const InputDecoration(
                hintText: 'Find table…',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _SegmentedControl(
            options: const ['grid', 'map', 'cc'],
            labels: const ['Grid', 'Floor Map', 'CC Focus'],
            selected: view,
            onSelect: onView,
          ),
          const Spacer(),
          const SeatLegendRow(),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
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
          for (var i = 0; i < options.length; i++) _SegmentButton(
            label: labels[i],
            active: options[i] == selected,
            onTap: () => onSelect(options[i]),
            border: i < options.length - 1,
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.border,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? DesignTokens.lightInk : Colors.transparent,
            border: Border(
              right: border
                  ? const BorderSide(color: DesignTokens.lightLine)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active
                  ? DesignTokens.lightBg
                  : DesignTokens.lightInk3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TablesGrid extends StatelessWidget {
  const _TablesGrid({required this.tables, required this.onOpen});
  final List<EbsTable> tables;
  final ValueChanged<EbsTable> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('TABLE')),
            DataColumn(label: Text('SEATS')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('RFID')),
            DataColumn(label: Text('OUTPUT')),
            DataColumn(label: Text('CC')),
            // Cycle 20 (#439, S2 Wave 3c) — aggregate chip total from
            // `chip_count_synced` WS events.
            DataColumn(label: Text('CHIPS'), numeric: true),
            DataColumn(label: Text('ACTION')),
          ],
          rows: [
            for (final t in tables)
              DataRow(
                onSelectChanged: (_) => onOpen(t),
                cells: [
                  DataCell(_TableNameCell(table: t)),
                  DataCell(_SeatsCell(table: t)),
                  DataCell(LobbyStatusBadge(status: t.status)),
                  DataCell(_RfidCell(t: t)),
                  DataCell(Text(
                    t.outputType ?? '—',
                    style: EbsTypography.monoSmall,
                  )),
                  DataCell(_CcCell(t: t)),
                  DataCell(_ChipTotalCell(chipTotal: t.chipTotal)),
                  DataCell(TextButton(
                    onPressed: () => onOpen(t),
                    child: const Text('Open ›'),
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Right-aligned compact chip total cell with a brief tint pulse when the
/// value changes (Cycle 20, #439 S2 Wave 3c).
///
/// AnimatedSwitcher keys on the value so a transition fires whenever the
/// chipTotal updates from a `chip_count_synced` WS event.
class _ChipTotalCell extends StatelessWidget {
  const _ChipTotalCell({required this.chipTotal});
  final int chipTotal;

  @override
  Widget build(BuildContext context) {
    final display = formatChipTotal(chipTotal);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        // Brief amber tint that fades to the regular ink as the new number
        // settles. Pure opacity transition keeps it cheap to repaint.
        final tint = ColorTween(
          begin: DesignTokens.warnBase,
          end: DesignTokens.lightInk,
        ).animate(animation);
        return AnimatedBuilder(
          animation: tint,
          builder: (_, __) => DefaultTextStyle.merge(
            style: TextStyle(color: tint.value),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(
        display,
        key: ValueKey<int>(chipTotal),
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamilyMono,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: chipTotal > 0
              ? DesignTokens.lightInk
              : DesignTokens.lightInk5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Compact display: 0 → "—", < 1k → raw, 1234 → "1.2k", 1234567 → "1.2M".
///
/// Exported (library-visible) for test parity. Cycle 20 (#439 S2 Wave 3c).
String formatChipTotal(int total) {
  if (total <= 0) return '—';
  if (total < 1000) return '$total';
  if (total < 1000000) {
    return '${(total / 1000).toStringAsFixed(1)}k';
  }
  if (total < 1000000000) {
    return '${(total / 1000000).toStringAsFixed(1)}M';
  }
  return '${(total / 1000000000).toStringAsFixed(1)}B';
}

class _TableNameCell extends StatelessWidget {
  const _TableNameCell({required this.table});
  final EbsTable table;

  @override
  Widget build(BuildContext context) {
    final isFeature = table.type == 'feature';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFeature) ...[
          const Icon(Icons.star, size: 14, color: DesignTokens.featInk),
          const SizedBox(width: 4),
        ],
        Text(
          table.name,
          style: EbsTypography.tableCell.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SeatsCell extends StatelessWidget {
  const _SeatsCell({required this.table});
  final EbsTable table;

  @override
  Widget build(BuildContext context) {
    // Synthesize seat states deterministically from tableId — until backend
    // ships a real seat manifest endpoint, this gives stable visual variety.
    final seats = List<SeatCellState>.generate(table.maxPlayers, (i) {
      if (table.status == 'empty') return SeatCellState.empty;
      final hash = (table.tableId * 7 + i * 3) % 10;
      if (hash == 0) return SeatCellState.eliminated;
      if (hash == 1) return SeatCellState.empty;
      return SeatCellState.active;
    });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < seats.length; i++)
          SeatDotCell(state: seats[i], seatNo: i + 1),
      ],
    );
  }
}

class _RfidCell extends StatelessWidget {
  const _RfidCell({required this.t});
  final EbsTable t;

  @override
  Widget build(BuildContext context) {
    if (t.rfidReaderId == null) {
      return const Text('—',
          style: TextStyle(color: DesignTokens.lightInk5));
    }
    final ok = t.deckRegistered;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ok ? DesignTokens.liveBase : DesignTokens.warnBase,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          ok ? 'Rdy' : 'Wait',
          style: EbsTypography.monoSmall,
        ),
      ],
    );
  }
}

class _CcCell extends StatelessWidget {
  const _CcCell({required this.t});
  final EbsTable t;

  @override
  Widget build(BuildContext context) {
    final isLive = t.status == 'live' && (t.currentGame ?? 0) > 0;
    final color =
        isLive ? DesignTokens.liveInk : DesignTokens.lightInk4;
    final dot =
        isLive ? DesignTokens.liveBase : DesignTokens.lightInk5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isLive ? 'LIVE' : 'IDLE',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamilyMono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
