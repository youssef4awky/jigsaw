import 'dart:typed_data';

class PuzzlePiece {
  final Uint8List bytes;
  final String id;
  final int correctIndex;
  bool isPlaced;

  PuzzlePiece({
    required this.id,
    required this.bytes,
    required this.correctIndex,
    this.isPlaced = false,
  });
}