// EbsOklch token unit tests — Cycle 19 Wave 2 Token Layer.
//
// Verifies the 25 static `const Color` token values match the
// Overview.md §13.1 OKLCH→Flutter sRGB conversion table exactly.
//
// SSOT references:
//   - `docs/mockups/EBS Command Center/tokens.css` (HTML SSOT, OKLCH)
//   - `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13.1
//     (Flutter sRGB conversion table — 25 rows)
//
// If any of these tests fail after re-running an OKLCH→sRGB converter,
// either (a) the converter changed, or (b) someone edited a token value
// without updating both the spec table AND this test. Lock the SSOT.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/foundation/theme/ebs_oklch.dart';

void main() {
  group('EbsOklch — Surfaces (broadcast-ops dark)', () {
    test('--bg-0 deepest frame', () {
      // oklch(0.16 0.012 240)
      expect(EbsOklch.bg0, equals(const Color(0xFF1F2326)));
    });

    test('--bg-1 status/action panels', () {
      // oklch(0.20 0.014 240)
      expect(EbsOklch.bg1, equals(const Color(0xFF272C30)));
    });

    test('--bg-2 cards/seats/controls', () {
      // oklch(0.24 0.014 240)
      expect(EbsOklch.bg2, equals(const Color(0xFF2F343A)));
    });

    test('--bg-3 raised/hover', () {
      // oklch(0.29 0.014 240)
      expect(EbsOklch.bg3, equals(const Color(0xFF393F46)));
    });

    test('--bg-felt table felt', () {
      // oklch(0.27 0.045 165)
      expect(EbsOklch.bgFelt, equals(const Color(0xFF2E4038)));
    });

    test('--bg-felt-rim', () {
      // oklch(0.20 0.035 165)
      expect(EbsOklch.bgFeltRim, equals(const Color(0xFF223027)));
    });
  });

  group('EbsOklch — Borders / dividers', () {
    test('--line', () {
      // oklch(0.34 0.014 240)
      expect(EbsOklch.line, equals(const Color(0xFF42484F)));
    });

    test('--line-soft (alpha 0.7)', () {
      // oklch(0.28 0.014 240 / 0.7)
      expect(EbsOklch.lineSoft, equals(const Color(0xB33A3F45)));
    });
  });

  group('EbsOklch — Text', () {
    test('--fg-0 primary text', () {
      // oklch(0.98 0.005 240)
      expect(EbsOklch.fg0, equals(const Color(0xFFF5F6F7)));
    });

    test('--fg-1 secondary text', () {
      // oklch(0.84 0.010 240)
      expect(EbsOklch.fg1, equals(const Color(0xFFCDD1D6)));
    });

    test('--fg-2 muted text', () {
      // oklch(0.62 0.010 240)
      expect(EbsOklch.fg2, equals(const Color(0xFF909599)));
    });

    test('--fg-3 disabled text', () {
      // oklch(0.45 0.010 240)
      expect(EbsOklch.fg3, equals(const Color(0xFF636770)));
    });
  });

  group('EbsOklch — Accent (broadcast amber)', () {
    test('--accent primary', () {
      // oklch(0.78 0.16 65)
      expect(EbsOklch.accent, equals(const Color(0xFFF4A028)));
    });

    test('--accent-strong emphasis', () {
      // oklch(0.72 0.18 60)
      expect(EbsOklch.accentStrong, equals(const Color(0xFFE08A1A)));
    });

    test('--accent-soft tint overlay (alpha 0.18)', () {
      // oklch(0.78 0.16 65 / 0.18)
      expect(EbsOklch.accentSoft, equals(const Color(0x2EF4A028)));
    });
  });

  group('EbsOklch — Semantic', () {
    test('--ok success green', () {
      // oklch(0.74 0.14 150)
      expect(EbsOklch.ok, equals(const Color(0xFF53B981)));
    });

    test('--warn warning amber', () {
      // oklch(0.80 0.16 80)
      expect(EbsOklch.warn, equals(const Color(0xFFE0B23F)));
    });

    test('--err error red', () {
      // oklch(0.66 0.20 25)
      expect(EbsOklch.err, equals(const Color(0xFFD8593A)));
    });

    test('--info info blue', () {
      // oklch(0.72 0.13 230)
      expect(EbsOklch.info, equals(const Color(0xFF5A98D8)));
    });
  });

  group('EbsOklch — Position roles', () {
    test('--pos-d dealer puck (bone white)', () {
      // oklch(0.92 0.04 90)
      expect(EbsOklch.posD, equals(const Color(0xFFE8E0CC)));
    });

    test('--pos-sb small blind', () {
      // oklch(0.74 0.14 230)
      expect(EbsOklch.posSb, equals(const Color(0xFF5B98D6)));
    });

    test('--pos-bb big blind', () {
      // oklch(0.72 0.16 320)
      expect(EbsOklch.posBb, equals(const Color(0xFFCB7AB8)));
    });
  });

  group('EbsOklch — Card colors', () {
    test('--card-bg off-white card face', () {
      // oklch(0.96 0.005 90)
      expect(EbsOklch.cardBg, equals(const Color(0xFFF5F2EC)));
    });

    test('--card-red red suits (H, D)', () {
      // oklch(0.55 0.21 25)
      expect(EbsOklch.cardRed, equals(const Color(0xFFCC3B20)));
    });

    test('--card-black black suits (S, C)', () {
      // oklch(0.18 0.02 240)
      expect(EbsOklch.cardBlack, equals(const Color(0xFF242830)));
    });
  });

  group('EbsOklch — token completeness', () {
    test('25 distinct token values are defined and non-null', () {
      // Smoke: collect all tokens, expect 25 entries.
      final tokens = <Color>[
        EbsOklch.bg0,
        EbsOklch.bg1,
        EbsOklch.bg2,
        EbsOklch.bg3,
        EbsOklch.bgFelt,
        EbsOklch.bgFeltRim,
        EbsOklch.line,
        EbsOklch.lineSoft,
        EbsOklch.fg0,
        EbsOklch.fg1,
        EbsOklch.fg2,
        EbsOklch.fg3,
        EbsOklch.accent,
        EbsOklch.accentStrong,
        EbsOklch.accentSoft,
        EbsOklch.ok,
        EbsOklch.warn,
        EbsOklch.err,
        EbsOklch.info,
        EbsOklch.posD,
        EbsOklch.posSb,
        EbsOklch.posBb,
        EbsOklch.cardBg,
        EbsOklch.cardRed,
        EbsOklch.cardBlack,
      ];
      expect(tokens, hasLength(25));
    });
  });
}
