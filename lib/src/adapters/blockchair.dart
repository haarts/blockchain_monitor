import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockchair extends Adapter {
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
    yield Transaction(inputs: [{'address': 'some-address'}]);
  }
}
