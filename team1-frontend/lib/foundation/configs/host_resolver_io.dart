// Host resolver (Mobile/Desktop) — Flutter Web 이 아닌 platform 에서는
// runtime host / origin 을 결정할 수 없으므로 빈 문자열 반환. caller 가
// host+port mode 로 fallback 처리.

String resolveRuntimeHost() => '';

/// Non-web build 에서는 browser origin 개념이 없으므로 빈 문자열 반환.
/// caller (`AppConfig.fromEnvironment`) 가 host+port mode 로 자동 fallback.
String resolveRuntimeOrigin() => '';
