import 'dart:typed_data';
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

    final marginX = (pieceWidth * 0.22).toInt();
    final marginY = (pieceHeight * 0.22).toInt();

    List<PuzzlePiece> pieces = [];
    int index = 0;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        int x = col * pieceWidth - marginX;
        int y = row * pieceHeight - marginY;

        int w = pieceWidth + marginX * 2;
        int h = pieceHeight + marginY * 2;

        if (x < 0) x = 0;
        if (y < 0) y = 0;

        if (x + w > resized.width) {
          w = resized.width - x;
        }

        if (y + h > resized.height) {
          h = resized.height - y;
        }

        final cropped = img.copyCrop(
          resized,
          x: x,
          y: y,
          width: w,
          height: h,
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
