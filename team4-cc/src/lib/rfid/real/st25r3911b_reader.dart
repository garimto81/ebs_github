// ST25R3911BReader — Phase 2 real hardware driver.
//
// Implementation notes:
// * Physical transport: ESP32 bridge over USB-CDC serial UART at
//   115200 baud (CCR-022 §9 handshake).
// * Host-side transport is abstracted behind [SerialTransport] so the
//   driver itself stays testable without a real COM port. Unit tests
//   inject [FakeSerialTransport]; production wires through
//   `serial_port_win32` (Windows) or `libserialport` (Linux/macOS).
// * Frame format (CCR-022 §10): `[0xAA][cmd:1][len:1][payload:len][crc8:1]`.
//   Response frames reuse the same envelope with the high bit of `cmd` set.
// * Lifecycle mirrors `RfidReaderStatus` per §9. Reconnect cadence follows
//   `ReaderReconnectPolicy.retryDelays` in API-03 §9.3.
//
// Phase 2 follow-ups (tracked in Backlog):
//  - Firmware handshake exchange + version parsing (§11 spec).
//  - Antenna tuning retry loop (§10 AntennaTuningPolicy, already specified).
//  - Deck registration flow (§12).
//  - ST25R3916 migration: subclass + chip-detect probe (§13, CCR-022).

import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../abstract/i_rfid_reader.dart';

final _log = Logger('ST25R3911BReader');

// ---------------------------------------------------------------------------
// Wire protocol constants (CCR-022 §10)
// ---------------------------------------------------------------------------

const int kFrameStart = 0xAA;
const int kCmdOpen = 0x01;
const int kCmdClose = 0x02;
const int kCmdProbe = 0x03; // firmware / chip family probe (§11, §13)
const int kCmdRegisterDeck = 0x20;
const int kResponseMask = 0x80;

// ---------------------------------------------------------------------------
// Serial transport abstraction
// ---------------------------------------------------------------------------

/// Minimal serial interface the driver depends on. Production binds this
/// to `serial_port_win32` or `libserialport`; tests inject a fake.
abstract class SerialTransport {
  /// Opens the port. Throws if the port cannot be claimed.
  Future<void> open(String portName, {int baudRate = 115200});

  /// Writes a framed command. Returns once bytes are flushed.
  Future<void> write(Uint8List bytes);

  /// Stream of bytes received from the reader (unframed).
  Stream<Uint8List> get bytes;

  Future<void> close();
}

/// Default no-op transport used until a platform implementation is wired.
///
/// Throws on [open] so production code fails loudly when the real
/// transport is missing instead of pretending to work.
class _UnboundSerialTransport implements SerialTransport {
  @override
  Stream<Uint8List> get bytes => const Stream.empty();
  @override
  Future<void> open(String portName, {int baudRate = 115200}) async {
    throw StateError(
      'No SerialTransport registered. Inject via St25r3911bReader '
      'constructor or bind a platform implementation before opening '
      'the reader. See CCR-022 §9.',
    );
  }

  @override
  Future<void> write(Uint8List bytes) async {}
  @override
  Future<void> close() async {}
}

// ---------------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------------

class St25r3911bReader implements IRfidReader {
  St25r3911bReader({SerialTransport? transport})
      : _transport = transport ?? _UnboundSerialTransport();

  final SerialTransport _transport;
  RfidReaderStatus _status = RfidReaderStatus.disconnected;
  StreamSubscription<Uint8List>? _rxSub;
  final _buffer = BytesBuilder();

  final _statusCtl = StreamController<RfidReaderStatus>.broadcast();
  final _cardDetectedCtl = StreamController<CardDetectedEvent>.broadcast();
  final _cardRemovedCtl = StreamController<CardRemovedEvent>.broadcast();
  final _deckRegisteredCtl = StreamController<DeckRegisteredEvent>.broadcast();
  final _antennaCtl =
      StreamController<AntennaStatusChangedEvent>.broadcast();
  final _errorCtl = StreamController<ReaderErrorEvent>.broadcast();

  // -- IRfidReader ----------------------------------------------------------

