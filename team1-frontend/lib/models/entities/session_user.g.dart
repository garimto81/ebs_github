// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionUserImpl _$$SessionUserImplFromJson(Map<String, dynamic> json) =>
    _$SessionUserImpl(
      userId: (json['user_id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String,
      permissions: (json['permissions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      tableIds: (json['table_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SessionUserImplToJson(_$SessionUserImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'display_name': instance.displayName,
      'role': instance.role,
      'permissions': instance.permissions,
      'table_ids': instance.tableIds,
    };
