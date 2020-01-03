import 'dart:io';
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

  group('blocks()', () {
    test('happy path', () async {
      var subscriptionSuccess = '{"id":"0","data":{"subscribed":true}}';
      var newBlock =
          '{"id":"1","data":{"height":611099,"hash":"00000000000000000010657f651f9a65814a3ba731ea997304ebcd6d9cf150eb"}}';
      server.messageGenerator = (sink) {
        sink.add(subscriptionSuccess);
        sink.add(newBlock);
      };
      var client =
          blockbook.Blockbook('', 'ws://${server.host}:${server.port}/ws');

      await Blockbook(Logger(), client).blocks().listen(expectAsync1((block) {
        expect(block.height, 611099);
      }));
    });
  });

  group('transactions()', () {
    test('happy path', () async {
      var prefix = Directory.current.path.endsWith('test') ? '' : 'test/';
      var subscriptionMessage = '{"id":"0","data":{"subscribed":true}}';
      var tx =
          File('${prefix}files/ws_subscribeAddresses.json').readAsStringSync();
      server.messageGenerator = (sink) async {
        await Future.delayed(
            Duration(seconds: 1), () => sink.add(subscriptionMessage));
        await Future.delayed(Duration(seconds: 1), () => sink.add(tx));
      };

      var client =
          blockbook.Blockbook('', 'ws://${server.host}:${server.port}/ws');

      await Blockbook(Logger(), client)
          .transactions('3MSy6m8gqSjJ3maAXT2d2XbjN1Z85h8R5E')
          .listen(expectAsync1((transaction) {
        expect(transaction.txHash,
            'b3064c23e45afe710fae26e5dff0bad060f878e9ab744f040cbaf50517617c12');
      }));
    });
  });

  group('confirmations()', () {
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
        ..enqueue(body: '{"error": "some reason"}')
        ..enqueue(body: '{"blockbook": {"bestHeight": 100}}');

      var monitor = Blockbook(Logger(), blockbook.Blockbook(server.url, ''));
      expect(
        monitor.confirmations('some-hash'),
        emitsError(TypeMatcher<AdapterException>()),
      );
    });
  });
}
