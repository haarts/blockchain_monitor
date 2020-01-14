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

  factory BlockchainInfo.defaults() {
    return BlockchainInfo(
      Logger(),
      Client(),
    );
  }

  final Logger _logger;
  final Client _inner;

  // TODO add retryStream
  @override
  Stream<Block> blocks() {
    return _inner.newBlocks().map(json.decode).map((block) => Block()
      ..height = block['x']['blockIndex']
      ..hash = block['x']['hash']);
  }

  @override
  Stream<int> confirmations(txHash) {
    return longPollConfirmations(
      () => _txHeight(txHash),
      _bestHeight,
    );
  }

  // TODO add retryStream
  // TODO add exception handling
  @override
  Stream<Transaction> transactions(address) {
    return _inner
        .transactionsForAddress(address)
        .map(json.decode)
        .asyncMap((tx) async {
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
    }).handleError((e, s) => print('$e,$s'));
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
