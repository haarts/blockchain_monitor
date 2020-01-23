import 'dart:convert';
import 'dart:math';

class Transaction {
  Transaction({this.inputs});

  // TODO: rename to 'hash' b/c what else could it be?
  String txHash;
  int blockHeight;
  List<Input> inputs;
  List<Output> outputs;

  bool get isRBF => _extractLowestSequence() < 0xffffffff - 1;
  int _extractLowestSequence() =>
      inputs.map((i) => i.sequence).fold(0xffffffff, min);

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'txHash': txHash,
        'blockHeight': blockHeight,
        'inputs': inputs,
        'outputs': outputs,
      };
}

class Input {
  String txHash;
  int sequence;
  int value;

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'txHash': txHash,
        'sequence': sequence,
        'value': value,
      };
}

class Output {
  int value;
  List<String> addresses;

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'value': value,
        'addresses': addresses,
      };
}
