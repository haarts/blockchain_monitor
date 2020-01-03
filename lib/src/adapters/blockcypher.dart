import 'package:logger/logger.dart';
import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockcypher extends Adapter {
  Blockcypher(this._logger);

  Logger _logger;

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
    yield Transaction();
  }
}
