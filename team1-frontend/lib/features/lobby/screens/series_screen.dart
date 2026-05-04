// EBS Lobby — Series screen (Month/Year-grouped card grid).
//
// Mirrors `SeriesScreen` from the design source (`Lobby/References/EBS_Lobby_Design/screens.jsx:18-50`)
// + UI.md §"그룹핑 — 월별 vs 년도별" (2026-05-04, B-LOBBY-SERIES-001).
//
// Toolbar: search · Hide completed checkbox · [Month / Year] segmented toggle.
// Group bands: "March 2026" (Month) or "2026" (Year), with item count.
// Persistence: in-memory only (영속화는 후속 task — shared_preferences 패키지 도입 시).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../foundation/theme/design_tokens.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../foundation/widgets/lobby_breadcrumb.dart';
import '../../../models/models.dart';
import '../providers/nav_provider.dart';
import '../providers/series_provider.dart';
import '../widgets/lobby_status_badge.dart';

enum SeriesGroupMode { year, month }

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  String _query = '';
  bool _hideCompleted = false;
  SeriesGroupMode _groupMode = SeriesGroupMode.year;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(seriesListProvider.notifier).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final asyncSeries = ref.watch(seriesListProvider);
    return Column(
      children: [
        const LobbyBreadcrumb(crumbs: [
          LobbyBreadcrumbCrumb(label: 'Home'),
          LobbyBreadcrumbCrumb(label: 'Series'),
        ]),
        _Toolbar(
          query: _query,
          hideCompleted: _hideCompleted,
          groupMode: _groupMode,
          onQuery: (q) => setState(() => _query = q),
          onHideCompleted: (v) => setState(() => _hideCompleted = v),
          onGroupMode: (m) => setState(() => _groupMode = m),
        ),
        Expanded(
          child: asyncSeries.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () =>
                  ref.read(seriesListProvider.notifier).fetch(),
            ),
            data: (list) {
              final filtered = _filter(list);
              if (filtered.isEmpty) {
                return const EmptyState(
                  message: 'No series available',
                  icon: Icons.workspace_premium_outlined,
                );
              }
              return _Grid(
                grouped: _group(filtered),
                onOpen: _onOpen,
              );
            },
          ),
        ),
      ],
    );
  }

  List<Series> _filter(List<Series> list) {
    return list.where((s) {
      if (_hideCompleted && s.isCompleted) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.seriesName.toLowerCase().contains(q) ||
          ((s.countryCode ?? '').toLowerCase().contains(q));
    }).toList();
  }

  /// Group series by year (`{year: items}`) or by year-month (`{YYYY-MM: items}`).
  /// Within each band items keep the natural order (latest beginAt first if
  /// the upstream provider sorts that way).
  List<_GroupBand> _group(List<Series> list) {
    if (_groupMode == SeriesGroupMode.year) {
      final map = <int, List<Series>>{};
      for (final s in list) {
        map.putIfAbsent(s.year, () => []).add(s);
      }
      final entries = map.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      return [
        for (final e in entries)
          _GroupBand(
            sortKey: e.key * 100 + 1,
            label: '${e.key}',
            items: e.value,
          ),
      ];
    }

    // Month mode: key = year * 100 + month, label = "March 2026"
    final map = <int, List<Series>>{};
    for (final s in list) {
      final key = s.year * 100 + _monthOfBegin(s);
      map.putIfAbsent(key, () => []).add(s);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return [
      for (final e in entries)
        _GroupBand(
          sortKey: e.key,
          label: _monthLabel(e.key),
          items: e.value,
        ),
    ];
  }

  int _monthOfBegin(Series s) {
    // beginAt is "YYYY-MM-DD..." per Series model. Fallback to 1 (Jan) if
    // the value is missing or malformed.
    if (s.beginAt.length < 7) return 1;
    return int.tryParse(s.beginAt.substring(5, 7)) ?? 1;
  }

  String _monthLabel(int yearMonth) {
    final year = yearMonth ~/ 100;
    final month = yearMonth % 100;
    final dt = DateTime(year, month);
    return '${DateFormat.MMMM().format(dt)} $year';
  }

  void _onOpen(Series s) {
    selectSeries(ref, s.seriesId, name: s.seriesName);
    context.go('/lobby/events/${s.seriesId}');
  }
}

