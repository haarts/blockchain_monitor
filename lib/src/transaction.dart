import 'dart:convert';

class Transaction {
  Transaction({this.inputs});

  String txHash;
  int blockHeight;
  List<Input> inputs;
  List<Output> outputs;

  bool get isRBF => _extractLowestSequence() < 1;
  int _extractLowestSequence() => 1;

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
