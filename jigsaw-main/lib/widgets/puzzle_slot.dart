import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import 'jigsaw_piece_view.dart';

class PuzzleSlot extends StatelessWidget {
  const PuzzleSlot({
    required this.fullImageBytes,
    required this.decodedWidth,
    required this.decodedHeight,
    required this.gridSize,
    required this.index,
    required this.placedPiece,
    required this.profile,
    required this.isHinted,
    required this.wrongFlash,
    required this.highlightColor,
    this.outlineOpacity = 1,
    required this.onWillAccept,
    required this.onAccept,
    required this.onMove,
    super.key,
  });

  final Uint8List fullImageBytes;
  final int decodedWidth;
  final int decodedHeight;
  final int gridSize;
  final int index;
  final PuzzlePiece? placedPiece;
  final JigsawEdgeProfile profile;
  final bool isHinted;
  final bool wrongFlash;
  final Color highlightColor;
  final double outlineOpacity;
  final bool Function(int data) onWillAccept;
  final void Function(int data) onAccept;
  final void Function(int? data) onMove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => onWillAccept(details.data),
      onMove: (details) => onMove(details.data),
      onLeave: (_) => onMove(null),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, _, __) {
        final hasPiece = placedPiece != null;
        final stroke = wrongFlash
            ? Colors.redAccent
            : (isHinted ? Colors.amber : Colors.white30);
        final fill = hasPiece
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.06 * outlineOpacity.clamp(0.0, 1.0));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (isHinted)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.42),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              if (wrongFlash)
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.42),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              JigsawSlotOutline(
                profile: profile,
                strokeColor: stroke,
                fillColor: fill,
                outlineOpacity: outlineOpacity,
              ),
              if (hasPiece)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      JigsawPieceView(
                        fullImageBytes: fullImageBytes,
                        decodedWidth: decodedWidth,
                        decodedHeight: decodedHeight,
                        row: placedPiece!.row,
                        col: placedPiece!.col,
                        gridSize: gridSize,
                        profile: profile,
                        outlineOpacity: outlineOpacity,
                      ),
                      const _ShineSweep(),
                    ],
                  ),
                ),
              if (!hasPiece && isHinted)
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 180),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ShineSweep extends StatefulWidget {
  const _ShineSweep();

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = -1.3 + (_controller.value * 2.6);
        return IgnorePointer(
          child: Align(
            alignment: Alignment(x, 0),
            child: Container(
              width: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0), Colors.white54, Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
