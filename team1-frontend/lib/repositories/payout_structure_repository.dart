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

  Future<List<PayoutStructure>> listPayoutStructures(
    int seriesId, {
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<PayoutStructure>>(
      '/series/$seriesId/payout-structures',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => PayoutStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PayoutStructure> getPayoutStructure(int seriesId, int psId) async {
    return _client.get<PayoutStructure>(
      '/series/$seriesId/payout-structures/$psId',
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PayoutStructure> createPayoutStructure(
    int seriesId,
    Map<String, dynamic> data,
  ) async {
    return _client.post<PayoutStructure>(
      '/series/$seriesId/payout-structures',
      data: data,
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
      '/series/$seriesId/payout-structures/$psId',
      data: data,
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deletePayoutStructure(int seriesId, int psId) async {
    await _client.delete<dynamic>(
      '/series/$seriesId/payout-structures/$psId',
    );
  }
}

final payoutStructureRepositoryProvider =
    Provider<PayoutStructureRepository>((ref) {
  return PayoutStructureRepository(ref.watch(boApiClientProvider));
});
