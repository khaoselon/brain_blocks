// lib/models/puzzle_piece.dart　
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// パズルピース座標
class PiecePosition extends Equatable {
  final int x;
  final int y;

  const PiecePosition(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  PiecePosition operator +(PiecePosition other) {
    return PiecePosition(x + other.x, y + other.y);
  }

  /// 90度回転（時計回り）
  PiecePosition rotate() {
    return PiecePosition(-y, x);
  }
}

/// パズルピース（相対座標のセル群）
class PuzzlePiece extends Equatable {
  final String id;
  final List<PiecePosition> cells; // 相対座標
  final Color color;
  final PiecePosition? boardPosition; // 盤面上の位置（null=未配置）
  final int rotation; // 0,1,2,3 (90度単位)

  const PuzzlePiece({
    required this.id,
    required this.cells,
    required this.color,
    this.boardPosition,
    this.rotation = 0,
  });

  @override
  List<Object?> get props => [id, cells, color, boardPosition, rotation];

  /// ピースをコピー（位置・回転変更用）
  PuzzlePiece copyWith({
    PiecePosition? boardPosition,
    int? rotation,
  }) {
    return PuzzlePiece(
      id: id,
      cells: cells,
      color: color,
      boardPosition: boardPosition ?? this.boardPosition,
      rotation: rotation ?? this.rotation,
    );
  }

  /// 回転後の座標を取得
  List<PiecePosition> getRotatedCells() {
    List<PiecePosition> rotated = cells;
    for (int i = 0; i < rotation; i++) {
      rotated = rotated.map((pos) => pos.rotate()).toList();
    }
    return rotated;
  }

  /// 盤面上での実際の座標を取得
  List<PiecePosition> getBoardCells() {
    if (boardPosition == null) return [];
    return getRotatedCells()
        .map((cell) => cell + boardPosition!)
        .toList();
  }

  /// 配置済みかどうか
  bool get isPlaced => boardPosition != null;
}
