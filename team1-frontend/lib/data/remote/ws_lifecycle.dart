// lib/data/remote/ws_lifecycle.dart
//
// G-4 교정: Lobby WebSocket 의 connect/disconnect 를 auth 상태에 동기화한다.
//
// 라이프사이클 규칙
// 1) auth.status == authenticated  → connect()
// 2) auth.status != authenticated  → disconnect()
// 3) accessToken 변화 (refresh)    → 재연결 (close → reconnect with new token)
// 4) Provider dispose              → disconnect + dispose
//
// `connect()`는 화면 코드에서 호출하지 않는다. 화면은 wsConnectionStateProvider
// 만 watch.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import 'ws_provider.dart';

/// Auth 상태 기반 WS connect/disconnect 컨트롤러.
///
/// 단순 [Provider] — 부팅 시 watch 되어 lazy 하게 활성화된다.
/// 내부에서 ref.listen 으로 auth 변화를 추적하므로 결과값은 의미 없음.
final lobbyWsLifecycleProvider = Provider<void>((ref) {
  final client = ref.watch(lobbyWsClientProvider);

  String? lastToken;

  void apply(AuthState s) {
    final isAuth = s.status == AuthStatus.authenticated;
    final tokenChanged = s.accessToken != lastToken;

    if (isAuth && (tokenChanged || lastToken == null)) {
      // close → reopen 으로 새 토큰 반영.
      client.disconnect();
      lastToken = s.accessToken;
      client.connect();
    } else if (!isAuth && lastToken != null) {
      client.disconnect();
      lastToken = null;
    }
  }

  // 초기 상태 즉시 적용.
  apply(ref.read(authProvider));

  // 이후 변화 추적.
  final sub = ref.listen<AuthState>(
    authProvider,
    (_, next) => apply(next),
  );

  ref.onDispose(() {
    sub.close();
    client.disconnect();
  });
});
