// AT-06 Game Settings modal (BS-05-08, CCR-028 Option A minimal scope).
// In-session fields: game_type, blind_structure_id, ante_override, straddle,
// run_it_multiple, cap_bb_multiplier. Global settings remain in team1 Lobby.
//
// 600×auto Dialog, 3 Tabs: Game / Blinds / Rules.
// IDLE-only fields greyed during hand with tooltip.
// RBAC: Admin/Operator only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/game_type.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../auth/auth_provider.dart';
import '../providers/config_provider.dart';
import '../providers/hand_fsm_provider.dart';

// ---------------------------------------------------------------------------
// Show helper
// ---------------------------------------------------------------------------

/// Show the AT-06 Game Settings modal. Returns true if saved.
Future<bool?> showGameSettingsModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const At06GameSettingsModal(),
  );
}

// ---------------------------------------------------------------------------
// AT-06 Game Settings Modal
// ---------------------------------------------------------------------------

class At06GameSettingsModal extends ConsumerStatefulWidget {
  const At06GameSettingsModal({super.key});

  @override
  ConsumerState<At06GameSettingsModal> createState() =>
      _At06GameSettingsModalState();
}

class _At06GameSettingsModalState extends ConsumerState<At06GameSettingsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Editable copies of config fields
  late GameType _gameType;
  late BetStructure _betStructure;
  late String? _blindStructureId;
  late int _anteOverride;
  late List<int> _straddleSeats;
  late bool _runItMultiple;
  late int _capBbMultiplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFromConfig();
  }

  void _loadFromConfig() {
    final config = ref.read(configProvider);
    _gameType = config.gameType;
    _betStructure = config.betStructure;
    _blindStructureId = config.blindStructureId;
    _anteOverride = config.ante;
    _straddleSeats = List<int>.from(config.straddleSeats);
    _runItMultiple = false; // Not stored in GameConfig yet — default
    _capBbMultiplier = 0; // Not stored in GameConfig yet — default
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final handFsm = ref.watch(handFsmProvider);
    final isIdle =
        handFsm == HandFsm.idle || handFsm == HandFsm.handComplete;
    final canEdit = auth.role == 'Admin' || auth.role == 'Operator';

    if (!canEdit) {
      return AlertDialog(
        title: const Text('Game Settings'),
        content: const Text('You do not have permission to edit game settings.'),
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
        width: EbsSpacing.modalWidthMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -- Title --
            Container(
              padding: const EdgeInsets.fromLTRB(
                EbsSpacing.md, EbsSpacing.md, EbsSpacing.sm, 0,
              ),
              child: Row(
                children: [
                  const Text('Game Settings', style: EbsTypography.modalTitle),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),

            // -- Tabs --
            TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface,
              indicatorColor: cs.primary,
              tabs: const [
                Tab(text: 'Game'),
                Tab(text: 'Blinds'),
                Tab(text: 'Rules'),
              ],
            ),

            // -- Tab content --
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _GameTab(
                    gameType: _gameType,
                    betStructure: _betStructure,
                    blindStructureId: _blindStructureId,
                    isIdle: isIdle,
                    onGameTypeChanged: (v) =>
                        setState(() => _gameType = v),
                    onBetStructureChanged: (v) =>
                        setState(() => _betStructure = v),
                    onBlindStructureIdChanged: (v) =>
                        setState(() => _blindStructureId = v),
                  ),
                  _BlindsTab(
                    anteOverride: _anteOverride,
                    straddleSeats: _straddleSeats,
                    isIdle: isIdle,
                    onAnteChanged: (v) =>
                        setState(() => _anteOverride = v),
                    onStraddleToggled: (seat) => setState(() {
                      if (_straddleSeats.contains(seat)) {
                        _straddleSeats.remove(seat);
                      } else {
                        _straddleSeats.add(seat);
                      }
                    }),
                  ),
                  _RulesTab(
                    runItMultiple: _runItMultiple,
                    capBbMultiplier: _capBbMultiplier,
                    onRunItMultipleChanged: (v) =>
                        setState(() => _runItMultiple = v),
                    onCapBbChanged: (v) =>
                        setState(() => _capBbMultiplier = v),
                  ),
                ],
              ),
            ),

            // -- Actions --
            Container(
              padding: const EdgeInsets.all(EbsSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
    );
  }

  void _handleSave() {
    final notifier = ref.read(configProvider.notifier);
    notifier.updateFromServer(
      ref.read(configProvider).copyWith(
            gameType: _gameType,
            betStructure: _betStructure,
            blindStructureId: _blindStructureId,
            ante: _anteOverride,
            straddleSeats: _straddleSeats,
          ),
    );
    Navigator.of(context).pop(true);
  }
}

// =============================================================================
// Tab 1: Game
// =============================================================================

class _GameTab extends StatelessWidget {
  const _GameTab({
    required this.gameType,
    required this.betStructure,
    required this.blindStructureId,
    required this.isIdle,
    required this.onGameTypeChanged,
    required this.onBetStructureChanged,
    required this.onBlindStructureIdChanged,
  });

