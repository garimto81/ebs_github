// AT-01 Main screen (BS-05-00 §AT screen catalogue, CCR-028).
//
// Composed of 7 Zones (Miller's Law 7+-2):
//   M-01 Toolbar, M-02 Info Bar, M-03 Seat Labels (top row),
//   M-04 Board Area (center), M-05 Seat Labels (bottom row),
//   M-06 Community Cards, M-07 Action Panel.
//
// Layout: Column [Toolbar(48) | InfoBar(40) | SeatArea(expand) | ActionPanel(120)]

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../data/remote/ws_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../resources/constants.dart';
import '../../../routing/app_router.dart';
import '../providers/action_button_provider.dart';
import '../providers/config_provider.dart';
import '../providers/hand_display_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/seat_provider.dart';
import '../providers/table_state_provider.dart';
import '../providers/undo_provider.dart';
import '../services/undo_stack.dart';
import '../../../rfid/providers/rfid_reader_provider.dart';
import '../providers/card_input_provider.dart';
import '../widgets/seat_cell.dart';
import '../demo/scenario_runner.dart';
import '../providers/demo_provider.dart';
import '../widgets/demo_control_panel.dart';
import 'at_03_card_selector.dart';
import 'at_06_game_settings_modal.dart';

// ---------------------------------------------------------------------------
// AT-01 Main Screen
// ---------------------------------------------------------------------------

class At01MainScreen extends ConsumerStatefulWidget {
  const At01MainScreen({super.key});

  @override
  ConsumerState<At01MainScreen> createState() => _At01MainScreenState();
}

class _At01MainScreenState extends ConsumerState<At01MainScreen> {
  late final FocusNode _focusNode;
  bool _isFallbackModalOpen = false;
  ScenarioRunner? _scenarioRunner;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Warm up keyboard handler and request focus after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(keyboardShortcutProvider); // initialise singleton
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consume keyboard-triggered actions from KeyboardShortcutHandler.
    ref.listen<CcAction?>(lastKeyboardActionProvider, (_, action) {
      if (action == null) return;
      _dispatchAction(ref, action);
      clearLastKeyboardAction(ref);
    });

