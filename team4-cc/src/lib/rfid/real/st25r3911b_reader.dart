// ST25R3911BReader — Phase 2 real hardware implementation stub.
//
// TODO(Phase 2): implement serial UART (ESP32 bridge) with
// handshake/reconnect/antenna tuning per API-03 §9~§13 (CCR-022).
// ST25R3916 migration path (CCR-022 §13) is handled by Riverpod DI
// selecting the correct concrete reader via `features.dart`.

import '../abstract/i_rfid_reader.dart';

class St25r3911bReader implements IRfidReader {
  @override
  RfidReaderStatus get status => throw UnimplementedError('Phase 2');

  @override
  Stream<CardDetectedEvent> get onCardDetected =>
      throw UnimplementedError('Phase 2');

  @override
  Stream<CardRemovedEvent> get onCardRemoved =>
      throw UnimplementedError('Phase 2');

  @override
  Stream<DeckRegisteredEvent> get onDeckRegistered =>
      throw UnimplementedError('Phase 2');

  @override
  Stream<AntennaStatusChangedEvent> get onAntennaStatusChanged =>
      throw UnimplementedError('Phase 2');

  @override
  Stream<ReaderErrorEvent> get onError => throw UnimplementedError('Phase 2');

  @override
  Stream<RfidReaderStatus> get onStatusChanged =>
      throw UnimplementedError('Phase 2');

  @override
  Future<void> open(String serialPort) => throw UnimplementedError('Phase 2');

  @override
  Future<void> close() => throw UnimplementedError('Phase 2');
}
