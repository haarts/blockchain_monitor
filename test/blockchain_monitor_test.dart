import 'package:blockchain_monitor/blockchain_monitor.dart';
import 'package:blockchain_monitor/src/redundant_stream.dart';
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
    yield Transaction()
      ..outputs = [
        Output()..addresses = ['some-address']
      ];
  }
}

void main() {
  Monitor monitor;

  setUp(() {
    monitor = Monitor([TestAdapter()]);
  });

  test('Monitor an address for transactions', () {
    monitor.address('some-address').listen(expectAsync1((tx) {
      expect(tx.outputs[0].addresses, ['some-address']);
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

  test('unique', () async {
    Stream<int> someRepeatingStream() async* {
      yield 0;
      yield 0;
      yield 1;
      yield 2;
      yield 2;
    }

    expect(
      someRepeatingStream().transform(Unique()),
      emitsInOrder(
        [
          0,
          1,
          2,
          emitsDone,
        ],
      ),
    );
  });
}
