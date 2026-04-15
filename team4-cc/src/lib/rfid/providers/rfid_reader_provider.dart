// Riverpod DI for IRfidReader (team4-cc/CLAUDE.md §RFID HAL 규칙).
//
// Business logic (seat_provider, hand_fsm_provider, etc.) MUST resolve
// IRfidReader via this provider. Direct instantiation is prohibited.
//
// This provider also wires RFID events to downstream state:
//   - CardDetected → seat hole card assignment
//   - DeckRegistered → DeckFSM state update
//   - ReaderError → UI notification

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../foundation/configs/features.dart';
import '../abstract/i_rfid_reader.dart';
import '../mock/mock_rfid_reader.dart';
import '../real/st25r3911b_reader.dart';

final _log = Logger('RfidReaderProvider');

// ---------------------------------------------------------------------------
// Core RFID reader provider (DI interface)
// ---------------------------------------------------------------------------

/// Detected RFID chip family (CCR-022 §13 migration path).
enum RfidChipFamily { st25r3911b, st25r3916, unknown }

/// Probes connected hardware to decide which reader driver to instantiate.
///
/// Phase 1: always returns [RfidChipFamily.unknown] because Features.useMockRfid
/// is the supported path.
/// Phase 2: extend with actual firmware handshake over UART — read
/// `IC_IDENTITY_REGISTER` and map the value per ST25R3911B datasheet
/// (0x08 = 3911B, 0x05 = 3916). Until hardware integration lands the
/// caller should not reach this code unless [Features.useMockRfid] is
/// false AND a reader is physically attached.
RfidChipFamily detectChipFamily() {
  // Phase 2 hook: replace with real UART probe (st25r3911b_reader.dart
  // exposes a static probe method once wired to serial_port_win32).
  return RfidChipFamily.unknown;
}

final rfidReaderProvider = Provider<IRfidReader>((ref) {
  if (Features.useMockRfid) {
    return MockRfidReader();
  }
  switch (detectChipFamily()) {
    case RfidChipFamily.st25r3911b:
    case RfidChipFamily.unknown:
      // Default to 3911B until Phase 2 chip-detection lands.
      return St25r3911bReader();
    case RfidChipFamily.st25r3916:
      // Phase 2: St25r3916Reader will be introduced (CCR-022 §13).
      // For now, 3911B driver is a close-enough superset; log a warning.
      _log.warning(
        'ST25R3916 detected but Phase 2 driver missing; '
        'falling back to ST25R3911B driver. CCR-022 §13.',
      );
      return St25r3911bReader();
  }
});

// ---------------------------------------------------------------------------
// RFID connection state
// ---------------------------------------------------------------------------

final rfidStatusProvider =
    StreamProvider<RfidReaderStatus>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onStatusChanged;
});

// ---------------------------------------------------------------------------
// Card detection stream
// ---------------------------------------------------------------------------

final cardDetectedProvider =
    StreamProvider<CardDetectedEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onCardDetected;
});

// ---------------------------------------------------------------------------
// Card removal stream
// ---------------------------------------------------------------------------

final cardRemovedProvider =
    StreamProvider<CardRemovedEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onCardRemoved;
});

// ---------------------------------------------------------------------------
// Deck registration stream
// ---------------------------------------------------------------------------

final deckRegisteredProvider =
    StreamProvider<DeckRegisteredEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onDeckRegistered;
});

// ---------------------------------------------------------------------------
// Reader error stream
// ---------------------------------------------------------------------------

final rfidErrorProvider =
    StreamProvider<ReaderErrorEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onError;
});

// ---------------------------------------------------------------------------
// Antenna status stream
// ---------------------------------------------------------------------------

final antennaStatusProvider =
    StreamProvider<AntennaStatusChangedEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.onAntennaStatusChanged;
});

// ---------------------------------------------------------------------------
// RFID Bridge — wires RFID events to CC state
// ---------------------------------------------------------------------------

/// Manages subscriptions from RFID reader to CC providers.
///
/// Usage: Create once in the widget tree (e.g. via ref.watch(rfidBridgeProvider))
/// and the bridge will automatically route events.
class RfidBridge {
  RfidBridge({
    required IRfidReader reader,
    required this.onCardDetected,
    required this.onCardRemoved,
    required this.onDeckRegistered,
    required this.onError,
  }) {
    _subs = [
      reader.onCardDetected.listen((event) {
        _log.fine('Card detected: ${event.uid}');
        onCardDetected(event);
      }),
      reader.onCardRemoved.listen((event) {
        _log.fine('Card removed: ${event.uid}');
        onCardRemoved(event);
      }),
      reader.onDeckRegistered.listen((event) {
        _log.info('Deck registered: ${event.deckId} '
            '(${event.cardCount} cards)');
        onDeckRegistered(event);
      }),
      reader.onError.listen((event) {
        _log.warning('RFID error [${event.code}]: ${event.message}');
        onError(event);
      }),
    ];
  }

