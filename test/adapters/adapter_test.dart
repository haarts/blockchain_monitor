import 'package:test/test.dart';

import 'package:blockchain_monitor/blockchain_monitor.dart';

void main() {
  test('longPollConfirmations()', () {
    var calls = 0;
    expect(
      longPollConfirmations(
        () async => 1,
        () async => calls++,
        interval: const Duration(milliseconds: 1),
      ),
      emitsInOrder([
        0,
        1,
        2,
      ]),
    );
  });
}
