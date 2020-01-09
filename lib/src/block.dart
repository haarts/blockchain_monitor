class Block {
  Block({this.height});
  int height;
  String hash;

  @override
  String toString() => 'Block: height = $height, hash = $hash';
}
