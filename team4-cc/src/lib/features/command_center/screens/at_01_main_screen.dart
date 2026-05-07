// AT-01 Main screen (BS-05-00 §AT screen catalogue, CCR-028).
//
// Composed of 7 Zones (Miller's Law 7+-2):
//   M-01 Toolbar, M-02 Info Bar, M-03 Seat Labels (top row),
//   M-04 Board Area (center), M-05 Seat Labels (bottom row),
//   M-06 Community Cards, M-07 Action Panel.
//
// Layout: Column [Toolbar(48) | InfoBar(40) | SeatArea(expand) | ActionPanel(120)]

import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app.dart';
import '../../../data/remote/ws_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/table_fsm.dart';
import '../../../foundation/logging/debug_log.dart';
import '../../../resources/constants.dart';
import '../../../routing/app_router.dart';
import '../../debug/debug_log_panel.dart';
import '../../debug/debug_log_provider.dart';
import '../providers/action_button_provider.dart';
import '../providers/config_provider.dart';
import '../providers/engine_provider.dart';
import '../providers/hand_display_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/seat_provider.dart';
import '../providers/table_state_provider.dart';
import '../providers/undo_provider.dart';
import '../services/engine_output_dispatcher.dart';
import '../services/undo_stack.dart';
import '../../../rfid/providers/rfid_reader_provider.dart';
import '../providers/card_input_provider.dart';
import '../widgets/cc_status_bar.dart';
import '../widgets/engine_connection_banner.dart';
import '../widgets/keyboard_hint_bar.dart';
import '../widgets/mini_table_diagram.dart';
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

      // Ensure TableFSM is LIVE on screen entry so action buttons work.
      // In production, the server sends TableFSM state via WS on connect.
      // Until that WS event arrives, auto-promote to LIVE so the operator
      // can interact immediately (BS-05-00 §2.1 Launch Flow step 6).
      final tableFsm = ref.read(tableStateProvider);
      if (tableFsm == TableFsm.empty) {
        ref.read(tableStateProvider.notifier).forceState(TableFsm.live);
      }
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
      _dispatchAction(ref, action, context: context);
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
        // Ctrl+L toggles debug log panel (global shortcut — takes precedence)
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyL &&
            HardwareKeyboard.instance.isControlPressed) {
          final notifier = ref.read(debugLogVisibleProvider.notifier);
          notifier.state = !notifier.state;
          return KeyEventResult.handled;
        }
        final handler = ref.read(keyboardShortcutProvider);
        final consumed = handler.handleKeyEvent(event);
        return consumed ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AppConstants.minWindowWidthPx.toDouble(),
              ),
              child: Column(
                children: [
                  const _Toolbar(),
                  // V2 (B-team4-011) — CcStatusBar 통합 한 줄.
                  // 현재 _Toolbar 와 공존 — 다음 turn 사용자 검토 후 _Toolbar
                  // 제거 + _InfoBar 흡수 통합 결정.
                  const CcStatusBar(),
                  const EngineConnectionBanner(),
                  const _RfidStatusBanner(),
                  if (ref.watch(demoProvider).isActive)
                    DemoControlPanel(
                      runner: _scenarioRunner ??= ScenarioRunner(
                        ProviderScope.containerOf(context),
                      ),
                    ),
                  const _InfoBar(),
                  const KeyboardHintBar(),
                  const Expanded(
                    child: _SeatArea(),
                  ),
                  _ActionPanel(
                    onAction: (action, {amount}) => _dispatchAction(ref, action,
                        amount: amount, context: context),
                  ),
                ],
              ),
            ),
            const DebugLogPanel(),
          ],
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

/// Executes a CC action (WebSocket_Events.md §9-§12).
///
/// **Online mode** (WS connected): sends typed command to BO → server responds
/// with broadcast event → ws_provider dispatcher updates local state.
///
/// **Demo/offline mode** (WS null): applies local FSM transition directly
/// via dispatchLocalDemoEvent so the UI still functions.
const _uuid = Uuid();

