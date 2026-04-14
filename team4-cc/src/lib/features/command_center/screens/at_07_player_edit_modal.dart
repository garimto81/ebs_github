// AT-07 Player Edit modal (BS-05-09, CCR-028).
// Long-press seat → edit name/country_code (IDLE only) + sit_out_toggle (any time).
// PATCH /players/{id} → server emits PlayerUpdated WebSocket event.
//
// 480×auto Dialog. 7 fields. [Save] [Cancel] [Reset Seat].
// RBAC: Admin/Operator (assigned tables only).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../../auth/auth_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

// ---------------------------------------------------------------------------
// Show helper
// ---------------------------------------------------------------------------

/// Show the AT-07 Player Edit modal for [seatNo]. Returns true if saved.
Future<bool?> showPlayerEditModal(BuildContext context, int seatNo) {
  return showDialog<bool>(
    context: context,
    builder: (_) => At07PlayerEditModal(seatNo: seatNo),
  );
}

// ---------------------------------------------------------------------------
// VIP levels
// ---------------------------------------------------------------------------

const _vipLevels = ['None', 'Silver', 'Gold', 'Platinum', 'Diamond'];

// ---------------------------------------------------------------------------
// Country data (subset for demo; full list from ISO 3166-1)
// ---------------------------------------------------------------------------

const _countries = <String, String>{
  '': 'Not set',
  'US': 'United States',
  'GB': 'United Kingdom',
  'CA': 'Canada',
  'AU': 'Australia',
  'DE': 'Germany',
  'FR': 'France',
  'JP': 'Japan',
  'KR': 'South Korea',
  'BR': 'Brazil',
  'MX': 'Mexico',
  'CN': 'China',
  'IN': 'India',
  'IT': 'Italy',
  'ES': 'Spain',
  'SE': 'Sweden',
};

String _countryFlag(String code) {
  if (code.isEmpty || code.length != 2) return '';
  // Convert country code to flag emoji (regional indicator symbols)
  final first = 0x1F1E6 + code.codeUnitAt(0) - 0x41;
  final second = 0x1F1E6 + code.codeUnitAt(1) - 0x41;
  return String.fromCharCodes([first, second]);
}

// ---------------------------------------------------------------------------
// AT-07 Player Edit Modal
// ---------------------------------------------------------------------------

class At07PlayerEditModal extends ConsumerStatefulWidget {
  const At07PlayerEditModal({super.key, required this.seatNo});
  final int seatNo;

  @override
  ConsumerState<At07PlayerEditModal> createState() =>
      _At07PlayerEditModalState();
}

