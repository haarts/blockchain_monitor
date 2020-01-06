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

  @override
  Stream<Transaction> transactions(address) async* {
    yield Transaction();
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
