// Host resolver — conditional import 로 platform 별 host 결정.
//
// Flutter Web: window.location.hostname (브라우저 origin host)
// Mobile/Desktop: 빈 문자열 (caller 가 localhost fallback)
//
// 사용 시점: AppConfig.fromEnvironment() — EBS_BO_HOST 환경변수 미설정 시 fallback.
// 효과: LAN IP `10.10.100.115:3000` 으로 접속한 다른 PC 도 그 PC 가 보는 host
//       기준으로 BO API 호출 → 같은 PC 의 localhost 가 아닌 LAN host 자동 사용.

export 'host_resolver_io.dart' if (dart.library.html) 'host_resolver_web.dart';
