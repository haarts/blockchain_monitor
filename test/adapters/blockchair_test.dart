import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:blockchair/blockchair.dart' as blockchair;

import 'package:blockchain_monitor/blockchain_monitor.dart';

class MockBlockchair extends Mock implements blockchair.Blockchair {}

void main() {
  var prefix = Directory.current.path.endsWith('test') ? '' : 'test/';

  group('blocks()', () {
    test('stream blocks', () async {
      var mock = MockBlockchair();
      when(mock.stats()).thenAnswer(
        (_) => Future.value(json.decode(
            File('${prefix}files/blockchair_stats.json').readAsStringSync())),
      );
      when(mock.block(any)).thenAnswer(
        (_) => Future.value(json.decode(
            File('${prefix}files/blockchair_block_612053.json')
                .readAsStringSync())),
      );
      var monitor = Blockchair(
        null,
        mock,
      );

      monitor.blocks().listen(expectAsync1((block) {
        expect(block.height, 612053);
      }));
    });
  });

  group('transactions()', () {
    test('ignore old txs', () {}, skip: 'TODO');
    test('return tx in which address is sender', () {}, skip: 'TODO');
    test('return tx in which address is recipient', () {}, skip: 'TODO');

    test('stream transactions', () async {
      var mock = MockBlockchair();
      var addressResponses = [
        Future<Map<String, dynamic>>.value(
          json.decode(File('${prefix}files/blockchair_address_no_txs.json')
              .readAsStringSync()),
        ),
        Future<Map<String, dynamic>>.value(
          json.decode(File('${prefix}files/blockchair_address.json')
              .readAsStringSync()),
        ),
      ];
      when(mock.address('3PBYXt5zihc9Wu1vRdeSd7enppFnzLwb5W'))
          .thenAnswer((_) => addressResponses.removeAt(0));
      when(mock.transaction(
              '3c521a6ee798dc14647a75dbdcfa96a667f198e1df6843eece5476acb11b18ff'))
          .thenAnswer((_) => Future.value(
                json.decode(
                    File('${prefix}files/blockchair_transaction_3c521a.json')
                        .readAsStringSync()),
              ));
      when(mock.transaction(
              '111072b628d04c7b60e5034518bc66bbf71afbdb6d183bdaf8e479409c5d95b7'))
          .thenAnswer((_) => Future.value(
                json.decode(
                    File('${prefix}files/blockchair_transaction_111072.json')
                        .readAsStringSync()),
              ));

      var monitor = Blockchair(
        null,
        mock,
      );

      monitor
          .transactions('3PBYXt5zihc9Wu1vRdeSd7enppFnzLwb5W')
          .listen(expectAsync1((tx) {
            expect(tx.blockHeight, isIn([597398, 597367]));
          }, count: 2));
    });
  });

  group('confirmations()', () {
    test('return confirmations', () async {
      var mock = MockBlockchair();
      when(mock.transaction('some-hash')).thenAnswer(
        (_) => Future.value({
          'data': {
            'some-hash': {
              'transaction': {'block_id': 100}
            }
          }
        }),
      );
      when(mock.stats()).thenAnswer(
        (_) => Future.value({
          'data': {'blocks': 105}
        }),
      );
      var monitor = Blockchair(
        Logger(),
        mock,
      );

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 6);
      }));
    });

    test('return 0 when tx is still in mempool', () async {
      var mock = MockBlockchair();
      when(mock.transaction('some-hash')).thenAnswer(
        (_) => Future.value({'data': []}),
      );
      var monitor = Blockchair(
        Logger(),
        mock,
      );

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 0);
      }));
    });

    test('throws an exception when Blockchair returns one', () async {
      var mock = MockBlockchair();
      when(mock.transaction('some-hash')).thenThrow(FormatException());

      var monitor = Blockchair(
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
