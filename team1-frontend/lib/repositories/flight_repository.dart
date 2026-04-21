import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class FlightRepository {
  FlightRepository(this._client);
  final BoApiClient _client;

  Future<List<EventFlight>> listFlights({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<EventFlight>>(
      '/Flights',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => EventFlight.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<EventFlight>> listByEvent(int eventId) async {
    return _client.get<List<EventFlight>>(
      '/Events/$eventId/Flights',
      fromJson: (json) => (json as List)
          .map((e) => EventFlight.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<EventFlight> getFlight(int id) async {
    return _client.get<EventFlight>(
      '/Flights/$id',
      fromJson: (json) => EventFlight.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EventFlight> createFlight(Map<String, dynamic> data) async {
    return _client.post<EventFlight>(
      '/Flights',
      data: data,
      fromJson: (json) => EventFlight.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EventFlight> updateFlight(int id, Map<String, dynamic> data) async {
    return _client.put<EventFlight>(
      '/Flights/$id',
      data: data,
      fromJson: (json) => EventFlight.fromJson(json as Map<String, dynamic>),
    );
  }
}

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  return FlightRepository(ref.watch(boApiClientProvider));
});