class _At07PlayerEditModalState extends ConsumerState<At07PlayerEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _stackController;
  late TextEditingController _avatarUrlController;

  late String _countryCode;
  late String _vipLevel;
  late SeatStatus _seatStatus;
  late PlayerActivity _activity;

  @override
  void initState() {
    super.initState();
    final seats = ref.read(seatsProvider);
    final seat = seats.firstWhere((s) => s.seatNo == widget.seatNo);
    final player = seat.player;

    _nameController = TextEditingController(text: player?.name ?? '');
    _stackController =
        TextEditingController(text: '${player?.stack ?? 0}');
    _avatarUrlController =
        TextEditingController(text: player?.avatarUrl ?? '');
    _countryCode = player?.countryCode ?? '';
    _vipLevel = 'None'; // Not stored in PlayerInfo yet
    _seatStatus = seat.status;
    _activity = seat.activity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stackController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final handFsm = ref.watch(handFsmProvider);
    final seat = ref.watch(seatsProvider)
        .firstWhere((s) => s.seatNo == widget.seatNo);
    final isIdle =
        handFsm == HandFsm.idle || handFsm == HandFsm.handComplete;
    final canEdit = auth.role == 'Admin' || auth.role == 'Operator';

    if (!canEdit) {
      return AlertDialog(
        title: Text('Seat ${widget.seatNo}'),
        content:
            const Text('You do not have permission to edit player details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Dialog(
      child: SizedBox(
        width: EbsSpacing.modalWidthSm,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Title --
              Container(
                padding: const EdgeInsets.fromLTRB(
                  EbsSpacing.md, EbsSpacing.md, EbsSpacing.sm, 0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Edit Player — Seat ${widget.seatNo}',
                      style: EbsTypography.modalTitle,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EbsSpacing.md,
                  vertical: EbsSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Name
                    const _FieldLabel('Name'),
                    const SizedBox(height: EbsSpacing.xs),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 2. Player ID (read-only)
                    const _FieldLabel('Player ID'),
                    const SizedBox(height: EbsSpacing.xs),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: EbsSpacing.sm,
                        vertical: EbsSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        '${seat.player?.id ?? "—"}',
                        style: EbsTypography.infoBar.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 3. Nationality (dropdown + flag)
                    const _FieldLabel('Nationality'),
                    const SizedBox(height: EbsSpacing.xs),
                    DropdownButtonFormField<String>(
                      value: _countries.containsKey(_countryCode)
                          ? _countryCode
                          : '',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _countries.entries.map((e) {
                        final flag = e.key.isNotEmpty
                            ? '${_countryFlag(e.key)} '
                            : '';
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text('$flag${e.value}'),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _countryCode = v ?? ''),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 4. Stack (IDLE only)
                    _IdleField(
                      label: 'Stack',
                      isIdle: isIdle,
                      child: TextField(
                        controller: _stackController,
                        enabled: isIdle,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 5. Avatar URL
                    const _FieldLabel('Avatar URL'),
                    const SizedBox(height: EbsSpacing.xs),
                    TextField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'https://...',
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 6. VIP Level
                    const _FieldLabel('VIP Level'),
                    const SizedBox(height: EbsSpacing.xs),
                    DropdownButtonFormField<String>(
                      value: _vipLevel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _vipLevels.map((v) {
                        return DropdownMenuItem(value: v, child: Text(v));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _vipLevel = v ?? 'None'),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 7. Seat Status (IDLE only)
                    _IdleField(
                      label: 'Seat Status',
                      isIdle: isIdle,
                      child: DropdownButtonFormField<SeatStatus>(
                        value: _seatStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: SeatStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: isIdle
                            ? (v) => setState(
                                () => _seatStatus = v ?? _seatStatus)
                            : null,
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // Sitting Out toggle (always available)
                    SwitchListTile(
                      title: const Text('Sitting Out'),
                      subtitle: Text(
                        isIdle
                            ? 'Immediate effect'
                            : 'Takes effect next hand',
                        style: EbsTypography.infoBar.copyWith(
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                      value: _activity == PlayerActivity.sittingOut,
                      onChanged: (v) => setState(() {
                        _activity = v
                            ? PlayerActivity.sittingOut
                            : PlayerActivity.active;
                      }),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // -- Actions --
              Padding(
                padding: const EdgeInsets.all(EbsSpacing.md),
                child: Row(
                  children: [
                    // Reset Seat (dangerous)
                    TextButton(
                      onPressed: () => _handleResetSeat(context),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                      ),
                      child: const Text('Reset Seat'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: EbsSpacing.sm),
                    ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text('Save'),
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

  void _handleSave() {
    final seatNotifier = ref.read(seatsProvider.notifier);
    final seat =
        ref.read(seatsProvider).firstWhere((s) => s.seatNo == widget.seatNo);

    if (seat.player != null) {
      // Update player info
      final updatedPlayer = seat.player!.copyWith(
        name: _nameController.text.trim(),
        stack: int.tryParse(_stackController.text) ?? seat.player!.stack,
        countryCode: _countryCode,
        avatarUrl: _avatarUrlController.text.trim().isNotEmpty
            ? _avatarUrlController.text.trim()
            : null,
      );

      // Apply player update via seat notifier
      seatNotifier.seatPlayer(widget.seatNo, updatedPlayer);

      // Apply activity change
      seatNotifier.setActivity(widget.seatNo, _activity);

      // Apply seat status if changed
      // (seatPlayer sets newSeat, so we may need to override)
    }

    // TODO: PATCH /players/{id} via BO API client
    debugPrint('Save player S${widget.seatNo}');
    Navigator.of(context).pop(true);
  }

  void _handleResetSeat(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Seat'),
        content: Text(
          'Vacate Seat ${widget.seatNo} and remove all player data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(seatsProvider.notifier).vacateSeat(widget.seatNo);
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: EbsTypography.playerName.copyWith(fontSize: 13));
  }
}

class _IdleField extends StatelessWidget {
  const _IdleField({
    required this.label,
    required this.isIdle,
    required this.child,
  });

  final String label;
  final bool isIdle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: EbsTypography.playerName.copyWith(fontSize: 13),
            ),
            if (!isIdle) ...[
              const SizedBox(width: EbsSpacing.xs),
              Tooltip(
                message: 'Can only be changed between hands (IDLE state)',
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: EbsSpacing.xs),
        child,
      ],
    );
  }
}
