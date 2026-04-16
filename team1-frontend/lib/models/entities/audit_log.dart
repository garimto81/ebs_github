import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'entity_type') required String entityType,
    @JsonKey(name: 'entity_id') int? entityId,
    required String action,
    String? detail,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
