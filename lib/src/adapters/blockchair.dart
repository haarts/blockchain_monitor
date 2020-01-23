import 'dart:io';
import 'package:blockchair/blockchair.dart' as blockchair;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class Blockchair extends Adapter {
  Blockchair(this._logger, this._inner);

  factory Blockchair.defaults([Logger logger]) {
    return Blockchair(
      logger,
      blockchair.Blockchair(_defaultUrl),
    );
  }

  static const String _defaultUrl = 'https://api.blockchair.com/bitcoin/';
  static const String _name = 'Blockchair';

  Logger _logger;
  blockchair.Blockchair _inner;

  @override
  Stream<Block> blocks() async* {
    int lastBlockHeight;
    while (true) {
      var response = await _inner.stats();
      if (lastBlockHeight != response['data']['blocks'] - 1) {
        lastBlockHeight = response['data']['blocks'] - 1;
        var blockResponse = (await _inner.block(lastBlockHeight))['data']
            ['$lastBlockHeight']['block'];

        var hash = blockResponse['hash'];
        var height = blockResponse['id'];

        _logger?.v({
          'msg': 'New block found for $_name',
          'hash': hash,
          'height': height,
          'name': _name,
        });

        yield Block(
          hash: hash,
          height: height,
        );
      }
      await Future.delayed(const Duration(seconds: 5));
    }
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
  Stream<Transaction> transactions(address) async* {
    //ignore: omit_local_variable_types
    Set<String> seenTxHashes;
    while (true) {
      var info = await retry(() => _inner.address(address));
      var txs = Set<String>.from(info['data'][address]['transactions']);
      seenTxHashes ??= txs;

      var transactions =
          await Future.wait(txs.difference(seenTxHashes).map((tx) {
        seenTxHashes.add(tx);
        return tx;
      }).map((tx) => _newTransaction(tx)));

      for (var tx in transactions) {
        _logger?.v({
          'msg': 'New transaction for $address on $_name',
          'address': address,
          'txHash': tx.txHash,
        });
        yield tx;
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<Transaction> _newTransaction(String txHash) async {
    var tx = await retry(() => _inner.transaction(txHash));

    return Transaction()
      ..txHash = txHash
      ..blockHeight = tx['data'][txHash]['transaction']['block_id']
      ..inputs = _inputsFromJson(tx['data'][txHash]['inputs']).toList()
      ..outputs = _outputsFromJson(tx['data'][txHash]['outputs']).toList();
  }

  Iterable<Input> _inputsFromJson(List inputs) {
    return inputs.map<Input>((input) => Input()
      ..txHash = input['spending_transaction_hash']
      ..sequence = input['spending_sequence']
      ..value = input['value']);
  }

  Iterable<Output> _outputsFromJson(List outputs) {
    return outputs.map<Output>((output) => Output()
      ..addresses = [output['recipient']]
      ..value = output['value']);
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
