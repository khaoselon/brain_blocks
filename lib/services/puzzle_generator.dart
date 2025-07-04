// lib/services/puzzle_generator.dart - 高度な形状対応版
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/puzzle_piece.dart';

/// 高度なパズルピース生成サービス
class PuzzleGenerator {
  static const _uuid = Uuid();
  static final _random = Random();

  /// 🎯 ピース形状テンプレート定義
  static final Map<String, List<List<String>>> _pieceTemplates = {
    // 基本形状
    'square_1x1': [
      ['1'],
    ],
    'square_2x2': [
      ['1', '2'],
      ['3', '4'],
    ],
    'rect_1x2': [
      ['1', '2'],
    ],
    'rect_2x1': [
      ['1'],
      ['2'],
    ],
    'rect_1x3': [
      ['1', '2', '3'],
    ],
    'rect_3x1': [
      ['1'],
      ['2'],
      ['3'],
    ],
    'rect_2x3': [
      ['1', '2', '3'],
      ['4', '5', '6'],
    ],

    // L字形状
    'L_small': [
      ['1', ' '],
      ['2', '3'],
    ],
    'L_medium': [
      ['1', ' ', ' '],
      ['2', '3', '4'],
    ],
    'L_large': [
      ['1', ' ', ' '],
      ['2', ' ', ' '],
      ['3', '4', '5'],
    ],
    'L_reverse': [
      [' ', '1'],
      ['3', '2'],
    ],

    // T字形状
    'T_small': [
      ['1', '2', '3'],
      [' ', '4', ' '],
    ],
    'T_medium': [
      ['1', '2', '3'],
      [' ', '4', ' '],
      [' ', '5', ' '],
    ],
    'T_upside_down': [
      [' ', '1', ' '],
      ['2', '3', '4'],
    ],

    // ＋字形状
    'plus_small': [
      [' ', '1', ' '],
      ['2', '3', '4'],
      [' ', '5', ' '],
    ],
    'plus_large': [
      [' ', ' ', '1', ' ', ' '],
      [' ', ' ', '2', ' ', ' '],
      ['3', '4', '5', '6', '7'],
      [' ', ' ', '8', ' ', ' '],
      [' ', ' ', '9', ' ', ' '],
    ],

    // Z/S字形状
    'Z_shape': [
      ['1', '2', ' '],
      [' ', '3', '4'],
    ],
    'S_shape': [
      [' ', '1', '2'],
      ['3', '4', ' '],
    ],

    // 特殊形状
    'stairs': [
      ['1', ' ', ' '],
      ['2', '3', ' '],
      [' ', '4', '5'],
    ],
    'corner': [
      ['1', '2'],
      ['3', ' '],
      ['4', ' '],
    ],
    'U_shape': [
      ['1', ' ', '2'],
      ['3', '4', '5'],
    ],
    'hook': [
      ['1', '2', '3'],
      ['4', ' ', ' '],
      ['5', ' ', ' '],
    ],

    // 大きな形状（10×10用）
    'big_L': [
      ['1', ' ', ' ', ' '],
      ['2', ' ', ' ', ' '],
      ['3', ' ', ' ', ' '],
      ['4', '5', '6', '7'],
    ],
    'big_T': [
      ['1', '2', '3', '4', '5'],
      [' ', ' ', '6', ' ', ' '],
      [' ', ' ', '7', ' ', ' '],
    ],
    'cross': [
      [' ', '1', ' '],
      ['2', '3', '4'],
      [' ', '5', ' '],
      [' ', '6', ' '],
    ],
  };

  /// 🎯 難易度別の推奨ピース組み合わせ
  static final Map<int, Map<String, int>> _difficultyPresets = {
    // 5×5 = 25セル
    5: {
      'square_2x2': 2, // 8セル
      'L_small': 2, // 6セル
      'T_small': 1, // 4セル
      'rect_1x3': 1, // 3セル
      'rect_2x1': 2, // 4セル
    },

    // 7×7 = 49セル
    7: {
      'square_2x2': 2, // 8セル
      'L_medium': 2, // 8セル
      'T_medium': 2, // 10セル
      'plus_small': 1, // 5セル
      'Z_shape': 2, // 8セル
      'rect_2x3': 1, // 6セル
      'rect_2x1': 2, // 4セル
    },

    // 10×10 = 100セル
    10: {
      'big_L': 1, // 7セル
      'big_T': 1, // 7セル
      'plus_large': 1, // 9セル
      'L_large': 2, // 10セル
      'T_medium': 3, // 15セル
      'square_2x2': 3, // 12セル
      'rect_2x3': 3, // 18セル
      'stairs': 2, // 10セル
      'hook': 2, // 10セル
      'rect_1x2': 1, // 2セル
    },
  };

