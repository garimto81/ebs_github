/// Canvas type determines default card visibility.
enum CanvasType {
  /// Venue display: hole cards never shown to audience.
  venue,

  /// Broadcast: hole cards shown per reveal config.
  broadcast,
}

/// How cards are revealed at showdown.
enum RevealType {
  /// All cards shown immediately.
  allImmediate,

  /// Last aggressor shows first, then clockwise.
  lastAggressorFirst,

  /// Winner shows, losers can muck.
  winnerOnly,

  /// All cards shown after all decisions made.
  allAfterDecision,

  /// Operator manually reveals each player.
  manualReveal,

  /// No auto-reveal; all handled externally.
  externalControl,
}

/// What to show when a player shows cards.
enum ShowType {
  /// Show both hole cards.
  bothCards,

  /// Show only the winning card(s).
  winningCardsOnly,

  /// Show one card (player's choice -- engine picks best).
  oneCard,

  /// Don't auto-show; let player decide.
  playerChoice,
}

/// How folded player cards are handled.
enum FoldHideType {
  /// Folded cards are immediately hidden.
  hideImmediately,

  /// Folded cards stay visible briefly then hide.
  briefRevealThenHide,
}

/// Complete card reveal configuration (6 x 4 x 2 = 48 combinations).
class CardRevealConfig {
  final RevealType revealType;
  final ShowType showType;
  final FoldHideType foldHideType;

  const CardRevealConfig({
    this.revealType = RevealType.lastAggressorFirst,
    this.showType = ShowType.bothCards,
    this.foldHideType = FoldHideType.hideImmediately,
  });

  /// Default broadcast configuration.
  static const broadcast = CardRevealConfig(
    revealType: RevealType.lastAggressorFirst,
    showType: ShowType.bothCards,
    foldHideType: FoldHideType.hideImmediately,
  );

  /// Default venue configuration.
  static const venue = CardRevealConfig(
    revealType: RevealType.externalControl,
    showType: ShowType.playerChoice,
    foldHideType: FoldHideType.hideImmediately,
  );

  CardRevealConfig copyWith({
    RevealType? revealType,
    ShowType? showType,
    FoldHideType? foldHideType,
  }) {
    return CardRevealConfig(
      revealType: revealType ?? this.revealType,
      showType: showType ?? this.showType,
      foldHideType: foldHideType ?? this.foldHideType,
    );
  }
}
