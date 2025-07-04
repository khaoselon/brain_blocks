// lib/widgets/piece_tray_widget.dart - 修正版
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import '../widgets/painters/piece_painter.dart';

class PieceTrayWidget extends StatefulWidget {
  final List<PuzzlePiece> pieces;
  final Function(String pieceId) onPieceSelected;
  final Function(String pieceId) onPieceRotated;

  const PieceTrayWidget({
    super.key,
    required this.pieces,
    required this.onPieceSelected,
    required this.onPieceRotated,
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
      margin: const EdgeInsets.only(right: 16),
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
      child: Column(
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

          // ピース一覧
          Expanded(
            child: unplacedPieces.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '全ピース配置完了！',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: unplacedPieces.length,
                    itemBuilder: (context, index) {
                      final piece = unplacedPieces[index];
                      return _buildPieceItem(piece);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceItem(PuzzlePiece piece) {
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
              // 🔥 修正：Draggableウィジェットの改善
              Expanded(
                child: Draggable<String>(
                  data: piece.id, // 🔥 重要：データとして piece.id を渡す
                  dragAnchorStrategy: pointerDragAnchorStrategy,

                  // 🔥 重要：ドラッグ開始時のログ
                  onDragStarted: () {
                    print('🚀 ドラッグ開始: ${piece.id}');
                    _selectPiece(piece.id);
                  },

                  // 🔥 重要：ドラッグ終了時のログ
                  onDragEnd: (details) {
                    print(
                      '🏁 ドラッグ終了: ${piece.id}, velocity: ${details.velocity}',
                    );
                  },

                  // 🔥 重要：ドラッグ中に表示されるウィジェット
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

                  // 🔥 重要：ドラッグ中の元の位置に表示されるウィジェット
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildPiecePreview(piece, cellSize),
                  ),

                  // 🔥 重要：通常時のウィジェット
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
        painter: PiecePainter(
          piece: piece,
          cellSize: cellSize,
          isSelected: piece.id == _selectedPieceId,
        ),
      ),
    );
  }

  void _selectPiece(String pieceId) {
    setState(() {
      _selectedPieceId = _selectedPieceId == pieceId ? null : pieceId;
    });
    widget.onPieceSelected(pieceId);
  }
}