void _dispatchAction(WidgetRef ref, CcAction action,
    {int? amount, BuildContext? context}) {
  // §1.1.1 Body Derivation Rule — correlation_id 1 회 생성, 양 경로 주입.
  final correlationId = _uuid.v4();
  DebugLog.d('ACTION', 'dispatch requested',
      {'action': action.name, 'amount': amount, 'correlation_id': correlationId});
  if (!ref.read(actionButtonProvider).isEnabled(action)) {
    DebugLog.w('ACTION', 'BLOCKED — actionButtonProvider.isEnabled=false',
        {'action': action.name});
    return;
  }

  final handFsm = ref.read(handFsmProvider.notifier);
  final ws = ref.read(boWsClientProvider);
  final undo = ref.read(undoStackProvider.notifier);
  final seats = ref.read(seatsProvider);
  final config = ref.read(configProvider);
  final launchConfig = ref.read(launchConfigProvider);
  final handNum = ref.read(handNumberProvider);
  final engineClient = ref.read(engineClientProvider);
  final engineSessionId = ref.read(engineSessionProvider);
  final actionSeat = seats.where((s) => s.actionOn).firstOrNull;
  final seatNo = actionSeat?.seatNo ?? 0;

  switch (action) {
    // -- NEW HAND (§9 WriteGameInfo) ------------------------------------
    case CcAction.newHand:
      final activePlayers = seats.where((s) => s.isOccupied).length;
      final dealerSet = seats.any((s) => s.isDealer);
      final fsmState = ref.read(handFsmProvider);
      DebugLog.i('NEW_HAND', 'pre-check', {
        'activePlayers': activePlayers,
        'dealerSet': dealerSet,
        'fsmState': fsmState.name,
        'ws': ws == null ? 'offline' : 'connected',
      });
      if (!handFsm.canStartHand(
          activePlayers: activePlayers, dealerSet: dealerSet)) {
        final reason = activePlayers < 2
            ? '좌석 2명 이상 착석 필요 (현재 $activePlayers명)'
            : !dealerSet
                ? '딜러 미지정 — 좌석 착석 시 자동 배정 (§2.3.1). 변경은 BTN 뱃지 클릭'
                : 'FSM 상태 오류 (idle/handComplete 아님: ${fsmState.name})';
        DebugLog.w('NEW_HAND', 'canStartHand=false — aborted', {'reason': reason});
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NEW HAND 불가 — $reason'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Debug Log',
                textColor: Colors.white,
                onPressed: () => ref
                    .read(debugLogVisibleProvider.notifier)
                    .state = true,
              ),
            ),
          );
        }
        return;
      }
      final dealerSeat =
          seats.where((s) => s.isDealer).firstOrNull?.seatNo ?? 1;

      // §1.1.1 Engine primary — createSession (auto HandStart + holecards).
      final occupied = seats.where((s) => s.isOccupied).toList();
      final engineFuture = () async {
        try {
          final variant = _gameTypeToVariant(config.gameType.name);
          DebugLog.i('ENGINE_DISPATCH', 'createSession', {
            'correlation_id': correlationId,
            'variant': variant,
            'seatCount': occupied.length,
          });
          final sessionId = await engineClient.createSession(
            variant: variant,
            seatCount: occupied.length,
            stacks: occupied.map((s) => s.player?.stack ?? 1000).toList(),
            blinds: {'sb': config.smallBlind, 'bb': config.bigBlind},
            dealerSeat: dealerSeat - 1, // 1-based → 0-based
          );
          ref.read(engineSessionProvider.notifier).state = sessionId;
          DebugLog.i('ENGINE_RESPONSE', 'session created',
              {'correlation_id': correlationId, 'sessionId': sessionId});
          // Initial state fetch → full-state snapshot dispatch.
          final state = await engineClient.getState(sessionId);
          EngineOutputDispatcher.dispatchState(ref, state,
              correlationId: correlationId);
        } catch (e) {
          DebugLog.e('ENGINE_DISPATCH', 'createSession failed',
              {'correlation_id': correlationId, 'error': e.toString()});
          // fallback: local FSM transition
          handFsm.startHand();
        }
      }();

      // §1.1.1 BO secondary — WriteGameInfo (audit + Lobby broadcast).
      if (ws != null) {
        DebugLog.i('BO_DISPATCH', 'WriteGameInfo',
            {'correlation_id': correlationId, 'table_id': config.tableNumber});
        ws.sendCommand('WriteGameInfo', {
          'correlation_id': correlationId,
          'table_id': config.tableNumber,
          'dealer_seat': dealerSeat,
          'sb_seat': _nextOccupied(seats, dealerSeat),
          'bb_seat': _nextOccupied(seats, _nextOccupied(seats, dealerSeat)),
          'sb_amount': config.smallBlind,
          'bb_amount': config.bigBlind,
          'ante_amount': config.ante,
          'big_blind_ante': config.bigBlindAnte,
          'straddle_seats': config.straddleSeats,
          'blind_structure_id': config.blindStructureId,
          'game_type': config.gameType.name,
          'active_seats': occupied.map((s) => s.seatNo).toList(),
        });
      } else {
        DebugLog.w('BO_DISPATCH', 'WS offline — BO audit skipped',
            {'correlation_id': correlationId});
      }

      // fire-and-forget Engine future; avoid blocking UI.
      unawaited(engineFuture);

    // -- DEAL (§11 WriteDeal, §1.1.1 Matrix — Engine skip) --------------
    // createSession (NEW HAND) 시점에 이미 PRE_FLOP + holecards 배분 완료.
    // DEAL 은 CC UI 공개 타이밍 마킹 + BO audit only.
    case CcAction.deal:
      if (!handFsm.canDeal) return;
      DebugLog.i('DEAL', 'UI marking + BO audit only (Engine skipped)',
          {'correlation_id': correlationId, 'hand_id': handNum});
      if (ws != null) {
        ws.sendDeal(handId: handNum);
      }
      handFsm.deal(); // UI 타이밍 마킹 — PRE_FLOP 전이

    // -- FOLD (§10 WriteAction) -----------------------------------------
    case CcAction.fold:
      _dispatchEngineAction(ref, engineClient, engineSessionId,
          'fold', seatNo, 0, correlationId);
      if (ws != null) {
        ws.sendAction(
            handId: handNum, seat: seatNo, actionType: 'fold');
      }
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': 'fold', 'seat': seatNo},
        timestamp: DateTime.now(),
        description: 'Fold – S$seatNo',
      ));

    // -- CHECK / CALL (§10 WriteAction) ---------------------------------
    case CcAction.checkCall:
      final label = ref.read(actionButtonProvider).checkCallLabel;
      final actionType = label == 'CALL' ? 'call' : 'check';
      _dispatchEngineAction(ref, engineClient, engineSessionId,
          actionType, seatNo, amount ?? 0, correlationId);
      if (ws != null) {
        ws.sendAction(
            handId: handNum,
            seat: seatNo,
            actionType: actionType,
            amount: amount ?? 0);
      }
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': actionType, 'seat': seatNo, 'amount': amount ?? 0},
        timestamp: DateTime.now(),
        description: '$label – S$seatNo',
      ));

    // -- BET / RAISE (§10 WriteAction) ----------------------------------
    case CcAction.betRaise:
      final label = ref.read(actionButtonProvider).betRaiseLabel;
      final actionType = label == 'RAISE' ? 'raise' : 'bet';
      _dispatchEngineAction(ref, engineClient, engineSessionId,
          actionType, seatNo, amount ?? 0, correlationId);
      if (ws != null) {
        ws.sendAction(
            handId: handNum,
            seat: seatNo,
            actionType: actionType,
            amount: amount ?? 0);
      }
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': actionType, 'seat': seatNo, 'amount': amount ?? 0},
        timestamp: DateTime.now(),
        description: '$label ${amount ?? 0} – S$seatNo',
      ));

    // -- ALL-IN (§10 WriteAction) ---------------------------------------
    case CcAction.allIn:
      final stack = actionSeat?.player?.stack ?? 0;
      _dispatchEngineAction(ref, engineClient, engineSessionId,
          'allin', seatNo, stack, correlationId);
      if (ws != null) {
        ws.sendAction(
            handId: handNum,
            seat: seatNo,
            actionType: 'allin',
            amount: stack);
      }
      undo.push(UndoableEvent(
        eventType: 'ActionPerformed',
        payload: {'action': 'allin', 'seat': seatNo, 'amount': stack},
        timestamp: DateTime.now(),
        description: 'All-In $stack – S$seatNo',
      ));

    // -- UNDO -----------------------------------------------------------
    case CcAction.undo:
      final event = undo.undo();
      if (event != null) {
        // §1.1.1 Matrix — UNDO 병행 dispatch.
        if (engineSessionId != null) {
          unawaited(engineClient
              .undo(engineSessionId)
              .then((resp) {
                DebugLog.i('ENGINE_RESPONSE', 'undo ok',
                    {'correlation_id': correlationId});
                EngineOutputDispatcher.dispatchState(ref, resp,
                    correlationId: correlationId);
              })
              .catchError((e) {
                DebugLog.e('ENGINE_DISPATCH', 'undo failed',
                    {'correlation_id': correlationId, 'error': e.toString()});
              }));
        }
        ws?.sendCommand('UndoAction', {
          'correlation_id': correlationId,
          'event_type': event.eventType,
          'payload': event.payload,
        });
      }

    // -- MISS DEAL ------------------------------------------------------
    case CcAction.missDeal:
      handFsm.forceState(HandFsm.idle);
      undo.clearOnHandComplete();
      ws?.sendCommand('MissDeal', {'hand_id': handNum});
  }
}