    // Manual_Card_Input.md §6.4.1 — auto-open AT-03 on FALLBACK transition.
    ref.listen<CardInputState>(cardInputProvider, (prev, next) {
      _maybeOpenFallbackModal(prev, next);
    });

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final handler = ref.read(keyboardShortcutProvider);
        final consumed = handler.handleKeyEvent(event);
        return consumed ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: Scaffold(
        body: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: AppConstants.minWindowWidthPx.toDouble(),
          ),
          child: Column(
            children: [
              const _Toolbar(),
              const _RfidStatusBanner(),
              if (ref.watch(demoProvider).isActive)
                DemoControlPanel(
                  runner: _scenarioRunner ??= ScenarioRunner(
                    ProviderScope.containerOf(context),
                  ),
                ),
              const _InfoBar(),
              const Expanded(
                child: _SeatArea(),
              ),
              _ActionPanel(
                onAction: (action, {amount}) =>
                    _dispatchAction(ref, action, amount: amount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Manual_Card_Input.md §6.4.1 — auto-open AT-03 on FALLBACK transition.
  Future<void> _maybeOpenFallbackModal(
    CardInputState? prev,
    CardInputState next,
  ) async {
    if (_isFallbackModalOpen) return;
    if (next.mode != CardInputMode.cardInput) return;
    final seatNo = next.targetSeatNo;
    if (seatNo == null) return;

    final newlyFallbackIdx = _firstNewlyFallback(prev, next);
    if (newlyFallbackIdx == null) return;

    _isFallbackModalOpen = true;
    try {
      final result = await showCardSelectorModal(
        context,
        targetSeatNo: seatNo,
        targetSlotIndex: newlyFallbackIdx,
        usedCards: next.dealtCards,
      );
      if (result == null) return; // ESC / Cancel keeps slot in FALLBACK.
      ref.read(cardInputProvider.notifier).manualSelect(
            newlyFallbackIdx,
            result.$1,
            result.$2,
          );
    } finally {
      _isFallbackModalOpen = false;
    }
  }

  int? _firstNewlyFallback(CardInputState? prev, CardInputState next) {
    for (var i = 0; i < next.slots.length; i++) {
      final isFallback = next.slots[i].status == CardSlotStatus.fallback;
      final wasFallback = prev != null &&
          i < prev.slots.length &&
          prev.slots[i].status == CardSlotStatus.fallback;
      if (isFallback && !wasFallback) return i;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Action dispatch — HandFSM + WebSocket + UndoStack (BS-05-02, CCR-021)
// ---------------------------------------------------------------------------

/// Executes a CC action: guard check → HandFsm transition → WS send → UndoStack.
///
/// Called by both UI button taps (_ActionPanel.onAction) and keyboard
/// shortcuts (ref.listen on lastKeyboardActionProvider).
void _dispatchAction(WidgetRef ref, CcAction action, {int? amount}) {
  // Guard: reject if this action is currently disabled by the FSM matrix.
  if (!ref.read(actionButtonProvider).isEnabled(action)) return;

  final handFsm = ref.read(handFsmProvider.notifier);
  final ws = ref.read(boWsClientProvider);
  final undo = ref.read(undoStackProvider.notifier);
  final seats = ref.read(seatsProvider);
  final config = ref.read(configProvider);
  final launchConfig = ref.read(launchConfigProvider);

  // Seat that currently has action_on (used for player-action commands).
  final actionSeat = seats.where((s) => s.actionOn).firstOrNull;

  switch (action) {
    // ------------------------------------------------------------------
    // NEW HAND — idle|handComplete → setupHand + WriteGameInfo (24 fields)
    // ------------------------------------------------------------------
    case CcAction.newHand:
      final activePlayers = seats.where((s) => s.isOccupied).length;
      final dealerSet = seats.any((s) => s.isDealer);
      if (!handFsm.canStartHand(
          activePlayers: activePlayers, dealerSet: dealerSet)) {
        return;
      }
      handFsm.startHand();
      ws?.sendCommand('WriteGameInfo', {
        'table_id': config.tableNumber,
        'game_type': config.gameType.name,
        'bet_structure': config.betStructure.name,
        'small_blind': config.smallBlind,
        'big_blind': config.bigBlind,
        'ante': config.ante,
        'big_blind_ante': config.bigBlindAnte,
        'straddle_seats': config.straddleSeats,
        'blind_structure_id': config.blindStructureId,
        'time_bank_seconds': config.timeBankSeconds,
        'shot_clock_seconds': config.shotClockSeconds,
        'max_buy_in': config.maxBuyIn,
        'min_buy_in': config.minBuyIn,
        'table_name': config.tableName,
        'table_number': config.tableNumber,
        'seat_count': seats.length,
        'active_seats': activePlayers,
        'dealer_seat': seats.where((s) => s.isDealer).firstOrNull?.seatNo,
        'cc_instance_id': launchConfig?.ccInstanceId,
        'players': seats
            .where((s) => s.isOccupied)
            .map((s) => {
                  'seat_no': s.seatNo,
                  'player_id': s.player?.id,
                  'name': s.player?.name,
                  'stack': s.player?.stack,
                })
            .toList(),
        'is_tournament': config.isTournament,
        'timestamp': DateTime.now().toIso8601String(),
      });

    // ------------------------------------------------------------------
    // DEAL — setupHand → preFlop + DealCards
    // ------------------------------------------------------------------
    case CcAction.deal:
      if (!handFsm.canDeal) return;
      handFsm.deal();
      ws?.sendCommand('DealCards', {'table_id': config.tableNumber});

    // ------------------------------------------------------------------
    // FOLD — ActionPerformed + UndoStack push
    // ------------------------------------------------------------------
    case CcAction.fold:
      ws?.sendCommand('ActionPerformed', {
        'table_id': config.tableNumber,
        'action': 'fold',
        'seat_no': actionSeat?.seatNo,
        'amount': 0,
      });
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': 'fold', 'seat_no': actionSeat?.seatNo},
        timestamp: DateTime.now(),
        description: 'Fold – S${actionSeat?.seatNo ?? '?'}',
      ));

    // ------------------------------------------------------------------
    // CHECK / CALL — ActionPerformed + UndoStack push
    // ------------------------------------------------------------------
    case CcAction.checkCall:
      final label = ref.read(actionButtonProvider).checkCallLabel;
      ws?.sendCommand('ActionPerformed', {
        'table_id': config.tableNumber,
        'action': 'check_call',
        'seat_no': actionSeat?.seatNo,
        'amount': amount ?? 0,
      });
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {
          'action': 'check_call',
          'seat_no': actionSeat?.seatNo,
          'amount': amount ?? 0,
        },
        timestamp: DateTime.now(),
        description: '$label – S${actionSeat?.seatNo ?? '?'}',
      ));

    // ------------------------------------------------------------------
    // BET / RAISE — ActionPerformed + UndoStack push
    // ------------------------------------------------------------------
    case CcAction.betRaise:
      final label = ref.read(actionButtonProvider).betRaiseLabel;
      ws?.sendCommand('ActionPerformed', {
        'table_id': config.tableNumber,
        'action': 'bet_raise',
        'seat_no': actionSeat?.seatNo,
        'amount': amount ?? 0,
      });
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {
          'action': 'bet_raise',
          'seat_no': actionSeat?.seatNo,
          'amount': amount ?? 0,
        },
        timestamp: DateTime.now(),
        description: '$label ${amount ?? 0} – S${actionSeat?.seatNo ?? '?'}',
      ));

    // ------------------------------------------------------------------
    // ALL-IN — ActionPerformed (full stack) + UndoStack push
    // ------------------------------------------------------------------
    case CcAction.allIn:
      final stack = actionSeat?.player?.stack ?? 0;
      ws?.sendCommand('ActionPerformed', {
        'table_id': config.tableNumber,
        'action': 'all_in',
        'seat_no': actionSeat?.seatNo,
        'amount': stack,
      });
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': 'all_in', 'seat_no': actionSeat?.seatNo, 'amount': stack},
        timestamp: DateTime.now(),
        description: 'All-In $stack – S${actionSeat?.seatNo ?? '?'}',
      ));

