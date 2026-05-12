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
      '/events',
      queryParameters: params,
      fromJson: (json) => (json as List)
          .map((e) => EbsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Cycle 10 (S2 hierarchy wire): nested route uses a path variable instead
  // of a query string, sidestepping the camelCase/snake_case divergence
  // between BO (FastAPI snake_case) and the SSOT Naming_Conventions.md
  // (camelCase JSON).  See docs/2. Development/2.5 Shared/Naming_Conventions.md
  // §1.  BO endpoint: routers/series.py L119 `/series/{series_id}/events`.
  Future<List<EbsEvent>> listBySeries(int seriesId) async {
    return _client.get<List<EbsEvent>>(
      '/series/$seriesId/events',
      fromJson: (json) => (json as List)
          .map((e) => EbsEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<EbsEvent> getEvent(int id) async {
    return _client.get<EbsEvent>(
      '/events/$id',
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsEvent> createEvent(Map<String, dynamic> data) async {
    return _client.post<EbsEvent>(
      '/events',
      data: data,
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<EbsEvent> updateEvent(int id, Map<String, dynamic> data) async {
    return _client.put<EbsEvent>(
      '/events/$id',
      data: data,
      fromJson: (json) => EbsEvent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteEvent(int id) async {
    await _client.delete<dynamic>('/events/$id');
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(boApiClientProvider));
});
