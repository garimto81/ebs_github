// AudioPlayerProvider — SFX trigger mapping (BS-07-05, CCR-033).
//
// Maps game events to sound effects using the ChannelPool.
// See BS-07-05-audio.md event→sound table and
// WSOP Fatima.app Audio Player Provider reference.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'channel_pool.dart';

// ---------------------------------------------------------------------------
// SFX identifiers (BS-07-05 event→sound mapping)
// ---------------------------------------------------------------------------

enum SfxId {
  actionBeep,       // Generic action confirmation beep
  alertChime,       // Alert/notification chime
  foldSound,        // Player fold
  allInDramatic,    // All-in dramatic sting
  cardDeal,         // Card deal whoosh
  potWin,           // Pot awarded fanfare
  timerWarning,     // Shot clock warning beep
  disconnectAlert,  // Connection lost alert
  chipSlide,        // Betting token slide
  checkTap,         // Check/tap sound
  newHandShuffle,   // New hand shuffle
  showdownReveal,   // Showdown card reveal
}

// ---------------------------------------------------------------------------
// SFX asset path mapping
// ---------------------------------------------------------------------------

const _sfxAssets = <SfxId, String>{
  SfxId.actionBeep: 'assets/audio/sfx/action_beep.mp3',
  SfxId.alertChime: 'assets/audio/sfx/alert_chime.mp3',
  SfxId.foldSound: 'assets/audio/sfx/fold.mp3',
  SfxId.allInDramatic: 'assets/audio/sfx/all_in.mp3',
  SfxId.cardDeal: 'assets/audio/sfx/card_deal.mp3',
  SfxId.potWin: 'assets/audio/sfx/pot_win.mp3',
  SfxId.timerWarning: 'assets/audio/sfx/timer_warning.mp3',
  SfxId.disconnectAlert: 'assets/audio/sfx/disconnect.mp3',
  SfxId.chipSlide: 'assets/audio/sfx/chip_slide.mp3',
  SfxId.checkTap: 'assets/audio/sfx/check_tap.mp3',
  SfxId.newHandShuffle: 'assets/audio/sfx/shuffle.mp3',
  SfxId.showdownReveal: 'assets/audio/sfx/showdown.mp3',
};

// ---------------------------------------------------------------------------
// Audio SFX port — narrow interface for consumers that only need to fire
// sound effects. Lets tests inject a silent double without constructing a
// real ChannelPool / just_audio platform channel.
// ---------------------------------------------------------------------------

abstract class AudioSfxPort {
  Future<void> playSfx(SfxId sfx);
}

// ---------------------------------------------------------------------------
// Audio controller (wraps ChannelPool with SFX mapping)
// ---------------------------------------------------------------------------

class AudioController implements AudioSfxPort {
  AudioController({required ChannelPool channelPool})
      : _pool = channelPool;

  final ChannelPool _pool;

  bool _enabled = true;
  bool get isEnabled => _enabled;

  /// Play a sound effect by ID.
  Future<void> playSfx(SfxId sfx) async {
    if (!_enabled) return;
    final path = _sfxAssets[sfx];
    if (path == null) return;
    await _pool.playSfx(path);
  }

  /// Play BGM track.
  Future<void> playBgm(String assetPath) async {
    if (!_enabled) return;
    await _pool.play(AudioChannel.bgm, assetPath);
  }

  /// Stop BGM.
  Future<void> stopBgm() async {
    await _pool.stop(AudioChannel.bgm);
  }

  /// Toggle mute.
  Future<void> toggleMute() async {
    await _pool.toggleMute();
  }

  /// Enable/disable audio entirely.
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _pool.toggleMute(); // mute when disabled
    }
  }

  /// Set master volume.
  Future<void> setMasterVolume(double volume) async {
    await _pool.setMasterVolume(volume);
  }

  /// Set BGM mix level.
  Future<void> setBgmVolume(double volume) async {
    await _pool.setVolume(AudioChannel.bgm, volume);
  }

  /// Set SFX mix level (applies to both effect channels).
  Future<void> setSfxVolume(double volume) async {
    await _pool.setVolume(AudioChannel.effect1, volume);
    await _pool.setVolume(AudioChannel.effect2, volume);
  }

  /// Dispose underlying channel pool.
  Future<void> dispose() async {
    await _pool.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final channelPoolProvider = Provider<ChannelPool>((ref) {
  final pool = ChannelPool();
  ref.onDispose(pool.dispose);
  return pool;
});

final audioControllerProvider = Provider<AudioController>((ref) {
  final pool = ref.watch(channelPoolProvider);
  final controller = AudioController(channelPool: pool);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Narrow SFX port used by dispatchers / providers that only need
/// playSfx. Defaults to the full [AudioController] but can be overridden
/// in tests with a silent implementation.
final audioSfxPortProvider = Provider<AudioSfxPort>((ref) {
  return ref.watch(audioControllerProvider);
});

/// Silent stand-in for tests / builds without audio assets.
class SilentAudioSfxPort implements AudioSfxPort {
  @override
  Future<void> playSfx(SfxId sfx) async {}
}
