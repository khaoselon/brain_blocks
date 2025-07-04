// lib/widgets/painters/hint_painter.dart
import 'package:flutter/material.dart';
import '../../models/puzzle_piece.dart';

/// ヒント表示用ペインター
class HintPainter extends CustomPainter {
  final PuzzlePiece piece;
  final PiecePosition hintPosition;
  final double cellSize;
  final Animation<double> animation;

  const HintPainter({
    required this.piece,
    required this.hintPosition,
    required this.cellSize,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final boardCells = piece
        .getRotatedCells()
        .map((cell) => cell + hintPosition)
        .toList();

    final opacity = (0.3 + 0.4 * animation.value);

    paint
      ..color = piece.color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (final cell in boardCells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      // 点線効果
      _drawDashedRect(canvas, rect, paint);
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashSize = 5.0;
    const gapSize = 3.0;

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;

    // 上辺
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dashSize,
      gapSize,
    );
    // 右辺
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dashSize,
      gapSize,
    );
    // 下辺
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dashSize,
      gapSize,
    );
    // 左辺
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dashSize,
      gapSize,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashSize,
    double gapSize,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashSize + gapSize)).floor();

    final direction = (end - start) / distance;

    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + direction * (i * (dashSize + gapSize));
      final dashEnd = dashStart + direction * dashSize;
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(HintPainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.hintPosition != hintPosition ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.animation.value != animation.value;
  }
}
