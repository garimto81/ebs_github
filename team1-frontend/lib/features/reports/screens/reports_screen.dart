// Reports screen — unified 4-tab container absorbing hand_history + audit_log.
//
// Tabs: Hands Summary, Player Stats, Session Log, Table Activity.
// CSV export button in AppBar. Each tab shows a DataTable with report data
// fetched via reportDataProvider.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../repositories/report_repository.dart';
import '../providers/report_provider.dart';

// ---------------------------------------------------------------------------
// Tab ↔ ReportType mapping
// ---------------------------------------------------------------------------

const _tabs = ReportType.values;

ReportType _typeFromSlug(String? slug) {
  return switch (slug) {
    'hands-summary' => ReportType.handsSummary,
    'player-stats' => ReportType.playerStats,
    'session-log' => ReportType.sessionLog,
    'table-activity' => ReportType.tableActivity,
    _ => ReportType.handsSummary,
  };
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReportsScreen extends ConsumerStatefulWidget {
  final String reportType;
  const ReportsScreen({super.key, required this.reportType});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = _tabs.indexOf(_typeFromSlug(widget.reportType));
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initial >= 0 ? initial : 0,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportType != widget.reportType) {
      final idx = _tabs.indexOf(_typeFromSlug(widget.reportType));
      if (idx >= 0 && _tabController.index != idx) {
        _tabController.index = idx;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final slug = _tabs[_tabController.index].value;
      context.go('/reports/$slug');
    }
  }

  ReportType get _currentType => _typeFromSlug(widget.reportType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: _tabLabel(t))).toList(),
        ),
      ),
      body: _ReportTabBody(reportType: _currentType),
    );
  }

  void _exportCsv(BuildContext context) {
    final data = ref.read(reportDataProvider(_currentType));
    data.whenData((report) {
      final rows = _extractRows(report);
      if (rows.isEmpty) return;
      final csv = _rowsToCsv(rows);
      Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard')),
      );
    });
  }

  String _tabLabel(ReportType t) {
    return switch (t) {
      ReportType.handsSummary => 'Hands Summary',
      ReportType.playerStats => 'Player Stats',
      ReportType.sessionLog => 'Session Log',
      ReportType.tableActivity => 'Table Activity',
    };
  }
}

// ---------------------------------------------------------------------------
// Tab body — renders a DataTable from the report map
// ---------------------------------------------------------------------------

class _ReportTabBody extends ConsumerWidget {
  final ReportType reportType;
  const _ReportTabBody({required this.reportType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReport = ref.watch(reportDataProvider(reportType));

    return asyncReport.when(
      loading: () => const LoadingState(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final rows = _extractRows(report);
        if (rows.isEmpty) {
          return EmptyState(
            message: 'No data for this report',
            icon: _iconForType(reportType),
          );
        }

        final columns = rows.first.keys.toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: columns
                  .map((c) => DataColumn(label: Text(_humanize(c))))
                  .toList(),
              rows: rows
                  .map((row) => DataRow(
                        cells: columns
                            .map((c) =>
                                DataCell(Text(row[c]?.toString() ?? '')))
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForType(ReportType t) {
    return switch (t) {
      ReportType.handsSummary => Icons.style,
      ReportType.playerStats => Icons.bar_chart,
      ReportType.sessionLog => Icons.receipt_long,
      ReportType.tableActivity => Icons.table_chart,
    };
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Extract a list of row maps from the report payload.
/// Supports `{ "rows": [...] }` or `{ "data": [...] }` or a bare list.
List<Map<String, dynamic>> _extractRows(Map<String, dynamic> report) {
  final dynamic payload = report['rows'] ?? report['data'] ?? report['items'];
  if (payload is List) {
    return payload
        .whereType<Map<String, dynamic>>()
        .toList();
  }
  return [];
}

String _humanize(String key) {
  return key
      .replaceAll('_', ' ')
      .replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])'), (m) => ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _rowsToCsv(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return '';
  final columns = rows.first.keys.toList();
  final buf = StringBuffer();
  buf.writeln(columns.join(','));
  for (final row in rows) {
    buf.writeln(columns.map((c) {
      final v = row[c]?.toString() ?? '';
      return v.contains(',') || v.contains('"')
          ? '"${v.replaceAll('"', '""')}"'
          : v;
    }).join(','));
  }
  return buf.toString();
}
