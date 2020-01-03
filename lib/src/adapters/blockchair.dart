import 'package:blockchair/blockchair.dart' as blockchair;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockchair extends Adapter {
  Blockchair(this._logger, this._inner);

  factory Blockchair.defaults() {
    return Blockchair(
      Logger(),
      blockchair.Blockchair(_defaultUrl),
    );
  }

  static const String _defaultUrl = 'https://api.blockchair.com/bitcoin/';

  Logger _logger;
  blockchair.Blockchair _inner;

  @override
  Stream<Block> blocks() async* {
    yield Block(height: 100);
  }

  @override
  Stream<int> confirmations(txHash) {
    return longPollConfirmations(
      () => _txHeight(txHash),
      _bestHeight,
    );
  }

  @override
  Stream<Transaction> transactions(address) async* {
    yield Transaction();
  }

  Future<int> _bestHeight() async {
    var response = await retry(_inner.stats);
    return response['data']['blocks'];
  }

  Future<int> _txHeight(String txHash) async {
    try {
      var response = await retry(
        () => _inner.transaction(txHash),
        maxAttempts: 3,
        maxDelay: const Duration(seconds: 3),
      );
      return response['data'][txHash]['transaction']['block_id'] ?? 0;
    } on FormatException catch (e) {
      throw AdapterException(
          'Blockchair', 'fetching tx height of $txHash, exception: $e');
    }
  }
}
