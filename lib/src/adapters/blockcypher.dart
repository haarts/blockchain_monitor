import 'dart:convert';
import 'dart:math';

import 'package:blockcypher/blockcypher.dart' as blockcypher;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockcypher extends Adapter {
  Blockcypher(
    this._logger,
    this._inner,
  );

  factory Blockcypher.defaults() {
    return Blockcypher(
      Logger(),
      // TODO: deal with token
      blockcypher.Client(
        'some token',
        httpUrl: _defaultHttpUrl,
        websocketUrl: _defaultWsUrl,
      ),
    );
  }

  static const String _defaultWsUrl =
      'wss://socket.blockcypher.com/v1/btc/main';
  static const String _defaultHttpUrl =
      'https://api.blockcypher.com/v1/btc/main';
  static const String _name = 'blockcypher';

  Logger _logger;
  blockcypher.Client _inner;

  @override
  Stream<int> confirmations(String txHash) {
    return longPollConfirmations(
      () => _txHeight(txHash),
      _bestHeight,
    );
  }

  @override
  Stream<Transaction> transactions(String address) async* {
    yield Transaction();
  }

  @override
  Stream<Block> blocks() async* {
    yield Block(height: 100);
  }

  Future<int> _txHeight(String txHash) async {
    var response = await retry(() => _inner.transaction(txHash));
    var message = json.decode(response);
    if (message.containsKey('error')) {
      throw AdapterException('Blockcypher', message.toString());
    }
    // Blockcypher returns -1 for unconfirmed transactions
    return max(message['block_height'], 0);
  }

  Future<int> _bestHeight() async {
    var response = await retry(
      _inner.blockchain,
      maxAttempts: 3,
      maxDelay: const Duration(seconds: 2),
    );
    return json.decode(response)['height'];
  }
}
