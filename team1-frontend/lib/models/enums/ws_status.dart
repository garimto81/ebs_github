import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum WsStatus {
  connecting('connecting'),
  connected('connected'),
  disconnected('disconnected'),
  reconnecting('reconnecting'),
  error('error');

  const WsStatus(this.value);

  final String value;
}
