// Rive Overlay Canvas (BS-07-02).
//
// Wraps OverlayRoot with an animation layer that consumes the animation queue
// from OverlayAnimationService and applies visual transitions.
//
// Dual rendering path:
//  - If the active skin bundle shipped a valid skin.riv, load the Rive
//    artboard and drive a StateMachineController with the animation spec
//    (Phase 2 path).
//  - Otherwise, run the Flutter-native animations already wired to
//    seatAnimationProvider / globalAnimationProvider (Phase 1 fallback).
//
// The selection is decided once per SkinBundle change via [_loadRiveArtboard].
// A failure loading the Rive file logs and downgrades to the Phase 1 path.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rive/rive.dart' as rive;

import '../../../models/entities/card_model.dart';
import '../providers/animation_provider.dart';
import '../services/animation_controller_service.dart';
import '../services/skin_consumer.dart';
import 'overlay_root.dart';

final _log = Logger('RiveOverlayCanvas');

/// State-machine name agreed with team1 graphic editor export pipeline.
const _kStateMachineName = 'EBS';

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
  rive.Artboard? _riveArtboard;
  rive.StateMachineController? _stateMachineController;
  List<int>? _loadedRiveBytesFingerprint;

  @override
  void initState() {
    super.initState();
    _startQueuePoll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stateMachineController?.dispose();
    super.dispose();
  }

  // ── Rive artboard loading ─────────────────────────────────────────────

  Future<void> _loadRiveArtboard(List<int> bytes) async {
    // Avoid reloading the same bundle twice.
    if (identical(_loadedRiveBytesFingerprint, bytes)) return;
    _loadedRiveBytesFingerprint = bytes;

    _stateMachineController?.dispose();
    _stateMachineController = null;
    _riveArtboard = null;

    try {
      final file = rive.RiveFile.import(
        ByteData.view(Uint8List.fromList(bytes).buffer),
      );
      final artboard = file.mainArtboard.instance();
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        _kStateMachineName,
      );
      if (controller == null) {
        _log.warning(
          'Skin Rive file has no "$_kStateMachineName" state machine; '
          'falling back to Flutter animations.',
        );
        return;
      }
      artboard.addController(controller);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _riveArtboard = artboard;
        _stateMachineController = controller;
      });
    } catch (e, st) {
      _log.warning('Rive artboard load failed; using Flutter path.', e, st);
    }
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
    // Track active skin bundle and (re)load Rive artboard when it changes.
    ref.listen<SkinConsumerState>(skinConsumerProvider, (prev, next) {
      final bundle = next.bundle;
      if (bundle == null) return;
      if (bundle.riveBytes.isEmpty) return;
      _loadRiveArtboard(bundle.riveBytes);
    });

    final artboard = _riveArtboard;
    if (artboard != null) {
      // Phase 2 render path — Rive artboard stacked over OverlayRoot so
      // data-driven widgets (chips, cards, pot) still render while the
      // artboard drives transitions and ambient animations.
      return Stack(
        fit: StackFit.expand,
        children: [
          OverlayRoot(
            chromaKeyColor: widget.chromaKeyColor,
            communityCards: widget.communityCards,
            mainPot: widget.mainPot,
            sidePots: widget.sidePots,
            equities: widget.equities,
            outsMap: widget.outsMap,
            lastActions: widget.lastActions,
            revealedSeats: widget.revealedSeats,
          ),
          IgnorePointer(
            child: rive.Rive(
              artboard: artboard,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    }

    // Phase 1 fallback — Flutter-native animations via providers.
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
