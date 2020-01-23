import 'dart:convert';
import 'package:blockchain_info/blockchain_info.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import 'adapter.dart';
import '../block.dart';
import '../transaction.dart';

class BlockchainInfo extends Adapter {
  BlockchainInfo(
    this._logger,
    this._inner,
  );

  factory BlockchainInfo.defaults([Logger logger]) {
    return BlockchainInfo(
      logger,
      Client(),
    );
  }

  final Logger _logger;
  final Client _inner;

  static const String _name = 'Blockchain.info';

  // TODO add retryStream
  // TODO immediately retrieve current block height upon invocation
  @override
  Stream<Block> blocks() {
    return _inner.newBlocks().map(json.decode).map((block) {
      var height = block['x']['height'];
      var hash = block['x']['hash'];

      _logger?.v({
        'msg': 'New block found for $_name',
        'hash': hash,
        'height': height,
        'name': _name,
      });

      return Block(
        height: height,
        hash: hash,
      );
    }).handleError((e) => AdapterException(_name, e.toString()));
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

  // TODO add retryStream
  @override
  Stream<Transaction> transactions(address) {
    return _inner
        .transactionsForAddress(address)
        .map(json.decode)
        .asyncMap((tx) async {
      _logger?.v({
        'msg': 'New transaction for $address on $_name',
        'address': address,
        'txHash': tx['x']['hash'],
      });
      return Transaction()
        ..txHash = tx['x']['hash']
        ..blockHeight =
            (await _inner.getTransaction(tx['x']['hash']))['block_height']
        ..inputs = tx['x']['inputs']
            .map<Input>((input) => _inputFromJSON(input))
            .toList()
        ..outputs = tx['x']['out']
            .map<Output>((output) => _outputFromJSON(output))
            .toList();
    }).handleError((e) => AdapterException(_name, e.toString()));
  }

  Output _outputFromJSON(Map<String, dynamic> output) {
    return Output()
      ..addresses = [output['addr']]
      ..value = output['value'];
  }

  // TODO: fix missing txHash (should it be a txHash at all?)
  Input _inputFromJSON(Map<String, dynamic> input) {
    return Input()
      ..sequence = input['sequence']
      ..value = input['prev_out']['value'];
  }

  Future<int> _bestHeight() async {
    var response = await retry(_inner.getLatestBlock);
    return response['height'];
  }

  Future<int> _txHeight(String txHash) async {
    var response = await retry(() => _inner.getTransaction(txHash));
    // Unconfirmed txs don't have the block_height field set
    return response['block_height'] ?? 0;
  }
}
