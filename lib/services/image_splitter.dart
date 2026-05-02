import 'package:flutter/services.dart';

import 'package:image/image.dart' as img;

import '../models/puzzle_piece.dart';

class ImageSplitter {
  static Future<List<PuzzlePiece>> split({int gridSize = 3}) async {
    final data = await rootBundle.load("assets/images/tut.png");

    final bytes = data.buffer.asUint8List();

    final original = img.decodeImage(bytes)!;

    final resized = img.copyResize(original, width: 600, height: 600);

    final pieceWidth = resized.width ~/ gridSize;

    final pieceHeight = resized.height ~/ gridSize;

    List<PuzzlePiece> pieces = [];

    int index = 0;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cropped = img.copyCrop(
          resized,
          x: col * pieceWidth,
          y: row * pieceHeight,
          width: pieceWidth,
          height: pieceHeight,
        );

        final pieceBytes = Uint8List.fromList(img.encodePng(cropped));

        pieces.add(
          PuzzlePiece(
            id: 'piece_$index',
            bytes: pieceBytes,
            correctIndex: index,
          ),
        );

        index++;
      }
    }

    return pieces;
  }
}