/// Map CC GameType enum name → Engine variant string (Harness §2.1).
String _gameTypeToVariant(String gameTypeName) {
  switch (gameTypeName) {
    case 'holdem':
      return 'nlh';
    case 'omaha':
      return 'omaha';
    case 'omahaHilo':
    case 'omaha_hilo':
      return 'omaha_hilo';
    case 'shortDeck':
    case 'short_deck':
      return 'short_deck';
  }
  return 'nlh'; // default fallback
}

/// Find next occupied seat clockwise from [fromSeat].
int _nextOccupied(List<SeatState> seats, int fromSeat) {
  for (var offset = 1; offset < 10; offset++) {
    final idx = (fromSeat - 1 + offset) % 10;
    if (seats[idx].isOccupied) return seats[idx].seatNo;
  }
  return fromSeat;
}

/// §1.1.1 Engine HTTP 병행 dispatch helper — fire-and-forget + outputEvents 소비.
///
/// [seat] 은 1-based (Seat 1~10), Engine 은 0-based `seatIndex` 사용 → 변환.
/// 실패 시 debug log 만, UI 는 롤백 없음 (Engine 응답의 ActionRejected 는 후속 B-team4-007).
void _dispatchEngineAction(
  WidgetRef ref,
  dynamic engineClient,
  String? sessionId,
  String actionType,
  int seat,
  int amount,
  String correlationId,
) {
  if (sessionId == null) {
    DebugLog.w('ENGINE_DISPATCH', 'no session — skipped',
        {'correlation_id': correlationId, 'action': actionType});
    return;
  }
  final seatIndex = seat - 1; // 1-based → 0-based
  DebugLog.d('ENGINE_DISPATCH', actionType, {
    'correlation_id': correlationId,
    'sessionId': sessionId,
    'seatIndex': seatIndex,
    'amount': amount,
  });
  final future = () async {
    try {
      late Map<String, dynamic> resp;
      switch (actionType) {
        case 'fold':
          resp = await engineClient.sendFold(sessionId, seatIndex);
        case 'check':
          resp = await engineClient.sendCheck(sessionId, seatIndex);
        case 'call':
          resp = await engineClient.sendCall(sessionId, seatIndex, amount);
        case 'bet':
          resp = await engineClient.sendBet(sessionId, seatIndex, amount);
        case 'raise':
          resp = await engineClient.sendRaise(sessionId, seatIndex, amount);
        case 'allin':
          resp = await engineClient.sendAllin(sessionId, seatIndex, amount);
        default:
          DebugLog.e('ENGINE_DISPATCH', 'unknown actionType',
              {'actionType': actionType});
          return;
      }
      DebugLog.i('ENGINE_RESPONSE', '$actionType ok',
          {'correlation_id': correlationId});
      EngineOutputDispatcher.dispatchState(ref, resp,
          correlationId: correlationId);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      DebugLog.e('ENGINE_DISPATCH', '$actionType failed', {
        'correlation_id': correlationId,
        'status': status,
        'error': e.message,
      });
    } catch (e) {
      DebugLog.e('ENGINE_DISPATCH', '$actionType exception',
          {'correlation_id': correlationId, 'error': e.toString()});
    }
  }();
  unawaited(future);
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
          _ToolbarIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'Table Settings',
            onPressed: () => showGameSettingsModal(context),
          ),
          _ToolbarIconButton(
            icon: Icons.bug_report_rounded,
            tooltip: 'Toggle Debug Log (Ctrl+L)',
            onPressed: () {
              final notifier = ref.read(debugLogVisibleProvider.notifier);
              notifier.state = !notifier.state;
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: cs.onSurface),
            tooltip: 'Menu',
            onSelected: (value) => _handleMenu(context, value, ref),
            itemBuilder: (_) => [
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
    return Column(children: [
      const SizedBox(height: 140, child: _TopStrip()),
      const SizedBox(height: 8),
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (int i = 0; i < 10; i++) ...[
            Expanded(child: SeatCell(seatIndex: i + 1)),
            if (i < 9) const SizedBox(width: 4)]]))),
    ]);
  }
}

