import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum TableStatus {
  empty('empty'),
  setup('setup'),
  live('live'),
  paused('paused'),
  closed('closed');

  const TableStatus(this.value);

  final String value;
}
