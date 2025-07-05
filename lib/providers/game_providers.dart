// lib/providers/game_providers.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:uuid/uuid.dart';
import '../models/game_state.dart';
import '../models/puzzle_piece.dart';
import '../services/puzzle_generator.dart';
import '../services/firebase_service.dart';
import 'dart:math' as math;

const _uuid = Uuid();

/// 🔥 新機能：拡張メソッドでfirstOrNullを追加
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// ゲーム設定プロバイダー
final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, GameSettings>((ref) {
      return GameSettingsNotifier();
    });

class GameSettingsNotifier extends StateNotifier<GameSettings> {
  GameSettingsNotifier()
    : super(
        const GameSettings(
          difficulty: GameDifficulty.easy,
          mode: GameMode.unlimited,
        ),
      );

  void updateDifficulty(GameDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  void updateMode(GameMode mode) {
    state = state.copyWith(mode: mode);
  }

  void updateSettings(GameSettings settings) {
    state = settings;
  }
}

/// メインゲーム状態プロバイダー（Firebase統合）
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  final settings = ref.watch(gameSettingsProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return GameStateNotifier(settings, firebaseService);
});

class GameStateNotifier extends StateNotifier<GameState> {
  final FirebaseService _firebaseService;
  Timer? _gameTimer;
  Trace? _gameTrace; // パフォーマンス計測

  GameStateNotifier(GameSettings settings, this._firebaseService)
    : super(GameState(gameId: _uuid.v4(), settings: settings, pieces: [])) {
    // 🔥 修正：初期化時のFirebaseサービス状態確認
    print('🎮 GameStateNotifier初期化');
    print('   Firebase初期化状態: ${_firebaseService.isInitialized}');

    if (!_firebaseService.isInitialized) {
      print('⚠️ Firebase未初期化でGameStateNotifier開始');
    }
  }

  /// 🔥 修正：新しいゲームを開始（Firebase未初期化対応強化）
  void startNewGame() {
    try {
      print('🎮 新しいゲーム開始処理');

      _stopTimer();

      // 🔥 修正：Firebase未初期化でも動作するように修正
      Trace? gameTrace;
      try {
        if (_firebaseService.isInitialized &&
            _firebaseService.performance != null) {
          gameTrace = _firebaseService.startTrace('game_session');
          gameTrace?.start();
          _gameTrace = gameTrace;
          print('✅ Firebase Trace開始');
        } else {
          print('⚠️ Firebase未初期化 - Traceスキップ');
          _gameTrace = null;
        }
      } catch (e) {
        print('⚠️ Firebase Trace開始エラー（続行）: $e');
        _gameTrace = null;
      }

      final pieces = PuzzleGenerator.generatePuzzle(
        gridSize: state.settings.difficulty.gridSize,
      );

      print('✅ パズル生成完了: ${pieces.length}ピース');

      state = GameState(
        gameId: _uuid.v4(),
        settings: state.settings,
        pieces: pieces,
        status: GameStatus.playing,
        startTime: DateTime.now(),
      );

      // 🔥 修正：Firebase Analytics（安全版）
      try {
        if (_firebaseService.isInitialized) {
          _firebaseService.logGameStart(
            difficulty: state.settings.difficulty.name,
            gameMode: state.settings.mode.name,
          );
          print('✅ Firebase Analytics送信成功');
        } else {
          print('⚠️ Firebase未初期化 - Analytics スキップ');
        }
      } catch (e) {
        print('⚠️ Firebase Analytics送信失敗（続行）: $e');
      }

      _startTimer();
      print('✅ 新しいゲーム開始完了');
    } catch (e, stackTrace) {
      print('❌ 新しいゲーム開始エラー: $e');
      print('スタックトレース: $stackTrace');

      // 🔥 修正：エラー時のフォールバック処理を強化
      try {
        // 最小限の状態でゲームを開始
        final fallbackPieces = _generateFallbackPuzzle();

        state = GameState(
          gameId: _uuid.v4(),
          settings: state.settings,
          pieces: fallbackPieces,
          status: GameStatus.playing,
          startTime: DateTime.now(),
        );

        _startTimer();
        print('✅ フォールバックでゲーム開始成功');
      } catch (fallbackError) {
        print('❌ フォールバックゲーム開始も失敗: $fallbackError');

        // 最後の手段：基本状態設定
        state = GameState(
          gameId: _uuid.v4(),
          settings: state.settings,
          pieces: [],
          status: GameStatus.setup,
          startTime: DateTime.now(),
        );
      }
    }
  }

