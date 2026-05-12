import 'package:flutter/material.dart';

import '../../../models/models.dart';

/// Player 상세 다이얼로그 — `Lobby/UI.md §화면 4 Player (독립 레이어)` 의
/// "Player 행 클릭 → 플레이어 상세 다이얼로그" 스펙 구현.
///
/// 읽기 전용. 프로필 이미지 (있으면) + WSOP ID + 이름 + 국적 + 포지션 +
/// 현재 테이블/좌석 + 칩 + 상태. Cycle 17 cascade — 4 핵심 필드
/// (Name + Country + Position + Stack) 강조. 편집/이동/제거는 후속 (B-F005).
class PlayerDetailDialog extends StatelessWidget {
  final Player player;

  const PlayerDetailDialog({super.key, required this.player});

  String _fmt(int? v) =>
      v == null ? '—' : v.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          );

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        player.profileImage != null && player.profileImage!.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          if (hasPhoto)
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(player.profileImage!),
              onBackgroundImageError: (_, __) {},
            )
          else
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                player.firstName.isNotEmpty ? player.firstName[0] : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${player.firstName} ${player.lastName}'),
                if (player.wsopId != null)
                  Text(
                    'WSOP #${player.wsopId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(context, 'Nationality', player.nationality ?? '—'),
            _row(context, 'Country Code', player.countryCode ?? '—'),
            _row(context, 'Position', player.position ?? '—'),
            const Divider(),
            _row(context, 'Current Table', player.tableName ?? 'Not seated'),
            _row(
              context,
              'Seat',
              player.seatIndex?.toString() ?? '—',
            ),
            _row(context, 'Stack', _fmt(player.stack)),
            _row(context, 'Status', player.playerStatus),
            const Divider(),
            _row(context, 'Player ID', player.playerId.toString()),
            _row(context, 'Source', player.source),
            _row(context, 'Demo', player.isDemo ? 'Yes' : 'No'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
