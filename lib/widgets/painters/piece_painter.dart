// lib/widgets/painters/piece_painter.dart
import 'package:flutter/material.dart';
import '../../models/puzzle_piece.dart';

/// 個別ピース描画（ドラッグ中・トレイ表示用）
class PiecePainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;
  final bool isSelected;
  final bool isDragging;
  final double scale;

  const PiecePainter({
    required this.piece,
    required this.cellSize,
    this.isSelected = false,
    this.isDragging = false,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cells = piece.getRotatedCells();

    if (cells.isEmpty) return;

    // スケール適用
    canvas.save();
    canvas.scale(scale);

    // 影効果（ドラッグ中）
    if (isDragging) {
      _drawShadow(canvas, cells, paint);
    }

    // ピース本体
    _drawPieceBody(canvas, cells, paint);

    // 選択状態のハイライト
    if (isSelected) {
      _drawSelectionHighlight(canvas, cells, paint);
    }

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, List<PiecePosition> cells, Paint paint) {
    paint
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize + 4,
        cell.y * cellSize + 4,
        cellSize,
        cellSize,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);
    }
  }

  void _drawPieceBody(Canvas canvas, List<PiecePosition> cells, Paint paint) {
    // グラデーション効果
    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      // ベース色
      paint
        ..color = piece.color
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);

      // ハイライト
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
          piece.color.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRRect(rrect, paint);
      paint.shader = null;

      // 境界線
      paint
        ..color = piece.color.withOpacity(0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);
    }
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    List<PiecePosition> cells,
    Paint paint,
  ) {
    paint
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize - 2,
        cell.y * cellSize - 2,
        cellSize + 4,
        cellSize + 4,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(PiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.scale != scale;
  }
}
