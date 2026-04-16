import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum SkinStatus {
  draft('draft'),
  validated('validated'),
  active('active'),
  archived('archived');

  const SkinStatus(this.value);

  final String value;
}
