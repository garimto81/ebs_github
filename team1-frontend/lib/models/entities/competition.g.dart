// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitionImpl _$$CompetitionImplFromJson(Map<String, dynamic> json) =>
    _$CompetitionImpl(
      competitionId: (json['competitionId'] as num).toInt(),
      name: json['name'] as String,
      competitionType: (json['competitionType'] as num).toInt(),
      competitionTag: (json['competitionTag'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$CompetitionImplToJson(_$CompetitionImpl instance) =>
    <String, dynamic>{
      'competitionId': instance.competitionId,
      'name': instance.name,
      'competitionType': instance.competitionType,
      'competitionTag': instance.competitionTag,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
