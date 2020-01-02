import 'package:blockbook/blockbook.dart' as blockbook;
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'package:blockchain_monitor/blockchain_monitor.dart';

void main() {
  MockWebServer server;
  setUp(() async {
    server = MockWebServer();
    await server.start();
  });

  tearDown(() async {
    server.shutdown();
  });

  test('return confirmations', () async {
    server
      ..enqueue(body: '{"blockHeight": 100}')
      ..enqueue(body: '{"blockbook": {"bestHeight": 100}}');

    var monitor = Blockbook(Logger(), blockbook.Blockbook(server.url, ''));

    monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
      expect(confirmations, 1);
    }));
  });

  test('throws an exception when Blockbook returns one', () async {
    server
      ..enqueue(body: '{"error": 100}')
      ..enqueue(body: '{"blockbook": {"bestHeight": 100}}');

    var monitor = Blockbook(Logger(), blockbook.Blockbook(server.url, ''));
    expect(
      monitor.confirmations('some-hash'),
      emitsError(TypeMatcher<AdapterExpection>()),
    );
  });
}
