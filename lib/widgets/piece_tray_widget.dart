// lib/widgets/piece_tray_widget.dart - 縦・横両対応版
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import '../widgets/painters/piece_painter.dart';

class PieceTrayWidget extends StatefulWidget {
  final List<PuzzlePiece> pieces;
  final Function(String pieceId) onPieceSelected;
  final Function(String pieceId) onPieceRotated;
  final bool isHorizontal; // 🔥 新機能：横向きレイアウトサポート

  const PieceTrayWidget({
    super.key,
    required this.pieces,
    required this.onPieceSelected,
    required this.onPieceRotated,
    this.isHorizontal = false, // デフォルトは縦向き
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
                ? const Offset(0, -2) // 横向き時は上向きの影
                : const Offset(0, 4), // 縦向き時は下向きの影
          ),
        ],
      ),
      child: widget.isHorizontal
          ? _buildHorizontalLayout(unplacedPieces)
          : _buildVerticalLayout(unplacedPieces),
    );
  }

  /// 🔥 新機能：横向きレイアウト（下部配置用）
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

  /// 既存の縦向きレイアウト
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

  /// 🔥 新機能：横向きピースアイテム
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
          // ピースプレビュー
          Expanded(
            child: GestureDetector(
              onTap: () => _selectPiece(piece.id),
              child: Draggable<String>(
                data: piece.id,
                dragAnchorStrategy: pointerDragAnchorStrategy,

                onDragStarted: () {
                  print('🚀 横向きトレイからドラッグ開始: ${piece.id}');
                  _selectPiece(piece.id);
                },

                onDragEnd: (details) {
                  print('🏁 横向きトレイドラッグ終了: ${piece.id}');
                },

                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: _buildPiecePreview(piece, cellSize * 2),
                    ),
                  ),
                ),

                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildPiecePreview(piece, cellSize),
                ),

                child: _buildPiecePreview(piece, cellSize),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 回転ボタン
          GestureDetector(
            onTap: () => widget.onPieceRotated(piece.id),
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

  /// 既存の縦向きピースアイテム
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
              // ドラッグ可能なピースプレビュー
              Expanded(
                child: Draggable<String>(
                  data: piece.id,
                  dragAnchorStrategy: pointerDragAnchorStrategy,

                  onDragStarted: () {
                    print('🚀 縦向きトレイからドラッグ開始: ${piece.id}');
                    _selectPiece(piece.id);
                  },

                  onDragEnd: (details) {
                    print('🏁 縦向きトレイドラッグ終了: ${piece.id}');
                  },

                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: _buildPiecePreview(piece, cellSize * 1.5),
                      ),
                    ),
                  ),

                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildPiecePreview(piece, cellSize),
                  ),

                  child: _buildPiecePreview(piece, cellSize),
                ),
              ),

              const SizedBox(width: 8),

              // 回転ボタン
              IconButton(
                onPressed: () => widget.onPieceRotated(piece.id),
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

  /// ピースプレビュー作成
  Widget _buildPiecePreview(PuzzlePiece piece, double cellSize) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    // 🔧 改善：最小・最大サイズを制限
    final constrainedWidth = widget.isHorizontal
        ? width.clamp(24.0, 64.0)
        : width.clamp(40.0, 120.0);
    final constrainedHeight = widget.isHorizontal
        ? height.clamp(24.0, 64.0)
        : height.clamp(40.0, 120.0);

    return SizedBox(
      width: constrainedWidth,
      height: constrainedHeight,
      child: CustomPaint(
        painter: PiecePainter(
          piece: piece,
          cellSize: cellSize,
          isSelected: piece.id == _selectedPieceId,
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
