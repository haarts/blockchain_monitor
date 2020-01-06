import 'package:blockchain_info/blockchain_info.dart';
import 'package:test/test.dart';

import 'package:blockchain_monitor/blockchain_monitor.dart';

class MockClient extends Client {
  @override
  Future<Map<String, dynamic>> getLatestBlock() =>
      Future.value({'height': 100});

  @override
  Future<Map<String, dynamic>> getTransaction(String txHash) =>
      Future.value({'block_height': 100});

  @override
  Stream<String> newBlocks() =>
      Stream.value('{"x": {"blockIndex":100, "hash": "some-hash"}}');

  @override
  Stream<String> transactionsForAddress(String address) => Stream.value(
      '{"x": {"hash": "some-hash", "inputs": [{"sequence": 1234, "prev_out": {"value": 1234}}], "out": [{"addr": "some-address", "value": 123}]}}');
}

void main() {
  group('confirmations()', () {
    test('return confirmations', () async {
      var monitor = BlockchainInfo(
        null,
        MockClient(),
      );
      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 1);
      }));
    });

    test('failure modes', () {}, skip: 'TODO');
  });

  group('blocks()', () {
    test('stream blocks', () {
      var monitor = BlockchainInfo(
        null,
        MockClient(),
      );
      expect(monitor.blocks(), emitsInOrder([TypeMatcher<Block>()]));
    });
  });

  group('transactions()', () {
    test('stream', () async {
      var monitor = BlockchainInfo(
        null,
        MockClient(),
      );
      expect(monitor.transactions('some address'),
          emits(TypeMatcher<Transaction>()));
    });
  });
}