  /// 🔥 新機能：フォールバック用の簡単なパズル生成
  List<PuzzlePiece> _generateFallbackPuzzle() {
    try {
      return PuzzleGenerator.generatePuzzle(
        gridSize: state.settings.difficulty.gridSize,
      );
    } catch (e) {
      print('❌ フォールバックパズル生成エラー: $e');

      // 最小限のピースを手動生成
      final gridSize = state.settings.difficulty.gridSize;
      final pieces = <PuzzlePiece>[];

      // 簡単な正方形ピースを生成
      for (int i = 0; i < (gridSize * gridSize ~/ 4); i++) {
        pieces.add(
          PuzzlePiece(
            id: _uuid.v4(),
            cells: const [
              PiecePosition(0, 0),
              PiecePosition(1, 0),
              PiecePosition(0, 1),
              PiecePosition(1, 1),
            ],
            color: Color(0xFF000000 + (i * 0x111111) % 0xFFFFFF),
          ),
        );
      }

      return pieces;
    }
  }

  /// ピースを配置（Firebase統合）
  void placePiece(String pieceId, PiecePosition position) {
    if (state.status != GameStatus.playing) {
      print('⚠️ ゲーム非プレイ状態でのピース配置試行');
      return;
    }

    try {
      final pieces = state.pieces.map((piece) {
        if (piece.id == pieceId) {
          return piece.copyWith(boardPosition: position);
        }
        return piece;
      }).toList();

      state = state.copyWith(pieces: pieces, moves: state.moves + 1);
      print('✅ ピース配置: $pieceId at $position');

      // 完了チェック
      _checkGameCompletion();
    } catch (e) {
      print('❌ ピース配置エラー: $e');
      rethrow;
    }
  }

  /// ピースを回転
  void rotatePiece(String pieceId) {
    if (state.status != GameStatus.playing) {
      print('⚠️ ゲーム非プレイ状態でのピース回転試行');
      return;
    }

    try {
      final pieces = state.pieces.map((piece) {
        if (piece.id == pieceId) {
          return piece.copyWith(rotation: (piece.rotation + 1) % 4);
        }
        return piece;
      }).toList();

      state = state.copyWith(pieces: pieces);
      print('✅ ピース回転: $pieceId');
    } catch (e) {
      print('❌ ピース回転エラー: $e');
      rethrow;
    }
  }

