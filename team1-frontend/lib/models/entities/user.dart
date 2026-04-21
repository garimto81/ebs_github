import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'userId') required int userId,
    required String email,
    @JsonKey(name: 'displayName') required String displayName,
    required String role,
    @JsonKey(name: 'isActive') required bool isActive,
    @JsonKey(name: 'totpEnabled') required bool totpEnabled,
    @JsonKey(name: 'lastLoginAt') String? lastLoginAt,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
