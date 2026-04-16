import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum SeatStatus {
  vacant('vacant'),
  occupied('occupied'),
  busted('busted');

  const SeatStatus(this.value);

  final String value;
}
