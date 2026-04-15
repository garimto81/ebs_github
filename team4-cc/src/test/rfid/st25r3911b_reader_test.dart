// Skeleton-level tests for ST25R3911BReader. Real hardware integration
// is Phase 2; these tests lock in the frame format + lifecycle so the
// implementation does not regress while the UART transport is stubbed.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/rfid/abstract/i_rfid_reader.dart';
import 'package:ebs_cc/rfid/real/st25r3911b_reader.dart';

class _FakeTransport implements SerialTransport {
  final _rxCtl = StreamController<Uint8List>.broadcast();
  final List<Uint8List> writes = [];
  bool isOpen = false;
  String? portName;

  @override
  Stream<Uint8List> get bytes => _rxCtl.stream;

  @override
  Future<void> open(String portName, {int baudRate = 115200}) async {
    this.portName = portName;
    isOpen = true;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    writes.add(bytes);
  }

  @override
  Future<void> close() async {
    isOpen = false;
  }
}

void main() {
  group('ST25R3911BReader skeleton', () {
    late _FakeTransport transport;
    late St25r3911bReader reader;

    setUp(() {
      transport = _FakeTransport();
      reader = St25r3911bReader(transport: transport);
    });

    test('initial status is disconnected', () {
      expect(reader.status, RfidReaderStatus.disconnected);
    });

    test('open emits connecting -> connected and writes kCmdOpen frame',
        () async {
      final states = <RfidReaderStatus>[];
      reader.onStatusChanged.listen(states.add);

      await reader.open('COM3');
      await Future<void>.delayed(Duration.zero);

      expect(transport.isOpen, true);
      expect(transport.portName, 'COM3');
      expect(states, contains(RfidReaderStatus.connecting));
      expect(states.last, RfidReaderStatus.connected);

      // Exactly one frame: [AA][01][00][crc].
      expect(transport.writes.length, 1);
      final frame = transport.writes.single;
      expect(frame[0], 0xAA);
      expect(frame[1], 0x01);
      expect(frame[2], 0x00);
      expect(frame.length, 4);
    });

    test('close writes kCmdClose and returns to disconnected', () async {
      await reader.open('COM3');
      transport.writes.clear();

      await reader.close();

      expect(transport.isOpen, false);
      expect(reader.status, RfidReaderStatus.disconnected);
      expect(transport.writes.length, 1);
      expect(transport.writes.single[1], 0x02);
    });

    test('open failure surfaces connectionFailed + error', () async {
      final failing = _FakeTransportFailing();
      final r = St25r3911bReader(transport: failing);

      final errors = <ReaderErrorEvent>[];
      r.onError.listen(errors.add);

      await expectLater(r.open('COM999'), throwsA(isA<StateError>()));
      // Let the broadcast StreamController flush the error event.
      await Future<void>.delayed(Duration.zero);
      expect(r.status, RfidReaderStatus.connectionFailed);
      expect(errors, isNotEmpty);
    });

    test('CRC mismatch on incoming frame surfaces error', () async {
      await reader.open('COM3');
      final errors = <ReaderErrorEvent>[];
      reader.onError.listen(errors.add);

      // Valid envelope with deliberately wrong CRC.
      transport._rxCtl.add(Uint8List.fromList([0xAA, 0x81, 0x00, 0xFF]));
      await Future<void>.delayed(Duration.zero);

      expect(errors.any((e) => e.message.contains('CRC')), true);
    });

    test('default reader without transport fails loudly on open', () async {
      final r = St25r3911bReader();
      await expectLater(r.open('COM3'), throwsA(isA<StateError>()));
    });
  });
}

class _FakeTransportFailing implements SerialTransport {
  @override
  Stream<Uint8List> get bytes => const Stream.empty();
  @override
  Future<void> open(String portName, {int baudRate = 115200}) async {
    throw StateError('port busy');
  }

  @override
  Future<void> write(Uint8List bytes) async {}
  @override
  Future<void> close() async {}
}
