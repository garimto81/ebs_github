// SkinRepository — .gfskin ZIP load with FSM (CCR-012, DATA-07).
//
// Skin Load FSM: IDLE → DOWNLOADING → EXTRACTING → VALIDATING → LOADED / ERROR
//
// CCR-011 reassigned Graphic Editor ownership to team1, so team4 only
// CONSUMES skins here; editing is out of scope.
// CCR-012: .gfskin is a ZIP container with manifest.json + skin.riv + assets.
// DATA-07: JSON Schema validation for manifest.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

// ---------------------------------------------------------------------------
// Skin Load FSM
// ---------------------------------------------------------------------------

enum SkinLoadState { idle, downloading, extracting, validating, loaded, error }

// ---------------------------------------------------------------------------
// Extracted bundle value object
// ---------------------------------------------------------------------------

class SkinBundle {
  const SkinBundle({
    required this.manifestJson,
    required this.riveBytes,
    this.assets = const {},
  });

  final Map<String, dynamic> manifestJson;
  final List<int> riveBytes;

  /// Additional asset files: filename → raw bytes (images, fonts, etc.)
  final Map<String, List<int>> assets;
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class SkinRepository {
  SkinRepository({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  SkinLoadState _state = SkinLoadState.idle;
  SkinLoadState get state => _state;

  SkinBundle? _activeBundle;
  SkinBundle? get activeBundle => _activeBundle;

  String? _lastError;
  String? get lastError => _lastError;

  // -- Load from raw bytes (in-memory ZIP extraction) -----------------------

  /// Load a .gfskin ZIP from bytes (in-memory).
  ///
  /// Extracts manifest.json (or skin.json), skin.riv, and any additional
  /// asset files. Validates manifest against DATA-07 JSON Schema.
  Future<SkinBundle> loadFromBytes(List<int> zipBytes) async {
    _lastError = null;

    _state = SkinLoadState.extracting;
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      _state = SkinLoadState.error;
      _lastError = 'ZIP decode failed: $e';
      throw FormatException(_lastError!);
    }

    Map<String, dynamic>? manifest;
    List<int>? rive;
    final assets = <String, List<int>>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.toLowerCase();
      final content = file.content as List<int>;

      if (name.endsWith('manifest.json') || name.endsWith('skin.json')) {
        try {
          final jsonStr = utf8.decode(content);
          manifest = jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          _state = SkinLoadState.error;
          _lastError = 'Manifest JSON parse failed: $e';
          throw FormatException(_lastError!);
        }
      } else if (name.endsWith('.riv')) {
        rive = content;
      } else {
        // Additional assets (images, fonts, etc.)
        assets[file.name] = content;
      }
    }

    if (manifest == null || rive == null) {
      _state = SkinLoadState.error;
      _lastError = 'Invalid .gfskin bundle: missing manifest.json or skin.riv';
      throw FormatException(_lastError!);
    }

    // -- Validate manifest against DATA-07 schema --
    _state = SkinLoadState.validating;
    final validationError = _validateManifest(manifest);
    if (validationError != null) {
      _state = SkinLoadState.error;
      _lastError = 'Manifest validation failed: $validationError';
      throw FormatException(_lastError!);
    }

    final bundle = SkinBundle(
      manifestJson: manifest,
      riveBytes: rive,
      assets: assets,
    );

    _activeBundle = bundle;
    _state = SkinLoadState.loaded;
    return bundle;
  }

  // -- Load from URL (download + extract) -----------------------------------

  /// Load a .gfskin from a remote URL.
  ///
  /// Downloads the ZIP via Dio, then delegates to [loadFromBytes].
  Future<SkinBundle> loadFromUrl(String url) async {
    final dio = _dio;
    if (dio == null) {
      _state = SkinLoadState.error;
      _lastError = 'Dio client not provided for remote loading';
      throw StateError(_lastError!);
    }

    _state = SkinLoadState.downloading;
    _lastError = null;

    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        _state = SkinLoadState.error;
        _lastError = 'Empty response from skin URL';
        throw FormatException(_lastError!);
      }
      return await loadFromBytes(bytes);
    } on DioException catch (e) {
      _state = SkinLoadState.error;
      _lastError = 'Skin download failed: ${e.message}';
      throw FormatException(_lastError!);
    }
  }

  // -- Reset ----------------------------------------------------------------

  /// Reset to idle state (e.g. on logout or table close).
  void reset() {
    _state = SkinLoadState.idle;
    _activeBundle = null;
    _lastError = null;
  }

  // -- Manifest validation (DATA-07) ----------------------------------------

  /// Public seam for DATA-07 validation tests.
  @visibleForTesting
  String? validateManifestForTest(Map<String, dynamic> manifest) =>
      _validateManifest(manifest);

  /// Validates manifest against DATA-07 required fields + value constraints.
  ///
  /// Returns null if valid, error string if invalid. Aligns with
  /// `docs/2. Development/2.2 Backend/Database/GFSkin_Schema.md §2`:
  /// required = [skin_name, version, resolution, colors, fonts].
  /// Full JSON Schema (Draft-07) validation via `json_schema` package
  /// can replace this when the schema JSON asset is shipped.
  String? _validateManifest(Map<String, dynamic> manifest) {
    const requiredFields = [
      'skin_name',
      'version',
      'resolution',
      'colors',
      'fonts',
    ];
    for (final field in requiredFields) {
      if (!manifest.containsKey(field)) {
        return 'Missing required field: $field';
      }
    }

    // skin_name: string, 1..40
    final skinName = manifest['skin_name'];
    if (skinName is! String || skinName.isEmpty || skinName.length > 40) {
      return 'Field "skin_name" must be a non-empty string (max 40 chars)';
    }

    // version: string matching /^\d+\.\d+\.\d+$/
    final version = manifest['version'];
    if (version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      return 'Field "version" must follow semver like "1.0.0"';
    }

    // resolution: { width in {1920,2560,3840}, height in {1080,1440,2160} }
    final resolution = manifest['resolution'];
    if (resolution is! Map<String, dynamic>) {
      return 'Field "resolution" must be an object';
    }
    const allowedWidth = {1920, 2560, 3840};
    const allowedHeight = {1080, 1440, 2160};
    final width = resolution['width'];
    final height = resolution['height'];
    if (width is! int || !allowedWidth.contains(width)) {
      return 'Field "resolution.width" must be one of $allowedWidth';
    }
    if (height is! int || !allowedHeight.contains(height)) {
      return 'Field "resolution.height" must be one of $allowedHeight';
    }

    // colors: object containing 8 required role keys, values hex RGB strings
    final colors = manifest['colors'];
    if (colors is! Map<String, dynamic>) {
      return 'Field "colors" must be an object';
    }
    const requiredColors = [
      'background',
      'text_primary',
      'text_secondary',
      'badge_check',
      'badge_fold',
      'badge_bet',
      'badge_call',
      'badge_allin',
    ];
    final hexRgb = RegExp(r'^#[0-9A-Fa-f]{6}$');
    for (final role in requiredColors) {
      final v = colors[role];
      if (v is! String || !hexRgb.hasMatch(v)) {
        return 'Field "colors.$role" must be a hex color like "#RRGGBB"';
      }
    }

    // fonts: object (detailed shape validated at consumption time)
    final fonts = manifest['fonts'];
    if (fonts is! Map<String, dynamic> || fonts.isEmpty) {
      return 'Field "fonts" must be a non-empty object';
    }

    return null;
  }
}
