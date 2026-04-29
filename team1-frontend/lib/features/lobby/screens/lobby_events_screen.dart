// EBS Lobby — Events screen (KPI strip + status tabs + dense table).

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
import '../providers/event_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/series_provider.dart';
import '../widgets/lobby_kpi_strip.dart';
import '../widgets/lobby_status_badge.dart';

class LobbyEventsScreen extends ConsumerStatefulWidget {
  const LobbyEventsScreen({super.key, required this.seriesId});
  final int seriesId;

  @override
  ConsumerState<LobbyEventsScreen> createState() =>
      _LobbyEventsScreenState();
}

class _LobbyEventsScreenState extends ConsumerState<LobbyEventsScreen> {
  String _tab = 'running';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(eventListProvider(widget.seriesId).notifier).fetch();
      // Make sure series is selected for breadcrumb / topbar cluster.
      final series = ref
          .read(seriesListProvider)
          .valueOrNull
          ?.where((s) => s.seriesId == widget.seriesId)
          .firstOrNull;
      if (series != null) {
        selectSeries(ref, series.seriesId, name: series.seriesName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(eventListProvider(widget.seriesId));
    final seriesName =
        ref.watch(currentSeriesNameProvider) ?? 'Series #${widget.seriesId}';

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
          const LobbyBreadcrumbCrumb(label: 'Events'),
        ]),
        Expanded(
          child: asyncEvents.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () => ref
                  .read(eventListProvider(widget.seriesId).notifier)
                  .fetch(),
            ),
            data: (events) {
              final counts = _countByStatus(events);
              final filtered =
                  events.where((e) => e.status == _tab).toList();
              return Column(
                children: [
                  LobbyKpiStrip(cards: _kpis(events)),
                  _Tabs(
                    counts: counts,
                    selected: _tab,
                    onSelect: (t) => setState(() => _tab = t),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            message: 'No events in this status',
                            icon: Icons.event_busy_outlined,
                          )
                        : _EventsTable(events: filtered, onOpen: _onOpen),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, int> _countByStatus(List<EbsEvent> events) {
    final c = <String, int>{
      'created': 0,
      'announced': 0,
      'registering': 0,
      'running': 0,
      'completed': 0,
    };
    for (final e in events) {
      c[e.status] = (c[e.status] ?? 0) + 1;
    }
    return c;
  }

  List<KpiCard> _kpis(List<EbsEvent> events) {
    final live = events.where((e) => e.status == 'running').length;
    final entries =
        events.fold<int>(0, (s, e) => s + e.totalEntries);
    return [
      KpiCard(label: 'TOTAL EVENTS', value: '${events.length}'),
      KpiCard(
        label: 'LIVE NOW',
        value: '$live',
        tone: live > 0 ? KpiTone.live : KpiTone.neutral,
      ),
      KpiCard(label: 'TOTAL ENTRIES', value: _fmt(entries)),
      const KpiCard(label: 'PRIZE POOL', value: '—', sub: 'pending'),
      const KpiCard(label: 'ACTIVE CC', value: '—', sub: 'pending'),
    ];
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  void _onOpen(EbsEvent e) {
    selectEvent(ref, e.eventId, name: e.eventName);
    context.go('/lobby/flights/${e.eventId}');
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelect;

  static const _order = [
    'created',
    'announced',
    'registering',
    'running',
    'completed'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.lightBg,
        border: Border(bottom: BorderSide(color: DesignTokens.lightLine)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final t in _order) _Tab(
            label: t,
            count: counts[t] ?? 0,
            active: t == selected,
            onTap: () => onSelect(t),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? DesignTokens.lightInk : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                _capitalize(label),
                style: EbsTypography.tabLabel.copyWith(
                  color: active
                      ? DesignTokens.lightInk
                      : DesignTokens.lightInk3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamilyMono,
                  fontSize: 11,
                  color: active
                      ? DesignTokens.lightInk2
                      : DesignTokens.lightInk4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _EventsTable extends StatelessWidget {
  const _EventsTable({required this.events, required this.onOpen});
  final List<EbsEvent> events;
  final ValueChanged<EbsEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1100),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('NO')),
              DataColumn(label: Text('START')),
              DataColumn(label: Text('EVENT')),
              DataColumn(label: Text('BUY-IN'), numeric: true),
              DataColumn(label: Text('GAME')),
              DataColumn(label: Text('MODE')),
              DataColumn(label: Text('ENTRIES'), numeric: true),
              DataColumn(label: Text('PLAYERS LEFT'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final e in events)
                DataRow(
                  onSelectChanged: (_) => onOpen(e),
                  cells: [
                    DataCell(Text('#${e.eventNo}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text(_short(e.startTime ?? ''),
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text(e.eventName,
                        style: EbsTypography.tableCell.copyWith(
                            fontWeight: FontWeight.w600))),
                    DataCell(Text(e.displayBuyIn ?? '—',
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text(_gameName(e.gameType),
                        style: EbsTypography.monoSmall)),
                    DataCell(Text(e.gameMode,
                        style: EbsTypography.monoSmall)),
                    DataCell(Text('${e.totalEntries}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text('${e.playersLeft}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(LobbyStatusBadge(status: e.status)),
                    DataCell(TextButton(
                      onPressed: () => onOpen(e),
                      child: const Text('Open ›'),
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _short(String iso) =>
      iso.length >= 16 ? iso.substring(5, 16).replaceAll('T', ' ') : iso;

  String _gameName(int gameType) {
    switch (gameType) {
      case 0:
        return 'NLH';
      case 21:
      case 11:
        return 'PLO';
      case 4:
        return 'O8';
      default:
        return 'MIX';
    }
  }
}