  /// 🔥 完全修正：ピースを盤面から取り除く（状態更新強化）
  void removePiece(String pieceId) {
    try {
      print('🔄 ピース除去開始: $pieceId');

      // 🔥 修正：現在の状態を詳細ログ出力
      final targetPiece = state.pieces
          .where((p) => p.id == pieceId)
          .firstOrNull;
      if (targetPiece == null) {
        print('❌ 指定されたピースが見つかりません: $pieceId');
        return;
      }

      print('   除去前の状態:');
      print('   - ピースID: ${targetPiece.id}');
      print('   - 配置状態: ${targetPiece.isPlaced}');
      print('   - 位置: ${targetPiece.boardPosition}');
      print('   - 総ピース数: ${state.pieces.length}');
      print('   - 配置済みピース数: ${state.pieces.where((p) => p.isPlaced).length}');

      // 🔥 重要：強制的に新しいリストを作成
      final updatedPieces = <PuzzlePiece>[];

      for (final piece in state.pieces) {
        if (piece.id == pieceId) {
          // 🔥 修正：新しいメソッドを使用して確実に配置解除
          final removedPiece = piece.createUnplacedCopy();
          updatedPieces.add(removedPiece);
          print('   ✅ ピース除去実行: ${piece.id} -> ${removedPiece.boardPosition}');
        } else {
          updatedPieces.add(piece);
        }
      }

      // 🔥 修正：強制的に新しい状態を作成
      final newState = GameState(
        gameId: state.gameId,
        settings: state.settings,
        pieces: updatedPieces, // 🔥 重要：新しいリストを設定
        status: state.status,
        moves: state.moves,
        elapsedSeconds: state.elapsedSeconds,
        hintsUsed: state.hintsUsed,
        startTime: state.startTime,
      );

      // 🔥 重要：状態を完全に置き換え
      state = newState;

      // 🔥 修正：除去後の状態確認
      final removedPiece = state.pieces
          .where((p) => p.id == pieceId)
          .firstOrNull;
      print('   除去後の状態:');
      print('   - ピースID: ${removedPiece?.id}');
      print('   - 配置状態: ${removedPiece?.isPlaced}');
      print('   - 位置: ${removedPiece?.boardPosition}');
      print('   - 配置済みピース数: ${state.pieces.where((p) => p.isPlaced).length}');

      if (removedPiece?.isPlaced == false) {
        print('✅ ピース除去成功: $pieceId');
      } else {
        print('❌ ピース除去失敗: まだ配置状態です');
      }

      // 🔥 新機能：UI更新を強制的にトリガー
      _forceUIUpdate();
    } catch (e, stackTrace) {
      print('❌ ピース除去エラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// 🔥 新機能：UI更新を強制的にトリガー
  void _forceUIUpdate() {
    try {
      // 状態を微細に変更してnotifyListenersを確実に発火
      final currentTime = DateTime.now();
      state = state.copyWith(startTime: currentTime);
      print('🔄 UI強制更新トリガー実行');
    } catch (e) {
      print('❌ UI強制更新エラー: $e');
    }
  }

  /// 🔥 新機能：デバッグ用の状態確認
  void debugCurrentState() {
    print('=== 現在のゲーム状態デバッグ ===');
    print('ゲームID: ${state.gameId}');
    print('ステータス: ${state.status}');
    print('総ピース数: ${state.pieces.length}');
    print('配置済みピース数: ${state.pieces.where((p) => p.isPlaced).length}');
    print('未配置ピース数: ${state.pieces.where((p) => !p.isPlaced).length}');

    for (int i = 0; i < state.pieces.length; i++) {
      final piece = state.pieces[i];
      print(
        '  ピース$i: ${piece.id.substring(0, 8)} - 配置: ${piece.isPlaced} - 位置: ${piece.boardPosition}',
      );
    }
    print('==========================');
  }

  /// ゲーム一時停止
  void pauseGame() {
    if (state.status == GameStatus.playing) {
      try {
        _stopTimer();
        state = state.copyWith(status: GameStatus.paused);
        print('✅ ゲーム一時停止');

        // パフォーマンストレース一時停止
        _gameTrace?.putAttribute('paused', 'true');
      } catch (e) {
        print('❌ ゲーム一時停止エラー: $e');
        rethrow;
      }
    }
  }

  /// ゲーム再開
  void resumeGame() {
    if (state.status == GameStatus.paused) {
      try {
        state = state.copyWith(status: GameStatus.playing);
        _startTimer();
        print('✅ ゲーム再開');

        // パフォーマンストレース再開
        _gameTrace?.putAttribute('resumed', 'true');
      } catch (e) {
        print('❌ ゲーム再開エラー: $e');
        rethrow;
      }
    }
  }

  /// 🔥 完全修正：ゲームリセット（Firebase未初期化対応）
  void resetGame() {
    try {
      print('🔄 ゲームリセット開始');
      print('   現在の状態: ${state.status}');
      print('   現在のピース数: ${state.pieces.length}');
      print('   Firebase初期化状態: ${_firebaseService.isInitialized}');

      // 現在のタイマーを停止
      _stopTimer();

      // 🔥 修正：Firebase関連処理（安全版）
      try {
        if (_gameTrace != null && _firebaseService.isInitialized) {
          _gameTrace!.putAttribute('reset', 'true');
          _gameTrace!.stop();
          print('✅ Firebase Trace終了');
        }
      } catch (e) {
        print('⚠️ Firebase Trace終了エラー（続行）: $e');
      }
      _gameTrace = null;

      // 🔥 重要：完全に新しいパズルを生成
      List<PuzzlePiece> newPieces;
      try {
        newPieces = PuzzleGenerator.generatePuzzle(
          gridSize: state.settings.difficulty.gridSize,
        );
        print('✅ 新しいパズル生成完了: ${newPieces.length}ピース');
      } catch (e) {
        print('❌ パズル生成エラー: $e');
        // フォールバック：基本的なピース生成
        newPieces = _generateFallbackPuzzle();
        print('🔄 フォールバックパズル生成: ${newPieces.length}ピース');
      }

      // 🔥 修正：完全に新しい状態を作成（すべてをリセット）
      state = GameState(
        gameId: _uuid.v4(), // 新しいゲームID
        settings: state.settings, // 設定は保持
        pieces: newPieces, // 🔥 重要：新しく生成されたピース
        status: GameStatus.playing, // 🔥 修正：プレイ状態で開始
        moves: 0, // リセット
        elapsedSeconds: 0, // リセット
        hintsUsed: 0, // リセット
        startTime: DateTime.now(), // 新しい開始時間
      );

      // 🔥 修正：新しいパフォーマンストレース開始（安全版）
      try {
        if (_firebaseService.isInitialized &&
            _firebaseService.performance != null) {
          _gameTrace = _firebaseService.startTrace('game_session_reset');
          _gameTrace?.start();
          print('✅ 新しいFirebase Trace開始');
        }
      } catch (e) {
        print('⚠️ 新Firebase Trace開始エラー（続行）: $e');
      }

      // 🔥 重要：タイマーを再開
      _startTimer();

      // 🔥 修正：Firebase Analytics（安全版）
      try {
        if (_firebaseService.isInitialized) {
          _firebaseService.logEvent(
            name: 'game_reset',
            parameters: {
              'difficulty': state.settings.difficulty.name,
              'game_mode': state.settings.mode.name,
              'pieces_count': newPieces.length,
            },
          );
          print('✅ Firebase リセットログ送信成功');
        } else {
          print('⚠️ Firebase未初期化 - リセットログスキップ');
        }
      } catch (e) {
        print('⚠️ Firebase リセットログ送信失敗（続行）: $e');
      }

      print('✅ ゲームリセット完了');
      print('   新しい状態: ${state.status}');
      print('   新しいピース数: ${state.pieces.length}');
      print('   新しいゲームID: ${state.gameId}');
    } catch (e, stackTrace) {
      print('❌ ゲームリセットエラー: $e');
      print('スタックトレース: $stackTrace');

      // 🔥 修正：エラー時の強力なフォールバック処理
      try {
        // 最低限の状態でゲームを継続
        final fallbackPieces = _generateFallbackPuzzle();

        state = GameState(
          gameId: _uuid.v4(),
          settings: state.settings,
          pieces: fallbackPieces,
          status: GameStatus.playing, // 🔥 修正：setup → playing
          moves: 0,
          elapsedSeconds: 0,
          hintsUsed: 0,
          startTime: DateTime.now(),
        );

        _startTimer(); // 🔥 追加：タイマー開始
        print('🔄 フォールバック状態設定完了');
      } catch (fallbackError) {
        print('❌ フォールバック処理も失敗: $fallbackError');
        // 最後の手段：最小限の状態
        state = GameState(
          gameId: _uuid.v4(),
          settings: const GameSettings(
            difficulty: GameDifficulty.easy,
            mode: GameMode.unlimited,
          ),
          pieces: [],
          status: GameStatus.setup,
        );
      }
    }
  }

  /// ヒント使用（Firebase連携・安全版）
  void useHint() {
    if (state.status != GameStatus.playing) {
      print('⚠️ ゲーム非プレイ状態でのヒント使用試行');
      return;
    }

    try {
      final unplacedPieces = state.pieces.where((p) => !p.isPlaced).toList();
      if (unplacedPieces.isNotEmpty) {
        state = state.copyWith(hintsUsed: state.hintsUsed + 1);
        print('✅ ヒント使用: ${state.hintsUsed}回目');

        // 🔥 修正：Firebase Analytics（安全版）
        try {
          if (_firebaseService.isInitialized) {
            _firebaseService.logEvent(
              name: 'hint_used',
              parameters: {
                'game_id': state.gameId,
                'difficulty': state.settings.difficulty.name,
                'current_moves': state.moves,
                'hints_total': state.hintsUsed,
              },
            );
            print('✅ ヒント使用ログ送信成功');
          } else {
            print('⚠️ Firebase未初期化 - ヒント使用ログスキップ');
          }
        } catch (e) {
          print('⚠️ ヒント使用ログ送信失敗（続行）: $e');
        }
      }
    } catch (e) {
      print('❌ ヒント使用エラー: $e');
      rethrow;
    }
  }

  /// 🔥 修正：タイマー開始（エラーハンドリング強化）
  void _startTimer() {
    try {
      _stopTimer(); // 既存のタイマーを停止

      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (state.status == GameStatus.playing) {
            state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

            // 制限時間チェック
            if (state.isTimeLimitExceeded) {
              _stopTimer();
              _completeGame(false);
            }
          }
        } catch (e) {
          print('❌ タイマー処理エラー: $e');
          _stopTimer();
        }
      });

      print('✅ タイマー開始');
    } catch (e) {
      print('❌ タイマー開始エラー: $e');
    }
  }

