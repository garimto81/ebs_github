// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitionImpl _$$CompetitionImplFromJson(Map<String, dynamic> json) =>
    _$CompetitionImpl(
      competitionId: (json['competition_id'] as num).toInt(),
      name: json['name'] as String,
      competitionType: (json['competition_type'] as num).toInt(),
      competitionTag: (json['competition_tag'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$CompetitionImplToJson(_$CompetitionImpl instance) =>
    <String, dynamic>{
      'competition_id': instance.competitionId,
      'name': instance.name,
      'competition_type': instance.competitionType,
      'competition_tag': instance.competitionTag,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
