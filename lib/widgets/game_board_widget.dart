// lib/widgets/game_board_widget.dart - 不具合修正版
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
  final Function(String pieceId)? onPieceRemoved;

  const GameBoardWidget({
    super.key,
    required this.gameState,
    this.hintPieceId,
    this.hintAnimation,
    required this.onPiecePlaced,
    this.onPieceRemoved,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with TickerProviderStateMixin {
  String? _draggedPieceId;
  PiecePosition? _currentDragPosition;
  bool _isDragActive = false;
  PuzzlePiece? _draggedPiece;
  Offset? _dragOffset;
  GlobalKey _boardKey = GlobalKey();

  // 配置済みピース操作
  String? _selectedPlacedPieceId;
  late AnimationController _selectionAnimationController;

  // 🔥 修正：ダブルタップ検出の改善
  DateTime? _lastTapTime;
  String? _lastTappedPieceId;
  static const Duration _doubleTapTimeout = Duration(
    milliseconds: 600,
  ); // 400ms→600msに延長

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    super.dispose();
  }

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
              onWillAccept: (pieceId) {
                if (pieceId == null || pieceId.isEmpty) return false;
                final piece = _findPieceById(pieceId);
                return piece != null;
              },

              onAccept: (pieceId) {
                print('✅ DragTarget.onAccept: $pieceId');
                if (_currentDragPosition != null && _draggedPiece != null) {
                  _handlePieceDrop(pieceId, _currentDragPosition!);
                }
                _resetDragState();
              },

              onMove: (details) {
                _handleDragMoveImproved(details, cellSize, gridSize);
              },

              onLeave: (data) {
                print('👋 DragTarget.onLeave: $data');
                _resetDragState();
              },

              builder: (context, candidateData, rejectedData) {
                return GestureDetector(
                  onTapDown: (details) =>
                      _handleBoardTap(details, cellSize, gridSize),
                  child: Container(
                    key: _boardKey,
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
                            selectedPieceId: _selectedPlacedPieceId,
                          ),
                        ),

                        // 選択されたピースのアニメーション
                        if (_selectedPlacedPieceId != null)
                          _buildSelectedPieceAnimation(cellSize),

                        // リアルタイムプレビュー
                        if (_isDragActive && _dragOffset != null)
                          _buildRealTimePreview(cellSize, boardSize, gridSize),

                        // ヒント表示
                        if (widget.hintPieceId != null &&
                            widget.hintAnimation != null)
                          _buildHintOverlay(cellSize),

                        // 🔥 改善：配置済みピース全体をドラッグ可能に
                        ..._buildPlacedPieceDragAreas(cellSize, gridSize),

                        // 🔥 修正：ピース除去ボタンの改善
                        if (_selectedPlacedPieceId != null &&
                            widget.onPieceRemoved != null)
                          _buildImprovedRemoveButton(),

                        // 操作ヘルプ
                        _buildInteractionHelp(),

                        // デバッグ情報
                        if (false) _buildDebugInfo(cellSize), // リリース時はfalse
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 🔥 修正：盤面タップ処理（ダブルタップ検出改善）
  void _handleBoardTap(TapDownDetails details, double cellSize, int gridSize) {
    final RenderBox? renderBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
      final tappedPosition = PiecePosition(gridX, gridY);
      final tappedPiece = _findPieceAtPosition(tappedPosition);

      if (tappedPiece != null && tappedPiece.isPlaced) {
        _handlePlacedPieceTap(tappedPiece);
      } else {
        _clearSelection();
      }
    }
  }

  /// 🔥 修正：配置済みピースタップ処理（ダブルタップ改善）
  void _handlePlacedPieceTap(PuzzlePiece piece) {
    final now = DateTime.now();

    // 🔥 修正：より正確なダブルタップ検出
    final isDoubleTap =
        _lastTapTime != null &&
        _lastTappedPieceId == piece.id &&
        now.difference(_lastTapTime!) <= _doubleTapTimeout;

    print('🎯 ピースタップ: ${piece.id}');
    print('   前回タップ時間: $_lastTapTime');
    print('   現在時間: $now');
    print(
      '   時間差: ${_lastTapTime != null ? now.difference(_lastTapTime!).inMilliseconds : "null"}ms',
    );
    print('   ダブルタップ判定: $isDoubleTap');

    if (isDoubleTap && widget.onPieceRemoved != null) {
      // ダブルタップ: ピーストレイに戻す
      print('🔄 ダブルタップ検出 - ピースを除去: ${piece.id}');
      _removePieceToTray(piece.id);

      // 🔥 重要：ダブルタップ後は状態をリセット
      _lastTapTime = null;
      _lastTappedPieceId = null;
    } else {
      // シングルタップ: 選択/選択解除
      _selectPlacedPiece(piece.id);

      // 🔥 修正：タップ情報を正しく更新
      _lastTapTime = now;
      _lastTappedPieceId = piece.id;
    }
  }

  /// 配置済みピース選択
  void _selectPlacedPiece(String pieceId) {
    setState(() {
      if (_selectedPlacedPieceId == pieceId) {
        _selectedPlacedPieceId = null;
        _selectionAnimationController.stop();
      } else {
        _selectedPlacedPieceId = pieceId;
        _selectionAnimationController.repeat(reverse: true);
      }
    });

    HapticFeedback.selectionClick();

    if (_selectedPlacedPieceId != null) {
      final message = widget.onPieceRemoved != null
          ? 'ピースを選択しました（ダブルタップまたは除去ボタンで除去）'
          : 'ピースを選択しました';
      _showMessage(message, Colors.blue);
    }
  }

  /// 🔥 修正：ピースをトレイに戻す処理の改善
  void _removePieceToTray(String pieceId) {
    print('🔄 ピースをトレイに戻す: $pieceId');

    // 🔥 重要：先に選択状態をクリア
    _clearSelection();

    // ピース除去コールバック実行
    try {
      widget.onPieceRemoved?.call(pieceId);
      HapticFeedback.mediumImpact();
      _showMessage('ピースを取り外しました', Colors.orange);
      print('✅ ピース除去成功: $pieceId');
    } catch (e) {
      print('❌ ピース除去エラー: $e');
      _showMessage('ピース除去に失敗しました', Colors.red);
    }
  }

  /// 選択クリア
  void _clearSelection() {
    setState(() {
      _selectedPlacedPieceId = null;
    });
    _selectionAnimationController.stop();
  }

  /// 配置済みピースの位置取得
  PuzzlePiece? _findPieceAtPosition(PiecePosition position) {
    for (final piece in widget.gameState.pieces) {
      if (piece.isPlaced) {
        final boardCells = piece.getBoardCells();
        if (boardCells.contains(position)) {
          return piece;
        }
      }
    }
    return null;
  }

  /// 選択されたピースのアニメーション
  Widget _buildSelectedPieceAnimation(double cellSize) {
    final selectedPiece = _findPieceById(_selectedPlacedPieceId!);
    if (selectedPiece == null || !selectedPiece.isPlaced) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _selectionAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SelectedPieceAnimationPainter(
            piece: selectedPiece,
            cellSize: cellSize,
            animationValue: _selectionAnimationController.value,
          ),
        );
      },
    );
  }

  /// 🔥 改善：配置済みピース全体をドラッグエリアに
  List<Widget> _buildPlacedPieceDragAreas(double cellSize, int gridSize) {
    if (widget.onPieceRemoved == null) return [];

    final areas = <Widget>[];

    for (final piece in widget.gameState.pieces) {
      if (piece.isPlaced) {
        areas.add(_buildPieceDragArea(piece, cellSize));
      }
    }

    return areas;
  }

  /// 🔥 改善：ピース全体のドラッグエリア
  Widget _buildPieceDragArea(PuzzlePiece piece, double cellSize) {
    final boardCells = piece.getBoardCells();
    if (boardCells.isEmpty) return const SizedBox.shrink();

    // ピースの境界を計算
    final minX = boardCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final maxX = boardCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final minY = boardCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxY = boardCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    return Positioned(
      left: minX * cellSize,
      top: minY * cellSize,
      width: (maxX - minX + 1) * cellSize,
      height: (maxY - minY + 1) * cellSize,
      child: Draggable<String>(
        data: piece.id,

        dragAnchorStrategy: (draggable, context, position) {
          return Offset(
            ((maxX - minX + 1) * cellSize) / 2,
            ((maxY - minY + 1) * cellSize) / 2,
          );
        },

        onDragStarted: () {
          print('🚀 配置済みピース全体ドラッグ開始: ${piece.id}');
          _removePieceToTray(piece.id); // 🔥 修正：統一された除去処理
          HapticFeedback.lightImpact();
        },

        onDragEnd: (details) {
          print('🏁 配置済みピース全体ドラッグ終了: ${piece.id}');
        },

        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.1,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildFloatingPiece(piece, cellSize),
            ),
          ),
        ),

        childWhenDragging: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
          ),
        ),

        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(
              Icons.drag_indicator,
              color: Colors.transparent, // 通常時は透明
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 修正：改善されたピース除去ボタン
  Widget _buildImprovedRemoveButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 新機能：除去確認ボタン
          FloatingActionButton.small(
            heroTag: "remove_piece", // heroTag追加でエラー回避
            onPressed: () {
              if (_selectedPlacedPieceId != null) {
                _showRemoveConfirmDialog();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            tooltip: 'ピースを除去',
            child: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  /// 🔥 新機能：除去確認ダイアログ
  void _showRemoveConfirmDialog() {
    if (_selectedPlacedPieceId == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('ピース除去'),
            ],
          ),
          content: const Text('選択したピースをトレイに戻しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_selectedPlacedPieceId != null) {
                  _removePieceToTray(_selectedPlacedPieceId!);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('除去', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// 操作ヘルプ表示
  Widget _buildInteractionHelp() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '操作方法',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '• タップ: ピース選択',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            if (widget.onPieceRemoved != null) ...[
              const Text(
                '• ダブルタップ: 即座に除去',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• 除去ボタン: 確認後除去',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Text(
                '• ドラッグ: どこでも移動',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// メッセージ表示
  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 200, left: 20, right: 20),
      ),
    );
  }

  // 以下、既存のメソッドは同じ
  void _handleDragMoveImproved(
    DragTargetDetails<String> details,
    double cellSize,
    int gridSize,
  ) {
    final pieceId = details.data;
    final piece = _findPieceById(pieceId);

    if (piece == null) return;

    final RenderBox? renderBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.offset);
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

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
      setState(() {
        _currentDragPosition = null;
        _dragOffset = localPosition;
      });
    }
  }

  Widget _buildRealTimePreview(
    double cellSize,
    double boardSize,
    int gridSize,
  ) {
    if (_draggedPiece == null || _dragOffset == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _dragOffset!.dx - (cellSize * 0.5),
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

  Widget _buildFloatingPiece(PuzzlePiece piece, double cellSize) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

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

  void _handlePieceDrop(String pieceId, PiecePosition position) {
    print('🎯 ピースドロップ: $pieceId at $position');

    final piece = _findPieceById(pieceId);
    if (piece == null) {
      _showMessage('ピースが見つかりませんでした', Colors.red);
      return;
    }

    final validationResult = _validatePlacement(piece, position);

    if (validationResult.isValid) {
      print('✅ 配置成功: $pieceId at $position');
      widget.onPiecePlaced(pieceId, position);
      HapticFeedback.lightImpact();
    } else {
      print('❌ 配置失敗: ${validationResult.reason}');
      _showMessage(validationResult.reason, Colors.red);
      HapticFeedback.mediumImpact();
    }
  }

  PlacementValidationResult _validatePlacement(
    PuzzlePiece piece,
    PiecePosition position,
  ) {
    final gridSize = widget.gameState.settings.difficulty.gridSize;
    final rotatedCells = piece.getRotatedCells();
    final boardCells = rotatedCells.map((cell) => cell + position).toList();

    for (final cell in boardCells) {
      if (cell.x < 0 ||
          cell.x >= gridSize ||
          cell.y < 0 ||
          cell.y >= gridSize) {
        return PlacementValidationResult(isValid: false, reason: '盤面の範囲外です');
      }
    }

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

  PuzzlePiece? _findPieceById(String pieceId) {
    try {
      return widget.gameState.pieces.firstWhere((p) => p.id == pieceId);
    } catch (e) {
      return null;
    }
  }

  void _resetDragState() {
    setState(() {
      _draggedPieceId = null;
      _draggedPiece = null;
      _currentDragPosition = null;
      _dragOffset = null;
      _isDragActive = false;
    });
  }

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
              '選択: ${_selectedPlacedPieceId?.substring(0, 8) ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Grid位置: ${_currentDragPosition?.toString() ?? "なし"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              '最終タップ時間: ${_lastTapTime?.millisecondsSinceEpoch ?? "なし"}',
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

/// 選択されたピースアニメーションペインター
class _SelectedPieceAnimationPainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;
  final double animationValue;

  const _SelectedPieceAnimationPainter({
    required this.piece,
    required this.cellSize,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardCells = piece.getBoardCells();
    final paint = Paint();

    final opacity = 0.3 + (animationValue * 0.5);

    paint
      ..color = Colors.yellow.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (final cell in boardCells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_SelectedPieceAnimationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
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

      final opacity = canPlace ? 0.8 : 0.6;
      final borderColor = canPlace ? piece.color : Colors.red;

      paint
        ..color = piece.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      paint
        ..color = borderColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);

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
