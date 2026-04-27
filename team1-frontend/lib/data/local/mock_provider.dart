// lib/data/local/mock_provider.dart
//
// G-2 교정: Dio 인스턴스 single-source-of-truth 통합.
// 이전엔 dioProvider 가 createDio 로 별도 Dio 를 만들어 boApiClientProvider
// 와 분기되었으나, 이제 boApiClientProvider 의 .raw 를 위임만 한다.
// useMock 토글, 인터셉터 체인, 토큰 주입 모두 boApiClient 에서 일원화.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../remote/bo_api_client.dart';

/// 단일 source: boApiClientProvider 가 만든 Dio 만 노출.
///
/// 신규 코드는 가능하면 [boApiClientProvider] 를 직접 watch 할 것.
/// 본 provider 는 외부 패키지 호환을 위한 어댑터 역할.
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(boApiClientProvider).raw;
});