  /// 🔥 修正：タイマー停止（安全版）
  void _stopTimer() {
    try {
      _gameTimer?.cancel();
      _gameTimer = null;
      print('🛑 タイマー停止');
    } catch (e) {
      print('❌ タイマー停止エラー: $e');
    }
  }

  /// ゲーム完了チェック
  void _checkGameCompletion() {
    try {
      if (state.isCompleted) {
        _stopTimer();
        _completeGame(true);
      } else if (state.isMoveLimitExceeded) {
        _stopTimer();
        _completeGame(false);
      }
    } catch (e) {
      print('❌ ゲーム完了チェックエラー: $e');
    }
  }

  /// ゲーム完了処理（Firebase連携・安全版）
  void _completeGame(bool isSuccess) {
    try {
      state = state.copyWith(
        status: isSuccess ? GameStatus.completed : GameStatus.failed,
      );

      print('🎯 ゲーム完了: ${isSuccess ? "成功" : "失敗"}');

      // 🔥 修正：パフォーマンストレース終了（安全版）
      try {
        if (_gameTrace != null && _firebaseService.isInitialized) {
          _gameTrace!.putAttribute('success', isSuccess.toString());
          _gameTrace!.putAttribute('moves', state.moves.toString());
          _gameTrace!.putAttribute(
            'time_seconds',
            state.elapsedSeconds.toString(),
          );
          _gameTrace!.stop();
          print('✅ Firebase Trace終了');
        }
      } catch (e) {
        print('⚠️ Firebase Trace終了エラー（続行）: $e');
      }

      // 🔥 修正：Firebase Analytics（安全版）
      try {
        if (_firebaseService.isInitialized) {
          _firebaseService.logGameComplete(
            difficulty: state.settings.difficulty.name,
            moves: state.moves,
            timeSeconds: state.elapsedSeconds,
            hintsUsed: state.hintsUsed,
            isSuccess: isSuccess,
          );
          print('✅ ゲーム完了ログ送信成功');
        } else {
          print('⚠️ Firebase未初期化 - ゲーム完了ログスキップ');
        }
      } catch (e) {
        print('⚠️ ゲーム完了ログ送信失敗（続行）: $e');
      }

      // 🔥 修正：カスタムイベント（安全版）
      if (isSuccess) {
        try {
          if (_firebaseService.isInitialized) {
            // 達成度分析
            final efficiency = _calculateGameEfficiency();
            _firebaseService.logEvent(
              name: 'game_success_analysis',
              parameters: {
                'difficulty': state.settings.difficulty.name,
                'efficiency_score': efficiency,
                'moves_per_piece': state.moves / state.pieces.length,
                'time_per_piece': state.elapsedSeconds / state.pieces.length,
              },
            );
            print('✅ 成功分析ログ送信成功');
          } else {
            print('⚠️ Firebase未初期化 - 成功分析ログスキップ');
          }
        } catch (e) {
          print('⚠️ 成功分析ログ送信失敗（続行）: $e');
        }
      }
    } catch (e) {
      print('❌ ゲーム完了処理エラー: $e');
    }
  }

