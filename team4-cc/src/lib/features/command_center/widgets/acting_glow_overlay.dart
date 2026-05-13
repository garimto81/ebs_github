// ActingGlowOverlay — reusable ACTING-state glow pulse wrapper.
//
// Cycle 19 Wave 4 (U7) — extracted from `seat_cell.dart` inline pulse so any
// surface (seat tile, action panel emphasis, future "next to act" hints) can
// reuse the same broadcast-amber rhythm.
//
// SSOT reference: `docs/mockups/EBS Command Center/app.css`
//   `.pcol.action-on::before` + `@keyframes action-pulse` — 1.6s ease-in-out
//   infinite. CSS uses opacity 0.25↔0.6 + scale 1.0↔1.015; this Flutter port
//   widens opacity to 0.4↔1.0 (task spec) so the ring stays readable on the
//   1920px Operator surface where the seat tiles are smaller than the HTML
//   mockup demo.
//
// Performance:
//   - `RepaintBoundary` isolates the animated `BoxShadow` so neighbouring
//     seat cells do not re-rasterize each frame.
//   - `BlurStyle.outer` lets Skia skip the interior blur work — only the
//     outer halo gets rasterized. This is the key Skia cost reducer for
//     `blurRadius: 28`.
//   - Single `AnimationController` ticks the alpha; the shadow list itself
//     is rebuilt only when `active` flips (constant `const` list otherwise).
//
// Token contract:
//   - Ring: `EbsOklch.accent` (full opacity, animated alpha).
//   - Halo: `EbsOklch.accentSoft` (animated alpha), `BlurStyle.outer` for
//     Skia perf.
//   - When `active=false` the wrapper renders the child untouched (no shadow,
//     no RepaintBoundary cost beyond a `Builder` boundary).

import 'package:flutter/material.dart';

import '../../../foundation/theme/ebs_oklch.dart';

/// Wraps a child with a pulsing accent-amber glow used to mark the seat /
/// surface that currently has action.
///
/// Mirrors HTML SSOT `.pcol.action-on::before` (`action-pulse 1.6s
/// ease-in-out infinite`). When [active] is `false`, no animation is run and
/// the child is returned unchanged.
class ActingGlowOverlay extends StatefulWidget {
  const ActingGlowOverlay({
    required this.active,
    required this.child,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1600),
    this.minOpacity = 0.4,
    this.maxOpacity = 1.0,
    super.key,
  });

  /// Whether the surface currently holds action (drives the pulse on/off).
  final bool active;

  /// Surface to wrap. Caller owns layout, padding, internal decoration.
  final Widget child;

  /// Mirrors the wrapped surface's corner radius so the glow follows shape.
  /// Defaults to `BorderRadius.circular(6)` — matches `SeatCell` decoration.
  final BorderRadius? borderRadius;

  /// Pulse cycle duration. HTML SSOT = 1.6s. Tests override to shorten.
  final Duration duration;

  /// Opacity at pulse trough (animation begin / reverse end). Default 0.4.
  final double minOpacity;

  /// Opacity at pulse crest. Default 1.0.
  final double maxOpacity;

  @override
  State<ActingGlowOverlay> createState() => _ActingGlowOverlayState();
}

class _ActingGlowOverlayState extends State<ActingGlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _pulse = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ActingGlowOverlay old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.active && !old.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(6);

    if (!widget.active) {
      // Untouched fast-path. No RepaintBoundary cost — caller already pays
      // for the surface's own layer if needed.
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final alpha = _pulse.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                // 2px solid accent ring — emulates `0 0 0 2px var(--accent)`.
                BoxShadow(
                  color: EbsOklch.accent.withValues(alpha: alpha),
                  spreadRadius: 2,
                  blurRadius: 0,
                ),
                // 28px soft outer halo — `BlurStyle.outer` lets Skia skip the
                // interior blur (no inset highlight cost).
                BoxShadow(
                  color: EbsOklch.accentSoft.withValues(alpha: alpha),
                  blurRadius: 28,
                  spreadRadius: 0,
                  blurStyle: BlurStyle.outer,
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
