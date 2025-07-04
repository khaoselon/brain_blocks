// lib/widgets/painters/game_board_painter.dart - 選択状態対応版
import 'package:flutter/material.dart';
import '../../models/puzzle_piece.dart';

/// ゲーム盤面描画（選択状態対応）
class GameBoardPainter extends CustomPainter {
  final int gridSize;
  final List<PuzzlePiece> pieces;
  final double cellSize;
  final Color backgroundColor;
  final Color gridLineColor;
  final bool showGrid;
  final String? selectedPieceId; // 🔥 新機能：選択されたピースID

  const GameBoardPainter({
    required this.gridSize,
    required this.pieces,
    required this.cellSize,
    this.backgroundColor = const Color(0xFFF8F9FA),
    this.gridLineColor = const Color(0xFFE9ECEF),
    this.showGrid = true,
    this.selectedPieceId, // 🔥 新機能
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

    // 配置済みピース描画（選択状態考慮）
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
      canvas.drawLine(Offset(x, 0), Offset(x, gridSize * cellSize), paint);
    }

    // 横線
    for (int i = 0; i <= gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(gridSize * cellSize, y), paint);
    }
  }

  void _drawPlacedPieces(Canvas canvas, Paint paint) {
    for (final piece in pieces) {
      if (piece.isPlaced) {
        final isSelected = piece.id == selectedPieceId;
        _drawPiece(canvas, piece, paint, isSelected);
      }
    }
  }

  /// 🔥 改善：選択状態を考慮したピース描画
  void _drawPiece(
    Canvas canvas,
    PuzzlePiece piece,
    Paint paint,
    bool isSelected,
  ) {
    final boardCells = piece.getBoardCells();

    // 🎨 ピース本体の描画
    paint
      ..color = piece.color.withOpacity(isSelected ? 0.9 : 0.8)
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

    // 🎨 ピース境界線
    paint
      ..color = isSelected
          ? Colors.yellow.withOpacity(0.9) // 選択時は黄色
          : piece.color.withOpacity(0.8)
      ..strokeWidth = isSelected ? 3.0 : 2.0
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

    // 🎨 ハイライト効果
    if (isSelected) {
      // 選択時の特別な効果
      paint
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      for (final cell in boardCells) {
        final rect = Rect.fromLTWH(
          cell.x * cellSize + 1,
          cell.y * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );

        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(rrect, paint);
      }
    } else {
      // 通常のハイライト
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

    // 🔥 新機能：選択時のコーナーインジケーター
    if (isSelected) {
      _drawSelectionIndicators(canvas, boardCells, paint);
    }
  }

  /// 🔥 新機能：選択インジケーター描画
  void _drawSelectionIndicators(
    Canvas canvas,
    List<PiecePosition> boardCells,
    Paint paint,
  ) {
    if (boardCells.isEmpty) return;

    // ピースの境界を計算
    final minX = boardCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final maxX = boardCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final minY = boardCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxY = boardCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    // コーナーマーカーの設定
    paint
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    const markerSize = 8.0;

    // 四隅にマーカーを描画
    final corners = [
      Offset(minX * cellSize, minY * cellSize), // 左上
      Offset((maxX + 1) * cellSize, minY * cellSize), // 右上
      Offset(minX * cellSize, (maxY + 1) * cellSize), // 左下
      Offset((maxX + 1) * cellSize, (maxY + 1) * cellSize), // 右下
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, markerSize / 2, paint);

      // 白い縁取り
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(corner, markerSize / 2, paint);

      // 戻す
      paint
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(GameBoardPainter oldDelegate) {
    return oldDelegate.pieces != pieces ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.selectedPieceId != selectedPieceId; // 🔥 新機能
  }
}