    // ------------------------------------------------------------------
    // UNDO — pop UndoStack + UndoAction WS command
    // ------------------------------------------------------------------
    case CcAction.undo:
      final event = undo.undo();
      if (event != null) {
        ws?.sendCommand('UndoAction', {
          'table_id': config.tableNumber,
          'event_type': event.eventType,
          'payload': event.payload,
        });
      }

    // ------------------------------------------------------------------
    // MISS DEAL — void hand → force idle + clear undo stack
    // ------------------------------------------------------------------
    case CcAction.missDeal:
      handFsm.forceState(HandFsm.idle);
      undo.clearOnHandComplete();
      ws?.sendCommand('MissDeal', {'table_id': config.tableNumber});
  }
}

// =============================================================================
// M-01: Toolbar (48px)
// =============================================================================

class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final handFsm = ref.watch(handFsmProvider);
    final tableFsm = ref.watch(tableStateProvider);
    final wsState = ref.watch(wsConnectionStateProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: EbsSpacing.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // -- Left: table name + number --
          Text(
            config.tableName.isEmpty
                ? 'Table #${config.tableNumber}'
                : '${config.tableName} #${config.tableNumber}',
            style: EbsTypography.toolbarTitle,
          ),

          const SizedBox(width: EbsSpacing.md),

          // -- Center: HandFSM state badge --
          _HandFsmBadge(handFsm: handFsm, tableFsm: tableFsm),

          const SizedBox(width: EbsSpacing.sm),

          // -- WS connection state indicator --
          _WsStatusDot(state: wsState),

          const Spacer(),

          // -- Right: action icons --
          _ToolbarIconButton(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Statistics (AT-04)',
            onPressed: () => _pushScreen(context, 'AT-04'),
          ),
          _ToolbarIconButton(
            icon: Icons.contactless_rounded,
            tooltip: 'RFID Register (AT-05)',
            onPressed: () => _pushScreen(context, 'AT-05'),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: cs.onSurface),
            tooltip: 'Menu',
            onSelected: (value) => _handleMenu(context, value, ref),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'game_settings',
                child: Text('Game Settings'),
              ),
              const PopupMenuItem(
                value: 'undo_history',
                child: Text('Undo History'),
              ),
              const PopupMenuItem(
                value: 'miss_deal',
                child: Text('Miss Deal'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'demo_toggle',
                child: Text(
                  ref.read(demoProvider).isActive
                      ? 'Demo Mode OFF'
                      : 'Demo Mode ON',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pushScreen(BuildContext context, String screenId) {
    switch (screenId) {
      case 'AT-04':
        context.push(AppRoutes.stats);
      case 'AT-05':
        context.push(AppRoutes.rfid);
      default:
        debugPrint('Unknown screen: $screenId');
    }
  }

  void _handleMenu(BuildContext context, String value, WidgetRef ref) {
    switch (value) {
      case 'game_settings':
        // ignore: discarded_futures
        showGameSettingsModal(context);
      case 'undo_history':
        debugPrint('Undo History — handled by ActionPanel UI');
      case 'miss_deal':
        debugPrint('Miss Deal — use ACT panel button');
      case 'demo_toggle':
        final notifier = ref.read(demoProvider.notifier);
        if (ref.read(demoProvider).isActive) {
          notifier.deactivate();
        } else {
          notifier.activate();
        }
      default:
        debugPrint('Unknown menu: $value');
    }
  }
}

// =============================================================================
// _RfidStatusBanner — Manual_Fallback.md §5.6
// =============================================================================

class _RfidStatusBanner extends ConsumerWidget {
  const _RfidStatusBanner();

  static const _heightPx = 36.0;
  static const _animMs = 200;
  static const Color _infoBg = Color(0xFF1976D2);
  static const Color _warnBg = Color(0xFFF57C00);
  static const Color _errorBg = Color(0xFFE53935);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(rfidNotificationProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: _animMs),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: -1,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: notification == null
          ? const SizedBox.shrink()
          : _BannerBody(notification: notification),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({required this.notification});

  final RfidNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _bg(notification);
    final icon = _icon(notification);
    return Container(
      key: ValueKey(notification.message),
      height: _RfidStatusBanner._heightPx,
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: EbsSpacing.sm),
          Expanded(
            child: Text(
              notification.message,
              style: EbsTypography.toolbarTitle.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _bg(RfidNotification n) {
    if (n.isError) return _RfidStatusBanner._errorBg;
    // info vs warn distinguished by message prefix per §5.6.
    if (n.message.startsWith('RFID 재연결')) {
      return _RfidStatusBanner._warnBg;
    }
    return _RfidStatusBanner._infoBg;
  }

  IconData _icon(RfidNotification n) {
    if (n.isError) return Icons.error_outline;
    if (n.message.startsWith('RFID 재연결')) return Icons.warning_amber;
    return Icons.wifi_tethering;
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}

// =============================================================================
// WS connection state dot
// =============================================================================

class _WsStatusDot extends StatelessWidget {
  const _WsStatusDot({required this.state});

  final WsConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      WsConnectionState.connected    => (const Color(0xFF66BB6A), 'WS'),
      WsConnectionState.connecting   => (const Color(0xFFFFA726), 'WS'),
      WsConnectionState.reconnecting => (const Color(0xFFFFA726), 'WS'),
      WsConnectionState.failed       => (const Color(0xFFEF5350), 'WS'),
      WsConnectionState.disconnected => (const Color(0xFF9E9E9E), 'WS'),
    };
    return Tooltip(
      message: state.name,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(label, style: EbsTypography.infoBar.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// =============================================================================
// HandFSM badge — color-coded state indicator
// =============================================================================

class _HandFsmBadge extends StatelessWidget {
  const _HandFsmBadge({required this.handFsm, required this.tableFsm});

  final HandFsm handFsm;
  final dynamic tableFsm;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(handFsm);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.sm,
        vertical: EbsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: EbsTypography.infoBar.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static (String, Color) _resolve(HandFsm fsm) {
    return switch (fsm) {
      HandFsm.idle         => ('IDLE', const Color(0xFF9E9E9E)),
      HandFsm.setupHand    => ('SETUP', const Color(0xFFFFA726)),
      HandFsm.preFlop      => ('PRE-FLOP', const Color(0xFF42A5F5)),
      HandFsm.flop         => ('FLOP', const Color(0xFF66BB6A)),
      HandFsm.turn         => ('TURN', const Color(0xFFAB47BC)),
      HandFsm.river        => ('RIVER', const Color(0xFFEF5350)),
      HandFsm.showdown     => ('SHOWDOWN', const Color(0xFFFDD835)),
      HandFsm.handComplete => ('COMPLETE', const Color(0xFF78909C)),
      HandFsm.runItMultiple => ('RUN IT', const Color(0xFFFF7043)),
    };
  }
}

// ---------------------------------------------------------------------------
// Number formatting (no intl dependency)
// ---------------------------------------------------------------------------

/// Format integer with comma separators (e.g., 1234567 -> "1,234,567").
String _fmtNum(int value) {
  if (value < 0) return '-${_fmtNum(-value)}';
  if (value < 1000) return value.toString();
  final s = value.toString();
  final buf = StringBuffer();
  final remainder = s.length % 3;
  if (remainder > 0) buf.write(s.substring(0, remainder));
  for (var i = remainder; i < s.length; i += 3) {
    if (buf.isNotEmpty) buf.write(',');
    buf.write(s.substring(i, i + 3));
  }
  return buf.toString();
}

// =============================================================================
// M-02: Info Bar (40px)
// =============================================================================

class _InfoBar extends ConsumerWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final handNum = ref.watch(handNumberProvider);
    final pot = ref.watch(potTotalProvider);
    final cs = Theme.of(context).colorScheme;

    final blindsText = config.ante > 0
        ? 'Blinds: ${_fmtNum(config.smallBlind)}'
            '/${_fmtNum(config.bigBlind)}'
            ' (ante ${_fmtNum(config.ante)})'
        : 'Blinds: ${_fmtNum(config.smallBlind)}'
            '/${_fmtNum(config.bigBlind)}';

    return Container(
      height: EbsSpacing.infoBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _InfoChip(label: blindsText),
          const _InfoDivider(),
          _InfoChip(label: 'Pot: ${_fmtNum(pot)}'),
          const _InfoDivider(),
          _InfoChip(label: 'Hand #$handNum'),
          const _InfoDivider(),
          _InfoChip(label: config.displayLabel),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: EbsTypography.infoBar);
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.sm),
      child: Text(
        '|',
        style: EbsTypography.infoBar.copyWith(
          color: Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

// =============================================================================
// M-03~M-06: Seat Area (Expanded) — oval 10-seat layout + board center
// =============================================================================

class _SeatArea extends ConsumerWidget {
  const _SeatArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(seatsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Oval parameters
        final cx = w / 2;
        final cy = h / 2;
        final rx = w * 0.42; // horizontal radius
        final ry = h * 0.40; // vertical radius

        final seatPositions = _computeSeatPositions(cx, cy, rx, ry);

        return Stack(
          children: [
            // Board area (center)
            Positioned(
              left: cx - 175,
              top: cy - 50,
              child: const _BoardArea(),
            ),

            // Dealer button indicator at center-bottom
            Positioned(
              left: cx - 12,
              top: cy + 55,
              child: _DealerIndicator(seats: seats),
            ),

            // 10 seat cells
            for (int i = 0; i < 10; i++)
              Positioned(
                left: seatPositions[i].dx - EbsSpacing.seatCellWidth / 2,
                top: seatPositions[i].dy - EbsSpacing.seatCellHeight / 2,
                child: SeatCell(seatIndex: i + 1),
              ),
          ],
        );
      },
    );
  }

  /// Compute 10 seat positions around an oval.
  /// Seats 1-10 clockwise from bottom-right.
  List<Offset> _computeSeatPositions(
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    // 10 seats around full 360° oval, clockwise from bottom-center (dealer).
    // Seat 1 = bottom-center-right, Seat 6 = top-center-left.
    // Start at π/2 (bottom), go clockwise (subtract angle).
    return List.generate(10, (i) {
      final angle = math.pi / 2 - (2 * math.pi * i / 10);
      return Offset(
        cx + rx * math.cos(angle),
        cy - ry * math.sin(angle),
      );
    });
  }

}

// ---------------------------------------------------------------------------
// Dealer button indicator
// ---------------------------------------------------------------------------

class _DealerIndicator extends StatelessWidget {
  const _DealerIndicator({required this.seats});

  final List<SeatState> seats;

  @override
  Widget build(BuildContext context) {
    final dealerSeat = seats.where((s) => s.isDealer).firstOrNull;
    if (dealerSeat == null) return const SizedBox.shrink();

    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFFDD835),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'D',
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// =============================================================================
// M-06: Board Area (community cards)
// =============================================================================

class _BoardArea extends ConsumerWidget {
  const _BoardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(boardCardsProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 350,
      height: 100,
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final hasCard = i < cards.length && cards[i].isNotEmpty;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.xs),
            child: _CardSlot(
              label: hasCard ? cards[i] : '',
              revealed: hasCard,
            ),
          );
        }),
      ),
    );
  }
}

class _CardSlot extends StatelessWidget {
  const _CardSlot({required this.label, required this.revealed});

  final String label;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: AppConstants.cardCellWidth,
      height: AppConstants.cardCellHeight,
      decoration: BoxDecoration(
        color: revealed ? Colors.white : const Color(0xFF2A2A40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: revealed ? cs.primary : Theme.of(context).dividerColor,
        ),
      ),
      alignment: Alignment.center,
      child: revealed
          ? Text(
              label,
              style: EbsTypography.cardLabel.copyWith(color: Colors.black),
            )
          : Icon(
              Icons.style_rounded,
              color: cs.onSurface.withAlpha(60),
              size: 20,
            ),
    );
  }
}

