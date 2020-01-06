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
}
