import 'dart:convert';
import 'dart:math';

import 'package:blockcypher/blockcypher.dart' as blockcypher;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import '../block.dart';
import '../transaction.dart';
import 'adapter.dart';

class Blockcypher extends Adapter {
  Blockcypher(
    this._logger,
    this._inner,
  );

  factory Blockcypher.mainnet(String token, [Logger logger]) {
    return Blockcypher(
      logger,
      blockcypher.Client(
        token: token,
        httpUrl: _mainnetHttpUrl,
        websocketUrl: _mainnetWsUrl,
      ),
    );
  }

  factory Blockcypher.testnet(String token, [Logger logger]) {
    return Blockcypher(
      logger,
      blockcypher.Client(
        token: token,
        httpUrl: _testnetHttpUrl,
        websocketUrl: _testnetWsUrl,
      ),
    );
  }

  static const String _mainnetWsUrl =
      'wss://socket.blockcypher.com/v1/btc/main';
  static const String _mainnetHttpUrl =
      'https://api.blockcypher.com/v1/btc/main';

  static const String _testnetWsUrl =
      'wss://socket.blockcypher.com/v1/btc/test3';
  static const String _testnetHttpUrl =
      'https://api.blockcypher.com/v1/btc/test3';

  static const String _name = 'blockcypher';

  Logger _logger;
  blockcypher.Client _inner;

  // TODO: This can be better right?
  // With tx-confirmation https://www.blockcypher.com/dev/bitcoin/#events-and-hooks
  @override
  Stream<int> confirmations(String txHash) {
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

  // TODO: add retry stream
  @override
  Stream<Transaction> transactions(String address) {
    return _inner.unconfirmedTransactions(address).map(json.decode).map((tx) {
      _logger?.v({
        'msg': 'New transaction for $address on $_name',
        'address': address,
        'txHash': tx['hash'],
      });
      return Transaction()
        ..txHash = tx['hash']
        ..blockHeight = 0
        ..inputs = tx['inputs'].map<Input>(_inputFromJson).toList()
        ..outputs = tx['outputs'].map<Output>(_outputFromJson).toList();
    }).handleError((e, s) => throw AdapterException(_name, e.toString(), s));
  }

  @override
  Stream<Block> blocks() {
    return _inner.newBlocks().map(json.decode).map((block) {
      var hash = block['hash'];
      var height = block['height'];

      _logger?.v({
        'msg': 'New block found for $_name',
        'hash': hash,
        'height': height,
        'name': _name,
      });

      return Block(
        hash: hash,
        height: height,
      );
    }).handleError((e, s) => throw AdapterException(_name, e.toString(), s));
  }

  Input _inputFromJson(input) {
    return Input()
      ..sequence = input['sequence']
      ..value = input['output_value']
      ..txHash = input['prev_hash'];
  }

  Output _outputFromJson(output) {
    return Output()
      ..addresses = output['addresses'].cast<String>()
      ..value = output['value'];
  }

  Future<int> _txHeight(String txHash) async {
    var response = await retry(() => _inner.transaction(txHash));
    var message = json.decode(response);
    if (message.containsKey('error')) {
      throw AdapterException(
        'Blockcypher',
        message.toString(),
        StackTrace.current,
      );
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
