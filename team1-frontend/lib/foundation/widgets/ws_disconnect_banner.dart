import 'package:flutter/material.dart';

class WsDisconnectBanner extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onReconnect;
  const WsDisconnectBanner({
    super.key,
    required this.isConnected,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();
    return MaterialBanner(
      content: const Text('WebSocket disconnected. Reconnecting...'),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      actions: [
        if (onReconnect != null)
          TextButton(
            onPressed: onReconnect,
            child: const Text('Reconnect'),
          ),
      ],
    );
  }
}
