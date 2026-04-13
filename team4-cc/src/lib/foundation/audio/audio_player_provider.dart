// AudioPlayerProvider — 1 BGM + 2 Effect + Temp channel pool.
// See BS-07-05-audio.md (CCR-033) and WSOP Fatima.app Audio Player Provider
// (wsoplive/.../Mobile-Dev/Refactoring/Audio Player Provider (2023.md).

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioPlayerProvider {
  AudioPlayerProvider._();

  double masterVolume = 0.7;
  double bgmMix = 0.3;
  double effectMix = 0.8;
  bool silentMode = false;

  // TODO(CCR-033): create BGM + Effect #1 + Effect #2 + dynamic Temp channels
  // via `just_audio` package. Handle event → sound mapping from BS-07-05 table.
}

final audioPlayerProvider = Provider<AudioPlayerProvider>(
  (ref) => AudioPlayerProvider._(),
);
