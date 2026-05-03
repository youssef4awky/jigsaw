class PuzzlePiece {
  final String id;
  final Uint8List bytes;
  final int correctIndex;

  final int row;
  final int col;

  bool isPlaced;

  PuzzlePiece({
    required this.id,
    required this.bytes,
    required this.correctIndex,
    required this.row,
    required this.col,
    this.isPlaced = false,
  });
}
