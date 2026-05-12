// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuditLogImpl _$$AuditLogImplFromJson(Map<String, dynamic> json) =>
    _$AuditLogImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      entityType: json['entityType'] as String,
      entityId: (json['entityId'] as num?)?.toInt(),
      action: json['action'] as String,
      detail: json['detail'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$AuditLogImplToJson(_$AuditLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'entityType': instance.entityType,
      if (instance.entityId case final value?) 'entityId': value,
      'action': instance.action,
      if (instance.detail case final value?) 'detail': value,
      if (instance.ipAddress case final value?) 'ipAddress': value,
      'createdAt': instance.createdAt,
    };
