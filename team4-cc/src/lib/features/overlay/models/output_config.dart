// Output configuration (BS-07-04).
//
// Defines the rendering output mode and parameters for the Overlay.
// Phase 1: HDMI + Chroma Key. Phase 2: NDI output stub.

// ---------------------------------------------------------------------------
// Output mode
// ---------------------------------------------------------------------------

enum OutputMode {
  /// Direct HDMI output (Flutter fullscreen window on secondary display).
  hdmi,

  /// NDI network output (Phase 2 — stub).
  ndi,

  /// Chroma key compositing (green/blue screen background).
  chromaKey,
}

// ---------------------------------------------------------------------------
// Output configuration
// ---------------------------------------------------------------------------

class OutputConfig {
  const OutputConfig({
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.chromaColor = 'green',
    this.ndiStreamName,
    this.mode = OutputMode.hdmi,
    this.enableAlphaChannel = false,
    this.jpegQuality = 95,
  });

  /// Output resolution width (1920 for 1080p, 3840 for 4K).
  final int width;

  /// Output resolution height (1080 for 1080p, 2160 for 4K).
  final int height;

  /// Target frames per second (30 or 60).
  final int fps;

  /// Chroma key background color: 'green', 'blue', or hex '#RRGGBB'.
  final String chromaColor;

  /// NDI stream name (Phase 2). null = NDI disabled.
  final String? ndiStreamName;

  /// Output rendering mode.
  final OutputMode mode;

  /// Whether to render with alpha channel (for compositing software).
  final bool enableAlphaChannel;

  /// JPEG quality for NDI output (Phase 2). Ignored for HDMI/chroma.
  final int jpegQuality;

  // -- Helpers ---------------------------------------------------------------

  /// Whether this config targets 4K resolution.
  bool get is4K => width >= 3840 && height >= 2160;

  /// Aspect ratio as string.
  String get aspectRatio {
    if (width == 1920 && height == 1080) return '16:9';
    if (width == 3840 && height == 2160) return '16:9';
    if (width == 1280 && height == 720) return '16:9';
    return '$width:$height';
  }

  /// Parse chroma color to ARGB int.
  int get chromaColorArgb {
    switch (chromaColor.toLowerCase()) {
      case 'green':
        return 0xFF00FF00;
      case 'blue':
        return 0xFF0000FF;
      default:
        // Try hex parse
        if (chromaColor.startsWith('#') && chromaColor.length == 7) {
          return int.parse('FF${chromaColor.substring(1)}', radix: 16);
        }
        return 0xFF00FF00; // default green
    }
  }

  OutputConfig copyWith({
    int? width,
    int? height,
    int? fps,
    String? chromaColor,
    String? ndiStreamName,
    OutputMode? mode,
    bool? enableAlphaChannel,
    int? jpegQuality,
  }) =>
      OutputConfig(
        width: width ?? this.width,
        height: height ?? this.height,
        fps: fps ?? this.fps,
        chromaColor: chromaColor ?? this.chromaColor,
        ndiStreamName: ndiStreamName ?? this.ndiStreamName,
        mode: mode ?? this.mode,
        enableAlphaChannel: enableAlphaChannel ?? this.enableAlphaChannel,
        jpegQuality: jpegQuality ?? this.jpegQuality,
      );
}
