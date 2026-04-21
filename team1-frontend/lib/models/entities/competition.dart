import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';
part 'competition.g.dart';

@freezed
class Competition with _$Competition {
  const factory Competition({
    @JsonKey(name: 'competitionId') required int competitionId,
    required String name,
    @JsonKey(name: 'competitionType') required int competitionType,
    @JsonKey(name: 'competitionTag') required int competitionTag,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
  }) = _Competition;

  factory Competition.fromJson(Map<String, dynamic> json) =>
      _$CompetitionFromJson(json);
}
