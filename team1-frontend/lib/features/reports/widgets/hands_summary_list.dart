import 'package:flutter/material.dart';

import 'game_rules_badges.dart';

/// Hands Summary list — one row per hand with v03 game-rules badges.
///
/// Specialized renderer for ReportType.handsSummary that recognizes the
/// Cycle 7 (v03) fields and renders them as compact colored badges instead
/// of plain text columns:
///   - ante_amount  (>0)
///   - straddle_amount  (>0, nullable)
///   - run_it_twice_count  (>1)
///
/// Falls back to bare text rendering for any row without those fields.
/// Generic columns (hand #, table, pot, etc.) remain as plain DataCells.
class HandsSummaryList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const HandsSummaryList({super.key, required this.rows});

  static const _v03Keys = {'ante_amount', 'straddle_amount', 'run_it_twice_count'};

  String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  String _humanize(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (m) => ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Generic columns = original keys minus v03 keys.
  /// V03 columns collapse into a single "Rules" badge column at the end.
  List<String> _genericColumns() {
    if (rows.isEmpty) return const [];
    return rows.first.keys.where((k) => !_v03Keys.contains(k)).toList();
  }

  bool get _anyRowHasV03 {
    return rows.any(
      (r) => r.keys.any((k) => _v03Keys.contains(k) && _isMeaningful(k, r[k])),
    );
  }

  bool _isMeaningful(String key, dynamic value) {
    if (value == null) return false;
    final parsed = (value is num) ? value : num.tryParse(value.toString());
    if (parsed == null) return false;
    switch (key) {
      case 'ante_amount':
      case 'straddle_amount':
        return parsed > 0;
      case 'run_it_twice_count':
        return parsed > 1;
    }
    return false;
  }

  Widget _v03BadgesForRow(Map<String, dynamic> row) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final anteAmount = parseInt(row['ante_amount']);
    final straddleRaw = row['straddle_amount'];
    final straddleAmount = straddleRaw == null ? null : parseInt(straddleRaw);
    final runItTwiceCount = parseInt(row['run_it_twice_count']);

    return GameRulesBadges(
      anteAmount: anteAmount,
      straddleAmount: straddleAmount,
      runItTwiceCount: runItTwiceCount == 0 ? 1 : runItTwiceCount,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No hands to display'));
    }

    final genericCols = _genericColumns();
    final showV03Column = _anyRowHasV03;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          key: const Key('hands_summary_table'),
          columns: [
            for (final c in genericCols) DataColumn(label: Text(_humanize(c))),
            if (showV03Column)
              const DataColumn(label: Text('Rules')),
          ],
          rows: [
            for (final row in rows)
              DataRow(cells: [
                for (final c in genericCols)
                  DataCell(Text(_renderCell(c, row[c]))),
                if (showV03Column)
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _v03BadgesForRow(row),
                    ),
                  ),
              ]),
          ],
        ),
      ),
    );
  }

  String _renderCell(String key, dynamic value) {
    if (value == null) return '';
    if (value is num) {
      // Currency-style formatting for pot/stack fields.
      if (key.contains('amount') ||
          key.contains('stack') ||
          key.contains('pot') ||
          key.contains('pnl')) {
        return _fmt(value.toInt());
      }
    }
    return value.toString();
  }
}
