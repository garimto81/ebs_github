// Audit Log screen — admin-only log viewer with search + DataTable.
//
// Ported from _archive-quasar/src/pages/AuditLogPage.vue (77 LOC).
// Columns: timestamp, user, action, entity, details, IP.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../../resources/l10n/app_localizations.dart';
import '../providers/audit_log_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch.
    Future.microtask(
        () => ref.read(auditLogProvider.notifier).fetchFirst());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(auditLogProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(l.auditLogTitle,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Search
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l.commonSearch,
                    suffixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _buildContent(state, l, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuditLogState state, AppLocalizations l, ThemeData theme) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState();
    }
    if (state.items.isEmpty) {
      return EmptyState(message: l.auditLogEmpty, icon: Icons.policy);
    }

    final filtered = _filter.isEmpty
        ? state.items
        : state.items.where((log) {
            final haystack =
                '${log.action} ${log.entityType} ${log.detail ?? ''}'
                    .toLowerCase();
            return haystack.contains(_filter);
          }).toList();

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l.auditLogTimestamp)),
            DataColumn(label: Text(l.auditLogUser)),
            DataColumn(label: Text(l.auditLogAction)),
            DataColumn(label: Text(l.auditLogEntity)),
            DataColumn(label: Text(l.auditLogDetails)),
            DataColumn(label: Text(l.auditLogIp)),
          ],
          rows: filtered.map((log) => _buildRow(log)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(AuditLog log) {
    return DataRow(cells: [
      DataCell(Text(log.createdAt)),
      DataCell(Text(log.userId.toString())),
      DataCell(Text(log.action)),
      DataCell(Text(log.entityType)),
      DataCell(Text(log.detail ?? '')),
      DataCell(Text(log.ipAddress ?? '')),
    ]);
  }
}
