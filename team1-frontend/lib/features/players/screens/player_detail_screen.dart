import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../lobby/providers/player_provider.dart';

/// Provider to fetch a single player by ID.
final playerDetailProvider =
    FutureProvider.family<Player?, int>((ref, playerId) async {
  // TODO: wire repository — ref.read(playerRepositoryProvider).getById(playerId)
  final list = ref.read(playerListProvider);
  return list.whenOrNull(
    data: (players) {
      try {
        return players.firstWhere((p) => p.playerId == playerId);
      } catch (_) {
        return null;
      }
    },
  );
});

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(playerId);
    if (id == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid player ID')),
      );
    }

    final playerAsync = ref.watch(playerDetailProvider(id));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            TextButton.icon(
              onPressed: () => context.go('/players'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: playerAsync.when(
                loading: () => const LoadingState(),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (player) {
                  if (player == null) {
                    return const Center(child: Text('Player not found'));
                  }
                  return _PlayerDetailContent(player: player);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDetailContent extends StatelessWidget {
  final Player player;
  const _PlayerDetailContent({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mock stats — will be populated from API
    final rng = math.Random(player.playerId);
    final handsPlayed = rng.nextInt(200);
    final vpip = rng.nextInt(40) + 10;
    final pfr = rng.nextInt(25) + 5;
    const startStack = 20000;
    final pnl = (player.stack ?? startStack) - startStack;

    // Mock stack history
    final stackHistory = <_StackEntry>[];
    if (player.stack != null) {
      var current = startStack;
      for (var i = 1; i <= math.min(handsPlayed, 30); i++) {
        current += (rng.nextDouble() - 0.45).round() * 3000;
        if (current < 0) current = 0;
        stackHistory.add(_StackEntry(handNo: i, stack: current));
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(
                      '${player.firstName.isNotEmpty ? player.firstName[0] : ""}${player.lastName.isNotEmpty ? player.lastName[0] : ""}',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${player.firstName} ${player.lastName}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        'WSOP ID: ${player.wsopId ?? "\u2014"}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        'Nationality: ${player.nationality ?? "\u2014"}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _StatusChip(
                    label: player.tableName != null ? 'Active' : 'Waiting',
                    isActive: player.tableName != null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current assignment
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Assignment',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (player.tableName != null)
                    Row(
                      children: [
                        _InfoBlock(
                            label: 'Table', value: player.tableName!),
                        const SizedBox(width: 32),
                        _InfoBlock(
                          label: 'Seat',
                          value: player.seatIndex?.toString() ?? '\u2014',
                        ),
                        const SizedBox(width: 32),
                        _InfoBlock(
                          label: 'Stack',
                          value: _formatStack(player.stack),
                          bold: true,
                        ),
                      ],
                    )
                  else
                    Text(
                      'Not assigned to any table',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                    label: 'Hands Played', value: handsPlayed.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: 'VPIP', value: '$vpip%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: 'PFR', value: '$pfr%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'P&L',
                  value: '${pnl >= 0 ? '+' : ''}${_formatStack(pnl)}',
                  valueColor: pnl >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stack history chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stack History',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (stackHistory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hand data yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: _StackHistoryChart(entries: stackHistory),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Table move history (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table History',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No moves recorded',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatStack(int? val) {
    if (val == null) return '\u2014';
    if (val.abs() >= 1000) {
      return '${(val / 1000).toStringAsFixed(val.abs() % 1000 == 0 ? 0 : 1)}k';
    }
    return val.toString();
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _StatusChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoBlock({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackEntry {
  final int handNo;
  final int stack;
  const _StackEntry({required this.handNo, required this.stack});
}

class _StackHistoryChart extends StatelessWidget {
  final List<_StackEntry> entries;
  const _StackHistoryChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maxStack = entries.map((e) => e.stack).reduce(math.max);
    final effectiveMax = maxStack == 0 ? 1 : maxStack;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / entries.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.map((entry) {
            final heightFraction = entry.stack / effectiveMax;
            return Tooltip(
              message: 'Hand #${entry.handNo}: ${entry.stack}',
              child: Container(
                width: barWidth - 1,
                height: constraints.maxHeight * heightFraction,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