// =============================================================================
// M-07: Action Panel (120px)
// =============================================================================

class _ActionPanel extends ConsumerWidget {
  const _ActionPanel({required this.onAction});

  final void Function(CcAction, {int? amount}) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btnState = ref.watch(actionButtonProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: EbsSpacing.actionPanelHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.md,
        vertical: EbsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            label: 'NEW HAND',
            enabled: btnState.isEnabled(CcAction.newHand),
            color: const Color(0xFF66BB6A),
            onPressed: btnState.isEnabled(CcAction.newHand)
                ? () => onAction(CcAction.newHand)
                : null,
          ),
          _ActionButton(
            label: 'DEAL',
            enabled: btnState.isEnabled(CcAction.deal),
            color: const Color(0xFF42A5F5),
            onPressed: btnState.isEnabled(CcAction.deal)
                ? () => onAction(CcAction.deal)
                : null,
          ),
          _ActionButton(
            label: 'FOLD',
            enabled: btnState.isEnabled(CcAction.fold),
            color: cs.error,
            onPressed: btnState.isEnabled(CcAction.fold)
                ? () => onAction(CcAction.fold)
                : null,
          ),
          _ActionButton(
            label: btnState.checkCallLabel,
            enabled: btnState.isEnabled(CcAction.checkCall),
            color: const Color(0xFF78909C),
            onPressed: btnState.isEnabled(CcAction.checkCall)
                ? () => onAction(CcAction.checkCall)
                : null,
          ),
          _ActionButton(
            label: btnState.betRaiseLabel,
            enabled: btnState.isEnabled(CcAction.betRaise),
            color: const Color(0xFFFFA726),
            onPressed: btnState.isEnabled(CcAction.betRaise)
                ? () => onAction(CcAction.betRaise)
                : null,
          ),
          _ActionButton(
            label: 'ALL-IN',
            enabled: btnState.isEnabled(CcAction.allIn),
            color: const Color(0xFFEF5350),
            onPressed: btnState.isEnabled(CcAction.allIn)
                ? () => onAction(CcAction.allIn)
                : null,
          ),
          _ActionButton(
            label: 'UNDO',
            enabled: btnState.isEnabled(CcAction.undo),
            color: const Color(0xFF9E9E9E),
            onPressed: btnState.isEnabled(CcAction.undo)
                ? () => onAction(CcAction.undo)
                : null,
          ),
          _ActionButton(
            label: 'MISS DEAL',
            enabled: btnState.isEnabled(CcAction.missDeal),
            color: const Color(0xFF9E9E9E),
            onPressed: btnState.isEnabled(CcAction.missDeal)
                ? () => onAction(CcAction.missDeal)
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.color,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.xs),
        child: SizedBox(
          height: EbsSpacing.actionButtonHeight,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? color : color.withAlpha(40),
              foregroundColor: enabled ? Colors.white : Colors.white38,
              minimumSize: const Size(EbsSpacing.actionButtonMinWidth,
                  EbsSpacing.actionButtonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: EbsTypography.actionButton),
            ),
          ),
        ),
      ),
    );
  }
}

