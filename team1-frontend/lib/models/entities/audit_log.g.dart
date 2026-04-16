// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuditLogImpl _$$AuditLogImplFromJson(Map<String, dynamic> json) =>
    _$AuditLogImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      entityType: json['entity_type'] as String,
      entityId: (json['entity_id'] as num?)?.toInt(),
      action: json['action'] as String,
      detail: json['detail'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$AuditLogImplToJson(_$AuditLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'action': instance.action,
      'detail': instance.detail,
      'ip_address': instance.ipAddress,
      'created_at': instance.createdAt,
    };
