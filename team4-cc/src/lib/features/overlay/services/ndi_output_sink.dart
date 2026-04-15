// NdiOutputSink — platform-channel boundary for the NDI broadcast output.
//
// EBS needs two concurrent overlay outputs:
//   * Backstage (HDMI, zero delay, operator-facing)
//   * Broadcast (NDI or HDMI-to-capture, with Security Delay applied)
//
// The NDI SDK is a C/C++ library distributed by NewTek; integrating it
// means wiring a MethodChannel to a native plugin. That plugin is
// Phase 2 platform work. This file defines the **Dart-side interface**
// so the rest of the app is already wired correctly and the platform
// implementation is the only remaining piece.
//
// Until the platform channel is shipped, [StubNdiOutputSink] is registered
// by default. It logs on every frame so integration tests can observe
// intended behavior without any native dependency.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('NdiOutputSink');

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

/// Abstraction over the NDI broadcast output. Implementations either
/// bind to the native NDI SDK via a MethodChannel or provide a no-op
/// stub for testing and non-broadcast builds.
abstract class NdiOutputSink {
  /// Whether the sink currently has a receiver connected.
  bool get isActive;

  /// Opens the NDI stream with the given name.
  ///
  /// Streaming is ready when the returned Future completes without error.
  /// Implementations may choose to throttle [send] calls before the
  /// stream is fully initialised.
  Future<void> open(String streamName);

  /// Sends one game-state frame to the NDI receiver.
  ///
  /// Content is a JSON-serializable map representing the broadcast render
  /// state after Security Delay has been applied. Native side is
  /// responsible for rasterisation + alpha channel encoding.
  Future<void> send(Map<String, dynamic> frame);

  /// Closes the NDI stream cleanly.
  Future<void> close();
}

// ---------------------------------------------------------------------------
// Platform-channel implementation (wired to Phase 2 native plugin)
// ---------------------------------------------------------------------------

class MethodChannelNdiOutputSink implements NdiOutputSink {
  MethodChannelNdiOutputSink([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('ebs/ndi_output');

  final MethodChannel _channel;
  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  Future<void> open(String streamName) async {
    try {
      await _channel.invokeMethod<void>('open', {'stream_name': streamName});
      _active = true;
    } on MissingPluginException catch (e) {
      _log.warning(
        'NDI platform plugin not installed; broadcast output inactive. '
        'Install the ebs_ndi platform plugin or keep StubNdiOutputSink. '
        '($e)',
      );
      _active = false;
    }
  }

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_active) return;
    await _channel.invokeMethod<void>('send', frame);
  }

  @override
  Future<void> close() async {
    _active = false;
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // already warned during open
    }
  }
}

// ---------------------------------------------------------------------------
// Stub implementation (default in Phase 1 / tests)
// ---------------------------------------------------------------------------

class StubNdiOutputSink implements NdiOutputSink {
  StubNdiOutputSink({this.logFrames = false});
  final bool logFrames;
  bool _active = false;
  int _frameCount = 0;

  int get frameCount => _frameCount;

  @override
  bool get isActive => _active;

  @override
  Future<void> open(String streamName) async {
    _log.info('stub NDI stream "$streamName" opened.');
    _active = true;
  }

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_active) return;
    _frameCount++;
    if (logFrames) {
      _log.fine('stub NDI frame #$_frameCount keys=${frame.keys.toList()}');
    }
  }

  @override
  Future<void> close() async {
    _active = false;
    _log.info('stub NDI stream closed after $_frameCount frames.');
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Default NDI sink. Swap at runtime via `overrideWithValue` for tests
/// or when the platform plugin is present.
final ndiOutputSinkProvider = Provider<NdiOutputSink>((ref) {
  return StubNdiOutputSink();
});
