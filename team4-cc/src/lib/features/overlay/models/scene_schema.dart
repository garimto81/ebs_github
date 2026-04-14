// Scene JSON schema (BS-07-04).
//
// Defines the spatial layout for overlay rendering:
// seat positions, card sizes, branding overrides, and resolution.
// Used by OverlayRoot to position Layer 1 elements.

// ---------------------------------------------------------------------------
// Seat position on the overlay canvas
// ---------------------------------------------------------------------------

class SeatPosition {
  const SeatPosition({
    required this.x,
    required this.y,
    this.nameOffsetY = -24.0,
    this.cardsOffsetY = 20.0,
  });

  /// Center X coordinate (pixels from left).
  final double x;

  /// Center Y coordinate (pixels from top).
  final double y;

  /// Vertical offset for player name label relative to seat center.
  final double nameOffsetY;

  /// Vertical offset for hole card display relative to seat center.
  final double cardsOffsetY;
}

// ---------------------------------------------------------------------------
// Card rendering size
// ---------------------------------------------------------------------------

class CardSize {
  const CardSize({
    this.width = 48.0,
    this.height = 68.0,
    this.gap = 4.0,
    this.cornerRadius = 4.0,
  });

  final double width;
  final double height;
  final double gap; // space between two hole cards
  final double cornerRadius;
}

// ---------------------------------------------------------------------------
// Branding overrides (from .gfskin manifest)
// ---------------------------------------------------------------------------

class BrandingOverrides {
  const BrandingOverrides({
    this.logoPath,
    this.primaryColor,
    this.secondaryColor,
    this.fontFamily,
    this.watermarkOpacity = 0.0,
  });

  final String? logoPath;
  final int? primaryColor; // ARGB hex value
  final int? secondaryColor;
  final String? fontFamily;
  final double watermarkOpacity;
}

// ---------------------------------------------------------------------------
// Scene Schema — complete spatial definition
// ---------------------------------------------------------------------------

class SceneSchema {
  const SceneSchema({
    required this.seatPositions,
    this.cardSize = const CardSize(),
    this.branding,
    this.width = 1920,
    this.height = 1080,
    this.boardX = 960.0,
    this.boardY = 400.0,
    this.potX = 960.0,
    this.potY = 340.0,
  });

  /// Seat number (1-based) → position on canvas.
  final Map<int, SeatPosition> seatPositions;

  /// Card rendering dimensions.
  final CardSize cardSize;

  /// Optional branding overrides from .gfskin skin.
  final BrandingOverrides? branding;

  /// Output resolution width.
  final int width;

  /// Output resolution height.
  final int height;

  /// Board (community cards) center X.
  final double boardX;

  /// Board (community cards) center Y.
  final double boardY;

  /// Pot display center X.
  final double potX;

  /// Pot display center Y.
  final double potY;

  // -- Factory: Standard 10-seat 1080p layout --------------------------------

  /// Default 10-seat oval layout for 1920x1080.
  factory SceneSchema.default1080p() {
    return SceneSchema(
      seatPositions: _default1080pSeats,
    );
  }

  /// Default 10-seat oval layout for 3840x2160 (4K).
  factory SceneSchema.default4K() {
    return SceneSchema(
      width: 3840,
      height: 2160,
      boardX: 1920.0,
      boardY: 800.0,
      potX: 1920.0,
      potY: 680.0,
      seatPositions: {
        for (final e in _default1080pSeats.entries)
          e.key: SeatPosition(
            x: e.value.x * 2,
            y: e.value.y * 2,
            nameOffsetY: e.value.nameOffsetY * 2,
            cardsOffsetY: e.value.cardsOffsetY * 2,
          ),
      },
      cardSize: const CardSize(
        width: 96,
        height: 136,
        gap: 8,
        cornerRadius: 8,
      ),
    );
  }

  static final Map<int, SeatPosition> _default1080pSeats = {
    1: const SeatPosition(x: 1600, y: 820),
    2: const SeatPosition(x: 1400, y: 920),
    3: const SeatPosition(x: 960, y: 960),
    4: const SeatPosition(x: 520, y: 920),
    5: const SeatPosition(x: 320, y: 820),
    6: const SeatPosition(x: 320, y: 280),
    7: const SeatPosition(x: 520, y: 180),
    8: const SeatPosition(x: 960, y: 140),
    9: const SeatPosition(x: 1400, y: 180),
    10: const SeatPosition(x: 1600, y: 280),
  };
}
