// Layer 1: Action Badge (semi-automatic — Security Delay applies, BS-07-07, CCR-036).
//
// Displays the most recent player action near their seat.
// Auto-fades after 3 seconds via AnimationController.
// Colors: fold=gray, check=green, bet=orange, raise=red, allIn=gold.

import 'package:flutter/material.dart';

/// Action badge color mapping.
Color _actionColor(String? actionText) {
  if (actionText == null) return Colors.transparent;
  final upper = actionText.toUpperCase();
  if (upper.startsWith('FOLD')) return const Color(0xFF616161); // Gray
  if (upper.startsWith('CHECK')) return const Color(0xFF43A047); // Green
  if (upper.startsWith('CALL')) return const Color(0xFF43A047); // Green
  if (upper.startsWith('BET')) return const Color(0xFFFB8C00); // Orange
  if (upper.startsWith('RAISE')) return const Color(0xFFE53935); // Red
  if (upper.startsWith('ALL')) return const Color(0xFFFDD835); // Gold
  return const Color(0xFF757575); // Default gray
}

/// Text color for contrast — gold badge uses dark text.
Color _actionTextColor(String? actionText) {
  if (actionText == null) return Colors.white;
  final upper = actionText.toUpperCase();
  if (upper.startsWith('ALL')) return Colors.black87; // Dark text on gold
  return Colors.white;
}

/// Displays a player action badge that auto-fades after [fadeDuration].
///
/// Set [actionText] to null to hide the badge immediately.
class ActionBadgeLayer extends StatefulWidget {
  const ActionBadgeLayer({
    super.key,
    this.actionText,
    this.fadeDuration = const Duration(seconds: 3),
  });

  /// Action label: "FOLD", "CHECK", "BET $500", "RAISE $1,200", "ALL-IN".
  /// null = hidden.
  final String? actionText;

  /// Duration before badge fades out.
  final Duration fadeDuration;

  @override
  State<ActionBadgeLayer> createState() => _ActionBadgeLayerState();
}

class _ActionBadgeLayerState extends State<ActionBadgeLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    if (widget.actionText != null) {
      _fadeController.value = 1.0;
      _startFadeTimer();
    }
  }

  @override
  void didUpdateWidget(ActionBadgeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actionText != oldWidget.actionText &&
        widget.actionText != null) {
      _fadeController.value = 1.0;
      _startFadeTimer();
    }
  }

  void _startFadeTimer() {
    Future.delayed(widget.fadeDuration, () {
      if (mounted) {
        _fadeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actionText == null) return const SizedBox.shrink();

    final bgColor = _actionColor(widget.actionText);
    final textColor = _actionTextColor(widget.actionText);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          widget.actionText!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