  @override
  RfidReaderStatus get status => _status;

  @override
  Stream<RfidReaderStatus> get onStatusChanged => _statusCtl.stream;

  @override
  Stream<CardDetectedEvent> get onCardDetected => _cardDetectedCtl.stream;

  @override
  Stream<CardRemovedEvent> get onCardRemoved => _cardRemovedCtl.stream;

  @override
  Stream<DeckRegisteredEvent> get onDeckRegistered =>
      _deckRegisteredCtl.stream;

  @override
  Stream<AntennaStatusChangedEvent> get onAntennaStatusChanged =>
      _antennaCtl.stream;

  @override
  Stream<ReaderErrorEvent> get onError => _errorCtl.stream;

  @override
  Future<void> open(String serialPort) async {
    _setStatus(RfidReaderStatus.connecting);
    try {
      await _transport.open(serialPort);
      _rxSub = _transport.bytes.listen(_onBytes, onError: (Object e) {
        _errorCtl.add(ReaderErrorEvent(code: 1, message: e.toString()));
      });
      await _send(kCmdOpen);
      _setStatus(RfidReaderStatus.connected);
    } catch (e, st) {
      _log.warning('open failed: $e', e, st);
      _setStatus(RfidReaderStatus.connectionFailed);
      _errorCtl.add(ReaderErrorEvent(code: 2, message: '$e'));
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    try {
      await _send(kCmdClose);
    } catch (_) {
      // best-effort; we still close the port.
    }
    await _rxSub?.cancel();
    _rxSub = null;
    await _transport.close();
    _setStatus(RfidReaderStatus.disconnected);
  }

  // -- Internal helpers -----------------------------------------------------

  void _setStatus(RfidReaderStatus next) {
    if (_status == next) return;
    _status = next;
    _statusCtl.add(next);
  }

  Future<void> _send(int cmd, [List<int>? payload]) {
    final body = payload ?? const <int>[];
    final frame = Uint8List(4 + body.length);
    frame[0] = kFrameStart;
    frame[1] = cmd;
    frame[2] = body.length;
    for (var i = 0; i < body.length; i++) {
      frame[3 + i] = body[i];
    }
    frame[frame.length - 1] = _crc8(frame.sublist(1, frame.length - 1));
    return _transport.write(frame);
  }

  void _onBytes(Uint8List chunk) {
    _buffer.add(chunk);
    final bytes = _buffer.toBytes();
    // Very small framer: find start, length, trailer.
    var cursor = 0;
    while (cursor + 4 <= bytes.length) {
      if (bytes[cursor] != kFrameStart) {
        cursor++;
        continue;
      }
      if (cursor + 3 >= bytes.length) break;
      final len = bytes[cursor + 2];
      final end = cursor + 4 + len;
      if (end > bytes.length) break; // wait for more bytes
      final frame = bytes.sublist(cursor, end);
      cursor = end;
      _handleFrame(frame);
    }
    // Keep any unparsed tail for the next chunk.
    final remainder = bytes.sublist(cursor);
    _buffer
      ..clear()
      ..add(remainder);
  }

  void _handleFrame(Uint8List frame) {
    // frame = [AA][cmd|0x80][len][payload...][crc]
    if (frame.length < 4) return;
    final cmd = frame[1] & 0x7F;
    final len = frame[2];
    final payload = frame.sublist(3, 3 + len);
    final crc = frame[3 + len];
    if (_crc8(frame.sublist(1, 3 + len)) != crc) {
      _errorCtl.add(const ReaderErrorEvent(code: 3, message: 'CRC mismatch'));
      return;
    }
    // Phase 2 TODO: dispatch to typed event parsers (CardDetected, etc.).
    // Current skeleton only logs for observability.
    _log.fine('frame cmd=0x${cmd.toRadixString(16)} len=$len '
        'payload=$payload');
  }

  /// CRC-8/MAXIM polynomial 0x31 init 0x00 — matches ESP32 firmware spec.
  int _crc8(List<int> data) {
    var crc = 0;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x31) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return crc;
  }
}
