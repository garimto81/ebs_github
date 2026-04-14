// Rive Overlay Canvas (BS-07-02).
//
// Wraps OverlayRoot with an animation layer that consumes the animation queue
// from OverlayAnimationService and applies visual transitions.
//
// Phase 1: Flutter-native animations (AnimatedContainer, FadeTransition,
//          SlideTransition, AnimatedOpacity).
// Phase 2: Rive StateMachine integration — replace Flutter transitions
//          with Rive artboard inputs driven by AnimationSpec.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/entities/card_model.dart';
import '../providers/animation_provider.dart';
import '../services/animation_controller_service.dart';
import 'overlay_root.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Animation tick interval for queue processing.
const _queuePollInterval = Duration(milliseconds: 16); // ~60fps

// ---------------------------------------------------------------------------
// RiveOverlayCanvas
// ---------------------------------------------------------------------------

/// Hosts [OverlayRoot] and applies queued animations from
/// [OverlayAnimationService].
///
/// Phase 1 strategy:
/// - Seat animations: update [seatAnimationProvider] per seat, driving
///   AnimatedOpacity / SlideTransition on seat element wrappers.
/// - Global animations: update [globalAnimationProvider], driving
///   board and pot transition wrappers.
/// - Queue is polled at ~60fps; each dequeued spec triggers the matching
///   provider update and schedules a clear after the spec's duration.
///
/// Phase 2: Replace poll+provider pattern with Rive StateMachineController
/// inputs. The [_riveArtboard] field is reserved for .riv file loading.
class RiveOverlayCanvas extends ConsumerStatefulWidget {
  const RiveOverlayCanvas({
    super.key,
    this.chromaKeyColor = const Color(0xFF00B140),
    this.communityCards = const [],
    this.mainPot = 0,
    this.sidePots = const [],
    this.equities = const {},
    this.outsMap = const {},
    this.lastActions = const {},
    this.revealedSeats = const {},
  });

  /// Background chroma key color — passed through to [OverlayRoot].
  final Color chromaKeyColor;

  /// Community cards — passed through to [OverlayRoot].
  final List<CardModel> communityCards;

  /// Main pot — passed through to [OverlayRoot].
  final int mainPot;

  /// Side pots — passed through to [OverlayRoot].
  final List<int> sidePots;

  /// Per-seat equity — passed through to [OverlayRoot].
  final Map<int, double> equities;

  /// Per-seat outs — passed through to [OverlayRoot].
  final Map<int, int> outsMap;

  /// Per-seat last action — passed through to [OverlayRoot].
  final Map<int, String> lastActions;

  /// Revealed seats — passed through to [OverlayRoot].
  final Set<int> revealedSeats;

  @override
  ConsumerState<RiveOverlayCanvas> createState() => _RiveOverlayCanvasState();
}

class _RiveOverlayCanvasState extends ConsumerState<RiveOverlayCanvas> {
  Timer? _pollTimer;

  // Phase 2 placeholder: Rive artboard and state machine controller.
  // Artboard? _riveArtboard;
  // StateMachineController? _stateMachineController;

  @override
  void initState() {
    super.initState();
    _startQueuePoll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Queue polling ─────────────────────────────────────────────────────

  void _startQueuePoll() {
    _pollTimer = Timer.periodic(_queuePollInterval, (_) => _processQueue());
  }

  /// Dequeue one animation per tick and dispatch to the appropriate provider.
  void _processQueue() {
    final service = ref.read(overlayAnimationProvider);
    final spec = service.dequeue();
    if (spec == null) return;

    if (spec.isGlobal) {
      _dispatchGlobal(spec);
    } else {
      _dispatchSeat(spec);
    }
  }

  /// Apply a seat-targeted animation: set provider, schedule clear.
  void _dispatchSeat(AnimationSpec spec) {
    ref.read(seatAnimationProvider(spec.targetSeat).notifier).state =
        spec.type;

    // Clear after duration (non-looping animations).
    if (spec.type != OverlayAnimation.pulse) {
      Future.delayed(spec.duration, () {
        if (mounted) {
          ref.read(seatAnimationProvider(spec.targetSeat).notifier).state =
              null;
        }
      });
    }
    // Pulse is looping — cleared externally when action moves to another seat.
  }

  /// Apply a global animation: set provider, schedule clear.
  void _dispatchGlobal(AnimationSpec spec) {
    ref.read(globalAnimationProvider.notifier).state = spec.type;

    Future.delayed(spec.duration, () {
      if (mounted) {
        ref.read(globalAnimationProvider.notifier).state = null;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Phase 1: Wrap OverlayRoot with animation-aware layer.
    // Phase 2: Replace with RiveAnimation widget + artboard.
    return OverlayRoot(
      chromaKeyColor: widget.chromaKeyColor,
      communityCards: widget.communityCards,
      mainPot: widget.mainPot,
      sidePots: widget.sidePots,
      equities: widget.equities,
      outsMap: widget.outsMap,
      lastActions: widget.lastActions,
      revealedSeats: widget.revealedSeats,
    );
  }
}
