// lib/widgets/game_board_widget.dart - ドラッグ&ドロップ改善版
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/puzzle_piece.dart';
import '../widgets/painters/game_board_painter.dart';
import '../widgets/painters/hint_painter.dart';

class GameBoardWidget extends StatefulWidget {
  final GameState gameState;
  final String? hintPieceId;
  final AnimationController? hintAnimation;
  final Function(String pieceId, PiecePosition position) onPiecePlaced;

  const GameBoardWidget({
    super.key,
    required this.gameState,
    this.hintPieceId,
    this.hintAnimation,
    required this.onPiecePlaced,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> {
  String? _draggedPieceId;
  PiecePosition? _dragPosition;
  bool _isDragActive = false;
  PuzzlePiece? _draggedPiece;
  List<PiecePosition>? _previewCells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = widget.gameState.settings.difficulty.gridSize;
        final maxSize = constraints.maxWidth.clamp(200.0, 600.0);
        final boardSize = maxSize;
        final cellSize = boardSize / gridSize;

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DragTarget<String>(
              // 🔥 改善：より寛容な受け入れ条件
              onWillAccept: (pieceId) {
                if (pieceId == null || pieceId.isEmpty) return false;

                final piece = _findPieceById(pieceId);
                if (piece == null || piece.isPlaced) return false;

                print('🎯 DragTarget.onWillAccept: $pieceId');
                return true;
              },

              // 🔥 改善：確実なドロップ処理
              onAccept: (pieceId) {
                print('✅ DragTarget.onAccept: $pieceId at $_dragPosition');
                if (_dragPosition != null && _draggedPiece != null) {
                  _handlePieceDrop(pieceId, _dragPosition!);
                } else {
                  print('❌ ドロップ処理失敗 - 位置またはピース情報が不正');
                  _showPlacementError('配置位置が特定できませんでした');
                }
                _resetDragState();
              },

              // 🔥 改善：精密な座標追跡
              onMove: (details) {
                _handleDragMove(details, cellSize, gridSize);
              },

              // ドラッグ終了処理
              onLeave: (data) {
                print('👋 DragTarget.onLeave: $data');
                _resetDragState();
              },

              builder: (context, candidateData, rejectedData) {
                return Stack(
                  children: [
                    // 基本ゲーム盤面
                    CustomPaint(
                      size: Size(boardSize, boardSize),
                      painter: GameBoardPainter(
                        gridSize: gridSize,
                        pieces: widget.gameState.pieces,
                        cellSize: cellSize,
                      ),
                    ),

                    // 配置プレビュー表示
                    if (_isDragActive && _previewCells != null)
                      _buildPlacementPreview(cellSize),

                    // ヒント表示
                    if (widget.hintPieceId != null &&
                        widget.hintAnimation != null)
                      _buildHintOverlay(cellSize),

                    // デバッグ情報（開発時のみ）
                    if (false) _buildDebugInfo(), // リリース時はfalseに
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 🔧 改善されたドラッグ移動処理
  void _handleDragMove(
    DragTargetDetails<String> details,
    double cellSize,
    int gridSize,
  ) {
    final pieceId = details.data;
    final piece = _findPieceById(pieceId);

    if (piece == null) {
      print('⚠️ ピース $pieceId が見つかりません');
      return;
    }

    final localPosition = details.offset;

    // 🔧 改善：より正確な座標変換
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    print(
      '📍 ドラッグ位置: (${localPosition.dx.toInt()}, ${localPosition.dy.toInt()}) → Grid($gridX, $gridY)',
    );

    // グリッド範囲内チェック
    if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
      final position = PiecePosition(gridX, gridY);
      final rotatedCells = piece.getRotatedCells();
      final previewCells = rotatedCells.map((cell) => cell + position).toList();

      setState(() {
        _draggedPieceId = pieceId;
        _draggedPiece = piece;
        _dragPosition = position;
        _previewCells = previewCells;
        _isDragActive = true;
      });
    } else {
      // 範囲外の場合はプレビューをクリア
      setState(() {
        _previewCells = null;
      });
    }
  }

  /// 🔧 改善されたピースドロップ処理
  void _handlePieceDrop(String pieceId, PiecePosition position) {
    print('🎯 ピースドロップ処理開始: $pieceId at $position');

    final piece = _findPieceById(pieceId);
    if (piece == null) {
      print('❌ ピース $pieceId が見つかりません');
      _showPlacementError('ピースが見つかりませんでした');
      return;
    }

    // 🔧 改善：詳細な配置可能性チェック
    final validationResult = _validatePlacement(piece, position);

    if (validationResult.isValid) {
      print('✅ 配置可能: $pieceId');
      widget.onPiecePlaced(pieceId, position);
      HapticFeedback.lightImpact();
    } else {
      print('❌ 配置不可: $pieceId - ${validationResult.reason}');
      _showPlacementError(validationResult.reason);
      HapticFeedback.mediumImpact();
    }
  }

  /// 🔧 改善された配置検証
  PlacementValidationResult _validatePlacement(
    PuzzlePiece piece,
    PiecePosition position,
  ) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;
    final rotatedCells = piece.getRotatedCells();
    final boardCells = rotatedCells.map((cell) => cell + position).toList();

    print('🔍 配置チェック: ピース ${piece.id}, 位置 $position');
    print('   回転後セル: $rotatedCells');
    print('   盤面座標: $boardCells');

    // 1. 盤面範囲チェック
    for (final cell in boardCells) {
      if (cell.x < 0 ||
          cell.x >= gridSize ||
          cell.y < 0 ||
          cell.y >= gridSize) {
        return PlacementValidationResult(
          isValid: false,
          reason: '盤面の範囲外です (${cell.x}, ${cell.y})',
        );
      }
    }

    // 2. 他のピースとの重複チェック
    final occupiedCells = <PiecePosition>{};
    for (final otherPiece in widget.gameState.pieces) {
      if (otherPiece.id != piece.id && otherPiece.isPlaced) {
        occupiedCells.addAll(otherPiece.getBoardCells());
      }
    }

    for (final cell in boardCells) {
      if (occupiedCells.contains(cell)) {
        return PlacementValidationResult(
          isValid: false,
          reason: '既に他のピースが配置されています',
        );
      }
    }

    return PlacementValidationResult(isValid: true, reason: '');
  }

  /// ピースIDからピースオブジェクトを取得
  PuzzlePiece? _findPieceById(String pieceId) {
    try {
      return widget.gameState.pieces.firstWhere((p) => p.id == pieceId);
    } catch (e) {
      return null;
    }
  }

  /// ドラッグ状態をリセット
  void _resetDragState() {
    setState(() {
      _draggedPieceId = null;
      _draggedPiece = null;
      _dragPosition = null;
      _previewCells = null;
      _isDragActive = false;
    });
  }

  /// 🎨 配置プレビュー表示
  Widget _buildPlacementPreview(double cellSize) {
    if (_previewCells == null || _draggedPiece == null) {
      return const SizedBox.shrink();
    }

    final validationResult = _validatePlacement(_draggedPiece!, _dragPosition!);
    final isValid = validationResult.isValid;
    final previewColor = isValid
        ? _draggedPiece!.color.withOpacity(0.6)
        : Colors.red.withOpacity(0.6);
    final borderColor = isValid ? _draggedPiece!.color : Colors.red;

    return CustomPaint(
      size: Size.infinite,
      painter: _PlacementPreviewPainter(
        cells: _previewCells!,
        cellSize: cellSize,
        fillColor: previewColor,
        borderColor: borderColor,
        isValid: isValid,
      ),
    );
  }

  /// 🎨 ヒント表示
  Widget _buildHintOverlay(double cellSize) {
    PuzzlePiece? hintPiece;
    try {
      hintPiece = widget.gameState.pieces.firstWhere(
        (p) => p.id == widget.hintPieceId,
      );
    } catch (e) {
      hintPiece = null;
    }

    if (hintPiece == null) return const SizedBox.shrink();

    final hintPosition = _findBestHintPosition(hintPiece);
    if (hintPosition == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: widget.hintAnimation!,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: HintPainter(
            piece: hintPiece!,
            hintPosition: hintPosition,
            cellSize: cellSize,
            animation: widget.hintAnimation!,
          ),
        );
      },
    );
  }

  /// 🔍 ヒント位置を探す
  PiecePosition? _findBestHintPosition(PuzzlePiece piece) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;

    // 4つの回転角度をすべて試す
    for (int rotation = 0; rotation < 4; rotation++) {
      final rotatedPiece = piece.copyWith(rotation: rotation);

      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          final position = PiecePosition(x, y);
          final result = _validatePlacement(rotatedPiece, position);
          if (result.isValid) {
            return position;
          }
        }
      }
    }
    return null;
  }

