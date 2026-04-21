import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/bo_api_client.dart';
import '../models/models.dart';

class EventRepository {
  EventRepository(this._client);
  final BoApiClient _client;

  Future<List<EbsEvent>> listEvents({
    Map<String, dynamic>? params,
  }) async {
    return _client.get<List<EbsEvent>>(
      '/Events',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => EbsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<EbsEvent> getEvent(int id) async {
    return _client.get<EbsEvent>(
      '/Events/$id',
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsEvent> createEvent(Map<String, dynamic> data) async {
    return _client.post<EbsEvent>(
      '/Events',
      data: data,
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsEvent> updateEvent(int id, Map<String, dynamic> data) async {
    return _client.put<EbsEvent>(
      '/Events/$id',
      data: data,
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteEvent(int id) async {
    await _client.delete<dynamic>('/Events/$id');
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(boApiClientProvider));
});
