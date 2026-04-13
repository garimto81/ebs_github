// SkinConsumer — receives `skin_updated` WebSocket events (CCR-015) and
// reloads the Overlay Rive canvas. Replaces team4's earlier bs08 proposal
// after CCR-011 moved Graphic Editor ownership to team1.
//
// Flow:
//   1. WebSocket dispatch → reload(skinId)
//   2. BO GET /skins/{id}/bundle → .gfskin ZIP bytes
//   3. SkinRepository.extractBundle() → manifest + skin.riv (CCR-012)
//   4. JSON Schema validate manifest against DATA-07
//   5. Load Rive bytes into Overlay root
//   6. On failure: rollback (keep previous skin) + Sentry report

import '../../../repositories/skin_repository.dart';

class SkinConsumer {
  SkinConsumer({required SkinRepository skinRepository})
      : _skinRepository = skinRepository;

  final SkinRepository _skinRepository;
  SkinBundle? _active;

  Future<void> reload(String skinId) async {
    // TODO(CCR-011, CCR-012, CCR-015): fetch bundle from BO, extract, validate.
    // Current stub records the intended contract for Phase C TDD.
    _skinRepository; // silence lint
    _active;
  }
}
