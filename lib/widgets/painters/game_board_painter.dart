// lib/widgets/painters/game_board_painter.dart
import 'package:flutter/material.dart';
import '../../models/puzzle_piece.dart';

/// ゲーム盤面描画
class GameBoardPainter extends CustomPainter {
  final int gridSize;
  final List<PuzzlePiece> pieces;
  final double cellSize;
  final Color backgroundColor;
  final Color gridLineColor;
  final bool showGrid;

  const GameBoardPainter({
    required this.gridSize,
    required this.pieces,
    required this.cellSize,
    this.backgroundColor = const Color(0xFFF8F9FA),
    this.gridLineColor = const Color(0xFFE9ECEF),
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 背景描画
    paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // グリッド線描画
    if (showGrid) {
      _drawGrid(canvas, size, paint);
    }

    // 配置済みピース描画
    _drawPlacedPieces(canvas, paint);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    paint
      ..color = gridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 縦線
    for (int i = 0; i <= gridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, gridSize * cellSize),
        paint,
      );
    }

    // 横線
    for (int i = 0; i <= gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(gridSize * cellSize, y),
        paint,
      );
    }
  }

  void _drawPlacedPieces(Canvas canvas, Paint paint) {
    for (final piece in pieces) {
      if (piece.isPlaced) {
        _drawPiece(canvas, piece, paint);
      }
    }
  }

  void _drawPiece(Canvas canvas, PuzzlePiece piece, Paint paint) {
    final boardCells = piece.getBoardCells();
    
    // ピース本体
    paint
      ..color = piece.color
      ..style = PaintingStyle.fill;

    for (final cell in boardCells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );
      
      // 角丸四角形で描画
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);
    }

    // ピース境界線
    paint
      ..color = piece.color.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final cell in boardCells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);
    }

    // ピース内部のハイライト効果
    paint
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final cell in boardCells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize + 2,
        cell.y * cellSize + 2,
        cellSize - 4,
        cellSize * 0.3,
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(GameBoardPainter oldDelegate) {
    return oldDelegate.pieces != pieces ||
           oldDelegate.gridSize != gridSize ||
           oldDelegate.cellSize != cellSize ||
           oldDelegate.showGrid != showGrid;
  }
}



