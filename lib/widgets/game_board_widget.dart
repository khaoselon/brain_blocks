// lib/widgets/game_board_widget.dart - 修正版
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = widget.gameState.settings.difficulty.gridSize;
        final boardSize = constraints.maxWidth.clamp(200.0, 600.0);
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
              // 🔥 重要：全ての文字列を受け入れる
              onWillAccept: (pieceId) {
                print('🎯 DragTarget.onWillAccept: $pieceId');
                return pieceId != null && pieceId.isNotEmpty;
              },

              // 🔥 重要：ドロップ処理
              onAccept: (pieceId) {
                print('✅ DragTarget.onAccept: $pieceId at $_dragPosition');
                if (_dragPosition != null) {
                  _handlePieceDrop(pieceId, _dragPosition!);
                } else {
                  print('❌ ドロップ位置が null です');
                }
              },

              // 🔥 重要：ドラッグ移動の追跡
              onMove: (details) {
                _handleDragMove(details, cellSize, gridSize);
              },

              // 🔥 重要：ドラッグ終了処理
              onLeave: (data) {
                print('👋 DragTarget.onLeave: $data');
                setState(() {
                  _draggedPieceId = null;
                  _dragPosition = null;
                  _isDragActive = false;
                });
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

                    // デバッグ用：ドラッグ位置表示
                    if (_isDragActive && _dragPosition != null)
                      _buildDragIndicator(cellSize),

                    // ヒント表示
                    if (widget.hintPieceId != null &&
                        widget.hintAnimation != null)
                      _buildHintOverlay(cellSize),

                    // ドラッグ中のプレビュー
                    if (_draggedPieceId != null && _dragPosition != null)
                      _buildDragPreview(cellSize),

                    // デバッグ情報表示
                    _buildDebugInfo(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 🔧 ドラッグ移動処理の修正
  void _handleDragMove(
    DragTargetDetails<String> details,
    double cellSize,
    int gridSize,
  ) {
    final localPosition = details.offset;

    // 座標をグリッド位置に変換
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    print(
      '📍 ドラッグ位置: (${localPosition.dx.toInt()}, ${localPosition.dy.toInt()}) → Grid($gridX, $gridY)',
    );

    // グリッド範囲内チェック
    if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
      setState(() {
        _draggedPieceId = details.data;
        _dragPosition = PiecePosition(gridX, gridY);
        _isDragActive = true;
      });
    } else {
      print('⚠️ グリッド範囲外: ($gridX, $gridY) / グリッドサイズ: $gridSize');
    }
  }

  /// 🔧 ピースドロップ処理の修正
  void _handlePieceDrop(String pieceId, PiecePosition position) {
    print('🎯 ピースドロップ処理開始: $pieceId at $position');

    final piece = widget.gameState.pieces.firstWhere(
      (p) => p.id == pieceId,
      orElse: () => throw Exception('ピース $pieceId が見つかりません'),
    );

    // 配置可能性チェック
    if (_isValidPlacement(piece, position)) {
      print('✅ 配置可能: $pieceId');
      widget.onPiecePlaced(pieceId, position);
    } else {
      print('❌ 配置不可: $pieceId - 重複または範囲外');
      _showPlacementError();
    }

    // 状態リセット
    setState(() {
      _draggedPieceId = null;
      _dragPosition = null;
      _isDragActive = false;
    });
  }

  /// 🔧 配置可能性チェックの改善
  bool _isValidPlacement(PuzzlePiece piece, PiecePosition position) {
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
        print('   ❌ 範囲外: $cell (グリッドサイズ: $gridSize)');
        return false;
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
        print('   ❌ 重複: $cell は既に使用されています');
        return false;
      }
    }

    print('   ✅ 配置可能');
    return true;
  }

  /// 🎨 ドラッグインジケーター（デバッグ用）
  Widget _buildDragIndicator(double cellSize) {
    if (_dragPosition == null) return const SizedBox.shrink();

    return Positioned(
      left: _dragPosition!.x * cellSize,
      top: _dragPosition!.y * cellSize,
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 3),
          color: Colors.red.withOpacity(0.2),
        ),
        child: const Center(child: Icon(Icons.add, color: Colors.red)),
      ),
    );
  }

  /// 🎨 ヒント表示
  Widget _buildHintOverlay(double cellSize) {
    final hintPiece = widget.gameState.pieces.firstWhere(
      (p) => p.id == widget.hintPieceId,
    );

    final hintPosition = _findBestHintPosition(hintPiece);
    if (hintPosition == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: widget.hintAnimation!,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: HintPainter(
            piece: hintPiece,
            hintPosition: hintPosition,
            cellSize: cellSize,
            animation: widget.hintAnimation!,
          ),
        );
      },
    );
  }

  /// 🎨 ドラッグプレビュー
  Widget _buildDragPreview(double cellSize) {
    final draggedPiece = widget.gameState.pieces.firstWhere(
      (p) => p.id == _draggedPieceId,
    );

    return Positioned(
      left: _dragPosition!.x * cellSize,
      top: _dragPosition!.y * cellSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: _buildPiecePreview(draggedPiece, cellSize),
        ),
      ),
    );
  }

  /// 🎨 ピースプレビュー作成
  Widget _buildPiecePreview(PuzzlePiece piece, double cellSize) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PiecePreviewPainter(
          piece: piece,
          cellSize: cellSize,
          opacity: 0.8,
        ),
      ),
    );
  }

  /// 🔍 ヒント位置を探す
  PiecePosition? _findBestHintPosition(PuzzlePiece piece) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final position = PiecePosition(x, y);
        if (_isValidPlacement(piece, position)) {
          return position;
        }
      }
    }
    return null;
  }

  /// ⚠️ 配置エラー表示
  void _showPlacementError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('そこには配置できません'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 🐛 デバッグ情報表示
  Widget _buildDebugInfo() {
    if (!mounted) return const SizedBox.shrink();

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
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
              'ドラッグピース: ${_draggedPieceId ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'ドラッグ位置: ${_dragPosition?.toString() ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// プレビューペインター
class _PiecePreviewPainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;
  final double opacity;

  const _PiecePreviewPainter({
    required this.piece,
    required this.cellSize,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cells = piece.getRotatedCells();

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      paint
        ..color = piece.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      paint
        ..color = piece.color.withOpacity(opacity * 0.8)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_PiecePreviewPainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.opacity != opacity;
  }
}
