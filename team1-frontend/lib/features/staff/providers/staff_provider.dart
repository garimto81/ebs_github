// Staff (User) provider — simple CRUD list + form state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/models.dart';
import '../../../repositories/staff_repository.dart';

// ---------------------------------------------------------------------------
// User list
// ---------------------------------------------------------------------------

class StaffListNotifier extends StateNotifier<AsyncValue<List<User>>> {
  StaffListNotifier(this._repo) : super(const AsyncValue.loading());

  final StaffRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.listUsers();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyRemoteUpdate(User updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final u in list)
          if (u.userId == updated.userId) updated else u,
      ]);
    });
  }

  void applyRemoteAdd(User added) {
    state.whenData((list) {
      state = AsyncValue.data([...list, added]);
    });
  }

  void applyRemoteDelete(int userId) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((u) => u.userId != userId).toList(),
      );
    });
  }
}

final staffListProvider =
    StateNotifierProvider<StaffListNotifier, AsyncValue<List<User>>>(
  (ref) => StaffListNotifier(ref.read(staffRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Form state for create/edit
// ---------------------------------------------------------------------------

final staffEditingIdProvider = StateProvider<int?>((ref) => null);
final staffFormDirtyProvider = StateProvider<bool>((ref) => false);
