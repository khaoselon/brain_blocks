// lib/widgets/piece_tray_widget.dart - ドラッグ精度改善版
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/puzzle_piece.dart';
import '../widgets/painters/piece_painter.dart';

class PieceTrayWidget extends StatefulWidget {
  final List<PuzzlePiece> pieces;
  final Function(String pieceId) onPieceSelected;
  final Function(String pieceId) onPieceRotated;
  final bool isHorizontal;

  const PieceTrayWidget({
    super.key,
    required this.pieces,
    required this.onPieceSelected,
    required this.onPieceRotated,
    this.isHorizontal = false,
  });

  @override
  State<PieceTrayWidget> createState() => _PieceTrayWidgetState();
}

class _PieceTrayWidgetState extends State<PieceTrayWidget> {
  String? _selectedPieceId;

  @override
  Widget build(BuildContext context) {
    final unplacedPieces = widget.pieces.where((p) => !p.isPlaced).toList();

    return Container(
      margin: widget.isHorizontal
          ? const EdgeInsets.symmetric(horizontal: 16)
          : const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: widget.isHorizontal
                ? const Offset(0, -2)
                : const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isHorizontal
          ? _buildHorizontalLayout(unplacedPieces)
          : _buildVerticalLayout(unplacedPieces),
    );
  }

