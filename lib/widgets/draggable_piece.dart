import 'dart:math';

import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import 'jigsaw_piece_view.dart';

class DraggablePiece extends StatefulWidget {
  const DraggablePiece({
    required this.piece,
    required this.size,
    required this.rotation,
    required this.profile,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCompleted,
    required this.data,
    this.isHinted = false,
    super.key,
  });

  final PuzzlePiece piece;
  final double size;
  final double rotation;
  final JigsawEdgeProfile profile;
  final int data;
  final VoidCallback onDragStarted;
  final ValueChanged<DraggableDetails> onDragEnd;
  final VoidCallback onDragCompleted;
  final bool isHinted;

  @override
  State<DraggablePiece> createState() => _DraggablePieceState();
}

class _DraggablePieceState extends State<DraggablePiece> with SingleTickerProviderStateMixin {
  late final AnimationController _idleController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final idleDy = sin(_idleController.value * pi * 2) * 2;
        final idleRotation = widget.rotation + (sin(_idleController.value * pi * 2) * 0.01);
        final base = Transform.translate(
          offset: Offset(0, idleDy),
          child: Transform.rotate(
            angle: idleRotation,
            child: _pieceCard(hovered: false),
          ),
        );
        return Draggable<int>(
          data: widget.data,
          onDragStarted: widget.onDragStarted,
          onDragCompleted: widget.onDragCompleted,
          onDragEnd: widget.onDragEnd,
          maxSimultaneousDrags: 1,
          feedback: SizedBox(
            width: widget.size,
            child: Transform.scale(
              scale: 1.08,
              child: _pieceCard(hovered: true),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.18,
            child: SizedBox(width: widget.size, child: base),
          ),
          child: SizedBox(width: widget.size, child: base),
        );
      },
    );
  }

  Widget _pieceCard({required bool hovered}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: hovered ? 24 : 10,
            spreadRadius: hovered ? 1.5 : 0,
            color: hovered ? Colors.cyanAccent.withValues(alpha: 0.35) : Colors.black26,
          ),
          if (widget.isHinted)
            BoxShadow(
              blurRadius: 22,
              spreadRadius: 2,
              color: Colors.amber.withValues(alpha: 0.5),
            ),
        ],
      ),
      child: JigsawPieceView(bytes: widget.piece.bytes, profile: widget.profile),
    );
  }
}
