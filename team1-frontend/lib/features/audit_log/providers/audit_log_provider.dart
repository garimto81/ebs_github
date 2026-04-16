// Audit Log provider — simple paginated list.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/models.dart';
import '../../../repositories/audit_log_repository.dart';

part 'audit_log_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Paginated state
// ---------------------------------------------------------------------------

@freezed
class AuditLogState with _$AuditLogState {
  const factory AuditLogState({
    @Default([]) List<AuditLog> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int currentPage,
    @Default(50) int pageSize,
    String? error,
    String? filterEntityType,
    int? filterUserId,
  }) = _AuditLogState;
}

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  AuditLogNotifier(this._repo) : super(const AuditLogState());

  final AuditLogRepository _repo;

  /// Fetch the first page. Resets pagination.
  Future<void> fetchFirst({String? entityType, int? userId}) async {
    state = AuditLogState(
      isLoading: true,
      filterEntityType: entityType,
      filterUserId: userId,
      pageSize: state.pageSize,
    );
    try {
      final filters = <String, dynamic>{
        'page': 0,
        'page_size': state.pageSize,
        if (entityType != null) 'entity_type': entityType,
        if (userId != null) 'user_id': userId,
      };
      final items = await _repo.listAuditLogs(filters: filters);
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= state.pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch the next page and append results.
  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;
    try {
      final filters = <String, dynamic>{
        'page': nextPage,
        'page_size': state.pageSize,
        if (state.filterEntityType != null)
          'entity_type': state.filterEntityType,
        if (state.filterUserId != null) 'user_id': state.filterUserId,
      };
      final newItems = await _repo.listAuditLogs(filters: filters);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= state.pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final auditLogProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogState>(
  (ref) => AuditLogNotifier(ref.read(auditLogRepositoryProvider)),
);