  /// ⚠️ 配置エラー表示
  void _showPlacementError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🐛 デバッグ情報表示
  Widget _buildDebugInfo() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ドラッグ状態: ${_isDragActive ? "アクティブ" : "非アクティブ"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'ピース: ${_draggedPieceId ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              '位置: ${_dragPosition?.toString() ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'プレビュー: ${_previewCells?.length ?? 0}セル',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// 配置検証結果
class PlacementValidationResult {
  final bool isValid;
  final String reason;

  PlacementValidationResult({required this.isValid, required this.reason});
}

/// プレビューペインター
class _PlacementPreviewPainter extends CustomPainter {
  final List<PiecePosition> cells;
  final double cellSize;
  final Color fillColor;
  final Color borderColor;
  final bool isValid;

  const _PlacementPreviewPainter({
    required this.cells,
    required this.cellSize,
    required this.fillColor,
    required this.borderColor,
    required this.isValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      // 塗りつぶし
      paint
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // 境界線
      paint
        ..color = borderColor
        ..strokeWidth = isValid ? 2.0 : 3.0
        ..style = PaintingStyle.stroke;

      if (isValid) {
        canvas.drawRRect(rrect, paint);
      } else {
        // 無効な場合は点線で表示
        _drawDashedBorder(canvas, rect, paint);
      }
    }
  }

  void _drawDashedBorder(Canvas canvas, Rect rect, Paint paint) {
    const dashSize = 5.0;
    const gapSize = 3.0;

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
  bool shouldRepaint(_PlacementPreviewPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isValid != isValid;
  }
}
