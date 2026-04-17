import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_user.freezed.dart';
part 'session_user.g.dart';

@freezed
class SessionUser with _$SessionUser {
  const factory SessionUser({
    @JsonKey(name: 'user_id') required int userId,
    required String email,
    @JsonKey(name: 'display_name') String? displayName,
    required String role,
    @Default({}) Map<String, int> permissions,
    @JsonKey(name: 'table_ids') @Default([]) List<int> tableIds,
  }) = _SessionUser;

  factory SessionUser.fromJson(Map<String, dynamic> json) =>
      _$SessionUserFromJson(json);
}