class _TopStrip extends ConsumerWidget {
  const _TopStrip();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seats = ref.watch(seatsProvider);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        const MiniTableDiagram(size: 120),
        const SizedBox(width: 16),
        const Expanded(child: Center(child: _BoardArea())),
        const SizedBox(width: 16),
        SizedBox(width: 120, child: Center(child: _DealerIndicator(seats: seats))),
      ]));
  }
}

class _SeatAreaOval_DEPRECATED extends ConsumerWidget {
  const _SeatAreaOval_DEPRECATED();
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
            // V3 (B-team4-011) — MiniTableDiagram top-left overlay.
            // R2 가드: D/SB/BB 뱃지는 본 미니맵에만 (좌석 컬럼 PositionShiftChip 와
            // 시각 분리 — 정보 중복 회피).
            const Positioned(
              left: 12,
              top: 8,
              child: MiniTableDiagram(size: 110),
            ),

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
          // V8 (B-team4-011) — Community board street labels.
          // Empty slots show "FLOP 1/2/3", "TURN", "RIVER" instead of generic icon.
          // Reference: claude-design-archive/2026-05-06/cc-react-extracted/App.jsx ts-slot-lbl.
          const streetLabels = ['FLOP 1', 'FLOP 2', 'FLOP 3', 'TURN', 'RIVER'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: EbsSpacing.xs),
            child: _CardSlot(
              label: hasCard ? cards[i] : '',
              streetLabel: streetLabels[i],
              revealed: hasCard,
            ),
          );
        }),
      ),
    );
  }
}

