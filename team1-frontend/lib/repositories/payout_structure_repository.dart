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

  Future<List<PayoutStructure>> listPayoutStructures({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<PayoutStructure>>(
      '/payout-structures',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => PayoutStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PayoutStructure> getPayoutStructure(int id) async {
    return _client.get<PayoutStructure>(
      '/payout-structures/$id',
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PayoutStructure> createPayoutStructure(
    Map<String, dynamic> data,
  ) async {
    return _client.post<PayoutStructure>(
      '/payout-structures',
      data: data,
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PayoutStructure> updatePayoutStructure(
    int id,
    Map<String, dynamic> data,
  ) async {
    return _client.put<PayoutStructure>(
      '/payout-structures/$id',
      data: data,
      fromJson: (json) =>
          PayoutStructure.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deletePayoutStructure(int id) async {
    await _client.delete<dynamic>('/payout-structures/$id');
  }
}

final payoutStructureRepositoryProvider =
    Provider<PayoutStructureRepository>((ref) {
  return PayoutStructureRepository(ref.watch(boApiClientProvider));
});
