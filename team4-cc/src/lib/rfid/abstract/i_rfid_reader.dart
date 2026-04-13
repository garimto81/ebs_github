// IRfidReader abstract interface from API-03-rfid-hal-interface.md.
//
// All business logic must depend on this interface, NOT concrete
// implementations. Obtain via `rfidReaderProvider` Riverpod DI
// (team4-cc/CLAUDE.md §RFID HAL 규칙).
//
// Lifecycle FSM (CCR-022 §9):
//   DISCONNECTED → CONNECTING → CONNECTED
//                      ↓            ↓
//                  CONNECTION_FAILED / RECONNECTING

enum RfidReaderStatus {
  disconnected,
  connecting,
  connected,
  connectionFailed,
  reconnecting,
}

class CardDetectedEvent {
  const CardDetectedEvent({required this.uid, required this.timestampMs});
  final String uid;
  final int timestampMs;
}

class CardRemovedEvent {
  const CardRemovedEvent({required this.uid});
  final String uid;
}

class DeckRegisteredEvent {
  const DeckRegisteredEvent({required this.deckId, required this.cardCount});
  final String deckId;
  final int cardCount;
}

class AntennaStatusChangedEvent {
  const AntennaStatusChangedEvent({
    required this.tuningQuality,
    required this.status,
  });
  final double tuningQuality;
  final String status; // "tuned" | "degraded" | "failed"
}

class ReaderErrorEvent {
  const ReaderErrorEvent({required this.code, required this.message});
  final int code;
  final String message;
}

abstract class IRfidReader {
  /// Current reader status; also emitted on `onStatusChanged`.
  RfidReaderStatus get status;

  /// Stream of card detection events (HF/ISO 15693 UID).
  Stream<CardDetectedEvent> get onCardDetected;

  /// Stream of card removal events.
  Stream<CardRemovedEvent> get onCardRemoved;

  /// Stream of deck registration progress/completion (BS-04-05 AT-05).
  Stream<DeckRegisteredEvent> get onDeckRegistered;

  /// Stream of antenna tuning quality updates (CCR-022 §10).
  Stream<AntennaStatusChangedEvent> get onAntennaStatusChanged;

  /// Stream of reader errors.
  Stream<ReaderErrorEvent> get onError;

  /// Stream of connection lifecycle transitions (CCR-022 §9).
  Stream<RfidReaderStatus> get onStatusChanged;

  /// Open the serial connection and perform handshake.
  Future<void> open(String serialPort);

  /// Close the connection cleanly.
  Future<void> close();
}
