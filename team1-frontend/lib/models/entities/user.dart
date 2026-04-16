import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id') required int userId,
    required String email,
    @JsonKey(name: 'display_name') required String displayName,
    required String role,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'totp_enabled') required bool totpEnabled,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
