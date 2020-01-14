import 'package:equatable/equatable.dart';

class Block extends Equatable {
  Block({this.height, this.hash});
  final int height;
  final String hash;

  @override
  List<Object> get props => [hash];

  @override
  String toString() => 'Block: height = $height, hash = $hash';
}
