import 'dart:io';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:blockcypher/blockcypher.dart' as blockcypher;

import 'package:blockchain_monitor/blockchain_monitor.dart';

class MockBlockcypher extends Mock implements blockcypher.Client {}

void main() {
  var prefix = Directory.current.path.endsWith('test') ? '' : 'test/';

  group('transactions()', () {
    test('returns transactions', () async {
      var mock = MockBlockcypher();
      when(mock.unconfirmedTransactions('some-address')).thenAnswer((_) =>
          Stream.value(File('${prefix}files/blockcypher_new_transaction.json')
              .readAsStringSync()));

      var monitor = Blockcypher(
        null,
        mock,
      );

      monitor.transactions('some-address').listen(expectAsync1((tx) {
        expect(tx.txHash,
            'f1ec11faf56efb52672e70664f554e8ec55ac21cce59d1a795164041c003d0b9');

        expect(tx.inputs, hasLength(2));
        expect(tx.inputs.first.sequence, 4294967295);

        expect(tx.outputs, hasLength(2));
        expect(tx.outputs.first.value, 5194064);
        expect(tx.outputs[1].addresses, ['1K1EKosWChX6R4goZr5z1UovmpsHgHxiHB']);
      }));
    });
  });

  group('blocks()', () {
    test('returns blocks', () async {
      var mock = MockBlockcypher();
      when(mock.newBlocks()).thenAnswer((_) => Stream.value(
          File('${prefix}files/blockcypher_new_block.json')
              .readAsStringSync()));

      var monitor = Blockcypher(
        null,
        mock,
      );
      monitor.blocks().listen(expectAsync1((block) {
        expect(block.height, 612639);
      }));
    });
  });

  group('confirmations()', () {
    test('return confirmations', () async {
      var mock = MockBlockcypher();
      when(mock.blockchain()).thenAnswer((_) => Future.value('{"height": 1}'));
      when(mock.transaction('some-hash'))
          .thenAnswer((_) => Future.value('{"block_height": 1}'));

      var monitor = Blockcypher(
        Logger(),
        mock,
      );

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 1);
      }));
    });

    test('throws an exception when Blockcypher returns one', () async {
      var mock = MockBlockcypher();
      when(mock.blockchain()).thenAnswer((_) => Future.value('{"height": 1}'));
      when(mock.transaction('some-hash'))
          .thenAnswer((_) => Future.value('{"error": "some error message"}'));

      var monitor = Blockcypher(
        Logger(),
        mock,
      );
      expect(
        monitor.confirmations('some-hash'),
        emitsError(TypeMatcher<AdapterException>()),
      );
    });
  });
}
