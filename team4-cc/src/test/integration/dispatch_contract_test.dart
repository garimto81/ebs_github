// End-to-end dispatch contract: fixture payloads -> provider state.
// Complements ws_provider_dispatch_test.dart by exercising realistic
// publisher payloads loaded from test/fixtures/fixtures.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/data/remote/ws_provider.dart';
import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_display_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/foundation/audio/audio_player_provider.dart';
import 'package:ebs_cc/foundation/configs/security_delay_config.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

import '../fixtures/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer fresh() => ProviderContainer(overrides: [
        audioSfxPortProvider.overrideWithValue(SilentAudioSfxPort()),
      ]);

  test('full hand sequence: HandStarted -> 3 actions -> flop 3 cards '
      '-> turn -> river -> HandEnded', () {
    final c = fresh();

    dispatchIncomingEventForTest(c, handStartedEvent());
    expect(c.read(handFsmProvider), HandFsm.preFlop);
    expect(c.read(handNumberProvider), 15);

    // Pre-flop raise -> hasBetToMatch true, pot updated.
    dispatchIncomingEventForTest(
      c,
      actionPerformedEvent(actionType: 'raise', potAfter: 1200),
    );
    expect(c.read(hasBetToMatchProvider), true);
    expect(c.read(potTotalProvider), 1200);

    // Flop 3 cards -> phase transitions to FLOP after third.
    for (final r in ['A', 'K', 'Q']) {
      dispatchIncomingEventForTest(
        c,
        cardDetectedEvent(rank: r, suit: 's', isBoard: true),
      );
    }
    expect(c.read(handFsmProvider), HandFsm.flop);
    expect(c.read(boardCardsProvider), ['As', 'Ks', 'Qs']);
    expect(c.read(hasBetToMatchProvider), false);

    // Turn + river
    dispatchIncomingEventForTest(
      c,
      cardDetectedEvent(rank: 'J', suit: 'h', isBoard: true),
    );
    expect(c.read(handFsmProvider), HandFsm.turn);
    dispatchIncomingEventForTest(
      c,
      cardDetectedEvent(rank: 'T', suit: 'd', isBoard: true),
    );
    expect(c.read(handFsmProvider), HandFsm.river);

    // HandEnded -> HAND_COMPLETE + bet context reset.
    dispatchIncomingEventForTest(c, handEndedEvent());
    expect(c.read(handFsmProvider), HandFsm.handComplete);
    expect(c.read(hasBetToMatchProvider), false);
  });

  test('ConfigChanged drives securityDelayConfigProvider', () {
    final c = fresh();

    dispatchIncomingEventForTest(
      c,
      configChangedPayload(enabled: true, delaySeconds: 45),
    );

    final cfg = c.read(securityDelayConfigProvider);
    expect(cfg.enabled, true);
    expect(cfg.delaySeconds, 45);
  });

  test('Hole-card detections do not leak into boardCardsProvider', () {
    final c = fresh();

    dispatchIncomingEventForTest(c, handStartedEvent());
    dispatchIncomingEventForTest(
      c,
      cardDetectedEvent(rank: 'A', suit: 's', isBoard: false, seat: 3),
    );

    expect(c.read(boardCardsProvider), isEmpty);
    // Still PRE_FLOP because no board card advanced street.
    expect(c.read(handFsmProvider), HandFsm.preFlop);
  });
}
