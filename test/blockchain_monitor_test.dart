import 'package:blockchain_monitor/blockchain_monitor.dart';
import 'package:test/test.dart';

class TestAdapter extends Adapter {
  @override
  Stream<Block> blocks() async* {
    yield Block(height: 100);
  }

  @override
  Stream<int> confirmations(txHash) async* {
    yield 0;
  }

  @override
  Stream<Transaction> transactions(address) async* {
    yield Transaction(inputs: [
      {'address': 'some-address'}
    ]);
  }
}

void main() {
  Monitor monitor;

  setUp(() {
    monitor = Monitor([TestAdapter()]);
  });

  test('Monitor an address for transactions', () {
    monitor.address('some-address').listen(expectAsync1((tx) {
      expect(tx.inputs[0]['address'], 'some-address');
    }));
  });

  test('Monitor a txHash for confirmations', () {
    monitor.confirmations('some-txhash').listen(expectAsync1((confirmations) {
      expect(confirmations, 0);
    }));
  });

  test('Monitor new blocks', () {
    monitor.blocks().listen(expectAsync1((block) {
      expect(block.height, 100);
    }));
  });

  test('de-duplicate events', () async {
    var monitor = Monitor([TestAdapter(), TestAdapter()]);
    monitor.confirmations('some-txhash').listen(expectAsync1((confirmations) {
          expect(confirmations, 0);
        }, count: 1));
  },
      skip:
          'this is broken, I thought I was testing RedundantStream here but I am not');
}