  /// 🎮 メインの生成メソッド
  static List<PuzzlePiece> generatePuzzle({required int gridSize, int? seed}) {
    if (seed != null) {
      // シード設定（テスト用）
    }

    // 最大10回の試行で完成可能なパズルを生成
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        final pieces = _generateAdvancedPuzzle(gridSize);
        if (_validatePuzzleCompleteness(pieces, gridSize)) {
          print('✅ 高度なパズル生成成功 (試行回数: ${attempt + 1}, ピース数: ${pieces.length})');
          _printPuzzleStats(pieces, gridSize);
          return pieces;
        }
      } catch (e) {
        print('⚠️ パズル生成試行 ${attempt + 1} 失敗: $e');
      }
    }

    // フォールバック
    print('🔄 フォールバック: ランダムパズルを生成');
    return _generateRandomPuzzle(gridSize);
  }

  /// 🔧 高度なパズル生成
  static List<PuzzlePiece> _generateAdvancedPuzzle(int gridSize) {
    // 基本セット + ランダム追加の組み合わせ
    final useRandomGeneration = _random.nextBool();

    if (useRandomGeneration) {
      return _generateRandomCombination(gridSize);
    } else {
      return _generatePresetCombination(gridSize);
    }
  }

  /// 🎲 ランダム組み合わせ生成
  static List<PuzzlePiece> _generateRandomCombination(int gridSize) {
    final targetCells = gridSize * gridSize;
    final pieces = <PuzzlePiece>[];
    int usedCells = 0;

    // 利用可能なテンプレートをフィルタリング
    final availableTemplates = _filterTemplatesBySize(gridSize);
    final colors = _generateColors(20); // 十分な数の色を用意
    int colorIndex = 0;

    while (usedCells < targetCells && pieces.length < 15) {
      // 最大15ピース
      final remainingCells = targetCells - usedCells;

      // 残りセル数に適したテンプレートを選択
      final suitableTemplates = availableTemplates.entries
          .where((entry) => _countCells(entry.value) <= remainingCells)
          .toList();

      if (suitableTemplates.isEmpty) {
        // 小さなピースで埋める
        final cellsNeeded = remainingCells;
        if (cellsNeeded >= 4) {
          pieces.add(
            _createPieceFromTemplate(
              'square_2x2',
              _pieceTemplates['square_2x2']!,
              colors[colorIndex % colors.length],
            ),
          );
          usedCells += 4;
        } else if (cellsNeeded >= 2) {
          pieces.add(
            _createPieceFromTemplate(
              'rect_1x2',
              _pieceTemplates['rect_1x2']!,
              colors[colorIndex % colors.length],
            ),
          );
          usedCells += 2;
        } else {
          pieces.add(
            _createPieceFromTemplate(
              'square_1x1',
              _pieceTemplates['square_1x1']!,
              colors[colorIndex % colors.length],
            ),
          );
          usedCells += 1;
        }
        break;
      }

      // ランダムにテンプレートを選択
      final selectedTemplate =
          suitableTemplates[_random.nextInt(suitableTemplates.length)];
      final templateName = selectedTemplate.key;
      final template = selectedTemplate.value;
      final cellCount = _countCells(template);

      pieces.add(
        _createPieceFromTemplate(
          templateName,
          template,
          colors[colorIndex % colors.length],
        ),
      );

      usedCells += cellCount;
      colorIndex++;
    }

    // セル数の調整
    if (usedCells != targetCells) {
      return _adjustPieceCount(pieces, targetCells, colors);
    }

    return pieces;
  }

  /// 🎯 プリセット組み合わせ生成
  static List<PuzzlePiece> _generatePresetCombination(int gridSize) {
    final preset = _difficultyPresets[gridSize];
    if (preset == null) {
      return _generateRandomCombination(gridSize);
    }

    final pieces = <PuzzlePiece>[];
    final colors = _generateColors(20);
    int colorIndex = 0;

    // プリセットに基づいてピースを生成
    preset.forEach((templateName, count) {
      final template = _pieceTemplates[templateName];
      if (template != null) {
        for (int i = 0; i < count; i++) {
          pieces.add(
            _createPieceFromTemplate(
              templateName,
              template,
              colors[colorIndex % colors.length],
            ),
          );
          colorIndex++;
        }
      }
    });

    return pieces;
  }

  /// 🔧 ピースをテンプレートから作成
  static PuzzlePiece _createPieceFromTemplate(
    String templateName,
    List<List<String>> template,
    Color color,
  ) {
    final cells = <PiecePosition>[];

    for (int y = 0; y < template.length; y++) {
      for (int x = 0; x < template[y].length; x++) {
        if (template[y][x].trim().isNotEmpty) {
          cells.add(PiecePosition(x, y));
        }
      }
    }

    return PuzzlePiece(id: _uuid.v4(), cells: cells, color: color);
  }

  /// 🔧 グリッドサイズに適したテンプレートをフィルタリング
  static Map<String, List<List<String>>> _filterTemplatesBySize(int gridSize) {
    return Map.fromEntries(
      _pieceTemplates.entries.where((entry) {
        final template = entry.value;
        final maxWidth = template.fold<int>(
          0,
          (max, row) => row.length > max ? row.length : max,
        );
        final height = template.length;

        // グリッドサイズの70%以下のサイズのテンプレートのみ使用
        return maxWidth <= (gridSize * 0.7).ceil() &&
            height <= (gridSize * 0.7).ceil();
      }),
    );
  }

  /// 🔢 テンプレートのセル数をカウント
  static int _countCells(List<List<String>> template) {
    int count = 0;
    for (final row in template) {
      for (final cell in row) {
        if (cell.trim().isNotEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  /// 🔧 ピース数調整
  static List<PuzzlePiece> _adjustPieceCount(
    List<PuzzlePiece> pieces,
    int targetCells,
    List<Color> colors,
  ) {
    final currentCells = pieces.fold(
      0,
      (sum, piece) => sum + piece.cells.length,
    );
    final difference = targetCells - currentCells;

    if (difference > 0) {
      // セルが足りない場合、小さなピースを追加
      int remaining = difference;
      int colorIndex = pieces.length;

      while (remaining > 0) {
        if (remaining >= 4) {
          pieces.add(
            _createPieceFromTemplate(
              'square_2x2',
              _pieceTemplates['square_2x2']!,
              colors[colorIndex % colors.length],
            ),
          );
          remaining -= 4;
        } else if (remaining >= 2) {
          pieces.add(
            _createPieceFromTemplate(
              'rect_1x2',
              _pieceTemplates['rect_1x2']!,
              colors[colorIndex % colors.length],
            ),
          );
          remaining -= 2;
        } else {
          pieces.add(
            _createPieceFromTemplate(
              'square_1x1',
              _pieceTemplates['square_1x1']!,
              colors[colorIndex % colors.length],
            ),
          );
          remaining -= 1;
        }
        colorIndex++;
      }
    } else if (difference < 0) {
      // セルが多すぎる場合、大きなピースを小さなピースに分割
      // 簡単のため、最後のピースを削除して調整
      while (pieces.isNotEmpty &&
          pieces.fold(0, (sum, piece) => sum + piece.cells.length) >
              targetCells) {
        pieces.removeLast();
      }

      // 残りを埋める
      return _adjustPieceCount(pieces, targetCells, colors);
    }

    return pieces;
  }

  /// 🎲 フォールバック用ランダムパズル
  static List<PuzzlePiece> _generateRandomPuzzle(int gridSize) {
    final pieces = <PuzzlePiece>[];
    final colors = _generateColors(10);
    final targetCells = gridSize * gridSize;
    int usedCells = 0;
    int colorIndex = 0;

    // シンプルな組み合わせで確実に生成
    while (usedCells < targetCells) {
      final remaining = targetCells - usedCells;

      if (remaining >= 4 && _random.nextBool()) {
        pieces.add(
          _createPieceFromTemplate(
            'square_2x2',
            _pieceTemplates['square_2x2']!,
            colors[colorIndex % colors.length],
          ),
        );
        usedCells += 4;
      } else if (remaining >= 3 && _random.nextBool()) {
        pieces.add(
          _createPieceFromTemplate(
            'L_small',
            _pieceTemplates['L_small']!,
            colors[colorIndex % colors.length],
          ),
        );
        usedCells += 3;
      } else if (remaining >= 2) {
        pieces.add(
          _createPieceFromTemplate(
            'rect_1x2',
            _pieceTemplates['rect_1x2']!,
            colors[colorIndex % colors.length],
          ),
        );
        usedCells += 2;
      } else {
        pieces.add(
          _createPieceFromTemplate(
            'square_1x1',
            _pieceTemplates['square_1x1']!,
            colors[colorIndex % colors.length],
          ),
        );
        usedCells += 1;
      }

      colorIndex++;
    }

    return pieces;
  }

  /// 🔍 パズル完成可能性検証
  static bool _validatePuzzleCompleteness(
    List<PuzzlePiece> pieces,
    int gridSize,
  ) {
    // 1. セル数チェック
    final totalCells = pieces.fold(0, (sum, piece) => sum + piece.cells.length);
    final expectedCells = gridSize * gridSize;

    if (totalCells != expectedCells) {
      print('❌ セル数不一致: $totalCells vs $expectedCells');
      return false;
    }

    // 2. 配置シミュレーション
    return _simulateAdvancedPlacement(pieces, gridSize);
  }

  /// 🎮 高度な配置シミュレーション
  static bool _simulateAdvancedPlacement(
    List<PuzzlePiece> pieces,
    int gridSize,
  ) {
    final board = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    // バックトラッキングで全配置を試す
    return _backtrackPlacement(pieces, 0, board, gridSize);
  }

  /// 🔄 バックトラッキング配置
  static bool _backtrackPlacement(
    List<PuzzlePiece> pieces,
    int pieceIndex,
    List<List<bool>> board,
    int gridSize,
  ) {
    if (pieceIndex >= pieces.length) {
      return true; // 全ピース配置完了
    }

    final piece = pieces[pieceIndex];

    // 4つの回転を試す
    for (int rotation = 0; rotation < 4; rotation++) {
      final rotatedPiece = piece.copyWith(rotation: rotation);
      final rotatedCells = rotatedPiece.getRotatedCells();

      // 全ての位置を試す
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          final position = PiecePosition(x, y);

          if (_canPlaceAdvanced(rotatedCells, position, board, gridSize)) {
            // 配置
            _placeOnBoard(rotatedCells, position, board, true);

            // 次のピースを再帰的に配置
            if (_backtrackPlacement(pieces, pieceIndex + 1, board, gridSize)) {
              return true;
            }

            // バックトラック
            _placeOnBoard(rotatedCells, position, board, false);
          }
        }
      }
    }

    return false; // このピースは配置不可能
  }

  /// 🔧 高度な配置可能性チェック
  static bool _canPlaceAdvanced(
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

  /// 🔧 ボードに配置/除去
  static void _placeOnBoard(
    List<PiecePosition> cells,
    PiecePosition position,
    List<List<bool>> board,
    bool place,
  ) {
    for (final cell in cells) {
      final boardX = position.x + cell.x;
      final boardY = position.y + cell.y;
      board[boardY][boardX] = place;
    }
  }

  /// 🎨 カラーパレット生成
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
      const Color(0xFF6F42C1), // インディゴ
      const Color(0xFFE83E8C), // ピンク
      const Color(0xFF198754), // 成功グリーン
      const Color(0xFFFFC107), // 警告イエロー
      const Color(0xFF0DCAF0), // 情報シアン
    ];

    for (int i = 0; i < count; i++) {
      if (i < baseColors.length) {
        colors.add(baseColors[i]);
      } else {
        // 基本色を変化させる
        final baseIndex = i % baseColors.length;
        final baseColor = baseColors[baseIndex];
        colors.add(_adjustColor(baseColor, i ~/ baseColors.length));
      }
    }

    return colors;
  }

  /// 🎨 色調整
  static Color _adjustColor(Color color, int variation) {
    final hsl = HSLColor.fromColor(color);
    final adjustedHue = (hsl.hue + variation * 30) % 360;
    final adjustedLightness = (hsl.lightness * (0.8 + variation * 0.1)).clamp(
      0.3,
      0.8,
    );

    return hsl.withHue(adjustedHue).withLightness(adjustedLightness).toColor();
  }

  /// 📊 パズル統計表示
  static void _printPuzzleStats(List<PuzzlePiece> pieces, int gridSize) {
    final totalCells = pieces.fold(0, (sum, piece) => sum + piece.cells.length);
    final expectedCells = gridSize * gridSize;

    print('=== 高度パズル統計 ===');
    print('グリッドサイズ: ${gridSize}×${gridSize} ($expectedCells セル)');
    print('ピース数: ${pieces.length}');
    print('総セル数: $totalCells');
    print('平均ピースサイズ: ${(totalCells / pieces.length).toStringAsFixed(1)} セル');

    // ピースサイズ分布
    final sizeCounts = <int, int>{};
    for (final piece in pieces) {
      final size = piece.cells.length;
      sizeCounts[size] = (sizeCounts[size] ?? 0) + 1;
    }

    print('サイズ分布:');
    sizeCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))
      ..forEach((entry) {
        print('  ${entry.key}セル: ${entry.value}個');
      });

    print('===================');
  }

  /// 🎲 カスタムピース追加メソッド（将来の拡張用）
  static void addCustomTemplate(String name, List<List<String>> template) {
    _pieceTemplates[name] = template;
  }

  /// 📝 利用可能なテンプレート一覧取得
  static List<String> getAvailableTemplates() {
    return _pieceTemplates.keys.toList();
  }
}
