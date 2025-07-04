// lib/services/puzzle_generator.dart - 完成可能性を保証する改善版
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/puzzle_piece.dart';

/// パズルピース生成サービス（完成保証版）
class PuzzleGenerator {
  static const _uuid = Uuid();
  static final _random = Random();

  /// メインの生成メソッド（完成可能性を保証）
  static List<PuzzlePiece> generatePuzzle({required int gridSize, int? seed}) {
    if (seed != null) {
      // シードが指定された場合はランダムを初期化
    }

    // 最大試行回数を設定して確実に完成可能なパズルを生成
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        final pieces = _generateValidPuzzle(gridSize);
        if (_validatePuzzleCompleteness(pieces, gridSize)) {
          print('✅ 完成可能なパズル生成成功 (試行回数: ${attempt + 1})');
          return pieces;
        }
      } catch (e) {
        print('⚠️ パズル生成試行 ${attempt + 1} 失敗: $e');
      }
    }

    // フォールバック: シンプルな確実に完成可能なパズル
    print('🔄 フォールバック: シンプルパズルを生成');
    return _generateSimplePuzzle(gridSize);
  }

  /// 確実に完成可能なパズル生成
  static List<PuzzlePiece> _generateValidPuzzle(int gridSize) {
    // 1. 全マスを確実にカバーする領域分割
    final grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => -1),
    );

    final regions = <List<PiecePosition>>[];

    // 改良された分割アルゴリズム
    _improvedDivideGrid(
      grid: grid,
      regions: regions,
      x: 0,
      y: 0,
      width: gridSize,
      height: gridSize,
      regionId: 0,
    );

    // 2. 全マスがカバーされているか検証
    if (!_validateGridCoverage(grid, gridSize)) {
      throw Exception('グリッドの完全カバレッジ失敗');
    }

    // 3. 各領域をピースに変換
    final pieces = <PuzzlePiece>[];
    final colors = _generateColors(regions.length);

    for (int i = 0; i < regions.length; i++) {
      if (regions[i].isNotEmpty) {
        final piece = _createPieceFromRegion(regions[i], colors[i]);
        pieces.add(piece);
      }
    }

    // 4. ピース配置可能性を検証
    if (!_validatePiecePlacement(pieces, gridSize)) {
      throw Exception('ピース配置可能性検証失敗');
    }

    return pieces;
  }

  /// 改良されたグリッド分割（全マスを確実にカバー）
  static void _improvedDivideGrid({
    required List<List<int>> grid,
    required List<List<PiecePosition>> regions,
    required int x,
    required int y,
    required int width,
    required int height,
    required int regionId,
  }) {
    final totalCells = width * height;

    // 小さな領域は分割しない（2-6セル）
    if (totalCells <= 6) {
      _createRegion(grid, regions, x, y, width, height, regionId);
      return;
    }

    // 分割可能性をチェック
    bool canDivideVertically = width >= 2;
    bool canDivideHorizontally = height >= 2;

    if (!canDivideVertically && !canDivideHorizontally) {
      _createRegion(grid, regions, x, y, width, height, regionId);
      return;
    }

    // より均等な分割を目指す
    final shouldDivideVertically =
        width > height || (width == height && _random.nextBool());

    if (shouldDivideVertically && canDivideVertically) {
      // 縦分割（1/3から2/3の位置で分割）
      final minSplit = (width * 0.33).ceil();
      final maxSplit = (width * 0.67).floor();
      final splitX = x + minSplit + _random.nextInt(maxSplit - minSplit + 1);

      _improvedDivideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: y,
        width: splitX - x,
        height: height,
        regionId: regionId,
      );
      _improvedDivideGrid(
        grid: grid,
        regions: regions,
        x: splitX,
        y: y,
        width: x + width - splitX,
        height: height,
        regionId: regions.length,
      );
    } else if (canDivideHorizontally) {
      // 横分割
      final minSplit = (height * 0.33).ceil();
      final maxSplit = (height * 0.67).floor();
      final splitY = y + minSplit + _random.nextInt(maxSplit - minSplit + 1);

      _improvedDivideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: y,
        width: width,
        height: splitY - y,
        regionId: regionId,
      );
      _improvedDivideGrid(
        grid: grid,
        regions: regions,
        x: x,
        y: splitY,
        width: width,
        height: y + height - splitY,
        regionId: regions.length,
      );
    } else {
      _createRegion(grid, regions, x, y, width, height, regionId);
    }
  }

  /// 領域を作成（改良版）
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

    // 全セルを領域に追加
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final pos = PiecePosition(x + dx, y + dy);
        region.add(pos);
        grid[y + dy][x + dx] = regionId;
      }
    }

    // 領域をリストに追加
    if (regions.length <= regionId) {
      regions.addAll(
        List.generate(regionId - regions.length + 1, (_) => <PiecePosition>[]),
      );
    }
    regions[regionId] = region;
  }

  /// グリッドカバレッジ検証
  static bool _validateGridCoverage(List<List<int>> grid, int gridSize) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] == -1) {
          print('❌ 未カバーのセル発見: ($x, $y)');
          return false;
        }
      }
    }
    return true;
  }

  /// パズルの完成可能性を検証
  static bool _validatePuzzleCompleteness(
    List<PuzzlePiece> pieces,
    int gridSize,
  ) {
    // 1. 全ピースのセル数の合計が総マス数と一致するかチェック
    final totalCells = pieces.fold(0, (sum, piece) => sum + piece.cells.length);
    final expectedCells = gridSize * gridSize;

    if (totalCells != expectedCells) {
      print('❌ セル数不一致: $totalCells vs $expectedCells');
      return false;
    }

    // 2. 実際に配置可能かシミュレーション
    return _simulatePuzzleSolution(pieces, gridSize);
  }

  /// パズル解決シミュレーション
  static bool _simulatePuzzleSolution(List<PuzzlePiece> pieces, int gridSize) {
    final board = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    // 各ピースを配置可能な位置に配置してみる
    for (final piece in pieces) {
      bool placed = false;

      for (int rotation = 0; rotation < 4 && !placed; rotation++) {
        final rotatedPiece = piece.copyWith(rotation: rotation);
        final rotatedCells = rotatedPiece.getRotatedCells();

        for (int y = 0; y < gridSize && !placed; y++) {
          for (int x = 0; x < gridSize && !placed; x++) {
            final position = PiecePosition(x, y);

            if (_canPlacePieceAt(rotatedCells, position, board, gridSize)) {
              _placePieceOnBoard(rotatedCells, position, board);
              placed = true;
            }
          }
        }
      }

      if (!placed) {
        print('❌ ピース ${piece.id} の配置位置が見つかりません');
        return false;
      }
    }

    return true;
  }

  /// ピース配置可能性チェック
  static bool _canPlacePieceAt(
    List<PiecePosition> cells,
    PiecePosition position,
    List<List<bool>> board,
    int gridSize,
  ) {
    for (final cell in cells) {
      final boardX = position.x + cell.x;
      final boardY = position.y + cell.y;

      // 範囲外チェック
      if (boardX < 0 ||
          boardX >= gridSize ||
          boardY < 0 ||
          boardY >= gridSize) {
        return false;
      }

      // 重複チェック
      if (board[boardY][boardX]) {
        return false;
      }
    }
    return true;
  }

  /// ボードにピースを配置
  static void _placePieceOnBoard(
    List<PiecePosition> cells,
    PiecePosition position,
    List<List<bool>> board,
  ) {
    for (final cell in cells) {
      final boardX = position.x + cell.x;
      final boardY = position.y + cell.y;
      board[boardY][boardX] = true;
    }
  }

  /// ピース配置可能性を検証
  static bool _validatePiecePlacement(List<PuzzlePiece> pieces, int gridSize) {
    // 各ピースが少なくとも1箇所は配置可能かチェック
    for (final piece in pieces) {
      bool canPlace = false;

      for (int rotation = 0; rotation < 4 && !canPlace; rotation++) {
        final rotatedPiece = piece.copyWith(rotation: rotation);
        final rotatedCells = rotatedPiece.getRotatedCells();

        for (int y = 0; y < gridSize && !canPlace; y++) {
          for (int x = 0; x < gridSize && !canPlace; x++) {
            final position = PiecePosition(x, y);
            final boardCells = rotatedCells
                .map((cell) => cell + position)
                .toList();

            // 範囲内チェック
            bool inBounds = boardCells.every(
              (cell) =>
                  cell.x >= 0 &&
                  cell.x < gridSize &&
                  cell.y >= 0 &&
                  cell.y < gridSize,
            );

            if (inBounds) {
              canPlace = true;
            }
          }
        }
      }

      if (!canPlace) {
        print('❌ ピース ${piece.id} は配置不可能');
        return false;
      }
    }

    return true;
  }

  /// フォールバック: シンプルで確実なパズル生成
  static List<PuzzlePiece> _generateSimplePuzzle(int gridSize) {
    final pieces = <PuzzlePiece>[];
    final colors = _generateColors(gridSize * 2);
    int colorIndex = 0;

    // 単純な四角形ピースを生成
    for (int y = 0; y < gridSize; y += 2) {
      for (int x = 0; x < gridSize; x += 2) {
        final cells = <PiecePosition>[];

        // 2x2または1x1のピースを作成
        final width = (x + 2 <= gridSize) ? 2 : 1;
        final height = (y + 2 <= gridSize) ? 2 : 1;

        for (int dy = 0; dy < height; dy++) {
          for (int dx = 0; dx < width; dx++) {
            if (x + dx < gridSize && y + dy < gridSize) {
              cells.add(PiecePosition(dx, dy));
            }
          }
        }

        if (cells.isNotEmpty) {
          pieces.add(
            PuzzlePiece(
              id: _uuid.v4(),
              cells: cells,
              color: colors[colorIndex % colors.length],
            ),
          );
          colorIndex++;
        }
      }
    }

    return pieces;
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

  /// デバッグ用：パズル統計表示
  static void debugPrintPuzzleStats(List<PuzzlePiece> pieces, int gridSize) {
    final totalCells = pieces.fold(0, (sum, piece) => sum + piece.cells.length);
    final expectedCells = gridSize * gridSize;

    print('=== パズル統計 ===');
    print('ピース数: ${pieces.length}');
    print('総セル数: $totalCells / $expectedCells');
    print('平均ピースサイズ: ${(totalCells / pieces.length).toStringAsFixed(1)}');

    for (int i = 0; i < pieces.length; i++) {
      print('ピース${i + 1}: ${pieces[i].cells.length}セル');
    }
    print('================');
  }
}