class _GroupBand {
  const _GroupBand({
    required this.sortKey,
    required this.label,
    required this.items,
  });
  final int sortKey;
  final String label;
  final List<Series> items;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.hideCompleted,
    required this.groupMode,
    required this.onQuery,
    required this.onHideCompleted,
    required this.onGroupMode,
  });

  final String query;
  final bool hideCompleted;
  final SeriesGroupMode groupMode;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onHideCompleted;
  final ValueChanged<SeriesGroupMode> onGroupMode;

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
            width: 280,
            height: 28,
            child: TextField(
              onChanged: onQuery,
              style: EbsTypography.formInput,
              decoration: const InputDecoration(
                hintText: 'Search series, venue, year…',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(children: [
            Checkbox(
              value: hideCompleted,
              onChanged: (v) => onHideCompleted(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Text('Hide completed', style: EbsTypography.body),
          ]),
          const Spacer(),
          SegmentedButton<SeriesGroupMode>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: EbsTypography.body.copyWith(fontSize: 11.5),
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: SeriesGroupMode.month,
                label: Text('Month'),
              ),
              ButtonSegment(
                value: SeriesGroupMode.year,
                label: Text('Year'),
              ),
            ],
            selected: {groupMode},
            onSelectionChanged: (s) => onGroupMode(s.first),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.grouped, required this.onOpen});
  final List<_GroupBand> grouped;
  final ValueChanged<Series> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final band in grouped) _Section(
            label: band.label,
            items: band.items,
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.items, required this.onOpen});
  final String label;
  final List<Series> items;
  final ValueChanged<Series> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupBandHeader(label: label, count: items.length),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final cols = (c.maxWidth / 294).floor().clamp(1, 6);
            return Wrap(
              spacing: DesignChrome.cardGridGap,
              runSpacing: DesignChrome.cardGridGap,
              children: [
                for (final s in items)
                  SizedBox(
                    width: (c.maxWidth -
                            DesignChrome.cardGridGap * (cols - 1)) /
                        cols,
                    child: _SeriesCard(series: s, onTap: () => onOpen(s)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _GroupBandHeader extends StatelessWidget {
  const _GroupBandHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: EbsTypography.yearBand),
        const SizedBox(width: 12),
        Text(
          '$count series',
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamilyMono,
            fontSize: 11,
            color: DesignTokens.lightInk3,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: DesignTokens.lightLine, height: 1),
        ),
      ],
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series, required this.onTap});
  final Series series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.lightBg,
            border: Border.all(color: DesignTokens.lightLine),
            borderRadius:
                BorderRadius.circular(DesignChrome.cardBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Banner(series: series),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.seriesName,
                      style: EbsTypography.pageTitle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      series.countryCode ?? '—',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamilyMono,
                        fontSize: 11.5,
                        color: DesignTokens.lightInk3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          series.currency,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamilyMono,
                            fontSize: 11,
                            color: DesignTokens.lightInk3,
                          ),
                        ),
                        LobbyStatusBadge(
                          status: series.isCompleted ? 'completed' : 'running',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.series});
  final Series series;

  @override
  Widget build(BuildContext context) {
    // Accent color cycles by year for visual variety. The design source uses
    // per-series accents; we approximate by hashing year + name.
    final accent = _accentFor(series);
    return Container(
      height: DesignChrome.cardBannerHeight,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (series.countryCode ?? '—').toUpperCase(),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14 * 10,
            ),
          ),
          const Spacer(),
          Text(
            _range(series),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _range(Series s) {
    final b = s.beginAt.length >= 10 ? s.beginAt.substring(0, 10) : s.beginAt;
    final e = s.endAt.length >= 10 ? s.endAt.substring(0, 10) : s.endAt;
    return '$b → $e';
  }

  Color _accentFor(Series s) {
    final palette = [
      const Color(0xFF3D5A3F),
      const Color(0xFF3F4C6B),
      const Color(0xFF5C3F6B),
      const Color(0xFF6B523F),
    ];
    final idx = s.seriesId % palette.length;
    return palette[idx];
  }
}
