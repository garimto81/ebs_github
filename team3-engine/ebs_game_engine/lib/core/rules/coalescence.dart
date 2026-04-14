/// Coalescence window for RFID burst processing.
///
/// Groups card detection events within a time window into a single batch.
/// Supports Hold'em (100ms), Draw (200ms), and Stud (variable burst size).

/// A single card detection from RFID.
class CardDetection {
  final int seatIndex; // -1 for community/board
  final String cardCode; // e.g., 'As', 'Kh'
  final String source; // 'seat', 'board', 'burn'

  const CardDetection({
    required this.seatIndex,
    required this.cardCode,
    this.source = 'seat',
  });

  @override
  String toString() => 'CardDetection($cardCode, seat=$seatIndex, $source)';
}

/// A completed batch of card detections from one coalescence window.
class CoalescenceBatch {
  final List<CardDetection> detections;
  final int windowMs;

  const CoalescenceBatch({
    required this.detections,
    required this.windowMs,
  });

  /// Group detections by seat.
  Map<int, List<CardDetection>> get bySeat {
    final map = <int, List<CardDetection>>{};
    for (final d in detections) {
      map.putIfAbsent(d.seatIndex, () => []).add(d);
    }
    return map;
  }

  /// Get community/board detections (seatIndex == -1).
  List<CardDetection> get boardDetections =>
      detections.where((d) => d.seatIndex == -1).toList();

  /// Get burn zone detections.
  List<CardDetection> get burnDetections =>
      detections.where((d) => d.source == 'burn').toList();

  /// Total cards detected.
  int get cardCount => detections.length;
}

/// Coalescence window that accumulates RFID card detections within a
/// configurable time window and emits them as a single batch.
class CoalescenceWindow {
  /// Window duration in milliseconds.
  final int windowMs;

  /// Maximum cards in a single burst (overflow protection).
  final int maxBurstSize;

  /// Accumulated card detections within the current window.
  final List<CardDetection> _buffer = [];

  /// Window start timestamp (ms since epoch).
  int? _windowStart;

  CoalescenceWindow({
    this.windowMs = 100, // default 100ms for Hold'em
    this.maxBurstSize = 52,
  });

  /// Factory for Draw games (200ms window per BS-06-2X §1 DRAW_ROUND).
  factory CoalescenceWindow.draw() => CoalescenceWindow(
        windowMs: 200,
        maxBurstSize: 30, // 6 players x 5 cards max
      );

  /// Factory for Stud 3rd street (100ms but 18-card burst per BS-06-3X §1 SETUP_HAND).
  factory CoalescenceWindow.stud3rd() => CoalescenceWindow(
        windowMs: 100,
        maxBurstSize: 18, // 6 players x 3 cards
      );

  /// Factory for Stud 4th-7th street.
  factory CoalescenceWindow.studStreet() => CoalescenceWindow(
        windowMs: 100,
        maxBurstSize: 8, // max 8 players x 1 card
      );

  /// Add a card detection event.
  /// Returns null if still within window, or the completed batch if window
  /// closed (either by time expiry or overflow).
  CoalescenceBatch? addDetection(CardDetection detection, int timestampMs) {
    if (_windowStart == null) {
      _windowStart = timestampMs;
    }

    // Check if within window
    if (timestampMs - _windowStart! <= windowMs) {
      if (_buffer.length < maxBurstSize) {
        _buffer.add(detection);
        return null; // still collecting
      } else {
        // Overflow: emit current batch, start new window
        final batch = _flush();
        _windowStart = timestampMs;
        _buffer.add(detection);
        return batch;
      }
    } else {
      // Window expired: emit batch, start new window
      final batch = _flush();
      _windowStart = timestampMs;
      _buffer.add(detection);
      return batch;
    }
  }

  /// Force-close the current window and return accumulated batch.
  CoalescenceBatch? flush() {
    if (_buffer.isEmpty) return null;
    return _flush();
  }

  CoalescenceBatch _flush() {
    final batch = CoalescenceBatch(
      detections: List.unmodifiable(_buffer),
      windowMs: windowMs,
    );
    _buffer.clear();
    _windowStart = null;
    return batch;
  }

  /// Current buffer size.
  int get pendingCount => _buffer.length;

  /// Whether the window is currently active.
  bool get isActive => _windowStart != null;
}

/// Validate Draw round detection order.
/// Discards must be detected before new dealt cards.
class DrawCoalescenceValidator {
  DrawCoalescenceValidator._();

  /// Check if a batch follows discard-first order.
  /// Returns null if valid, or error message if invalid.
  static String? validateDrawBatch(CoalescenceBatch batch) {
    bool sawNewDealt = false;
    for (final d in batch.detections) {
      if (d.source == 'seat') {
        sawNewDealt = true;
      } else if (d.source == 'burn' && sawNewDealt) {
        return 'WRONG_SEQUENCE: discard detected after new_dealt card '
            'at seat ${d.seatIndex}';
      }
    }
    return null; // valid
  }

  /// Separate a draw batch into discards and new cards.
  static ({List<CardDetection> discards, List<CardDetection> newCards})
      separateDrawBatch(CoalescenceBatch batch) {
    return (
      discards: batch.detections.where((d) => d.source == 'burn').toList(),
      newCards: batch.detections.where((d) => d.source == 'seat').toList(),
    );
  }
}
