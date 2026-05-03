import 'dart:typed_data';

import 'puzzle_piece.dart';

class PuzzleSplitResult {
  const PuzzleSplitResult({
    required this.fullImageBytes,
    required this.decodedWidth,
    required this.decodedHeight,
    required this.pieces,
  });

  /// Single encoded image (square) shared by every piece renderer.
  final Uint8List fullImageBytes;

  /// Pixel width/height of [fullImageBytes] after decode-resize (used for asserts / future non-square grids).
  final int decodedWidth;
  final int decodedHeight;

  final List<PuzzlePiece> pieces;
}
