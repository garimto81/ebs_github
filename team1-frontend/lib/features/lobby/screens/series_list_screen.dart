import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/nav_provider.dart';
import '../providers/series_provider.dart';

/// Series list with search, bookmark filter, and card grid.
///
/// Ported from SeriesListPage.vue.
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({super.key});

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  final _searchCtrl = TextEditingController();
  bool _filterBookmarked = false;
  bool _filterUpdated = false;
  final Set<int> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    // Fetch on first load
    Future.microtask(() => ref.read(seriesListProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _filterBookmarked = false;
      _filterUpdated = false;
    });
  }

  List<Series> _applyFilters(List<Series> list) {
    var result = list;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result =
          result.where((s) => s.seriesName.toLowerCase().contains(q)).toList();
    }
    if (_filterUpdated) {
      final cutoff =
          DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
      result = result.where((s) => s.updatedAt.compareTo(cutoff) > 0).toList();
    }
    if (_filterBookmarked) {
      result =
          result.where((s) => _bookmarks.contains(s.seriesId)).toList();
    }
    return result;
  }

  void _toggleBookmark(int id) {
    setState(() {
      if (_bookmarks.contains(id)) {
        _bookmarks.remove(id);
      } else {
        _bookmarks.add(id);
      }
    });
  }

  void _onSelect(Series s) {
    selectSeries(ref, s.seriesId, name: s.seriesName);
    context.go('/series/${s.seriesId}/events');
  }

  @override
  Widget build(BuildContext context) {
    final asyncSeries = ref.watch(seriesListProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(asyncSeries),
            const SizedBox(height: 16),
            // Content
            Expanded(child: _buildContent(asyncSeries)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Series>> asyncSeries) {
    final count = asyncSeries.valueOrNull?.length ?? 0;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Series',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '$count total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search series...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Updated'),
          selected: _filterUpdated,
          onSelected: (v) => setState(() => _filterUpdated = v),
        ),
        const SizedBox(width: 4),
        FilterChip(
          label: const Text('Bookmarks'),
          selected: _filterBookmarked,
          onSelected: (v) => setState(() => _filterBookmarked = v),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetFilters,
          tooltip: 'Reset filters',
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: () {
            // TODO: show series creation form
          },
          icon: const Icon(Icons.add),
          label: const Text('New Series'),
        ),
      ],
    );
  }

  Widget _buildContent(AsyncValue<List<Series>> asyncSeries) {
    return asyncSeries.when(
      loading: () => const LoadingState(),
      error: (err, _) => ErrorBanner(
        message: err.toString(),
        onRetry: () => ref.read(seriesListProvider.notifier).fetch(),
      ),
      data: (list) {
        final filtered = _applyFilters(list);
        if (filtered.isEmpty) {
          return const EmptyState(
            message: 'No series found',
            icon: Icons.emoji_events,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 960
                ? 4
                : constraints.maxWidth > 640
                    ? 3
                    : 2;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildSeriesCard(filtered[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildSeriesCard(Series s) {
    final isBookmarked = _bookmarks.contains(s.seriesId);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onSelect(s),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.seriesName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.star : Icons.star_border,
                      color: isBookmarked ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => _toggleBookmark(s.seriesId),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ),
              Text(
                '${s.year} \u00b7 ${s.currency}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDate(s.beginAt)} \u2192 ${_formatDate(s.endAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                  _StatusBadge(
                    label: s.isCompleted ? 'completed' : 'running',
                    color: s.isCompleted ? Colors.grey : Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.length >= 10) return iso.substring(0, 10);
    return '\u2014';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
