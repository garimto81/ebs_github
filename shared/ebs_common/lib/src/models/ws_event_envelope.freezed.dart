// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ws_event_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WsEventEnvelope _$WsEventEnvelopeFromJson(Map<String, dynamic> json) {
  return _WsEventEnvelope.fromJson(json);
}

/// @nodoc
mixin _$WsEventEnvelope {
  int get seq => throw _privateConstructorUsedError;
  String get channel => throw _privateConstructorUsedError;
  String get event => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  String get ts => throw _privateConstructorUsedError;

  /// Serializes this WsEventEnvelope to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WsEventEnvelope
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WsEventEnvelopeCopyWith<WsEventEnvelope> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WsEventEnvelopeCopyWith<$Res> {
  factory $WsEventEnvelopeCopyWith(
          WsEventEnvelope value, $Res Function(WsEventEnvelope) then) =
      _$WsEventEnvelopeCopyWithImpl<$Res, WsEventEnvelope>;
  @useResult
  $Res call(
      {int seq,
      String channel,
      String event,
      Map<String, dynamic> payload,
      String ts});
}

/// @nodoc
class _$WsEventEnvelopeCopyWithImpl<$Res, $Val extends WsEventEnvelope>
    implements $WsEventEnvelopeCopyWith<$Res> {
  _$WsEventEnvelopeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WsEventEnvelope
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seq = null,
    Object? channel = null,
    Object? event = null,
    Object? payload = null,
    Object? ts = null,
  }) {
    return _then(_value.copyWith(
      seq: null == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as String,
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WsEventEnvelopeImplCopyWith<$Res>
    implements $WsEventEnvelopeCopyWith<$Res> {
  factory _$$WsEventEnvelopeImplCopyWith(_$WsEventEnvelopeImpl value,
          $Res Function(_$WsEventEnvelopeImpl) then) =
      __$$WsEventEnvelopeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int seq,
      String channel,
      String event,
      Map<String, dynamic> payload,
      String ts});
}

/// @nodoc
class __$$WsEventEnvelopeImplCopyWithImpl<$Res>
    extends _$WsEventEnvelopeCopyWithImpl<$Res, _$WsEventEnvelopeImpl>
    implements _$$WsEventEnvelopeImplCopyWith<$Res> {
  __$$WsEventEnvelopeImplCopyWithImpl(
      _$WsEventEnvelopeImpl _value, $Res Function(_$WsEventEnvelopeImpl) _then)
      : super(_value, _then);

  /// Create a copy of WsEventEnvelope
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seq = null,
    Object? channel = null,
    Object? event = null,
    Object? payload = null,
    Object? ts = null,
  }) {
    return _then(_$WsEventEnvelopeImpl(
      seq: null == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as String,
      event: null == event
          ? _value.event
          : event // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      ts: null == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WsEventEnvelopeImpl implements _WsEventEnvelope {
  const _$WsEventEnvelopeImpl(
      {required this.seq,
      required this.channel,
      required this.event,
      required final Map<String, dynamic> payload,
      required this.ts})
      : _payload = payload;

  factory _$WsEventEnvelopeImpl.fromJson(Map<String, dynamic> json) =>
      _$$WsEventEnvelopeImplFromJson(json);

  @override
  final int seq;
  @override
  final String channel;
  @override
  final String event;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final String ts;

  @override
  String toString() {
    return 'WsEventEnvelope(seq: $seq, channel: $channel, event: $event, payload: $payload, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WsEventEnvelopeImpl &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.event, event) || other.event == event) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.ts, ts) || other.ts == ts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, seq, channel, event,
      const DeepCollectionEquality().hash(_payload), ts);

  /// Create a copy of WsEventEnvelope
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WsEventEnvelopeImplCopyWith<_$WsEventEnvelopeImpl> get copyWith =>
      __$$WsEventEnvelopeImplCopyWithImpl<_$WsEventEnvelopeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WsEventEnvelopeImplToJson(
      this,
    );
  }
}

abstract class _WsEventEnvelope implements WsEventEnvelope {
  const factory _WsEventEnvelope(
      {required final int seq,
      required final String channel,
      required final String event,
      required final Map<String, dynamic> payload,
      required final String ts}) = _$WsEventEnvelopeImpl;

  factory _WsEventEnvelope.fromJson(Map<String, dynamic> json) =
      _$WsEventEnvelopeImpl.fromJson;

  @override
  int get seq;
  @override
  String get channel;
  @override
  String get event;
  @override
  Map<String, dynamic> get payload;
  @override
  String get ts;

  /// Create a copy of WsEventEnvelope
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WsEventEnvelopeImplCopyWith<_$WsEventEnvelopeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
