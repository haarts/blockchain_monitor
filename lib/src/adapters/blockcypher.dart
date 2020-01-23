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

  factory Blockcypher.defaults(String token, [Logger logger]) {
    return Blockcypher(
      logger,
      blockcypher.Client(
        token: token,
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
  // TODO: handle exception
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
        ..inputs =
            tx['inputs'].map<Input>((input) => _inputFromJson(input)).toList()
        ..outputs = tx['outputs']
            .map<Output>((output) => _outputFromJson(output))
            .toList();
    });
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
    });
  }

  Input _inputFromJson(Map<String, dynamic> input) {
    return Input()
      ..sequence = input['sequence']
      ..value = input['output_value']
      ..txHash = input['prev_hash'];
  }

  Output _outputFromJson(Map<String, dynamic> output) {
    return Output()
      ..addresses = output['addresses'].cast<String>()
      ..value = output['value'];
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
