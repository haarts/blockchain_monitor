import 'package:blockbook/blockbook.dart' as blockbook;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockbook extends Adapter {
  Blockbook(
    this._logger,
    this._inner,
  );

  factory Blockbook.defaults() {
    return Blockbook(
      Logger(),
      blockbook.Blockbook(_defaultUrl, _defaultWebsocketUrl),
    );
  }

  static const String _defaultUrl = 'https://btc1.trezor.io';
  static const String _defaultWebsocketUrl = 'wss://btc1.trezor.io/websocket';

  Logger _logger;
  blockbook.Blockbook _inner;

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
    yield Transaction(inputs: [
      {'address': 'some-address'}
    ]);
  }

  Future<int> _bestHeight() async {
    var response = await retry(_inner.status);
    if (response.containsKey('error')) {
      throw AdapterException('Blockbook', response.toString());
    }

    return response['blockbook']['bestHeight'];
  }

  Future<int> _txHeight(String txHash) async {
    var response = await retry(() => _inner.transaction(txHash));
    if (response.containsKey('error')) {
      throw AdapterException('Blockbook', response.toString());
    }

    return response['blockHeight'] ?? 0;
  }
}
