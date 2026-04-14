// Overlay animation Riverpod providers (BS-07-02).
//
// Exposes OverlayAnimationService and per-seat / global animation state
// for the widget layer to consume.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/animation_controller_service.dart';

// ---------------------------------------------------------------------------
// Service provider — singleton animation queue manager
// ---------------------------------------------------------------------------

/// Provides the [OverlayAnimationService] singleton for animation queue
/// management and GameState-to-animation mapping.
final overlayAnimationProvider = Provider<OverlayAnimationService>(
  (ref) => OverlayAnimationService(),
);

// ---------------------------------------------------------------------------
// Per-seat animation state (family provider, indexed by seatNo 1-10)
// ---------------------------------------------------------------------------

/// Active animation for a specific seat. Null when idle.
///
/// Widget layer sets this when dequeuing a seat-targeted animation,
/// and clears it (null) when the animation completes.
///
/// Example:
/// ```dart
/// ref.read(seatAnimationProvider(3).notifier).state =
///     OverlayAnimation.slideAndDarken;
/// ```
final seatAnimationProvider = StateProvider.family<OverlayAnimation?, int>(
  (ref, seatIndex) => null,
);

// ---------------------------------------------------------------------------
// Global animation state (board, pot, etc.)
// ---------------------------------------------------------------------------

/// Active global animation (board card deal, pot rolling, etc.). Null when idle.
///
/// Widget layer sets this when dequeuing a global animation,
/// and clears it (null) when the animation completes.
final globalAnimationProvider = StateProvider<OverlayAnimation?>(
  (ref) => null,
);
