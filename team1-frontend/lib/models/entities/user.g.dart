// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      userId: (json['user_id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      totpEnabled: json['totp_enabled'] as bool,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'display_name': instance.displayName,
      'role': instance.role,
      'is_active': instance.isActive,
      'totp_enabled': instance.totpEnabled,
      'last_login_at': instance.lastLoginAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
