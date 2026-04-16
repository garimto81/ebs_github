// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hand_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HandAction _$HandActionFromJson(Map<String, dynamic> json) {
  return _HandAction.fromJson(json);
}

/// @nodoc
mixin _$HandAction {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'hand_id')
  int get handId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seat_no')
  int get seatNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_type')
  String get actionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_amount')
  int get actionAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'pot_after')
  int? get potAfter => throw _privateConstructorUsedError;
  String get street => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_order')
  int get actionOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'board_cards')
  String? get boardCards => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_time')
  String? get actionTime => throw _privateConstructorUsedError;

  /// Serializes this HandAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HandAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandActionCopyWith<HandAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandActionCopyWith<$Res> {
  factory $HandActionCopyWith(
          HandAction value, $Res Function(HandAction) then) =
      _$HandActionCopyWithImpl<$Res, HandAction>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'hand_id') int handId,
      @JsonKey(name: 'seat_no') int seatNo,
      @JsonKey(name: 'action_type') String actionType,
      @JsonKey(name: 'action_amount') int actionAmount,
      @JsonKey(name: 'pot_after') int? potAfter,
      String street,
      @JsonKey(name: 'action_order') int actionOrder,
      @JsonKey(name: 'board_cards') String? boardCards,
      @JsonKey(name: 'action_time') String? actionTime});
}

/// @nodoc
class _$HandActionCopyWithImpl<$Res, $Val extends HandAction>
    implements $HandActionCopyWith<$Res> {
  _$HandActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HandAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handId = null,
    Object? seatNo = null,
    Object? actionType = null,
    Object? actionAmount = null,
    Object? potAfter = freezed,
    Object? street = null,
    Object? actionOrder = null,
    Object? boardCards = freezed,
    Object? actionTime = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      actionAmount: null == actionAmount
          ? _value.actionAmount
          : actionAmount // ignore: cast_nullable_to_non_nullable
              as int,
      potAfter: freezed == potAfter
          ? _value.potAfter
          : potAfter // ignore: cast_nullable_to_non_nullable
              as int?,
      street: null == street
          ? _value.street
          : street // ignore: cast_nullable_to_non_nullable
              as String,
      actionOrder: null == actionOrder
          ? _value.actionOrder
          : actionOrder // ignore: cast_nullable_to_non_nullable
              as int,
      boardCards: freezed == boardCards
          ? _value.boardCards
          : boardCards // ignore: cast_nullable_to_non_nullable
              as String?,
      actionTime: freezed == actionTime
          ? _value.actionTime
          : actionTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HandActionImplCopyWith<$Res>
    implements $HandActionCopyWith<$Res> {
  factory _$$HandActionImplCopyWith(
          _$HandActionImpl value, $Res Function(_$HandActionImpl) then) =
      __$$HandActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'hand_id') int handId,
      @JsonKey(name: 'seat_no') int seatNo,
      @JsonKey(name: 'action_type') String actionType,
      @JsonKey(name: 'action_amount') int actionAmount,
      @JsonKey(name: 'pot_after') int? potAfter,
      String street,
      @JsonKey(name: 'action_order') int actionOrder,
      @JsonKey(name: 'board_cards') String? boardCards,
      @JsonKey(name: 'action_time') String? actionTime});
}

