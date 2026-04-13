// SkinRepository — downloads `.gfskin` ZIP from BO and extracts in memory.
//
// CCR-012: .gfskin is a ZIP container. Overlay loads skin.json + skin.riv
// via in-memory decompression. Local cache is an implementation detail.
// CCR-011 reassigned Graphic Editor ownership to team1, so team4 only
// CONSUMES skins here; editing is out of scope.

import 'package:archive/archive.dart';

class SkinBundle {
  const SkinBundle({
    required this.manifestJson,
    required this.riveBytes,
  });

  final Map<String, dynamic> manifestJson;
  final List<int> riveBytes;
}

class SkinRepository {
  SkinRepository();

  /// Extract a .gfskin ZIP bundle in memory.
  ///
  /// Validates that both `manifest.json` (or `skin.json`) and `skin.riv`
  /// are present. Full JSON Schema validation (DATA-07) is performed by
  /// the caller using `json_schema` package.
  SkinBundle extractBundle(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    Map<String, dynamic>? manifest;
    List<int>? rive;

    for (final file in archive.files) {
      if (file.isFile) {
        final name = file.name.toLowerCase();
        if (name.endsWith('manifest.json') || name.endsWith('skin.json')) {
          // TODO: parse JSON → manifest. Placeholder:
          manifest = <String, dynamic>{};
        } else if (name.endsWith('skin.riv')) {
          rive = file.content as List<int>;
        }
      }
    }

    if (manifest == null || rive == null) {
      throw const FormatException(
        'Invalid .gfskin bundle: missing manifest.json or skin.riv',
      );
    }

    return SkinBundle(manifestJson: manifest, riveBytes: rive);
  }
}
