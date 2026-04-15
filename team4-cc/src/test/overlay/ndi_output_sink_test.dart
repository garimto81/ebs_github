// NdiOutputSink contract tests. Covers the stub implementation (always
// available) and the MethodChannel implementation (with a fake channel).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/overlay/services/ndi_output_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubNdiOutputSink', () {
    test('starts inactive; open -> active; close -> inactive', () async {
      final sink = StubNdiOutputSink();
      expect(sink.isActive, false);
      await sink.open('test');
      expect(sink.isActive, true);
      await sink.close();
      expect(sink.isActive, false);
    });

    test('frames only count while active', () async {
      final sink = StubNdiOutputSink();
      await sink.send({'a': 1});
      expect(sink.frameCount, 0);

      await sink.open('stream');
      await sink.send({'a': 1});
      await sink.send({'b': 2});
      expect(sink.frameCount, 2);

      await sink.close();
      await sink.send({'c': 3});
      expect(sink.frameCount, 2);
    });
  });

  group('MethodChannelNdiOutputSink', () {
    const channel = MethodChannel('ebs/ndi_output');
    final calls = <MethodCall>[];
    late MethodChannelNdiOutputSink sink;

    setUp(() {
      calls.clear();
      sink = MethodChannelNdiOutputSink(channel);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('open / send / close produce matching method calls', () async {
      await sink.open('wsop-2026');
      await sink.send({'pot': 1000});
      await sink.close();

      expect(calls.map((c) => c.method).toList(),
          ['open', 'send', 'close']);
      expect(calls[0].arguments, {'stream_name': 'wsop-2026'});
      expect(calls[1].arguments, {'pot': 1000});
    });

    test('missing plugin -> stays inactive, no throw', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw MissingPluginException('no impl');
      });
      await sink.open('x');
      expect(sink.isActive, false);
      // send should be a no-op while inactive.
      await sink.send({'pot': 1});
    });
  });
}
