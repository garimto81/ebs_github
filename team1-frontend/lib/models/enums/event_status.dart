import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum EventStatus {
  created('created'),
  announced('announced'),
  registering('registering'),
  running('running'),
  completed('completed');

  const EventStatus(this.value);

  final String value;
}
