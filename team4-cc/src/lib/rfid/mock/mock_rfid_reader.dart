// MockRfidReader — Phase 1 primary driver.
//
// Deterministic fault injection for unit/integration tests.
// BS-04 §Mock Priority: Mock is not a fallback, it is the primary dev mode.

import 'dart:async';

import '../abstract/i_rfid_reader.dart';

class MockRfidReader implements IRfidReader {
  MockRfidReader();

  RfidReaderStatus _status = RfidReaderStatus.disconnected;

  final _cardDetected = StreamController<CardDetectedEvent>.broadcast();
  final _cardRemoved = StreamController<CardRemovedEvent>.broadcast();
  final _deckRegistered = StreamController<DeckRegisteredEvent>.broadcast();
  final _antenna = StreamController<AntennaStatusChangedEvent>.broadcast();
  final _error = StreamController<ReaderErrorEvent>.broadcast();
  final _statusChanged = StreamController<RfidReaderStatus>.broadcast();

  @override
  RfidReaderStatus get status => _status;

  @override
  Stream<CardDetectedEvent> get onCardDetected => _cardDetected.stream;

  @override
  Stream<CardRemovedEvent> get onCardRemoved => _cardRemoved.stream;

  @override
  Stream<DeckRegisteredEvent> get onDeckRegistered => _deckRegistered.stream;

  @override
  Stream<AntennaStatusChangedEvent> get onAntennaStatusChanged =>
      _antenna.stream;

  @override
  Stream<ReaderErrorEvent> get onError => _error.stream;

  @override
  Stream<RfidReaderStatus> get onStatusChanged => _statusChanged.stream;

  @override
  Future<void> open(String serialPort) async {
    _transition(RfidReaderStatus.connecting);
    // Deterministic: succeed immediately unless test injects failure.
    _transition(RfidReaderStatus.connected);
  }

  @override
  Future<void> close() async {
    _transition(RfidReaderStatus.disconnected);
  }

  // ── Mock-only API for tests ───────────────────────────────

  /// Inject a card detection event.
  void injectCard(String uid) {
    _cardDetected.add(CardDetectedEvent(
      uid: uid,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Inject a card removal event.
  void injectRemoval(String uid) {
    _cardRemoved.add(CardRemovedEvent(uid: uid));
  }

  /// Inject a reader error (for testing error paths).
  void injectError({required int code, required String message}) {
    _error.add(ReaderErrorEvent(code: code, message: message));
  }

  /// Inject a forced disconnect (CCR-022 §9 reconnect testing).
  void injectDisconnect() {
    _transition(RfidReaderStatus.reconnecting);
  }

  /// Inject a reconnect after a prior `injectDisconnect`.
  void injectReconnect() {
    _transition(RfidReaderStatus.connected);
  }

  /// Auto-register 54 cards sequentially for AT-05 testing (BS-04-05).
  void autoRegisterDeck(String deckId) {
    _deckRegistered.add(DeckRegisteredEvent(deckId: deckId, cardCount: 54));
  }

  void _transition(RfidReaderStatus next) {
    _status = next;
    _statusChanged.add(next);
  }

  Future<void> dispose() async {
    await _cardDetected.close();
    await _cardRemoved.close();
    await _deckRegistered.close();
    await _antenna.close();
    await _error.close();
    await _statusChanged.close();
  }
}
