import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum BetStructure {
  noLimit(0, 'No Limit'),
  potLimit(1, 'Pot Limit'),
  fixedLimit(2, 'Fixed Limit');

  const BetStructure(this.value, this.label);

  final int value;
  final String label;
}
