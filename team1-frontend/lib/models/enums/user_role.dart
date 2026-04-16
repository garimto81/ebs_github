import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum UserRole {
  admin('admin'),
  operator('operator'),
  viewer('viewer');

  const UserRole(this.value);

  final String value;
}
