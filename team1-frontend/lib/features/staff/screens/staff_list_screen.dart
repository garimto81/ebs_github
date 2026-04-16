import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/lobby_colors.dart';
import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/staff_provider.dart';
import '../widgets/user_form_dialog.dart';

/// Role filter state.
final _roleFilterProvider = StateProvider<String>((ref) => 'all');

/// Search query for staff list.
final _staffSearchProvider = StateProvider<String>((ref) => '');

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(staffListProvider.notifier).fetch(),
    );
  }

  void _openCreateDialog() {
    ref.read(staffEditingIdProvider.notifier).state = null;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UserFormDialog(),
    );
  }

  void _openEditDialog(User user) {
    ref.read(staffEditingIdProvider.notifier).state = user.userId;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(existingUser: user),
    );
  }

  Future<void> _confirmDelete(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.displayName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(staffListProvider.notifier).applyRemoteDelete(user.userId);
    }
  }

  Future<void> _confirmForceLogout(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Logout'),
        content: Text('Force logout ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Force Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // TODO: call usersApi.forceLogout(user.userId)
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(staffListProvider);
    final roleFilter = ref.watch(_roleFilterProvider);
    final search = ref.watch(_staffSearchProvider).toLowerCase();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Staff Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 240,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        ref.read(_staffSearchProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 12),
                // Role filter
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: roleFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'operator', child: Text('Operator')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(_roleFilterProvider.notifier).state = v;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New User'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: usersAsync.when(
                loading: () => const LoadingState(),
                error: (err, _) => ErrorBanner(
                  message: 'Failed to load users: $err',
                  onRetry: () =>
                      ref.read(staffListProvider.notifier).fetch(),
                ),
                data: (users) {
                  var filtered = users;

                  // Apply search
                  if (search.isNotEmpty) {
                    filtered = filtered
                        .where((u) =>
                            u.email.toLowerCase().contains(search) ||
                            u.displayName.toLowerCase().contains(search))
                        .toList();
                  }

                  // Apply role filter
                  if (roleFilter != 'all') {
                    filtered = filtered
                        .where((u) => u.role == roleFilter)
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'No users found',
                      icon: Icons.badge,
                    );
                  }

                  return _StaffDataTable(
                    users: filtered,
                    onEdit: _openEditDialog,
                    onDelete: _confirmDelete,
                    onForceLogout: _confirmForceLogout,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDataTable extends StatelessWidget {
  final List<User> users;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;
  final ValueChanged<User> onForceLogout;

  const _StaffDataTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onForceLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Display Name')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Last Login')),
          DataColumn(label: Text('Actions')),
        ],
        rows: users.map((u) {
          return DataRow(
            cells: [
              DataCell(Text(u.email)),
              DataCell(Text(u.displayName)),
              DataCell(_RoleBadge(role: u.role)),
              DataCell(_ActiveIndicator(isActive: u.isActive)),
              DataCell(Text(_formatRelativeTime(u.lastLoginAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => onEdit(u),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Force Logout'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      onSelected: (action) {
                        if (action == 'logout') onForceLogout(u);
                        if (action == 'delete') onDelete(u);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static String _formatRelativeTime(String? iso) {
    if (iso == null) return '--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = LobbyColors.roleAdmin;
      case 'operator':
        color = LobbyColors.roleOperator;
      case 'viewer':
        color = LobbyColors.roleViewer;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.substring(0, 1).toUpperCase() + role.substring(1),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActiveIndicator extends StatelessWidget {
  final bool isActive;
  const _ActiveIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.circle : Icons.radio_button_unchecked,
          size: 12,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(isActive ? 'Active' : 'Disabled'),
      ],
    );
  }
}
