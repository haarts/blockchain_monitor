import '../block.dart';
import '../transaction.dart';

export 'blockbook.dart';
export 'blockchair.dart';
export 'blockcypher.dart';
export 'blockchain_info.dart';

abstract class Adapter {
  Stream<Block> blocks();

  Stream<int> confirmations(String txHash);

  Stream<Transaction> transactions(String address);
}
