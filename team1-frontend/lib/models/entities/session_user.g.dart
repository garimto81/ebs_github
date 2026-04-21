// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionUserImpl _$$SessionUserImplFromJson(Map<String, dynamic> json) =>
    _$SessionUserImpl(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: json['role'] as String,
      permissions: (json['permissions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      tableIds: (json['tableIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SessionUserImplToJson(_$SessionUserImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'displayName': instance.displayName,
      'role': instance.role,
      'permissions': instance.permissions,
      'tableIds': instance.tableIds,
    };
