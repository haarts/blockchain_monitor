import 'package:logger/logger.dart';

import 'redundant_stream.dart';
import 'block.dart';
import 'transaction.dart';
import 'adapters/adapter.dart';

/// Instantiate this class to obtain a robust blockchain monitor.
class Monitor {
  Monitor(this._adapters);

  List<Adapter> _adapters;

  factory Monitor.defaults({String blockcypherToken, Logger logger}) {
    return Monitor([
      Blockbook.defaults(logger),
      Blockchair.defaults(logger),
      Blockcypher.defaults(blockcypherToken, logger),
      BlockchainInfo.defaults(logger),
    ]);
  }

  /// Pass an address to be notified of all transactions occuring involving
  /// that address.
  Stream<Transaction> address(String address) {
    return RedundantStream<Transaction>(
        _adapters.map((adapter) => adapter.transactions(address))).stream;
  }

  /// Get notified whenever a new block is published.
  Stream<Block> blocks() {
    return RedundantStream<Block>(_adapters.map((adapter) => adapter.blocks()))
        .stream;
  }

  /// Given a transaction hash return a stream with ever increasing
  /// confirmations counts.
  Stream<int> confirmations(String txHash) {
    return RedundantStream<int>(
        _adapters.map((adapter) => adapter.confirmations(txHash))).stream;
  }
}
