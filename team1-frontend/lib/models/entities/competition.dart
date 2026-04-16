import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';
part 'competition.g.dart';

@freezed
class Competition with _$Competition {
  const factory Competition({
    @JsonKey(name: 'competition_id') required int competitionId,
    required String name,
    @JsonKey(name: 'competition_type') required int competitionType,
    @JsonKey(name: 'competition_tag') required int competitionTag,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Competition;

  factory Competition.fromJson(Map<String, dynamic> json) =>
      _$CompetitionFromJson(json);
}
