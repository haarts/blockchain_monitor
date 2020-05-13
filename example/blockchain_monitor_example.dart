import 'package:logger/logger.dart';
import 'package:blockchain_monitor/blockchain_monitor.dart';

//ignore_for_file: avoid_print

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
  monitor.blocks().listen(print);
}
