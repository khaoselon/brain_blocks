// lib/services/puzzle_generator.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/puzzle_piece.dart';

/// パズルピース生成サービス
class PuzzleGenerator {
  static const _uuid = Uuid();
  static final _random = Random();

  /// メインの生成メソッド
  static List<PuzzlePiece> generatePuzzle({required int gridSize, int? seed}) {
    if (seed != null) {
      // シードが指定された場合はランダムを初期化
      // _random = Random(seed); // 実装時はここでシード設定
    }

    // 1. グリッドを初期化
    final grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => -1),
    );

    // 2. 再帰分割でピース領域を生成
    final regions = <List<PiecePosition>>[];
    _divideGrid(
      grid: grid,
      regions: regions,
      x: 0,
      y: 0,
      width: gridSize,
      height: gridSize,
      regionId: 0,
    );

    // 3. 各領域をピースに変換
    final pieces = <PuzzlePiece>[];
    final colors = _generateColors(regions.length);

    for (int i = 0; i < regions.length; i++) {
      final piece = _createPieceFromRegion(regions[i], colors[i]);
      pieces.add(piece);
    }

    return pieces;
  }

  /// 再帰分割によるグリッド分割
  static void _divideGrid({
    required List<List<int>> grid,
    required List<List<PiecePosition>> regions,
    required int x,
    required int y,
    required int width,
    required int height,
    required int regionId,
  }) {
    // 最小サイズに達したら分割停止
    if (width * height <= 6) {
      _createRegion(grid, regions, x, y, width, height, regionId);
      return;
    }

    // ランダムで縦横分割を決定
    final shouldDivideVertically =
        width > height || (width == height && _random.nextBool());

    if (shouldDivideVertically && width >= 2) {
      // 縦分割
      final splitX = x + 1 + _random.nextInt(width - 1);
      _divideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: y,
        width: splitX - x,
        height: height,
        regionId: regionId,
      );
      _divideGrid(
        grid: grid,
        regions: regions,
        x: splitX,
        y: y,
        width: x + width - splitX,
        height: height,
        regionId: regions.length,
      );
    } else if (height >= 2) {
      // 横分割
      final splitY = y + 1 + _random.nextInt(height - 1);
      _divideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: y,
        width: width,
        height: splitY - y,
        regionId: regionId,
      );
      _divideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: splitY,
        width: width,
        height: y + height - splitY,
        regionId: regions.length,
      );
    } else {
      // 分割できない場合は領域作成
      _createRegion(grid, regions, x, y, width, height, regionId);
    }
  }

  /// 領域を作成
  static void _createRegion(
    List<List<int>> grid,
    List<List<PiecePosition>> regions,
    int x,
    int y,
    int width,
    int height,
    int regionId,
  ) {
    final region = <PiecePosition>[];

    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final pos = PiecePosition(x + dx, y + dy);
        region.add(pos);
        grid[y + dy][x + dx] = regionId;
      }
    }

    // 追加のランダム分割（複雑な形状作成）
    _randomlyModifyRegion(grid, region, regionId);

    regions.add(region);
  }

  /// 領域をランダムに修正（より複雑な形状のため）
  static void _randomlyModifyRegion(
    List<List<int>> grid,
    List<PiecePosition> region,
    int regionId,
  ) {
    if (region.length <= 2) return;

    // 小確率でセルを隣接領域に移動
    for (int i = region.length - 1; i >= 0; i--) {
      if (_random.nextDouble() < 0.1) {
        // 10%の確率
        final pos = region[i];
        final neighbors = _getNeighbors(grid, pos.x, pos.y);

        // 隣接する別の領域があれば移動
        for (final neighbor in neighbors) {
          final neighborId = grid[neighbor.y][neighbor.x];
          if (neighborId != regionId && neighborId != -1) {
            grid[pos.y][pos.x] = neighborId;
            region.removeAt(i);
            break;
          }
        }
      }
    }
  }

  /// 隣接セルを取得
  static List<PiecePosition> _getNeighbors(List<List<int>> grid, int x, int y) {
    final neighbors = <PiecePosition>[];
    final directions = [
      PiecePosition(0, -1), // 上
      PiecePosition(1, 0), // 右
      PiecePosition(0, 1), // 下
      PiecePosition(-1, 0), // 左
    ];

    for (final dir in directions) {
      final newX = x + dir.x;
      final newY = y + dir.y;

      if (newX >= 0 &&
          newX < grid[0].length &&
          newY >= 0 &&
          newY < grid.length) {
        neighbors.add(PiecePosition(newX, newY));
      }
    }

    return neighbors;
  }

  /// 領域からピースを作成
  static PuzzlePiece _createPieceFromRegion(
    List<PiecePosition> region,
    Color color,
  ) {
    if (region.isEmpty) {
      throw Exception('Empty region cannot create piece');
    }

    // 最小座標を基準点とする
    final minX = region.map((p) => p.x).reduce(min);
    final minY = region.map((p) => p.y).reduce(min);

    // 相対座標に変換
    final relativeCells = region
        .map((pos) => PiecePosition(pos.x - minX, pos.y - minY))
        .toList();

    return PuzzlePiece(id: _uuid.v4(), cells: relativeCells, color: color);
  }

  /// カラーパレット生成
  static List<Color> _generateColors(int count) {
    final colors = <Color>[];

    // 色覚バリアフリー対応カラーパレット
    final baseColors = [
      const Color(0xFF2E86C1), // 青
      const Color(0xFFE74C3C), // 赤
      const Color(0xFF28B463), // 緑
      const Color(0xFFF39C12), // オレンジ
      const Color(0xFF8E44AD), // 紫
      const Color(0xFF17A2B8), // シアン
      const Color(0xFFDC3545), // 深紅
      const Color(0xFF6C757D), // グレー
      const Color(0xFF20C997), // ティール
      const Color(0xFFFD7E14), // 明オレンジ
    ];

    for (int i = 0; i < count; i++) {
      if (i < baseColors.length) {
        colors.add(baseColors[i]);
      } else {
        // 基本色を少し変化させる
        final baseIndex = i % baseColors.length;
        final baseColor = baseColors[baseIndex];
        colors.add(_adjustColor(baseColor, i ~/ baseColors.length));
      }
    }

    return colors;
  }

  /// 色調整（明度・彩度変更）
  static Color _adjustColor(Color color, int variation) {
    final hsl = HSLColor.fromColor(color);
    final adjustedHue = (hsl.hue + variation * 30) % 360;
    final adjustedLightness = (hsl.lightness * (0.8 + variation * 0.1)).clamp(
      0.3,
      0.8,
    );

    return hsl.withHue(adjustedHue).withLightness(adjustedLightness).toColor();
  }

  /// デバッグ用：グリッド表示
  static void debugPrintGrid(List<List<int>> grid) {
    for (final row in grid) {
      print(row.map((cell) => cell.toString().padLeft(2)).join(' '));
    }
  }
}
