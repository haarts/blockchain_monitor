import 'dart:convert';
import 'dart:io';

import 'package:blockbook/blockbook.dart' as blockbook;
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'package:blockchain_monitor/blockchain_monitor.dart';

class MockBlockbook extends Mock implements blockbook.Blockbook {}

void main() {
  group('blocks()', () {
    test('happy path', () async {
      var subscriptionSuccess =
          json.decode('{"id":"0","data":{"subscribed":true}}');
      var newBlock = json.decode(
          '{"id":"1","data":{"height":611099,"hash":"00000000000000000010657f651f9a65814a3ba731ea997304ebcd6d9cf150eb"}}');

      var mock = MockBlockbook();
      when(mock.subscribeNewBlock()).thenAnswer((_) => Stream.fromIterable([
            subscriptionSuccess,
            newBlock,
          ]));

      Blockbook(Logger(), mock).blocks().listen(expectAsync1((block) {
        expect(block.height, 611099);
      }));
    });
  });

  group('transactions()', () {
    test('happy path', () async {
      var prefix = Directory.current.path.endsWith('test') ? '' : 'test/';
      var subscriptionMessage =
          json.decode('{"id":"0","data":{"subscribed":true}}');
      var tx = json.decode(
          File('${prefix}files/ws_subscribeAddresses.json').readAsStringSync());

      var mock = MockBlockbook();
      when(mock.subscribeAddresses(any)).thenAnswer((_) => Stream.fromIterable([
            subscriptionMessage,
            tx,
          ]));

      Blockbook(Logger(), mock)
          .transactions('3MSy6m8gqSjJ3maAXT2d2XbjN1Z85h8R5E')
          .listen(expectAsync1((transaction) {
        expect(transaction.txHash,
            'b3064c23e45afe710fae26e5dff0bad060f878e9ab744f040cbaf50517617c12');
      }));
    });
  });

  group('confirmations()', () {
    test('return confirmations', () async {
      var mock = MockBlockbook();
      when(mock.transaction(any))
          .thenAnswer((_) => Future.value({'blockHeight': 100}));
      when(mock.status()).thenAnswer((_) => Future.value({
            'blockbook': {'bestHeight': 100}
          }));

      var monitor = Blockbook(Logger(), mock);

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 1);
      }));
    });

    test('return 0 when tx is in mempool', () async {
      var mock = MockBlockbook();
      when(mock.transaction(any))
          .thenAnswer((_) => Future.value({'blockHeight': -1}));
      when(mock.status()).thenAnswer((_) => Future.value({
            'blockbook': {'bestHeight': 100}
          }));

      var monitor = Blockbook(Logger(), mock);

      monitor.confirmations('some-hash').listen(expectAsync1((confirmations) {
        expect(confirmations, 0);
      }));
    });

    test('throws an exception when Blockbook returns one', () async {
      var mock = MockBlockbook();
      when(mock.transaction(any))
          .thenAnswer((_) => Future.value({'error': 'some reason'}));
      when(mock.status()).thenAnswer((_) => Future.value({
            'blockbook': {'bestHeight': 100}
          }));

      var monitor = Blockbook(Logger(), mock);
      expect(
        monitor.confirmations('some-hash'),
        emitsError(TypeMatcher<AdapterException>()),
      );
    });
  });
}