class _CardSlot extends StatelessWidget {
  const _CardSlot({
    required this.label,
    required this.streetLabel,
    required this.revealed,
  });

  final String label;
  final String streetLabel;
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
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style_rounded,
                  color: cs.onSurface.withAlpha(60),
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  streetLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withAlpha(140),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
    final seats = ref.watch(seatsProvider);
    final fsm = ref.watch(handFsmProvider);
    final actionSeat = seats.where((s) => s.actionOn).firstOrNull;
    final biggestBet = seats.fold<int>(0, (m, s) => s.currentBet > m ? s.currentBet : m);
    final myBet = actionSeat?.currentBet ?? 0;
    final callAmount = (biggestBet - myBet).clamp(0, 1 << 30);
    final stack = actionSeat?.player?.stack ?? 0;
    final isCall = btnState.checkCallLabel == 'CALL';
    final isRaise = btnState.betRaiseLabel == 'RAISE';
    final isIdle = fsm == HandFsm.idle || fsm == HandFsm.handComplete;
    final isShowdown = fsm == HandFsm.showdown;
    final lifecycleLabel = isIdle ? 'START HAND' : (isShowdown ? 'FINISH HAND' : 'IN PROGRESS');
    final lifecycleSub = isIdle ? 'Ready to deal' : isShowdown ? 'Tap to reset' : fsm.name.toUpperCase();

