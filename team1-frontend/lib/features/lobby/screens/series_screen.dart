// EBS Lobby — Series screen (year-grouped card grid).
//
// Mirrors `SeriesScreen` from the design source. Cards group by year, each
// card has a banner accent + name + venue + event count + status badge.

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
import '../providers/series_provider.dart';
import '../widgets/lobby_status_badge.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  String _query = '';
  bool _hideCompleted = false;

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
          onQuery: (q) => setState(() => _query = q),
          onHideCompleted: (v) => setState(() => _hideCompleted = v),
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
                grouped: _groupByYear(filtered),
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

  List<MapEntry<int, List<Series>>> _groupByYear(List<Series> list) {
    final map = <int, List<Series>>{};
    for (final s in list) {
      map.putIfAbsent(s.year, () => []).add(s);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  void _onOpen(Series s) {
    selectSeries(ref, s.seriesId, name: s.seriesName);
    context.go('/lobby/events/${s.seriesId}');
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.hideCompleted,
    required this.onQuery,
    required this.onHideCompleted,
  });

  final String query;
  final bool hideCompleted;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onHideCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      // HTML: `.toolbar { padding: 6px 16px; border-bottom: 1px solid #eee }`
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
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
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.grouped, required this.onOpen});
  final List<MapEntry<int, List<Series>>> grouped;
  final ValueChanged<Series> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // HTML: main content area padding matches toolbar (16px sides)
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in grouped) _Section(
            year: entry.key,
            items: entry.value,
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.year, required this.items, required this.onOpen});
  final int year;
  final List<Series> items;
  final ValueChanged<Series> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YearBand(year: year, count: items.length),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            // HTML: `grid-template-columns: repeat(4, 1fr)` → min ~220px per card
            final cols = (c.maxWidth / 220).floor().clamp(1, 6);
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

class _YearBand extends StatelessWidget {
  const _YearBand({required this.year, required this.count});
  final int year;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$year', style: EbsTypography.yearBand),
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
          // HTML: `border: 1px solid #e0e0e0` — NO border-radius
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.fromBorderSide(
              BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Banner(series: series),
              Padding(
                // HTML: `.card-body { padding: 6px 8px }`
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.seriesName,
                      // HTML: `.card-name { font-size: 10px; font-weight: 700 }`
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamilyUi,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      series.countryCode ?? '—',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamilyMono,
                        fontSize: 9,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          series.currency,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamilyMono,
                            fontSize: 9,
                            color: Color(0xFF999999),
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
    // HTML: `.card-banner { height: 52px; background: <flat-hex-color> }` — NO gradient.
    // Accent cycles by seriesId for visual variety (same hue palette, flat).
    final accent = _accentFor(series);
    return Container(
      height: DesignChrome.cardBannerHeight, // 52px per HTML
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            (series.countryCode ?? '—').toUpperCase(),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyUi,
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            _range(series),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamilyMono,
              color: Colors.white,
              fontSize: 9,
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
