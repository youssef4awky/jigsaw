class PuzzlePiece {
  final String id;
  final int correctIndex;
  final int row;
  final int col;

  bool isPlaced;

  PuzzlePiece({
    required this.id,
    required this.correctIndex,
    required this.row,
    required this.col,
    this.isPlaced = false,
  });
}
