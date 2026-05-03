import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/puzzle_piece.dart';
import '../models/puzzle_split_result.dart';

class ImageSplitter {
  /// Loads one image, resizes to a square, encodes once, and emits piece metadata only.
  /// Visual mapping is handled by clipping + translating the shared image per piece.
  static Future<PuzzleSplitResult> split({int gridSize = 3}) async {
    final data = await rootBundle.load('assets/images/tut.png');
    final bytes = data.buffer.asUint8List();

    final original = img.decodeImage(bytes)!;
    const edge = 600;
    final resized = img.copyResize(original, width: edge, height: edge);

    final fullImageBytes = Uint8List.fromList(img.encodePng(resized));

    final pieces = <PuzzlePiece>[];
    var index = 0;
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        pieces.add(
          PuzzlePiece(
            id: 'piece_$index',
            correctIndex: index,
            row: row,
            col: col,
          ),
        );
        index++;
      }
    }

    return PuzzleSplitResult(
      fullImageBytes: fullImageBytes,
      decodedWidth: resized.width,
      decodedHeight: resized.height,
      pieces: pieces,
    );
  }
}
