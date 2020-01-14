import 'package:blockchain_monitor/blockchain_monitor.dart';

void main() {
  var monitor = Monitor.defaults();
  monitor.blocks().listen(print);
}
