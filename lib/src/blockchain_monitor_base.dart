import 'package:logger/logger.dart';

import 'adapters/adapter.dart';
import 'block.dart';
import 'redundant_stream.dart';
import 'transaction.dart';

/// Instantiate this class to obtain a robust blockchain monitor.
class Monitor {
  Monitor(this._adapters);

  factory Monitor.mainnet({String blockcypherToken, Logger logger}) {
    return Monitor([
      Blockbook.mainnet(logger),
      Blockchair.mainnet(logger),
      Blockcypher.mainnet(blockcypherToken, logger),
      BlockchainInfo.mainnet(logger),
    ]);
  }

  factory Monitor.testnet({String blockcypherToken, Logger logger}) {
    return Monitor([
      Blockbook.testnet(logger),
      Blockchair.testnet(logger),
      Blockcypher.testnet(blockcypherToken, logger),
      BlockchainInfo.testnet(logger),
    ]);
  }

  List<Adapter> _adapters;

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
