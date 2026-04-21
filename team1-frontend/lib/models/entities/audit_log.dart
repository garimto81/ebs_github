import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    required int id,
    @JsonKey(name: 'userId') required int userId,
    @JsonKey(name: 'entityType') required String entityType,
    @JsonKey(name: 'entityId') int? entityId,
    required String action,
    String? detail,
    @JsonKey(name: 'ipAddress') String? ipAddress,
    @JsonKey(name: 'createdAt') required String createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
