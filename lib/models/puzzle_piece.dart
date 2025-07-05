// lib/models/puzzle_piece.dart - copyWith修正版
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

  @override
  String toString() => 'PiecePosition($x, $y)';
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

  /// 🔥 修正：ピースをコピー（位置・回転変更用）- 明示的null処理
  PuzzlePiece copyWith({
    PiecePosition? boardPosition,
    int? rotation,
    bool? clearPosition, // 🔥 新機能：明示的に位置をクリア
  }) {
    // 🔥 修正：明示的にboardPositionをnullにする場合の処理
    PiecePosition? newBoardPosition;
    if (clearPosition == true) {
      newBoardPosition = null;
    } else if (boardPosition != null) {
      newBoardPosition = boardPosition;
    } else {
      newBoardPosition = this.boardPosition;
    }

    return PuzzlePiece(
      id: id,
      cells: cells,
      color: color,
      boardPosition: newBoardPosition,
      rotation: rotation ?? this.rotation,
    );
  }

  /// 🔥 新機能：配置をクリアした新しいピースを作成
  PuzzlePiece clearPlacement() {
    return PuzzlePiece(
      id: id,
      cells: cells,
      color: color,
      boardPosition: null, // 明示的にnull
      rotation: rotation, // 回転状態は保持
    );
  }

  /// 🔥 新機能：完全に新しいピースを作成（除去用）
  PuzzlePiece createUnplacedCopy() {
    return PuzzlePiece(
      id: id,
      cells: List<PiecePosition>.from(cells), // 新しいリスト
      color: color,
      boardPosition: null, // 必ずnull
      rotation: rotation,
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
    return getRotatedCells().map((cell) => cell + boardPosition!).toList();
  }

  /// 配置済みかどうか
  bool get isPlaced => boardPosition != null;

  @override
  String toString() {
    return 'PuzzlePiece(id: $id, boardPosition: $boardPosition, rotation: $rotation, isPlaced: $isPlaced)';
  }
}