  /// ゲーム効率計算
  double _calculateGameEfficiency() {
    try {
      final idealMoves = state.pieces.length; // 理想的な手数
      final actualMoves = state.moves;
      if (actualMoves == 0) return 0.0;
      return (idealMoves / actualMoves * 100).clamp(0, 100);
    } catch (e) {
      print('❌ ゲーム効率計算エラー: $e');
      return 0.0;
    }
  }

  @override
  void dispose() {
    print('🧹 GameStateNotifier dispose開始');
    try {
      _stopTimer();
      _gameTrace?.stop();
      print('✅ GameStateNotifier dispose完了');
    } catch (e) {
      print('❌ GameStateNotifier dispose エラー: $e');
    }
    super.dispose();
  }
}

/// 配置検証プロバイダー
final placementValidatorProvider = Provider<PlacementValidator>((ref) {
  return PlacementValidator();
});

class PlacementValidator {
  /// ピース配置が有効かチェック
  bool isValidPlacement({
    required PuzzlePiece piece,
    required PiecePosition position,
    required List<PuzzlePiece> otherPieces,
    required int gridSize,
  }) {
    try {
      final rotatedCells = piece.getRotatedCells();
      final boardCells = rotatedCells.map((cell) => cell + position).toList();

      // 盤面範囲チェック
      for (final cell in boardCells) {
        if (cell.x < 0 ||
            cell.x >= gridSize ||
            cell.y < 0 ||
            cell.y >= gridSize) {
          return false;
        }
      }

      // 他のピースとの重複チェック
      final occupiedCells = <PiecePosition>{};
      for (final otherPiece in otherPieces) {
        if (otherPiece.id != piece.id && otherPiece.isPlaced) {
          occupiedCells.addAll(otherPiece.getBoardCells());
        }
      }

      for (final cell in boardCells) {
        if (occupiedCells.contains(cell)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ 配置検証エラー: $e');
      return false;
    }
  }

  /// スナップ位置を計算
  PiecePosition? findSnapPosition({
    required PuzzlePiece piece,
    required PiecePosition targetPosition,
    required List<PuzzlePiece> otherPieces,
    required int gridSize,
    double snapThreshold = 0.5,
  }) {
    try {
      // 最も近い有効な位置を探索
      final candidates = <PiecePosition>[];

      // ターゲット周辺の候補位置を生成
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final candidate = PiecePosition(
            targetPosition.x + dx,
            targetPosition.y + dy,
          );
          candidates.add(candidate);
        }
      }

      // 有効な位置から最も近いものを選択
      PiecePosition? bestPosition;
      double minDistance = double.infinity;

      for (final candidate in candidates) {
        if (isValidPlacement(
          piece: piece,
          position: candidate,
          otherPieces: otherPieces,
          gridSize: gridSize,
        )) {
          final distance = _calculateDistance(targetPosition, candidate);
          if (distance < minDistance && distance <= snapThreshold) {
            minDistance = distance;
            bestPosition = candidate;
          }
        }
      }

      return bestPosition;
    } catch (e) {
      print('❌ スナップ位置計算エラー: $e');
      return null;
    }
  }