  final GameType gameType;
  final BetStructure betStructure;
  final String? blindStructureId;
  final bool isIdle;
  final ValueChanged<GameType> onGameTypeChanged;
  final ValueChanged<BetStructure> onBetStructureChanged;
  final ValueChanged<String?> onBlindStructureIdChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EbsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game type
          _IdleOnlyField(
            label: 'Game Type',
            isIdle: isIdle,
            child: DropdownButtonFormField<GameType>(
              value: gameType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: GameType.values.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(_gameTypeLabel(g)),
                );
              }).toList(),
              onChanged: isIdle ? (v) => onGameTypeChanged(v!) : null,
            ),
          ),

          const SizedBox(height: EbsSpacing.md),

          // Bet structure (always part of game type selection)
          _IdleOnlyField(
            label: 'Bet Structure',
            isIdle: isIdle,
            child: DropdownButtonFormField<BetStructure>(
              value: betStructure,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: BetStructure.values.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(_betStructureLabel(b)),
                );
              }).toList(),
              onChanged: isIdle ? (v) => onBetStructureChanged(v!) : null,
            ),
          ),

          const SizedBox(height: EbsSpacing.md),

          // Blind structure ID (tournament only)
          _IdleOnlyField(
            label: 'Blind Structure ID',
            isIdle: isIdle,
            child: TextFormField(
              initialValue: blindStructureId ?? '',
              enabled: isIdle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Leave empty for cash game',
              ),
              onChanged: (v) =>
                  onBlindStructureIdChanged(v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  static String _gameTypeLabel(GameType g) => switch (g) {
        GameType.holdem => "Hold'em",
        GameType.omaha => 'Omaha',
        GameType.omahaHiLo => 'Omaha Hi/Lo',
        GameType.stud => '7-Card Stud',
        GameType.studHiLo => 'Stud Hi/Lo',
        GameType.razz => 'Razz',
        GameType.drawTriple => 'Triple Draw',
        GameType.drawSingle => 'Single Draw',
        GameType.drawBadugi => 'Badugi',
        GameType.shortDeck => 'Short Deck',
      };

  static String _betStructureLabel(BetStructure b) => switch (b) {
        BetStructure.noLimit => 'No Limit',
        BetStructure.potLimit => 'Pot Limit',
        BetStructure.fixedLimit => 'Fixed Limit',
      };
}

// =============================================================================
// Tab 2: Blinds
// =============================================================================

class _BlindsTab extends StatelessWidget {
  const _BlindsTab({
    required this.anteOverride,
    required this.straddleSeats,
    required this.isIdle,
    required this.onAnteChanged,
    required this.onStraddleToggled,
  });

  final int anteOverride;
  final List<int> straddleSeats;
  final bool isIdle;
  final ValueChanged<int> onAnteChanged;
  final ValueChanged<int> onStraddleToggled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EbsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ante override
          _IdleOnlyField(
            label: 'Ante Override',
            isIdle: isIdle,
            child: TextFormField(
              initialValue: '$anteOverride',
              enabled: isIdle,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '0 = no ante',
              ),
              onChanged: (v) => onAnteChanged(int.tryParse(v) ?? 0),
            ),
          ),

          const SizedBox(height: EbsSpacing.md),

          // Straddle seats (always editable)
          Text(
            'Straddle Enabled Seats',
            style: EbsTypography.playerName.copyWith(fontSize: 13),
          ),
          const SizedBox(height: EbsSpacing.xs),
          Wrap(
            spacing: EbsSpacing.xs,
            runSpacing: EbsSpacing.xs,
            children: List.generate(10, (i) {
              final seat = i + 1;
              final isSelected = straddleSeats.contains(seat);
              return FilterChip(
                label: Text('S$seat'),
                selected: isSelected,
                onSelected: (_) => onStraddleToggled(seat),
                selectedColor:
                    Theme.of(context).colorScheme.primary.withAlpha(60),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 3: Rules
// =============================================================================

class _RulesTab extends StatelessWidget {
  const _RulesTab({
    required this.runItMultiple,
    required this.capBbMultiplier,
    required this.onRunItMultipleChanged,
    required this.onCapBbChanged,
  });

  final bool runItMultiple;
  final int capBbMultiplier;
  final ValueChanged<bool> onRunItMultipleChanged;
  final ValueChanged<int> onCapBbChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EbsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Run it twice (always editable)
          SwitchListTile(
            title: const Text('Allow Run It Twice'),
            subtitle: const Text('Players may request multiple run-outs'),
            value: runItMultiple,
            onChanged: onRunItMultipleChanged,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: EbsSpacing.md),

          // Cap BB multiplier (always editable)
          Text(
            'Cap BB Multiplier',
            style: EbsTypography.playerName.copyWith(fontSize: 13),
          ),
          const SizedBox(height: EbsSpacing.xs),
          TextFormField(
            initialValue: '$capBbMultiplier',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: '0 = no cap',
              suffixText: 'x BB',
            ),
            onChanged: (v) => onCapBbChanged(int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: EbsSpacing.xs),
          Text(
            'Maximum bet size as a multiple of the big blind. 0 disables the cap.',
            style: EbsTypography.infoBar.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// IDLE-only field wrapper
// =============================================================================

class _IdleOnlyField extends StatelessWidget {
  const _IdleOnlyField({
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
