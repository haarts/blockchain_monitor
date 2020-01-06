import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:blockcypher/blockcypher.dart' as blockcypher;

import 'package:blockchain_monitor/blockchain_monitor.dart';

class MockBlockcypher extends blockcypher.Client {
  MockBlockcypher() : super('', websocketUrl: '');

  @override
  Future<String> blockchain() {
    return Future.value('{"height": 1}');
  }

  @override
  Future<String> transaction(String txid) async {
    return Future.value('{"block_height": 1}');
  }
}

class FailingMockBlockcypher extends blockcypher.Client {
  FailingMockBlockcypher() : super('', websocketUrl: '');

  @override
  Future<String> blockchain() {
    return Future.value('{"height": 1}');
  }

  @override
  Future<String> transaction(String txid) async {
    return Future.value('{"error": "some error message"}');
  }
}

void main() {
  group('confirmations()', () {
    test('return confirmations', () async {
      var monitor = Blockcypher(
        Logger(),
        MockBlockcypher(),
      );

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 1);
      }));
    });

    test('throws an exception when Blockcypher returns one', () async {
      var monitor = Blockcypher(
        Logger(),
        FailingMockBlockcypher(),
      );
      expect(
        monitor.confirmations('some-hash'),
        emitsError(TypeMatcher<AdapterException>()),
      );
    });
  });
}
