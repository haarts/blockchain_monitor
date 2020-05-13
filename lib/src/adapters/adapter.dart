import '../block.dart';
import '../transaction.dart';

export 'blockbook.dart';
export 'blockchain_info.dart';
export 'blockchair.dart';
export 'blockcypher.dart';

abstract class Adapter {
  /// Stream of blocks as they are mined
  Stream<Block> blocks();

  // Stream of ever increasing number of confirmations for a particular tx
  Stream<int> confirmations(String txHash);

  // Stream of all transactions involving this address.
  Stream<Transaction> transactions(String address);
}

class AdapterException implements Exception {
  AdapterException(this.name, this.reason, this.stackTrace);
  final String name;
  final String reason;
  final StackTrace stackTrace;

  @override
  String toString() =>
      'An Exception occured in the $name adapter: $reason, $stackTrace';
}

Stream<int> longPollConfirmations(
  Future<int> Function() txHeight,
  Future<int> Function() currentHeight, {
  Duration interval = const Duration(seconds: 60),
}) {
  return _longPoll(
    txHeight,
    currentHeight,
    interval,
  ).distinct();
}

// TODO: txHeight doesn't change once it is mined and could be cached
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
    await Future.delayed(interval);
  }
}
