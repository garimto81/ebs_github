// EBS — 빌드 식별 표시 위젯 (2026-05-07 신설).
//
// 모든 화면 하단/footer 에 동일 형식으로 표시하여 사용자가 어느 빌드를 보고
// 있는지 1초 안에 식별 가능. SW 캐시 vs 새 빌드 혼동 영구 차단.
//
// 빌드 시 주입: `flutter build web --dart-define=BUILD_ID=$(date +%Y%m%d-%H%M)`
// 미주입 시: `dev` 표시 → 옛 SW 캐시 또는 개발 모드 신호.

import 'package:flutter/material.dart';

/// 빌드 시점에 `--dart-define=BUILD_ID=YYYYMMDD-HHMM` 으로 주입.
const String kBuildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

/// 앱 semver. pubspec.yaml `version:` 와 동기화 (수동, 단일 source).
const String kAppVersion = '0.1.0';

/// 표준 표시 문자열 — `EBS v0.1.0 · 0507-0030`.
String get kBuildLabel => 'EBS v$kAppVersion · $kBuildId';

/// 화면 footer 에 부착하는 작은 라벨 위젯.
///
/// [muted] true 면 회색조 텍스트 (login screen 같은 카드 외 영역).
/// [muted] false 면 LobbySideRail 의 dark rail 톤 사용.
class BuildIdLabel extends StatelessWidget {
  const BuildIdLabel({
    super.key,
    this.muted = true,
    this.fontSize = 10,
  });

  final bool muted;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      kBuildLabel,
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: fontSize,
        color: muted ? scheme.outline : null,
        letterSpacing: 0.4,
      ),
    );
  }
}
