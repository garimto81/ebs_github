import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';

/// Payout structure entity — lightweight map-based until a dedicated
/// Freezed model is warranted.
class PayoutStructure {
  final int payoutStructureId;
  final String name;
  final Map<String, dynamic> raw;

  const PayoutStructure({
    required this.payoutStructureId,
    required this.name,
    required this.raw,
  });

  factory PayoutStructure.fromJson(Map<String, dynamic> json) =>
      PayoutStructure(
        payoutStructureId: json['payout_structure_id'] as int,
        name: json['name'] as String,
        raw: json,
      );

  Map<String, dynamic> toJson() => raw;
}

class PayoutStructureRepository {
  PayoutStructureRepository(this._client);
  final BoApiClient _client;

  // Backend_HTTP.md §PayoutStructure: series-nested CRUD.
  // Flight 적용 Payout는 /flights/:id/payout-structure 별도 경로 (team2 소유).

  // V9.5 SSOT 정합: BO 가 flat /payout-structures 채택 (series-scope 폐기).
  // seriesId 는 query param 또는 body field 로 전달. method signature 는 caller
  // 영향 최소화 위해 보존.

  Future<List<PayoutStructure>> listPayoutStructures(
    int seriesId, {
    Map<String, dynamic>? params,
  }) async {
    final mergedParams = <String, dynamic>{
      'series_id': seriesId,
      ...?params,
    };
    return _client.get<List<PayoutStructure>>(
      '/payout-structures',
      queryParameters: mergedParams,
      fromJson: (json) => (json as List)
          .map((e) => PayoutStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PayoutStructure> getPayoutStructure(int seriesId, int psId) async {
    // seriesId 는 caller compatibility 보존용. BO path 는 flat.
    return _client.get<PayoutStructure>(
      '/payout-structures/$psId',
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PayoutStructure> createPayoutStructure(
    int seriesId,
    Map<String, dynamic> data,
  ) async {
    final body = <String, dynamic>{
      'series_id': seriesId,
      ...data,
    };
    return _client.post<PayoutStructure>(
      '/payout-structures',
      data: body,
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PayoutStructure> updatePayoutStructure(
    int seriesId,
    int psId,
    Map<String, dynamic> data,
  ) async {
    return _client.put<PayoutStructure>(
      '/payout-structures/$psId',
      data: data,
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deletePayoutStructure(int seriesId, int psId) async {
    await _client.delete<dynamic>('/payout-structures/$psId');
  }
}

final payoutStructureRepositoryProvider =
    Provider<PayoutStructureRepository>((ref) {
  return PayoutStructureRepository(ref.watch(boApiClientProvider));
});
