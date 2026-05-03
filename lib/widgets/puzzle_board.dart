import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import 'jigsaw_piece_view.dart';
import 'puzzle_slot.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    required this.gridSize,
    required this.boardPieces,
    required this.profiles,
    required this.hintIndex,
    required this.wrongFlashIndex,
    required this.hintColor,
    this.outlineOpacity = 1,
    required this.onWillAccept,
    required this.onAccept,
    required this.onMove,
    super.key,
  });

  final int gridSize;
  final List<PuzzlePiece> boardPieces;
  final List<JigsawEdgeProfile> profiles;
  final int? hintIndex;
  final int? wrongFlashIndex;
  final Color hintColor;
  final double outlineOpacity;
  final bool Function(int index, int data) onWillAccept;
  final void Function(int index, int data) onAccept;
  final void Function(int index, int? data) onMove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: gridSize * gridSize,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemBuilder: (context, index) {
        final piece = boardPieces[index];
        return PuzzleSlot(
          index: index,
          placedPiece: piece.isPlaced ? piece : null,
          profile: profiles[index],
          isHinted: hintIndex == index,
          wrongFlash: wrongFlashIndex == index,
          highlightColor: hintColor,
          outlineOpacity: outlineOpacity,
          onWillAccept: (data) => onWillAccept(index, data),
          onAccept: (data) => onAccept(index, data),
          onMove: (data) => onMove(index, data),
        );
      },
    );
  }
}