/// @nodoc
class __$$HandActionImplCopyWithImpl<$Res>
    extends _$HandActionCopyWithImpl<$Res, _$HandActionImpl>
    implements _$$HandActionImplCopyWith<$Res> {
  __$$HandActionImplCopyWithImpl(
      _$HandActionImpl _value, $Res Function(_$HandActionImpl) _then)
      : super(_value, _then);

  /// Create a copy of HandAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handId = null,
    Object? seatNo = null,
    Object? actionType = null,
    Object? actionAmount = null,
    Object? potAfter = freezed,
    Object? street = null,
    Object? actionOrder = null,
    Object? boardCards = freezed,
    Object? actionTime = freezed,
  }) {
    return _then(_$HandActionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      actionAmount: null == actionAmount
          ? _value.actionAmount
          : actionAmount // ignore: cast_nullable_to_non_nullable
              as int,
      potAfter: freezed == potAfter
          ? _value.potAfter
          : potAfter // ignore: cast_nullable_to_non_nullable
              as int?,
      street: null == street
          ? _value.street
          : street // ignore: cast_nullable_to_non_nullable
              as String,
      actionOrder: null == actionOrder
          ? _value.actionOrder
          : actionOrder // ignore: cast_nullable_to_non_nullable
              as int,
      boardCards: freezed == boardCards
          ? _value.boardCards
          : boardCards // ignore: cast_nullable_to_non_nullable
              as String?,
      actionTime: freezed == actionTime
          ? _value.actionTime
          : actionTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HandActionImpl implements _HandAction {
  const _$HandActionImpl(
      {required this.id,
      @JsonKey(name: 'hand_id') required this.handId,
      @JsonKey(name: 'seat_no') required this.seatNo,
      @JsonKey(name: 'action_type') required this.actionType,
      @JsonKey(name: 'action_amount') required this.actionAmount,
      @JsonKey(name: 'pot_after') this.potAfter,
      required this.street,
      @JsonKey(name: 'action_order') required this.actionOrder,
      @JsonKey(name: 'board_cards') this.boardCards,
      @JsonKey(name: 'action_time') this.actionTime});

  factory _$HandActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandActionImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'hand_id')
  final int handId;
  @override
  @JsonKey(name: 'seat_no')
  final int seatNo;
  @override
  @JsonKey(name: 'action_type')
  final String actionType;
  @override
  @JsonKey(name: 'action_amount')
  final int actionAmount;
  @override
  @JsonKey(name: 'pot_after')
  final int? potAfter;
  @override
  final String street;
  @override
  @JsonKey(name: 'action_order')
  final int actionOrder;
  @override
  @JsonKey(name: 'board_cards')
  final String? boardCards;
  @override
  @JsonKey(name: 'action_time')
  final String? actionTime;

  @override
  String toString() {
    return 'HandAction(id: $id, handId: $handId, seatNo: $seatNo, actionType: $actionType, actionAmount: $actionAmount, potAfter: $potAfter, street: $street, actionOrder: $actionOrder, boardCards: $boardCards, actionTime: $actionTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handId, handId) || other.handId == handId) &&
            (identical(other.seatNo, seatNo) || other.seatNo == seatNo) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            (identical(other.actionAmount, actionAmount) ||
                other.actionAmount == actionAmount) &&
            (identical(other.potAfter, potAfter) ||
                other.potAfter == potAfter) &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.actionOrder, actionOrder) ||
                other.actionOrder == actionOrder) &&
            (identical(other.boardCards, boardCards) ||
                other.boardCards == boardCards) &&
            (identical(other.actionTime, actionTime) ||
                other.actionTime == actionTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, handId, seatNo, actionType,
      actionAmount, potAfter, street, actionOrder, boardCards, actionTime);

  /// Create a copy of HandAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandActionImplCopyWith<_$HandActionImpl> get copyWith =>
      __$$HandActionImplCopyWithImpl<_$HandActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HandActionImplToJson(
      this,
    );
  }
}

abstract class _HandAction implements HandAction {
  const factory _HandAction(
          {required final int id,
          @JsonKey(name: 'hand_id') required final int handId,
          @JsonKey(name: 'seat_no') required final int seatNo,
          @JsonKey(name: 'action_type') required final String actionType,
          @JsonKey(name: 'action_amount') required final int actionAmount,
          @JsonKey(name: 'pot_after') final int? potAfter,
          required final String street,
          @JsonKey(name: 'action_order') required final int actionOrder,
          @JsonKey(name: 'board_cards') final String? boardCards,
          @JsonKey(name: 'action_time') final String? actionTime}) =
      _$HandActionImpl;

  factory _HandAction.fromJson(Map<String, dynamic> json) =
      _$HandActionImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'hand_id')
  int get handId;
  @override
  @JsonKey(name: 'seat_no')
  int get seatNo;
  @override
  @JsonKey(name: 'action_type')
  String get actionType;
  @override
  @JsonKey(name: 'action_amount')
  int get actionAmount;
  @override
  @JsonKey(name: 'pot_after')
  int? get potAfter;
  @override
  String get street;
  @override
  @JsonKey(name: 'action_order')
  int get actionOrder;
  @override
  @JsonKey(name: 'board_cards')
  String? get boardCards;
  @override
  @JsonKey(name: 'action_time')
  String? get actionTime;

  /// Create a copy of HandAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandActionImplCopyWith<_$HandActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
