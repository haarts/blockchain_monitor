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

class AdapterExpection implements Exception {
  AdapterExpection(this.name, this.reason);
  final String name;
  final String reason;

  @override
  String toString() => 'An Exception occured in the $name adapter: $reason';
}

Stream<int> longPollConfirmations(
  Future<int> Function() txHeight,
  Future<int> Function() currentHeight, [
  Duration interval,
]) {
  return _longPoll(
    txHeight,
    currentHeight,
    interval,
  ).distinct();
}

Stream<int> _longPoll(
  Future<int> Function() txHeight,
  Future<int> Function() currentHeight, [
  Duration interval,
]) async* {
  while (true) {
    var tx = await txHeight();
    if (tx == 0) {
      yield 0;
    } else {
      yield await currentHeight() - tx + 1;
    }
    await Future.delayed(interval ?? const Duration(seconds: 60));
  }
}
