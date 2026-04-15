// DATA-07 GFSkin manifest validation — per
// docs/2. Development/2.2 Backend/Database/GFSkin_Schema.md §2.

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/repositories/skin_repository.dart';

Map<String, dynamic> _validManifest() => {
      'skin_name': 'WSOP 2026 Default',
      'version': '1.0.0',
      'resolution': {'width': 1920, 'height': 1080},
      'colors': {
        'background': '#000000',
        'text_primary': '#FFFFFF',
        'text_secondary': '#B0B0B0',
        'badge_check': '#2E7D32',
        'badge_fold': '#616161',
        'badge_bet': '#1976D2',
        'badge_call': '#0288D1',
        'badge_allin': '#E53935',
      },
      'fonts': {
        'title': {'family': 'Roboto', 'size': 24},
      },
    };

void main() {
  final repo = SkinRepository();

  group('GFSkin manifest validation (DATA-07)', () {
    test('valid manifest passes', () {
      expect(repo.validateManifestForTest(_validManifest()), isNull);
    });

    test('missing required field is rejected', () {
      for (final field in [
        'skin_name',
        'version',
        'resolution',
        'colors',
        'fonts',
      ]) {
        final m = _validManifest()..remove(field);
        expect(repo.validateManifestForTest(m),
            contains('Missing required field: $field'));
      }
    });

    test('skin_name length bounds', () {
      final m = _validManifest()..['skin_name'] = '';
      expect(repo.validateManifestForTest(m), contains('skin_name'));
      m['skin_name'] = 'x' * 41;
      expect(repo.validateManifestForTest(m), contains('skin_name'));
    });

    test('version must follow semver pattern', () {
      final m = _validManifest()..['version'] = '1.0';
      expect(repo.validateManifestForTest(m), contains('semver'));
    });

    test('resolution width/height must be in allowed enum', () {
      final m = _validManifest();
      m['resolution'] = {'width': 1024, 'height': 768};
      expect(repo.validateManifestForTest(m), contains('resolution.width'));
      m['resolution'] = {'width': 1920, 'height': 900};
      expect(repo.validateManifestForTest(m), contains('resolution.height'));
    });

    test('colors must contain all 8 role keys with hex values', () {
      final m = _validManifest();
      (m['colors'] as Map<String, dynamic>).remove('badge_allin');
      expect(repo.validateManifestForTest(m), contains('colors.badge_allin'));

      final m2 = _validManifest();
      (m2['colors'] as Map<String, dynamic>)['text_primary'] = 'white';
      expect(repo.validateManifestForTest(m2), contains('colors.text_primary'));
    });

    test('fonts must be a non-empty object', () {
      final m = _validManifest()..['fonts'] = <String, dynamic>{};
      expect(repo.validateManifestForTest(m), contains('fonts'));
    });
  });
}
