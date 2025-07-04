// lib/widgets/game_board_widget.dart - 座標ずれ修正版
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
  PiecePosition? _currentDragPosition;
  bool _isDragActive = false;
  PuzzlePiece? _draggedPiece;
  Offset? _dragOffset; // 🔥 新機能：実際のドラッグ座標
  List<PiecePosition>? _previewCells;
  GlobalKey _boardKey = GlobalKey(); // 🔥 盤面の正確な位置取得用

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
              // 🔥 改善：より柔軟な受け入れ条件
              onWillAccept: (pieceId) {
                if (pieceId == null || pieceId.isEmpty) return false;
                final piece = _findPieceById(pieceId);
                return piece != null && !piece.isPlaced;
              },

              // 🔥 改善：正確なドロップ処理
              onAccept: (pieceId) {
                print('✅ DragTarget.onAccept: $pieceId');
                if (_currentDragPosition != null && _draggedPiece != null) {
                  _handlePieceDrop(pieceId, _currentDragPosition!);
                }
                _resetDragState();
              },

              // 🔥 修正：正確な座標追跡
              onMove: (details) {
                _handleDragMoveImproved(details, cellSize, gridSize);
              },

              onLeave: (data) {
                print('👋 DragTarget.onLeave: $data');
                _resetDragState();
              },

              builder: (context, candidateData, rejectedData) {
                return Container(
                  key: _boardKey, // 🔥 重要：盤面位置の特定用
                  width: boardSize,
                  height: boardSize,
                  child: Stack(
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

                      // 🔥 改善：リアルタイム配置プレビュー
                      if (_isDragActive && _dragOffset != null)
                        _buildRealTimePreview(cellSize, boardSize, gridSize),

                      // ヒント表示
                      if (widget.hintPieceId != null &&
                          widget.hintAnimation != null)
                        _buildHintOverlay(cellSize),

                      // デバッグ情報（開発時のみ）
                      if (true) _buildDebugInfo(cellSize), // デバッグ用
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 🔧 大幅改善：正確な座標変換処理
  void _handleDragMoveImproved(
    DragTargetDetails<String> details,
    double cellSize,
    int gridSize,
  ) {
    final pieceId = details.data;
    final piece = _findPieceById(pieceId);

    if (piece == null) return;

    // 🔥 重要：盤面内の相対座標を取得
    final RenderBox? renderBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // グローバル座標から盤面内座標に変換
    final localPosition = renderBox.globalToLocal(details.offset);

    print('🎯 Global: ${details.offset}, Local: $localPosition');

    // 🔧 改善：正確なグリッド座標計算
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    print('📍 Grid位置: ($gridX, $gridY), セルサイズ: $cellSize');

    // グリッド範囲内チェック
    if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
      final position = PiecePosition(gridX, gridY);

      setState(() {
        _draggedPieceId = pieceId;
        _draggedPiece = piece;
        _currentDragPosition = position;
        _dragOffset = localPosition;
        _isDragActive = true;
      });
    } else {
      // 範囲外の場合
      setState(() {
        _currentDragPosition = null;
        _dragOffset = localPosition; // 位置は記録しておく
      });
    }
  }

  /// 🔥 新機能：リアルタイムプレビュー
  Widget _buildRealTimePreview(
    double cellSize,
    double boardSize,
    int gridSize,
  ) {
    if (_draggedPiece == null || _dragOffset == null) {
      return const SizedBox.shrink();
    }

    // ドラッグ位置でのピース表示
    return Positioned(
      left: _dragOffset!.dx - (cellSize * 0.5), // ピースの中心をカーソルに合わせる
      top: _dragOffset!.dy - (cellSize * 0.5),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: _buildFloatingPiece(_draggedPiece!, cellSize),
        ),
      ),
    );
  }

  /// 🎨 フローティングピース表示
  Widget _buildFloatingPiece(PuzzlePiece piece, double cellSize) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    // ピースの境界を計算
    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    // 🔧 配置可能性チェック
    bool canPlace = false;
    if (_currentDragPosition != null) {
      final result = _validatePlacement(piece, _currentDragPosition!);
      canPlace = result.isValid;
    }

    return Container(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FloatingPiecePainter(
          piece: piece,
          cellSize: cellSize,
          canPlace: canPlace,
        ),
      ),
    );
  }

  /// 🔧 改善されたピースドロップ処理
  void _handlePieceDrop(String pieceId, PiecePosition position) {
    print('🎯 ピースドロップ: $pieceId at $position');

    final piece = _findPieceById(pieceId);
    if (piece == null) {
      _showPlacementError('ピースが見つかりませんでした');
      return;
    }

    final validationResult = _validatePlacement(piece, position);

    if (validationResult.isValid) {
      print('✅ 配置成功: $pieceId at $position');
      widget.onPiecePlaced(pieceId, position);
      HapticFeedback.lightImpact();
    } else {
      print('❌ 配置失敗: ${validationResult.reason}');
      _showPlacementError(validationResult.reason);
      HapticFeedback.mediumImpact();
    }
  }

  /// 🔧 配置検証
  PlacementValidationResult _validatePlacement(
    PuzzlePiece piece,
    PiecePosition position,
  ) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;
    final rotatedCells = piece.getRotatedCells();
    final boardCells = rotatedCells.map((cell) => cell + position).toList();

    // 1. 盤面範囲チェック
    for (final cell in boardCells) {
      if (cell.x < 0 ||
          cell.x >= gridSize ||
          cell.y < 0 ||
          cell.y >= gridSize) {
        return PlacementValidationResult(isValid: false, reason: '盤面の範囲外です');
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
          reason: '他のピースと重複しています',
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
      _currentDragPosition = null;
      _dragOffset = null;
      _previewCells = null;
      _isDragActive = false;
    });
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

  /// ヒント位置を探す
  PiecePosition? _findBestHintPosition(PuzzlePiece piece) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;

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

  /// エラー表示
  void _showPlacementError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🐛 デバッグ情報表示
  Widget _buildDebugInfo(double cellSize) {
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
              'ドラッグ: ${_isDragActive ? "ON" : "OFF"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'ピース: ${_draggedPieceId?.substring(0, 8) ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Grid位置: ${_currentDragPosition?.toString() ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'オフセット: ${_dragOffset != null ? "(${_dragOffset!.dx.toInt()}, ${_dragOffset!.dy.toInt()})" : "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'セルサイズ: ${cellSize.toStringAsFixed(1)}',
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

/// フローティングピースペインター
class _FloatingPiecePainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;
  final bool canPlace;

  const _FloatingPiecePainter({
    required this.piece,
    required this.cellSize,
    required this.canPlace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cells = piece.getRotatedCells();

    // 最小座標を基準にする
    final minX = cells.isNotEmpty
        ? cells.map((c) => c.x).reduce((a, b) => a < b ? a : b)
        : 0;
    final minY = cells.isNotEmpty
        ? cells.map((c) => c.y).reduce((a, b) => a < b ? a : b)
        : 0;

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        (cell.x - minX) * cellSize,
        (cell.y - minY) * cellSize,
        cellSize,
        cellSize,
      );

      // 配置可能性に応じて色を変更
      final opacity = canPlace ? 0.8 : 0.6;
      final borderColor = canPlace ? piece.color : Colors.red;

      // 塗りつぶし
      paint
        ..color = piece.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // 境界線
      paint
        ..color = borderColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);

      // ハイライト効果
      if (canPlace) {
        paint
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        final highlightRect = Rect.fromLTWH(
          (cell.x - minX) * cellSize + 2,
          (cell.y - minY) * cellSize + 2,
          cellSize - 4,
          cellSize * 0.3,
        );

        final highlightRRect = RRect.fromRectAndRadius(
          highlightRect,
          const Radius.circular(2),
        );
        canvas.drawRRect(highlightRRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloatingPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.canPlace != canPlace;
  }
}
