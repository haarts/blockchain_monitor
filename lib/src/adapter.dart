import 'block.dart';
import 'transaction.dart';

abstract class Adapter {
  Stream<Block> blocks();

  Stream<int> confirmations(String txHash);

  Stream<Transaction> transactions(String address);
}