  double _calculateDistance(PiecePosition a, PiecePosition b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// ゲーム統計プロバイダー（Firebase統合）
final gameStatsProvider = StateNotifierProvider<GameStatsNotifier, GameStats>((
  ref,
) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return GameStatsNotifier(firebaseService);
});

class GameStats {
  final int gamesPlayed;
  final int gamesCompleted;
  final int totalMoves;
  final int totalTime; // 秒
  final int hintsUsed;
  final Map<GameDifficulty, int> bestTimes; // 各難易度の最短時間

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesCompleted = 0,
    this.totalMoves = 0,
    this.totalTime = 0,
    this.hintsUsed = 0,
    this.bestTimes = const {},
  });

  double get completionRate {
    return gamesPlayed > 0 ? gamesCompleted / gamesPlayed : 0.0;
  }

  double get averageTime {
    return gamesCompleted > 0 ? totalTime / gamesCompleted : 0.0;
  }

  double get averageMoves {
    return gamesCompleted > 0 ? totalMoves / gamesCompleted : 0.0;
  }
}

class GameStatsNotifier extends StateNotifier<GameStats> {
  final FirebaseService _firebaseService;

  GameStatsNotifier(this._firebaseService) : super(const GameStats()) {
    // 🔥 修正：初期化時のFirebase状態確認
    print('📊 GameStatsNotifier初期化');
    print('   Firebase初期化状態: ${_firebaseService.isInitialized}');
  }

