import 'package:logger/logger.dart';
import 'package:blockchain_monitor/blockchain_monitor.dart';

void main(List<String> args) {
  var token = args[0];
  var monitor = Monitor.mainnet(
    blockcypherToken: token,
    logger: Logger(
      level: Level.verbose,
      filter: ProductionFilter(),
      printer: LogfmtPrinter(),
    ),
  );
  var address = args[1];
  monitor.address(address).listen(print);
}
