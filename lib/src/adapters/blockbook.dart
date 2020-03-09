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

  factory Blockbook.mainnet([Logger logger]) {
    return Blockbook(
      logger,
      blockbook.Blockbook(_mainnetUrl, _mainnetWebsocketUrl),
    );
  }

  factory Blockbook.testnet([Logger logger]) {
    return Blockbook(
      logger,
      blockbook.Blockbook(_testnetUrl, _testnetWebsocketUrl),
    );
  }

  static const String _mainnetUrl = 'https://btc1.trezor.io';
  static const String _mainnetWebsocketUrl = 'wss://btc1.trezor.io/websocket';
  static const String _testnetUrl = 'https://tbtc2.trezor.io';
  static const String _testnetWebsocketUrl = 'wss://tbtc2.trezor.io/websocket';
  static const String _name = 'blockbook';

  Logger _logger;
  blockbook.Blockbook _inner;

  @override
  Stream<Block> blocks() {
    return _inner
        .subscribeNewBlock()
        .skip(1)
        .map<Block>((block) => _blockFromJSON(block['data']))
        .map((block) {
      _logger?.v({
        'msg': 'New block found for $_name',
        'hash': block.hash,
        'height': block.height,
        'name': _name,
      });

      return block;
    }).handleError((e, s) => throw AdapterException(_name, e.toString(), s));
  }

  @override
  Stream<int> confirmations(txHash) {
    return longPollConfirmations(
      () => _txHeight(txHash),
      _bestHeight,
    ).map((height) {
      _logger?.v({
        'msg': 'New confirmation for $txHash on $_name',
        'txHash': txHash,
        'height': height,
        'name': _name,
      });
      return height;
    });
  }

  @override
  Stream<Transaction> transactions(address) {
    // skip(1) ignores the subscription success message
    return _inner
        .subscribeAddresses([address])
        .skip(1)
        .map<Transaction>((tx) => _transactionFromJSON(tx['data']['tx']))
        .map((tx) {
          _logger?.v({
            'msg': 'New transaction for $address on $_name',
            'address': address,
            'txHash': tx.txHash,
            'name': _name,
          });

          return tx;
        })
        .handleError((e, s) => throw AdapterException(_name, e.toString(), s));
  }

  Block _blockFromJSON(Map<String, dynamic> response) => Block(
        height: response['height'],
        hash: response['hash'],
      );

  Transaction _transactionFromJSON(Map<String, dynamic> response) {
    return Transaction()
      ..txHash = response['txid']
      ..blockHeight = response['blockHeight']
      ..inputs =
          response['vin'].map<Input>((input) => _inputFromJSON(input)).toList()
      ..outputs = response['vout']
          .map<Output>((output) => _outputFromJSON(output))
          .toList();
  }

  Input _inputFromJSON(Map<String, dynamic> response) {
    return Input()
      ..txHash = response['txid']
      ..sequence = response['sequence']
      ..value = int.parse(response['value']);
  }

  Output _outputFromJSON(Map<String, dynamic> response) {
    return Output()
      ..addresses = response['addresses'].cast<String>()
      ..value = int.parse(response['value']);
  }

  Future<int> _bestHeight() async {
    var response = await retry(_inner.status);
    if (response.containsKey('error')) {
      throw AdapterException(
        'Blockbook',
        response.toString(),
        StackTrace.current,
      );
    }

    return response['blockbook']['bestHeight'];
  }

  Future<int> _txHeight(String txHash) async {
    var response = await retry(() => _inner.transaction(txHash));
    if (response.containsKey('error')) {
      throw AdapterException(
        'Blockbook',
        response.toString(),
        StackTrace.current,
      );
    }

    return response['blockHeight'] ?? 0;
  }
}
