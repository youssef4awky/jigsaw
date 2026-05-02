import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class JigsawEdgeProfile {
  const JigsawEdgeProfile({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final int top;
  final int right;
  final int bottom;
  final int left;
}

class JigsawSlotOutline extends StatelessWidget {
  const JigsawSlotOutline({
    required this.profile,
    required this.strokeColor,
    this.fillColor = Colors.transparent,
    this.outlineOpacity = 1,
    super.key,
  });

  final JigsawEdgeProfile profile;
  final Color strokeColor;
  final Color fillColor;
  final double outlineOpacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: JigsawOutlinePainter(
        profile: profile,
        strokeColor: strokeColor,
        fillColor: fillColor,
        outlineOpacity: outlineOpacity,
      ),
    );
  }
}

class JigsawPieceView extends StatelessWidget {
  const JigsawPieceView({
    required this.bytes,
    required this.profile,
    this.borderColor = const Color(0x80FFFFFF),
    this.outlineOpacity = 1,
    super.key,
  });

  final Uint8List bytes;
  final JigsawEdgeProfile profile;
  final Color borderColor;
  final double outlineOpacity;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: JigsawOutlinePainter(
          profile: profile,
          strokeColor: borderColor,
          fillColor: Colors.transparent,
          outlineOpacity: outlineOpacity,
        ),
        child: ClipPath(
          clipper: JigsawClipper(profile),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class JigsawClipper extends CustomClipper<Path> {
  const JigsawClipper(this.profile);

  final JigsawEdgeProfile profile;

  @override
  Path getClip(Size size) => _jigsawPath(size, profile);

  @override
  bool shouldReclip(covariant JigsawClipper oldClipper) => oldClipper.profile != profile;
}

class JigsawOutlinePainter extends CustomPainter {
  const JigsawOutlinePainter({
    required this.profile,
    required this.strokeColor,
    required this.fillColor,
    this.outlineOpacity = 1,
  });

  final JigsawEdgeProfile profile;
  final Color strokeColor;
  final Color fillColor;
  final double outlineOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (outlineOpacity <= 0.001) return;
    final path = _jigsawPath(size, profile);
    if (fillColor != Colors.transparent) {
      final fill = Paint()
        ..color = fillColor.withValues(alpha: fillColor.a * outlineOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    }
    final stroke = Paint()
      ..color = strokeColor.withValues(alpha: strokeColor.a * outlineOpacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant JigsawOutlinePainter oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.outlineOpacity != outlineOpacity;
  }
}

Path _jigsawPath(Size size, JigsawEdgeProfile p) {
  final w = size.width;
  final h = size.height;
  final s = min(w, h);
  final corner = s * 0.06;
  final tabW = s * 0.34;
  final neckW = s * 0.14;
  final tabD = s * 0.18;
  final path = Path()..moveTo(corner, 0);

  _topEdge(path, w, p.top, corner, tabW, neckW, tabD);
  _rightEdge(path, w, h, p.right, corner, tabW, neckW, tabD);
  _bottomEdge(path, w, h, p.bottom, corner, tabW, neckW, tabD);
  _leftEdge(path, h, p.left, corner, tabW, neckW, tabD);
  path.close();
  return path;
}

void _topEdge(Path path, double w, int edge, double corner, double tabW, double neckW, double tabD) {
  path.lineTo((w - tabW) / 2 - neckW / 2, 0);
  if (edge != 0) {
    final out = edge == 1 ? -tabD : tabD;
    final x0 = (w - tabW) / 2;
    final x1 = x0 + (tabW - neckW) / 2;
    final x2 = x1 + neckW;
    final x3 = x0 + tabW;
    // neck in
    path.quadraticBezierTo(x0 + tabW * 0.06, 0, x1, out * 0.25);
    // bulb
    path.cubicTo(x1 + neckW * 0.08, out * 0.75, x1 + neckW * 0.18, out, x0 + tabW / 2, out);
    path.cubicTo(x2 - neckW * 0.18, out, x2 - neckW * 0.08, out * 0.75, x2, out * 0.25);
    // neck out
    path.quadraticBezierTo(x3 - tabW * 0.06, 0, x3 + neckW / 2, 0);
  }
  path.lineTo(w - corner, 0);
  path.quadraticBezierTo(w, 0, w, corner);
}

void _rightEdge(Path path, double w, double h, int edge, double corner, double tabW, double neckW, double tabD) {
  path.lineTo(w, (h - tabW) / 2 - neckW / 2);
  if (edge != 0) {
    final out = edge == 1 ? tabD : -tabD;
    final y0 = (h - tabW) / 2;
    final y1 = y0 + (tabW - neckW) / 2;
    final y2 = y1 + neckW;
    final y3 = y0 + tabW;
    path.quadraticBezierTo(w, y0 + tabW * 0.06, w + out * 0.25, y1);
    path.cubicTo(w + out * 0.75, y1 + neckW * 0.08, w + out, y1 + neckW * 0.18, w + out, y0 + tabW / 2);
    path.cubicTo(w + out, y2 - neckW * 0.18, w + out * 0.75, y2 - neckW * 0.08, w + out * 0.25, y2);
    path.quadraticBezierTo(w, y3 - tabW * 0.06, w, y3 + neckW / 2);
  }
  path.lineTo(w, h - corner);
  path.quadraticBezierTo(w, h, w - corner, h);
}

void _bottomEdge(Path path, double w, double h, int edge, double corner, double tabW, double neckW, double tabD) {
  path.lineTo((w + tabW) / 2 + neckW / 2, h);
  if (edge != 0) {
    final out = edge == 1 ? tabD : -tabD;
    final x0 = (w - tabW) / 2;
    final x1 = x0 + (tabW - neckW) / 2;
    final x2 = x1 + neckW;
    final x3 = x0 + tabW;
    path.quadraticBezierTo(x3 - tabW * 0.06, h, x2, h + out * 0.25);
    path.cubicTo(x2 - neckW * 0.08, h + out * 0.75, x2 - neckW * 0.18, h + out, x0 + tabW / 2, h + out);
    path.cubicTo(x1 + neckW * 0.18, h + out, x1 + neckW * 0.08, h + out * 0.75, x1, h + out * 0.25);
    path.quadraticBezierTo(x0 + tabW * 0.06, h, x0 - neckW / 2, h);
  }
  path.lineTo(corner, h);
  path.quadraticBezierTo(0, h, 0, h - corner);
}

void _leftEdge(Path path, double h, int edge, double corner, double tabW, double neckW, double tabD) {
  path.lineTo(0, (h + tabW) / 2 + neckW / 2);
  if (edge != 0) {
    final out = edge == 1 ? -tabD : tabD;
    final y0 = (h - tabW) / 2;
    final y1 = y0 + (tabW - neckW) / 2;
    final y2 = y1 + neckW;
    final y3 = y0 + tabW;
    path.quadraticBezierTo(0, y3 - tabW * 0.06, out * 0.25, y2);
    path.cubicTo(out * 0.75, y2 - neckW * 0.08, out, y2 - neckW * 0.18, out, y0 + tabW / 2);
    path.cubicTo(out, y1 + neckW * 0.18, out * 0.75, y1 + neckW * 0.08, out * 0.25, y1);
    path.quadraticBezierTo(0, y0 + tabW * 0.06, 0, y0 - neckW / 2);
  }
  path.lineTo(0, corner);
  path.quadraticBezierTo(0, 0, corner, 0);
}