  void recordGameCompletion({
    required GameDifficulty difficulty,
    required int moves,
    required int timeSeconds,
    required int hintsUsed,
  }) {
    try {
      final newBestTimes = Map<GameDifficulty, int>.from(state.bestTimes);
      final currentBest = newBestTimes[difficulty];

      bool isNewRecord = false;
      if (currentBest == null || timeSeconds < currentBest) {
        newBestTimes[difficulty] = timeSeconds;
        isNewRecord = true;
      }

      state = GameStats(
        gamesPlayed: state.gamesPlayed + 1,
        gamesCompleted: state.gamesCompleted + 1,
        totalMoves: state.totalMoves + moves,
        totalTime: state.totalTime + timeSeconds,
        hintsUsed: state.hintsUsed + hintsUsed,
        bestTimes: newBestTimes,
      );

      // 🔥 修正：Firebase Analytics（安全版）
      if (isNewRecord) {
        try {
          if (_firebaseService.isInitialized) {
            _firebaseService.logEvent(
              name: 'new_best_time',
              parameters: {
                'difficulty': difficulty.name,
                'best_time_seconds': timeSeconds,
                'previous_best': currentBest ?? 0,
              },
            );
            print('✅ 新記録ログ送信成功');
          } else {
            print('⚠️ Firebase未初期化 - 新記録ログスキップ');
          }
        } catch (e) {
          print('⚠️ 新記録ログ送信失敗（続行）: $e');
        }
      }

      // 🔥 修正：統計更新ログ（安全版）
      try {
        if (_firebaseService.isInitialized) {
          _firebaseService.logEvent(
            name: 'player_stats_update',
            parameters: {
              'games_played': state.gamesPlayed,
              'completion_rate': state.completionRate,
              'average_time': state.averageTime,
              'average_moves': state.averageMoves,
            },
          );
          print('✅ 統計更新ログ送信成功');
        } else {
          print('⚠️ Firebase未初期化 - 統計更新ログスキップ');
        }
      } catch (e) {
        print('⚠️ 統計更新ログ送信失敗（続行）: $e');
      }
    } catch (e) {
      print('❌ ゲーム完了記録エラー: $e');
    }
  }

  void recordGameStart() {
    try {
      state = GameStats(
        gamesPlayed: state.gamesPlayed + 1,
        gamesCompleted: state.gamesCompleted,
        totalMoves: state.totalMoves,
        totalTime: state.totalTime,
        hintsUsed: state.hintsUsed,
        bestTimes: state.bestTimes,
      );
      print('📊 ゲーム開始記録完了');
    } catch (e) {
      print('❌ ゲーム開始記録エラー: $e');
    }
  }
}
