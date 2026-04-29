// EBS Lobby — semantic StatusBadge factory.
//
// Maps event/flight/table status string ("running" / "registering" / etc.)
// to the design's `.b-running` / `.b-registering` / `.b-announced` /
// `.b-completed` / `.b-created` semantic tokens, then renders via the
// shared StatusBadge primitive.

import 'package:flutter/material.dart';

import '../../../foundation/theme/lobby_colors.dart';
import '../../../foundation/widgets/lobby_chrome_widgets.dart';

class LobbyStatusBadge extends StatelessWidget {
  const LobbyStatusBadge({super.key, required this.status});

  /// One of: running / registering / announced / completed / created /
  /// live / setup / empty / break / finished.
  final String status;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(status);
    return StatusBadge(
      label: spec.label,
      bg: spec.bg,
      ink: spec.ink,
      dot: spec.dot,
    );
  }

  _BadgeSpec _spec(String s) {
    switch (s) {
      case 'running':
      case 'live':
        return const _BadgeSpec(
          'Running',
          LobbyColors.statusRunningBg,
          LobbyColors.statusRunningInk,
          LobbyColors.statusRunning,
        );
      case 'registering':
      case 'setup':
        return const _BadgeSpec(
          'Registering',
          LobbyColors.statusRegisteringBg,
          LobbyColors.statusRegisteringInk,
          LobbyColors.statusRegistering,
        );
      case 'announced':
        return const _BadgeSpec(
          'Announced',
          LobbyColors.statusAnnouncedBg,
          LobbyColors.statusAnnouncedInk,
          LobbyColors.statusAnnounced,
        );
      case 'completed':
      case 'finished':
        return const _BadgeSpec(
          'Completed',
          LobbyColors.statusCompletedBg,
          LobbyColors.statusCompletedInk,
          LobbyColors.statusCompleted,
        );
      case 'created':
      case 'empty':
        return const _BadgeSpec(
          'Created',
          LobbyColors.statusCreatedBg,
          LobbyColors.statusCreatedInk,
          LobbyColors.statusCreated,
        );
      default:
        // Fallback — capitalize and use neutral palette
        final label = s.isEmpty ? '—' : (s[0].toUpperCase() + s.substring(1));
        return _BadgeSpec(
          label,
          LobbyColors.statusCompletedBg,
          LobbyColors.statusCompletedInk,
          LobbyColors.statusCompleted,
        );
    }
  }
}

class _BadgeSpec {
  const _BadgeSpec(this.label, this.bg, this.ink, this.dot);
  final String label;
  final Color bg;
  final Color ink;
  final Color dot;
}
