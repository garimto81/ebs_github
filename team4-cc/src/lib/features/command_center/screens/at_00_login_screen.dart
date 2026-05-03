// AT-00 Login screen (BS-05-00 §화면 카탈로그, CCR-028).
//
// Two modes:
//   1. Auto-auth: LaunchConfig from args → authenticate immediately on init.
//   2. Manual:    No args → show Table ID + Token form → [Connect] button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../../models/launch_config.dart';

class At00LoginScreen extends ConsumerStatefulWidget {
  const At00LoginScreen({super.key});

  @override
  ConsumerState<At00LoginScreen> createState() => _At00LoginScreenState();
}

class _At00LoginScreenState extends ConsumerState<At00LoginScreen> {
  final _tableIdController = TextEditingController();
  final _tokenController = TextEditingController();
  final _wsUrlController = TextEditingController(text: 'ws://localhost:8000/ws/cc');
  final _boBaseUrlController = TextEditingController(text: 'http://localhost:8000');

  bool _autoAuthAttempted = false;

  @override
  void dispose() {
    _tableIdController.dispose();
    _tokenController.dispose();
    _wsUrlController.dispose();
    _boBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final launchConfig = ref.watch(launchConfigProvider);
    final authState = ref.watch(authProvider);

    // Auto-authenticate once if launch args were provided.
    if (launchConfig != null && !_autoAuthAttempted) {
      _autoAuthAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).authenticate(launchConfig);
      });
    }

    // SG-008-b11 v1.3 — Web 자동 진입 시 manual login 폼 깜박임 방지.
    // launchConfig 가 존재하면 ("CC 호출됨") connect 폼 대신 loading placeholder 만
    // 표시하고 auto-auth 완료 즉시 router 가 /main 으로 redirect.
    if (launchConfig != null &&
        authState.status != AuthStatus.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Table ${launchConfig.tableId} 연결 중...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'EBS Command Center',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to table',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Table ID
                  TextField(
                    controller: _tableIdController,
                    decoration: const InputDecoration(
                      labelText: 'Table ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Token
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'JWT Token',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // WebSocket URL
                  TextField(
                    controller: _wsUrlController,
                    decoration: const InputDecoration(
                      labelText: 'WebSocket URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cable),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BO Base URL
                  TextField(
                    controller: _boBaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'BO Base URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (authState.status == AuthStatus.error &&
                      authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Connect button
                  FilledButton.icon(
                    onPressed: authState.status == AuthStatus.authenticating
                        ? null
                        : _onConnect,
                    icon: authState.status == AuthStatus.authenticating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Connect'),
                  ),

                  const SizedBox(height: 16),

                  // Connection status indicator
                  _ConnectionStatusIndicator(status: authState.status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onConnect() {
    final tableId = int.tryParse(_tableIdController.text.trim());
    if (tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Table ID (must be a number)')),
      );
      return;
    }

    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is required')),
      );
      return;
    }

    final config = LaunchConfig(
      tableId: tableId,
      token: token,
      ccInstanceId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
      wsUrl: _wsUrlController.text.trim(),
      boBaseUrl: _boBaseUrlController.text.trim(),
    );

    ref.read(authProvider.notifier).authenticate(config);
  }
}

// ---------------------------------------------------------------------------
// Connection status indicator
// ---------------------------------------------------------------------------

class _ConnectionStatusIndicator extends StatelessWidget {
  const _ConnectionStatusIndicator({required this.status});

  final AuthStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AuthStatus.unauthenticated => (Colors.grey, 'Disconnected'),
      AuthStatus.authenticating => (Colors.orange, 'Connecting...'),
      AuthStatus.authenticated => (Colors.green, 'Connected'),
      AuthStatus.error => (Colors.red, 'Error'),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
