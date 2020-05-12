# A high level blockchain monitoring library.

[![pub package](https://img.shields.io/pub/v/blockchain_monitor.svg)](https://pub.dartlang.org/packages/blockchain_monitor)
[![GH Actions](https://github.com/inapay/blockchain_monitor/workflows/dart/badge.svg)](https://github.com/inapay/blockchain_monitor/actions)



This library allows you to monitor blockchain events:
- new block
- new transaction for a particular address
- new confirmation for a particular transaction

It does so by using 4 different public API's:
- Blockbook (https://wiki.trezor.io/Blockbook)
- Blockcypher (https://www.blockcypher.com/dev/bitcoin/#introduction)
- Blockchain.info (https://www.blockchain.com/api)
- Blockchair (https://blockchair.com/api)

It uses 4 different API's for redundancy reasons. All events are normalized and de-duplicated.

Please note that this library does not contain any querying capabilities. Use the individual clients for that instead.

## Usage

A simple usage example:

```dart
import 'package:blockchain_monitor/blockchain_monitor.dart';

main() async {
  var monitor = new Monitor();
  Stream<Transaction> txs = monitor.address('some Bitcoin address');
  await for (tx in txs) {
    print(tx);
  }
  
  Stream<int> confirmations = monitor.confirmations('some tx hash');
  await for (confirmation in confirmations) {
    print(confirmation);
  }
  
  Stream<Block> blocks = monitor.blocks();
  await for (block in blocks) {
    print(block);
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://github.com/inapay/blockchain_monitor/issues
