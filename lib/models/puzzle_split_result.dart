import '../widgets/jigsaw_piece_view.dart';
import 'puzzle_piece.dart';

class PuzzleSplitResult {
  const PuzzleSplitResult({required this.pieces, required this.profiles});

  final List<PuzzlePiece> pieces;
  final List<JigsawEdgeProfile> profiles;
}
