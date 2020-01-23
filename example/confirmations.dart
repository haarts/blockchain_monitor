import 'package:logger/logger.dart';
import 'package:blockchain_monitor/blockchain_monitor.dart';

void main(List<String> args) {
  var token = args[0];
  var monitor = Monitor.defaults(
    blockcypherToken: token,
    logger: Logger(
      level: Level.verbose,
      filter: ProductionFilter(),
      printer: LogfmtPrinter(),
    ),
  );
  var tx = args[1];
  monitor.confirmations(tx).listen(print);
}
