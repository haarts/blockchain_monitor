import 'package:logger/logger.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'package:test/test.dart';
import 'package:blockchair/blockchair.dart' as blockchair;

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

  group('confirmations()', () {
    test('return confirmations', () async {
      server
        ..enqueue(
          body: '{"data": {"some-hash": {"transaction": {"block_id": 100}}}}',
        )
        ..enqueue(body: '{"data": {"blocks": 105}}');

      var monitor = Blockchair(
        Logger(),
        blockchair.Blockchair(server.url),
      );

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 6);
      }));
    });

    test('throws an exception when Blockchair returns one', () async {
      server
        ..enqueue( body: 'some garbage')
        ..enqueue( body: 'some garbage')
        ..enqueue( body: 'some garbage')
        ..enqueue(body: '{"data": {"blocks": 100}}');

      var monitor = Blockchair(
        Logger(),
        blockchair.Blockchair(server.url),
      );
      expect(
        monitor.confirmations('some-hash'),
        emitsError(TypeMatcher<AdapterException>()),
      );
    });
  });
}
