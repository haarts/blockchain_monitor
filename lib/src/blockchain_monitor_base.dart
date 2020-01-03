import 'package:logger/logger.dart';

import 'redundant_stream.dart';
import 'block.dart';
import 'transaction.dart';
import 'adapters/adapter.dart';

/// Instantiate this class to obtain a robust blockchain monitor.
class Monitor {
  Monitor(this._adapters);

  List<Adapter> _adapters;

  // TODO: pass logger onward
  factory Monitor.defaults([Logger logger]) {
    return Monitor([
      Blockbook.defaults(),
      Blockchair.defaults(),
      Blockcypher(logger),
      BlockchainInfo(logger),
    ]);
  }

  Stream<Transaction> address(String address) {
    return RedundantStream<Transaction>(
        _adapters.map((adapter) => adapter.transactions(address))).stream;
  }

  Stream<Block> blocks() {
    return RedundantStream<Block>(_adapters.map((adapter) => adapter.blocks()))
        .stream;
  }

  Stream<int> confirmations(String txHash) {
    return RedundantStream<int>(
        _adapters.map((adapter) => adapter.confirmations(txHash))).stream;
  }
}