  /// 横向きレイアウト（下部配置用）
  Widget _buildHorizontalLayout(List<PuzzlePiece> unplacedPieces) {
    return Column(
      children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF2E86C1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.extension, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'ピース (${unplacedPieces.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (unplacedPieces.isNotEmpty)
                Text(
                  '左右にスクロール',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        // ピース一覧（横スクロール）
        Expanded(
          child: unplacedPieces.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: unplacedPieces.map((piece) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: _buildHorizontalPieceItem(piece),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  /// 縦向きレイアウト
  Widget _buildVerticalLayout(List<PuzzlePiece> unplacedPieces) {
    return Column(
      children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2E86C1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.extension, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'ピース (${unplacedPieces.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ピース一覧（縦スクロール）
        Expanded(
          child: unplacedPieces.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: unplacedPieces.length,
                  itemBuilder: (context, index) {
                    final piece = unplacedPieces[index];
                    return _buildVerticalPieceItem(piece);
                  },
                ),
        ),
      ],
    );
  }

  /// 🔥 改善：横向きピースアイテム（正確なドラッグ）
  Widget _buildHorizontalPieceItem(PuzzlePiece piece) {
    const cellSize = 16.0;
    final isSelected = piece.id == _selectedPieceId;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? piece.color.withOpacity(0.2)
            : piece.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? piece.color : piece.color.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 改善：正確なドラッグ可能ピースプレビュー
          Expanded(
            child: GestureDetector(
              onTap: () => _selectPiece(piece.id),
              child: _buildAccurateDraggable(piece, cellSize),
            ),
          ),

          const SizedBox(height: 4),

          // 回転ボタン
          GestureDetector(
            onTap: () {
              widget.onPieceRotated(piece.id);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: piece.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rotate_right, size: 16, color: piece.color),
            ),
          ),
        ],
      ),
    );
  }

  /// 縦向きピースアイテム
  Widget _buildVerticalPieceItem(PuzzlePiece piece) {
    final isSelected = piece.id == _selectedPieceId;
    const cellSize = 20.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? piece.color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: piece.color, width: 2) : null,
      ),
      child: InkWell(
        onTap: () => _selectPiece(piece.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 🔥 改善：正確なドラッグ可能エリア
              Expanded(child: _buildAccurateDraggable(piece, cellSize)),

              const SizedBox(width: 8),

              // 回転ボタン
              IconButton(
                onPressed: () {
                  widget.onPieceRotated(piece.id);
                  HapticFeedback.selectionClick();
                },
                icon: const Icon(Icons.rotate_right),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: piece.color.withOpacity(0.1),
                  foregroundColor: piece.color,
                  minimumSize: const Size(32, 32),
                ),
                tooltip: '回転',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 新機能：正確なドラッグ可能ウィジェット
  Widget _buildAccurateDraggable(PuzzlePiece piece, double cellSize) {
    return Draggable<String>(
      data: piece.id,

      // 🔥 重要：ドラッグアンカーストラテジー
      dragAnchorStrategy: (draggable, context, position) {
        // ピースの中心を基準にドラッグ
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        return Offset(size.width / 2, size.height / 2);
      },

      onDragStarted: () {
        print('🚀 正確なドラッグ開始: ${piece.id}');
        _selectPiece(piece.id);
        HapticFeedback.lightImpact();
      },

      onDragEnd: (details) {
        print('🏁 正確なドラッグ終了: ${piece.id}');
        print('   終了位置: ${details.offset}');
        print('   速度: ${details.velocity}');
      },

      onDragUpdate: (details) {
        // ドラッグ中の座標をログ出力（デバッグ用）
        if (false) {
          // デバッグ時のみ有効
          print('📱 ドラッグ更新: ${details.globalPosition}');
        }
      },

      // 🔥 改善：より大きく見やすいフィードバック
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: widget.isHorizontal ? 2.0 : 1.5, // 横向きの場合はより大きく
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildEnhancedPiecePreview(
              piece,
              cellSize * (widget.isHorizontal ? 1.5 : 1.2),
              isFloating: true,
            ),
          ),
        ),
      ),

      // ドラッグ中の元の位置表示
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildEnhancedPiecePreview(piece, cellSize),
      ),

      // 通常時の表示
      child: _buildEnhancedPiecePreview(piece, cellSize),
    );
  }

  /// 🎨 強化されたピースプレビュー
  Widget _buildEnhancedPiecePreview(
    PuzzlePiece piece,
    double cellSize, {
    bool isFloating = false,
  }) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    // サイズ制限
    final constrainedWidth = widget.isHorizontal
        ? width.clamp(24.0, 80.0)
        : width.clamp(40.0, 120.0);
    final constrainedHeight = widget.isHorizontal
        ? height.clamp(24.0, 80.0)
        : height.clamp(40.0, 120.0);

    return Container(
      width: constrainedWidth,
      height: constrainedHeight,
      child: CustomPaint(
        painter: _EnhancedPiecePainter(
          piece: piece,
          cellSize: cellSize,
          isSelected: piece.id == _selectedPieceId,
          isFloating: isFloating,
        ),
      ),
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: widget.isHorizontal ? 32 : 48,
            color: Colors.green,
          ),
          SizedBox(height: widget.isHorizontal ? 4 : 8),
          Text(
            '全ピース配置完了！',
            style: TextStyle(
              fontSize: widget.isHorizontal ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// ピース選択処理
  void _selectPiece(String pieceId) {
    setState(() {
      _selectedPieceId = _selectedPieceId == pieceId ? null : pieceId;
    });
    widget.onPieceSelected(pieceId);
  }
}

/// 🎨 強化されたピースペインター
class _EnhancedPiecePainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;
  final bool isSelected;
  final bool isFloating;

  const _EnhancedPiecePainter({
    required this.piece,
    required this.cellSize,
    required this.isSelected,
    this.isFloating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cells = piece.getRotatedCells();

    if (cells.isEmpty) return;

    // 最小座標を基準にする
    final minX = cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        (cell.x - minX) * cellSize,
        (cell.y - minY) * cellSize,
        cellSize,
        cellSize,
      );

      // 🎨 改善：グラデーション効果
      if (isFloating) {
        // フローティング時は特別なエフェクト
        paint
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              piece.color.withOpacity(0.9),
              piece.color.withOpacity(0.7),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.fill;
      } else {
        // 通常時
        paint
          ..color = piece.color.withOpacity(isSelected ? 0.9 : 0.8)
          ..style = PaintingStyle.fill;
      }

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // 境界線
      paint
        ..shader = null
        ..color = isSelected
            ? piece.color.withOpacity(1.0)
            : piece.color.withOpacity(0.8)
        ..strokeWidth = isSelected ? 2.0 : 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);

      // ハイライト効果
      if (isSelected || isFloating) {
        paint
          ..color = Colors.white.withOpacity(0.4)
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
  bool shouldRepaint(_EnhancedPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isFloating != isFloating;
  }
}
