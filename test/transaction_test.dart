import 'package:test/test.dart';

import 'package:blockchain_monitor/blockchain_monitor.dart';

void main() {
  group('isRBF', () {
    test('when sequence is 0xffffffff - 1', () {
      var transaction = Transaction()
        ..inputs = [Input()..sequence = 0xffffffff - 1];
      expect(transaction.isRBF, false);
    });

    test('when sequence is anything else', () {
      var transaction = Transaction()..inputs = [Input()..sequence = -1];
      expect(transaction.isRBF, true);

      transaction = Transaction()
        ..inputs = [Input()..sequence = 0xffffffff - 2];
      expect(transaction.isRBF, true);

      transaction = Transaction()..inputs = [Input()..sequence = 100];
      expect(transaction.isRBF, true);
    });
  });
}
