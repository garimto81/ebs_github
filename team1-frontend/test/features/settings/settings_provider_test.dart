// SettingsSectionNotifier unit tests — draft/committed/dirty pattern.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ebs_lobby/features/settings/providers/settings_provider.dart';
import 'package:ebs_lobby/repositories/settings_repository.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late ProviderContainer container;
  late MockSettingsRepository mockRepo;
  const section = SettingsSection.outputs;

  setUp(() {
    mockRepo = MockSettingsRepository();
    container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  SettingsSectionNotifier notifier() =>
      container.read(settingsSectionProvider(section).notifier);

  SettingsSectionState state() =>
      container.read(settingsSectionProvider(section));

  // -------------------------------------------------------------------------
  // fetch
  // -------------------------------------------------------------------------

  group('fetch', () {
    test('loads committed state from repository', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80, 'muted': false},
      );

      await notifier().fetch();

      expect(state().committed, {'volume': 80, 'muted': false});
      expect(state().draft, {'volume': 80, 'muted': false});
      expect(state().isDirty, isFalse);
      expect(state().isLoading, isFalse);
    });

    test('sets error on failure', () async {
      when(() => mockRepo.getConfig('outputs'))
          .thenThrow(Exception('Network error'));

      await notifier().fetch();

      expect(state().error, contains('Network error'));
      expect(state().isLoading, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // updateField
  // -------------------------------------------------------------------------

  group('updateField', () {
    test('sets dirty flag when draft differs from committed', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      await notifier().fetch();

      notifier().updateField('volume', 95);

      expect(state().draft['volume'], 95);
      expect(state().isDirty, isTrue);
    });

    test('clears dirty flag when draft matches committed', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      await notifier().fetch();

      notifier().updateField('volume', 95);
      expect(state().isDirty, isTrue);

      notifier().updateField('volume', 80);
      expect(state().isDirty, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // save
  // -------------------------------------------------------------------------

  group('save', () {
    test('commits draft and clears dirty', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      when(() => mockRepo.updateConfig('outputs', {'volume': 95})).thenAnswer(
        (_) async => {'volume': 95},
      );
      await notifier().fetch();

      notifier().updateField('volume', 95);
      expect(state().isDirty, isTrue);

      await notifier().save();

      expect(state().committed['volume'], 95);
      expect(state().draft['volume'], 95);
      expect(state().isDirty, isFalse);
      expect(state().isSaving, isFalse);
    });

    test('does nothing when not dirty', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      await notifier().fetch();

      await notifier().save();

      // updateConfig should never be called.
      verifyNever(() => mockRepo.updateConfig(any(), any()));
    });

    test('sets error on save failure', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      when(() => mockRepo.updateConfig('outputs', {'volume': 95}))
          .thenThrow(Exception('Server error'));
      await notifier().fetch();

      notifier().updateField('volume', 95);
      await notifier().save();

      expect(state().error, contains('Server error'));
      expect(state().isSaving, isFalse);
      // Draft remains dirty so user can retry.
      expect(state().isDirty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // revert
  // -------------------------------------------------------------------------

  group('revert', () {
    test('restores committed values', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      await notifier().fetch();

      notifier().updateField('volume', 95);
      expect(state().isDirty, isTrue);

      notifier().revert();

      expect(state().draft['volume'], 80);
      expect(state().isDirty, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // applyRemoteChange
  // -------------------------------------------------------------------------

  group('applyRemoteChange', () {
    test('updates committed and draft when not dirty', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80, 'muted': false},
      );
      await notifier().fetch();

      notifier().applyRemoteChange('volume', 60);

      expect(state().committed['volume'], 60);
      expect(state().draft['volume'], 60);
      expect(state().isDirty, isFalse);
    });

    test('updates committed but does NOT overwrite dirty draft', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80, 'muted': false},
      );
      await notifier().fetch();

      // User has local edits.
      notifier().updateField('volume', 95);
      expect(state().isDirty, isTrue);

      // Remote change comes in.
      notifier().applyRemoteChange('volume', 60);

      // Committed updated, draft preserved.
      expect(state().committed['volume'], 60);
      expect(state().draft['volume'], 95);
      expect(state().isDirty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // replaceAll
  // -------------------------------------------------------------------------

  group('replaceAll', () {
    test('bulk replaces both committed and draft', () {
      notifier().replaceAll({'x': 1, 'y': 2});

      expect(state().committed, {'x': 1, 'y': 2});
      expect(state().draft, {'x': 1, 'y': 2});
      expect(state().isDirty, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isAnySettingsDirtyProvider
  // -------------------------------------------------------------------------

  group('isAnySettingsDirtyProvider', () {
    test('returns true when any section is dirty', () async {
      when(() => mockRepo.getConfig('outputs')).thenAnswer(
        (_) async => {'volume': 80},
      );
      await notifier().fetch();

      expect(container.read(isAnySettingsDirtyProvider), isFalse);

      notifier().updateField('volume', 99);
      expect(container.read(isAnySettingsDirtyProvider), isTrue);
    });
  });
}
