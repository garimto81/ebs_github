// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      totpEnabled: json['totpEnabled'] as bool,
      lastLoginAt: json['lastLoginAt'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'displayName': instance.displayName,
      'role': instance.role,
      'isActive': instance.isActive,
      'totpEnabled': instance.totpEnabled,
      'lastLoginAt': instance.lastLoginAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
