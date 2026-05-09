// AT-00 Login screen (BS-05-00 §화면 카탈로그, CCR-028).
//
// Modes (SG-008-b11 v1.4):
//   1. Auto-auth: launchConfig present (URL query 또는 args) → 자동 인증 + placeholder.
//   2. Stand-alone (password-only): launchConfig 없을 때 비번 1 field. Email/host/table 등은
//      localStorage `ebs_cc_last_config` 에서 last successful config 로드 (lobby launch 시 자동 저장).
//      → POST /auth/login (default email + password) → token → CC 사용.
//   3. Advanced (Configure): localStorage 비어있거나 사용자 [Configure] 토글 시 4-field expanded form.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../auth/auth_provider.dart';
import '../../../models/launch_config.dart';
import '../../../foundation/cc_settings_storage.dart';

class At00LoginScreen extends ConsumerStatefulWidget {
  const At00LoginScreen({super.key});

  @override
  ConsumerState<At00LoginScreen> createState() => _At00LoginScreenState();
}

class _At00LoginScreenState extends ConsumerState<At00LoginScreen> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  // Advanced (Configure) mode fields
  final _tableIdController = TextEditingController();
  final _tokenController = TextEditingController();
  final _wsUrlController = TextEditingController(text: 'ws://localhost:8000/ws/cc');
  final _boBaseUrlController = TextEditingController(text: 'http://localhost:8000');

  bool _autoAuthAttempted = false;
  bool _showAdvanced = false;
  bool _busy = false;
  CcLastSession? _lastSession;

  @override
  void initState() {
    super.initState();
    // Restore last session config from localStorage (web) — issue 2.
    _lastSession = CcSettingsStorage.loadLastSession();
    if (_lastSession != null) {
      _emailController.text = _lastSession!.email ?? '';
      _tableIdController.text = (_lastSession!.tableId ?? 1).toString();
      _wsUrlController.text = _lastSession!.wsUrl ?? _wsUrlController.text;
      _boBaseUrlController.text = _lastSession!.boBaseUrl ?? _boBaseUrlController.text;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
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
    if (launchConfig != null && authState.status != AuthStatus.error) {
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

    // Stand-alone form (password-only by default, [Configure] for advanced).
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
                  Text(
                    'EBS Command Center',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastSession != null && !_showAdvanced
                        ? '비밀번호 입력'
                        : 'Connect to table',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Last session summary (read-only) — issue 2 핵심 UX
                  if (_lastSession != null && !_showAdvanced) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('Email', _lastSession!.email ?? '(none)'),
                          _kv('Table', '#${_lastSession!.tableId ?? 1}'),
                          _kv('BO', _lastSession!.boBaseUrl ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password — single field (issue 2)
                    TextField(
                      controller: _passwordController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _onPasswordConnect(),
                    ),
                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: _busy ? null : _onPasswordConnect,
                      icon: _busy
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('Connect'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showAdvanced = true),
                      child: const Text('Configure (advanced)'),
                    ),
                  ] else ...[
                    // ── Advanced / first-time: full 4-field form
                    if (_lastSession == null) ...[
                      const Text(
                        'No previous session. Configure manually:',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tableIdController,
                      decoration: const InputDecoration(
                        labelText: 'Table ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.table_restaurant),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _boBaseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'BO Base URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _onAdvancedConnect,
                      icon: _busy
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('Connect'),
                    ),
                    if (_lastSession != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _showAdvanced = false),
                        child: const Text('← Back to password-only'),
                      ),
                    ],
                  ],

                  // Error
                  if (authState.status == AuthStatus.error &&
                      authState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authState.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ConnectionStatusIndicator(status: authState.status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(k,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12))),
            Expanded(child: Text(v,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  /// Password-only connect (issue 2 핵심): localStorage 에서 last config 로드 +
  /// 사용자 입력 비번 → POST /auth/login → token → CC 사용.
  Future<void> _onPasswordConnect() async {
    final last = _lastSession;
    if (last == null || last.email == null || last.boBaseUrl == null) {
      _toast('이전 세션 데이터 없음 — Configure 모드 필요');
      return;
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      _toast('비밀번호 필요');
      return;
    }
    await _loginAndAuthenticate(
      email: last.email!,
      password: password,
      boBaseUrl: last.boBaseUrl!,
      tableId: last.tableId ?? 1,
      wsUrl: last.wsUrl ?? '',
    );
  }

  /// Advanced (4-field) connect — first-time / dev path.
  Future<void> _onAdvancedConnect() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final tableId = int.tryParse(_tableIdController.text.trim()) ?? 1;
    final boBase = _boBaseUrlController.text.trim();
    if (email.isEmpty || password.isEmpty || boBase.isEmpty) {
      _toast('Email + Password + BO URL 필수');
      return;
    }
    final wsUrl = _wsUrlController.text.trim().isNotEmpty
        ? _wsUrlController.text.trim()
        : '${boBase.replaceFirst(RegExp(r'^http'), 'ws')}/ws/cc?table_id=$tableId';
    await _loginAndAuthenticate(
      email: email,
      password: password,
      boBaseUrl: boBase,
      tableId: tableId,
      wsUrl: wsUrl,
    );
  }

  Future<void> _loginAndAuthenticate({
    required String email,
    required String password,
    required String boBaseUrl,
    required int tableId,
    required String wsUrl,
  }) async {
    setState(() => _busy = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: boBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      // 2026-05-10: BO v9.5 cascade — auth router moved to /api/v1/auth/*.
      // Lobby was updated; CC was missing this prefix → 404 on Connect.
      final res = await dio.post('/api/v1/auth/login',
          data: {'email': email, 'password': password});
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      final token = data?['accessToken'] as String?;
      if (token == null) {
        throw Exception('Login response missing accessToken');
      }
      // Persist last successful session (without password/token).
      await CcSettingsStorage.saveLastSession(CcLastSession(
        email: email,
        boBaseUrl: boBaseUrl,
        tableId: tableId,
        wsUrl: wsUrl,
      ));

      final config = LaunchConfig(
        tableId: tableId,
        token: token,
        ccInstanceId: 'standalone-${DateTime.now().millisecondsSinceEpoch}',
        wsUrl: wsUrl,
        boBaseUrl: boBaseUrl,
      );
      ref.read(authProvider.notifier).authenticate(config);
    } on DioException catch (e) {
      _toast('인증 실패: HTTP ${e.response?.statusCode ?? '?'}');
    } catch (e) {
      _toast('연결 오류: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
