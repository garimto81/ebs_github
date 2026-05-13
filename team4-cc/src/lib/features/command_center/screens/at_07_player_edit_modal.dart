// AT-07 Player Edit modal (BS-05-09, CCR-028).
// Long-press seat → edit name/country_code (IDLE only) + sit_out_toggle (any time).
// PATCH /players/{id} → server emits PlayerUpdated WebSocket event.
//
// 480×auto Dialog. 7 fields. [Save] [Cancel] [Reset Seat].
// RBAC: Admin/Operator (assigned tables only).
//
// Cycle 19 Wave 4 U6 — Broadcast Dark Amber OKLCH 정합.
// 디자인 reference:
//   - HTML SSOT : `docs/mockups/EBS Command Center/FieldEditor.jsx`
//   - CSS SSOT  : `docs/mockups/EBS Command Center/app.css` §".fe-popover"
//   - 토큰 적용 :
//       Surface       : EbsOklch.bg3 + EbsShadows.card
//       Input bg/fg   : EbsOklch.bg1 / EbsOklch.fg0
//       Focus ring    : EbsOklch.accent (2px)
//       Validation    : EbsOklch.err (label + helper text)
//       Section line  : EbsOklch.line
//       Field label   : EbsOklch.fg2 (uppercase, 10.5px)
//       Sub helper    : EbsOklch.fg3
//       Reset button  : EbsOklch.err (destructive)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/bo_api_client.dart';
import '../../../foundation/theme/ebs_oklch.dart';
import '../../../foundation/theme/ebs_shadows.dart';
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
    final auth = ref.watch(authProvider);
    final handFsm = ref.watch(handFsmProvider);
    final seat = ref.watch(seatsProvider)
        .firstWhere((s) => s.seatNo == widget.seatNo);
    final isIdle =
        handFsm == HandFsm.idle || handFsm == HandFsm.handComplete;
    final canEdit = auth.role == 'Admin' || auth.role == 'Operator';

    if (!canEdit) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: EbsSpacing.modalWidthSm,
          decoration: BoxDecoration(
            color: EbsOklch.bg3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EbsOklch.line),
            boxShadow: EbsShadows.card,
          ),
          padding: const EdgeInsets.all(EbsSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seat ${widget.seatNo}',
                style: EbsTypography.modalTitle.copyWith(color: EbsOklch.fg0),
              ),
              const SizedBox(height: EbsSpacing.sm),
              const Text(
                'You do not have permission to edit player details.',
                style: TextStyle(color: EbsOklch.fg1, fontSize: 13),
              ),
              const SizedBox(height: EbsSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: EbsOklch.fg1),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      // Strip Material default surface — root Container owns the bg3 popover.
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.lg,
        vertical: EbsSpacing.xl,
      ),
      child: Container(
        width: EbsSpacing.modalWidthSm,
        decoration: BoxDecoration(
          color: EbsOklch.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EbsOklch.line),
          boxShadow: EbsShadows.card,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Title --
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EbsSpacing.md + 2,
                  EbsSpacing.sm + 6,
                  EbsSpacing.sm + 2,
                  EbsSpacing.sm + 6,
                ),
                child: Row(
                  children: [
                    // Seat chip (.fe-seat parity).
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EbsSpacing.sm,
                        vertical: EbsSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: EbsOklch.bg2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: EbsOklch.line),
                      ),
                      child: Text(
                        'S${widget.seatNo}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: EbsOklch.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: EbsSpacing.sm + 2),
                    Expanded(
                      child: Text(
                        'Edit Player',
                        style: EbsTypography.modalTitle.copyWith(
                          fontSize: 14,
                          color: EbsOklch.fg0,
                          letterSpacing: -0.14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: EbsOklch.fg1,
                      onPressed: () => Navigator.of(context).pop(false),
                      splashRadius: 16,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              const _SectionDivider(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EbsSpacing.md + 2,
                  vertical: EbsSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Name
                    const _FieldLabel('Name'),
                    const SizedBox(height: EbsSpacing.xs + 2),
                    _OklchTextField(
                      controller: _nameController,
                      hintText: 'Player name',
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 2. Player ID (read-only)
                    const _FieldLabel('Player ID'),
                    const SizedBox(height: EbsSpacing.xs + 2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: EbsSpacing.sm + 4,
                        vertical: EbsSpacing.sm + 4,
                      ),
                      decoration: BoxDecoration(
                        color: EbsOklch.bg1,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: EbsOklch.line),
                      ),
                      child: Text(
                        '${seat.player?.id ?? "—"}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          color: EbsOklch.fg2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 3. Nationality (dropdown + flag)
                    const _FieldLabel('Nationality'),
                    const SizedBox(height: EbsSpacing.xs + 2),
                    _OklchDropdown<String>(
                      value: _countries.containsKey(_countryCode)
                          ? _countryCode
                          : '',
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
                      child: _OklchTextField(
                        controller: _stackController,
                        enabled: isIdle,
                        keyboardType: TextInputType.number,
                        mono: true,
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 5. Avatar URL
                    const _FieldLabel('Avatar URL'),
                    const SizedBox(height: EbsSpacing.xs + 2),
                    _OklchTextField(
                      controller: _avatarUrlController,
                      hintText: 'https://...',
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // 6. VIP Level
                    const _FieldLabel('VIP Level'),
                    const SizedBox(height: EbsSpacing.xs + 2),
                    _OklchDropdown<String>(
                      value: _vipLevel,
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
                      child: _OklchDropdown<SeatStatus>(
                        value: _seatStatus,
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
                        enabled: isIdle,
                      ),
                    ),

                    const SizedBox(height: EbsSpacing.md),

                    // Sitting Out toggle (always available)
                    SwitchListTile(
                      title: const Text(
                        'Sitting Out',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EbsOklch.fg0,
                        ),
                      ),
                      subtitle: Text(
                        isIdle
                            ? 'Immediate effect'
                            : 'Takes effect next hand',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: EbsOklch.fg2,
                        ),
                      ),
                      activeThumbColor: EbsOklch.accent,
                      activeTrackColor: EbsOklch.accentSoft,
                      inactiveThumbColor: EbsOklch.fg3,
                      inactiveTrackColor: EbsOklch.bg1,
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

              const _SectionDivider(),

              // -- Actions --
              Padding(
                padding: const EdgeInsets.all(EbsSpacing.md + 2),
                child: Row(
                  children: [
                    // Reset Seat (destructive — err token).
                    TextButton(
                      onPressed: () => _handleResetSeat(context),
                      style: TextButton.styleFrom(
                        foregroundColor: EbsOklch.err,
                        padding: const EdgeInsets.symmetric(
                          horizontal: EbsSpacing.sm + 4,
                          vertical: EbsSpacing.sm,
                        ),
                      ),
                      child: const Text(
                        'Reset Seat',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: EbsOklch.fg1,
                        backgroundColor: EbsOklch.bg2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: EbsSpacing.md,
                          vertical: EbsSpacing.sm + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: EbsOklch.line),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: EbsSpacing.sm + 2),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EbsOklch.accent,
                        foregroundColor: EbsOklch.bg0,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: EbsSpacing.md + 2,
                          vertical: EbsSpacing.sm + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.36,
                        ),
                      ),
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

  Future<void> _handleSave() async {
    final seatNotifier = ref.read(seatsProvider.notifier);
    final seat =
        ref.read(seatsProvider).firstWhere((s) => s.seatNo == widget.seatNo);

    if (seat.player == null) {
      Navigator.of(context).pop(false);
      return;
    }

    final name = _nameController.text.trim();
    final stack = int.tryParse(_stackController.text) ?? seat.player!.stack;
    final avatarUrl = _avatarUrlController.text.trim();
    final countryCode = _countryCode;

    // Optimistic local update (UI latency-first).
    final updatedPlayer = seat.player!.copyWith(
      name: name,
      stack: stack,
      countryCode: countryCode,
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
    );
    seatNotifier.seatPlayer(widget.seatNo, updatedPlayer);
    seatNotifier.setActivity(widget.seatNo, _activity);

    // Server sync — PATCH /api/tables/{id}/seats/{seat_no}/player.
    final config = ref.read(launchConfigProvider);
    if (config == null) {
      // Launch config missing (dev/test) — skip server call.
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    final api = ref.read(boApiClientProvider);
    try {
      await api.updatePlayer(config.tableId, widget.seatNo, {
        'name': name,
        'stack': stack,
        if (countryCode.isNotEmpty) 'country_code': countryCode,
        if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        'activity': _activity.name,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[AT-07] updatePlayer failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패 — 서버 동기화 오류: $e')),
      );
      // Keep local state applied; operator may retry via Save.
    }
  }

  void _handleResetSeat(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EbsOklch.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: EbsOklch.err),
        ),
        title: const Text(
          'Reset Seat',
          style: TextStyle(color: EbsOklch.fg0, fontSize: 16),
        ),
        content: Text(
          'Vacate Seat ${widget.seatNo} and remove all player data?',
          style: const TextStyle(color: EbsOklch.fg1, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: EbsOklch.fg1),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(seatsProvider.notifier).vacateSeat(widget.seatNo);
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EbsOklch.err,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers — OKLCH-skinned form primitives
// =============================================================================

/// `.fe-label` — uppercase 10.5px / 0.10em letter-spacing / fg-2.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.05, // 0.10em
        color: EbsOklch.fg2,
      ),
    );
  }
}

/// Section divider — `border-bottom: 1px solid var(--line)`.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: EbsOklch.line);
}

/// `.fe-input` — bg-1 surface, fg-0 text, accent focus ring (2px).
class _OklchTextField extends StatelessWidget {
  const _OklchTextField({
    required this.controller,
    this.hintText,
    this.enabled = true,
    this.keyboardType,
    this.mono = false,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: mono ? 'JetBrains Mono' : 'Inter',
        fontSize: mono ? 14 : 14,
        fontWeight: FontWeight.w600,
        color: enabled ? EbsOklch.fg0 : EbsOklch.fg3,
        fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
      ),
      cursorColor: EbsOklch.accent,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? EbsOklch.bg1 : EbsOklch.bg2,
        hintText: hintText,
        hintStyle: const TextStyle(color: EbsOklch.fg3, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EbsSpacing.sm + 4,
          vertical: EbsSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.accent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: EbsOklch.line.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.err),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.err, width: 2),
        ),
        errorStyle: const TextStyle(
          color: EbsOklch.err,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// OKLCH-skinned dropdown wrapper around `DropdownButtonFormField`.
class _OklchDropdown<T> extends StatelessWidget {
  const _OklchDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      dropdownColor: EbsOklch.bg2,
      iconEnabledColor: EbsOklch.fg1,
      iconDisabledColor: EbsOklch.fg3,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: enabled ? EbsOklch.fg0 : EbsOklch.fg3,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? EbsOklch.bg1 : EbsOklch.bg2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EbsSpacing.sm + 4,
          vertical: EbsSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: EbsOklch.accent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: EbsOklch.line.withValues(alpha: 0.5)),
        ),
      ),
    );
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
            _FieldLabel(label),
            if (!isIdle) ...[
              const SizedBox(width: EbsSpacing.xs),
              const Tooltip(
                message: 'Can only be changed between hands (IDLE state)',
                child: Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: EbsOklch.fg3,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: EbsSpacing.xs + 2),
        child,
      ],
    );
  }
}