  final void Function(CardDetectedEvent) onCardDetected;
  final void Function(CardRemovedEvent) onCardRemoved;
  final void Function(DeckRegisteredEvent) onDeckRegistered;
  final void Function(ReaderErrorEvent) onError;

  late final List<StreamSubscription<dynamic>> _subs;

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
  }
}

// ---------------------------------------------------------------------------
// Deck FSM state
// ---------------------------------------------------------------------------

enum DeckFsmState {
  unregistered,
  registering,
  registered,
  error,
}

class DeckState {
  const DeckState({
    this.state = DeckFsmState.unregistered,
    this.deckId,
    this.cardCount = 0,
    this.errorMessage,
  });

  final DeckFsmState state;
  final String? deckId;
  final int cardCount;
  final String? errorMessage;

  DeckState copyWith({
    DeckFsmState? state,
    String? deckId,
    int? cardCount,
    String? errorMessage,
  }) =>
      DeckState(
        state: state ?? this.state,
        deckId: deckId ?? this.deckId,
        cardCount: cardCount ?? this.cardCount,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class DeckNotifier extends StateNotifier<DeckState> {
  DeckNotifier() : super(const DeckState());

  void startRegistering() {
    state = state.copyWith(state: DeckFsmState.registering);
  }

  void onDeckRegistered(DeckRegisteredEvent event) {
    state = DeckState(
      state: DeckFsmState.registered,
      deckId: event.deckId,
      cardCount: event.cardCount,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      state: DeckFsmState.error,
      errorMessage: message,
    );
  }

  void reset() {
    state = const DeckState();
  }
}

final deckStateProvider =
    StateNotifierProvider<DeckNotifier, DeckState>((ref) {
  return DeckNotifier();
});

// ---------------------------------------------------------------------------
// RFID notification state (for UI error/info display)
// ---------------------------------------------------------------------------

class RfidNotification {
  const RfidNotification({
    required this.message,
    this.isError = false,
    this.timestamp,
  });

  final String message;
  final bool isError;
  final DateTime? timestamp;
}

final rfidNotificationProvider =
    StateProvider<RfidNotification?>((ref) => null);

/// Bridges the local hardware status stream into [rfidNotificationProvider].
///
/// Watches `rfidStatusProvider` (which forwards `IRfidReader.onStatusChanged`)
/// and updates the notification using the same builder ws_provider uses for
/// server-side `RfidStatusChanged` events. Both code paths therefore agree
/// on banner content per Manual_Fallback.md §5.5/§5.6.
///
/// The bridge function is intentionally exposed (not done as a side-effect
/// inside a Provider) so the host app can opt in via
/// `ref.listen(rfidStatusBridgeProvider, (_, __) {})` from a top-level
/// widget. This avoids accidentally creating duplicate listeners.
final rfidStatusBridgeProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<RfidReaderStatus>>(rfidStatusProvider, (_, next) {
    next.whenData((status) {
      ref.read(rfidNotificationProvider.notifier).state =
          _localBuildRfidNotification(status);
    });
  });
});

/// Local notification builder — kept here to avoid a circular import on
/// ws_provider. Mirrors `buildRfidNotification` exactly per the §5.6 spec.
RfidNotification? _localBuildRfidNotification(RfidReaderStatus status) {
  switch (status) {
    case RfidReaderStatus.connected:
      return null;
    case RfidReaderStatus.connecting:
      return RfidNotification(
        message: 'RFID 리더 연결 중…',
        isError: false,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.reconnecting:
      return RfidNotification(
        message: 'RFID 재연결 중 — 수동 입력으로 진행 가능',
        isError: false,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.connectionFailed:
      return RfidNotification(
        message: 'RFID 연결 실패 — 수동 입력으로 진행하세요',
        isError: true,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.disconnected:
      return RfidNotification(
        message: 'RFID 장애 — 수동 입력 모드',
        isError: true,
        timestamp: DateTime.now(),
      );
  }
}
