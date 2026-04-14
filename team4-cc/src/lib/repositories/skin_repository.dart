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

  /// Validates manifest against DATA-07 required fields.
  ///
  /// Returns null if valid, error string if invalid.
  /// Full JSON Schema validation via `json_schema` package can be added
  /// when the DATA-07 schema JSON is finalized.
  String? _validateManifest(Map<String, dynamic> manifest) {
    // Required fields per DATA-07
    const requiredFields = ['version', 'name'];
    for (final field in requiredFields) {
      if (!manifest.containsKey(field)) {
        return 'Missing required field: $field';
      }
    }

    final version = manifest['version'];
    if (version is! String) {
      return 'Field "version" must be a string';
    }

    final name = manifest['name'];
    if (name is! String || name.isEmpty) {
      return 'Field "name" must be a non-empty string';
    }

    return null;
  }
}
