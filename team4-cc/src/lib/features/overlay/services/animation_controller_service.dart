// Rive Animation Controller Service (BS-07-02).
//
// Manages overlay animation lifecycle: enum definitions, duration specs,
// queue management, and GameState-to-animation mapping.
//
// Phase 1: Flutter-native fallback animations (AnimatedContainer, transitions).
// Phase 2: Rive StateMachine integration with .riv files.

// ---------------------------------------------------------------------------
// Animation type enum — maps 1:1 to BS-07-02 animation table
// ---------------------------------------------------------------------------

/// All overlay animation types defined in BS-07-02.
enum OverlayAnimation {
  /// Element entrance — 300ms slide from bottom.
  slideUp,

  /// Fold visual — 400ms slide + opacity reduction.
  slideAndDarken,

  /// Action-on emphasis — 800ms looping pulse.
  pulse,

  /// Card reveal — 400ms Y-axis flip.
  flip,

  /// Card distribution — 300ms arc trajectory.
  cardDeal,

  /// Pot value change — 500ms rolling number.
  potRolling,

  /// Dealer button relocation — 400ms smooth slide.
  dealerMove,
}

// ---------------------------------------------------------------------------
// Animation spec — describes a single animation instance
// ---------------------------------------------------------------------------

/// Describes one animation to play, including target and timing.
class AnimationSpec {
  const AnimationSpec(
    this.type,
    this.duration, {
    this.targetSeat = -1,
  });

  /// Which animation to play.
  final OverlayAnimation type;

  /// How long the animation runs (from BS-07-02 duration table).
  final Duration duration;

  /// Target seat number (1-based). -1 for global elements (board, pot).
  final int targetSeat;

  /// Whether this targets a specific seat vs. a global element.
  bool get isGlobal => targetSeat == -1;

  @override
  String toString() =>
      'AnimationSpec($type, ${duration.inMilliseconds}ms, seat=$targetSeat)';
}

// ---------------------------------------------------------------------------
// Animation controller service
// ---------------------------------------------------------------------------

/// Manages overlay animation queue and GameState-to-animation mapping.
///
/// Usage:
/// 1. Call [mapStateChange] when a new GameState arrives to produce animations.
/// 2. Enqueue results via [enqueue] or [enqueueAll].
/// 3. Consume with [dequeue] from the widget layer to drive transitions.
///
/// Phase 1: Widgets use Flutter-native AnimatedContainer/FadeTransition.
/// Phase 2: Widgets forward specs to Rive StateMachine inputs.
class OverlayAnimationService {
  // ── Duration table (BS-07-02) ─────────────────────────────────────────

  /// Canonical animation durations from BS-07-02 spec.
  static const Map<OverlayAnimation, Duration> durations = {
    OverlayAnimation.slideUp: Duration(milliseconds: 300),
    OverlayAnimation.slideAndDarken: Duration(milliseconds: 400),
    OverlayAnimation.pulse: Duration(milliseconds: 800),
    OverlayAnimation.flip: Duration(milliseconds: 400),
    OverlayAnimation.cardDeal: Duration(milliseconds: 300),
    OverlayAnimation.potRolling: Duration(milliseconds: 500),
    OverlayAnimation.dealerMove: Duration(milliseconds: 400),
  };

  /// Returns the canonical duration for [type].
  static Duration durationOf(OverlayAnimation type) =>
      durations[type] ?? const Duration(milliseconds: 300);

  // ── Queue management ──────────────────────────────────────────────────

  final List<AnimationSpec> _queue = [];

  /// Number of pending animations.
  int get pendingCount => _queue.length;

  /// Whether the queue has pending animations.
  bool get hasPending => _queue.isNotEmpty;

  /// Add a single animation to the queue.
  void enqueue(AnimationSpec spec) => _queue.add(spec);

  /// Add multiple animations to the queue.
  void enqueueAll(List<AnimationSpec> specs) => _queue.addAll(specs);

  /// Remove and return the next animation, or null if empty.
  AnimationSpec? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Peek at the next animation without removing it.
  AnimationSpec? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  /// Discard all pending animations (e.g., on hand reset).
  void clear() => _queue.clear();

  // ── State change → animation mapping ──────────────────────────────────

  /// Maps a GameState transition to a list of [AnimationSpec]s.
  ///
  /// Called by the overlay state listener when OutputEvent arrives.
  /// Returns animations in execution order (seat-specific first, then global).
  ///
  /// Parameters:
  /// - [previousPhase] / [currentPhase]: hand phase strings (e.g., "preflop").
  /// - [foldedSeat]: seat number that just folded (triggers slideAndDarken).
  /// - [actionOnSeat]: seat number with action (triggers pulse).
  /// - [dealerSeat]: seat number receiving dealer button (triggers dealerMove).
  /// - [boardChanged]: community cards changed (triggers cardDeal).
  /// - [potChanged]: pot amount changed (triggers potRolling).
  /// - [revealedSeats]: seats showing cards for first time (triggers flip).
  List<AnimationSpec> mapStateChange({
    required String previousPhase,
    required String currentPhase,
    int? foldedSeat,
    int? actionOnSeat,
    int? dealerSeat,
    bool boardChanged = false,
    bool potChanged = false,
    List<int> revealedSeats = const [],
  }) {
    final animations = <AnimationSpec>[];

    // ── Seat-specific animations (order: fold → reveal → action → dealer) ──

    // Fold: darken the folded seat.
    if (foldedSeat != null) {
      animations.add(AnimationSpec(
        OverlayAnimation.slideAndDarken,
        durationOf(OverlayAnimation.slideAndDarken),
        targetSeat: foldedSeat,
      ));
    }

    // Card reveal: flip animation per revealed seat.
    for (final seat in revealedSeats) {
      animations.add(AnimationSpec(
        OverlayAnimation.flip,
        durationOf(OverlayAnimation.flip),
        targetSeat: seat,
      ));
    }

    // Action-on: pulse the active seat.
    if (actionOnSeat != null) {
      animations.add(AnimationSpec(
        OverlayAnimation.pulse,
        durationOf(OverlayAnimation.pulse),
        targetSeat: actionOnSeat,
      ));
    }

    // Dealer button move.
    if (dealerSeat != null) {
      animations.add(AnimationSpec(
        OverlayAnimation.dealerMove,
        durationOf(OverlayAnimation.dealerMove),
        targetSeat: dealerSeat,
      ));
    }

    // ── Global animations (order: board → pot) ──────────────────────────

    // Board change: card deal animation.
    if (boardChanged) {
      animations.add(AnimationSpec(
        OverlayAnimation.cardDeal,
        durationOf(OverlayAnimation.cardDeal),
      ));
    }

    // Pot change: rolling number animation.
    if (potChanged) {
      animations.add(AnimationSpec(
        OverlayAnimation.potRolling,
        durationOf(OverlayAnimation.potRolling),
      ));
    }

    return animations;
  }
}
