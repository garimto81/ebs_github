// Audio Channel Pool (CCR-033, BS-07-05 §Multi-channel architecture).
//
// 3 fixed channels: BGM, Effect #1, Effect #2.
// Dynamic Temp channel creation when both Effect channels are busy.
// Uses just_audio package for cross-platform audio playback.

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

final _log = Logger('ChannelPool');

// ---------------------------------------------------------------------------
// Channel identifiers
// ---------------------------------------------------------------------------

enum AudioChannel { bgm, effect1, effect2 }

// ---------------------------------------------------------------------------
// Channel Pool
// ---------------------------------------------------------------------------

class ChannelPool {
  ChannelPool() {
    _players = {
      AudioChannel.bgm: AudioPlayer(),
      AudioChannel.effect1: AudioPlayer(),
      AudioChannel.effect2: AudioPlayer(),
    };
  }

  late final Map<AudioChannel, AudioPlayer> _players;

  /// Temp channel pool for overflow when both effect channels are busy.
  final List<AudioPlayer> _tempPlayers = [];
  static const _maxTempChannels = 4;

  bool _muted = false;
  bool get isMuted => _muted;

  final Map<AudioChannel, double> _volumes = {
    AudioChannel.bgm: 0.3,
    AudioChannel.effect1: 0.8,
    AudioChannel.effect2: 0.8,
  };

  double _masterVolume = 0.7;
  double get masterVolume => _masterVolume;

  // -- Playback -------------------------------------------------------------

  /// Play an asset on the specified channel.
  ///
  /// For BGM: loops continuously.
  /// For Effects: plays once.
  Future<void> play(AudioChannel channel, String assetPath) async {
    final player = _players[channel];
    if (player == null) return;

    try {
      await player.setAsset(assetPath);
      await player.setVolume(_effectiveVolume(channel));

      if (channel == AudioChannel.bgm) {
        await player.setLoopMode(LoopMode.one);
      } else {
        await player.setLoopMode(LoopMode.off);
      }

      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      _log.warning('Failed to play $assetPath on $channel: $e');
    }
  }

  /// Play a sound effect, auto-selecting an available effect channel.
  ///
  /// Tries Effect #1, then Effect #2, then allocates a temp channel.
  Future<void> playSfx(String assetPath) async {
    // Try Effect #1
    if (!_isPlaying(AudioChannel.effect1)) {
      await play(AudioChannel.effect1, assetPath);
      return;
    }

    // Try Effect #2
    if (!_isPlaying(AudioChannel.effect2)) {
      await play(AudioChannel.effect2, assetPath);
      return;
    }

    // Both busy — use temp channel
    await _playOnTemp(assetPath);
  }

  /// Stop playback on a channel.
  Future<void> stop(AudioChannel channel) async {
    await _players[channel]?.stop();
  }

  /// Pause playback on a channel.
  Future<void> pause(AudioChannel channel) async {
    await _players[channel]?.pause();
  }

  /// Resume playback on a channel.
  Future<void> resume(AudioChannel channel) async {
    await _players[channel]?.play();
  }

  // -- Volume ---------------------------------------------------------------

  /// Set volume for a specific channel (0.0 to 1.0).
  Future<void> setVolume(AudioChannel channel, double volume) async {
    _volumes[channel] = volume.clamp(0.0, 1.0);
    await _players[channel]?.setVolume(_effectiveVolume(channel));
  }

  /// Set master volume (0.0 to 1.0).
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    for (final channel in AudioChannel.values) {
      await _players[channel]?.setVolume(_effectiveVolume(channel));
    }
  }

  /// Toggle global mute.
  Future<void> toggleMute() async {
    _muted = !_muted;
    for (final channel in AudioChannel.values) {
      await _players[channel]?.setVolume(_effectiveVolume(channel));
    }
    for (final player in _tempPlayers) {
      await player.setVolume(_muted ? 0.0 : _masterVolume * 0.8);
    }
  }

  double _effectiveVolume(AudioChannel channel) {
    if (_muted) return 0.0;
    return _masterVolume * (_volumes[channel] ?? 0.5);
  }

  // -- Temp channel management ----------------------------------------------

  Future<void> _playOnTemp(String assetPath) async {
    // Reclaim finished temp players
    _tempPlayers.removeWhere(
      (p) => p.processingState == ProcessingState.completed,
    );

    if (_tempPlayers.length >= _maxTempChannels) {
      _log.warning('All temp channels busy, dropping SFX: $assetPath');
      return;
    }

    final player = AudioPlayer();
    _tempPlayers.add(player);

    try {
      await player.setAsset(assetPath);
      await player.setVolume(_muted ? 0.0 : _masterVolume * 0.8);
      await player.setLoopMode(LoopMode.off);
      await player.play();

      // Auto-dispose when done
      player.processingStateStream
          .where((s) => s == ProcessingState.completed)
          .first
          .then((_) {
        player.dispose();
        _tempPlayers.remove(player);
      });
    } catch (e) {
      _log.warning('Failed to play temp SFX $assetPath: $e');
      player.dispose();
      _tempPlayers.remove(player);
    }
  }

  bool _isPlaying(AudioChannel channel) {
    final player = _players[channel];
    if (player == null) return false;
    return player.playing &&
        player.processingState != ProcessingState.completed;
  }

  // -- Dispose --------------------------------------------------------------

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    for (final player in _tempPlayers) {
      await player.dispose();
    }
    _tempPlayers.clear();
  }
}