    String fmt(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Column(children: [
          Expanded(child: _ActionButton(label: 'UNDO',
            enabled: btnState.isEnabled(CcAction.undo),
            color: const Color(0xFF9E9E9E),
            onPressed: btnState.isEnabled(CcAction.undo) ? () => onAction(CcAction.undo) : null)),
          const SizedBox(height: 4),
          Expanded(child: _ActionButton(label: 'MISS DEAL',
            enabled: btnState.isEnabled(CcAction.missDeal),
            color: const Color(0xFF9E9E9E),
            onPressed: btnState.isEnabled(CcAction.missDeal) ? () => onAction(CcAction.missDeal) : null)),
        ])),
        const SizedBox(width: 8),
        Expanded(flex: 6, child: Row(children: [
          _ActionButton(label: 'FOLD',
            enabled: btnState.isEnabled(CcAction.fold),
            color: const Color(0xFFE53935),
            onPressed: btnState.isEnabled(CcAction.fold) ? () => onAction(CcAction.fold) : null),
          _ActionButton(label: btnState.checkCallLabel,
            enabled: btnState.isEnabled(CcAction.checkCall),
            color: const Color(0xFF78909C),
            subText: isCall && callAmount > 0 ? '\$${fmt(callAmount)}' : null,
            onPressed: btnState.isEnabled(CcAction.checkCall) ? () => onAction(CcAction.checkCall) : null),
          _ActionButton(label: btnState.betRaiseLabel,
            enabled: btnState.isEnabled(CcAction.betRaise),
            color: const Color(0xFFFFA726),
            onPressed: btnState.isEnabled(CcAction.betRaise) ? () => onAction(CcAction.betRaise) : null),
          _ActionButton(label: 'ALL-IN',
            enabled: btnState.isEnabled(CcAction.allIn),
            color: const Color(0xFFEF5350),
            subText: stack > 0 ? '\$${fmt(stack)}' : null,
            onPressed: btnState.isEnabled(CcAction.allIn) ? () => onAction(CcAction.allIn) : null),
        ])),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Column(children: [
          Expanded(flex: 3, child: _ActionButton(label: lifecycleLabel,
            enabled: btnState.isEnabled(CcAction.newHand),
            color: const Color(0xFF66BB6A),
            big: true,
            subText: lifecycleSub,
            onPressed: btnState.isEnabled(CcAction.newHand) ? () => onAction(CcAction.newHand) : null)),
          const SizedBox(height: 4),
          Expanded(child: _ActionButton(label: 'DEAL',
            enabled: btnState.isEnabled(CcAction.deal),
            color: const Color(0xFF42A5F5),
            onPressed: btnState.isEnabled(CcAction.deal) ? () => onAction(CcAction.deal) : null)),
        ])),
      ]),
    );
  
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.color,
    this.onPressed,
    this.big = false,
    this.subText,
  });

  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;
  final bool big;
  final String? subText;

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(fit: BoxFit.scaleDown,
                  child: Text(label,
                    style: EbsTypography.actionButton.copyWith(
                      fontSize: big ? 18 : null,
                      fontWeight: big ? FontWeight.w800 : null))),
                if (subText != null)
                  Padding(padding: const EdgeInsets.only(top: 2),
                    child: Text(subText!,
                      style: TextStyle(fontSize: 10,
                        fontFamily: subText!.startsWith('\$') ? 'monospace' : null,
                        color: enabled ? Colors.white70 : Colors.white30,
                        fontWeight: FontWeight.w600))),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

