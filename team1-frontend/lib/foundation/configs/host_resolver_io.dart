// Host resolver (Mobile/Desktop) — Flutter Web 이 아닌 platform 에서는
// runtime host 를 결정할 수 없으므로 빈 문자열 반환. caller 가 localhost
// fallback 처리.

String resolveRuntimeHost() => '';
