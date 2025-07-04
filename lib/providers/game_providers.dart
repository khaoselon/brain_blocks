// lib/providers/game_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:uuid/uuid.dart';
import '../models/game_state.dart';
import '../models/puzzle_piece.dart';
import '../services/puzzle_generator.dart';
import '../services/firebase_service.dart';
import 'dart:math' as math;

const _uuid = Uuid();

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
    : super(GameState(gameId: _uuid.v4(), settings: settings, pieces: []));

  /// 新しいゲームを開始（Firebase連携）
  void startNewGame() {
    _stopTimer();

    // パフォーマンストレース開始
    _gameTrace = _firebaseService.startTrace('game_session');
    _gameTrace?.start();

    final pieces = PuzzleGenerator.generatePuzzle(
      gridSize: state.settings.difficulty.gridSize,
    );

    state = GameState(
      gameId: _uuid.v4(),
      settings: state.settings,
      pieces: pieces,
      status: GameStatus.playing,
      startTime: DateTime.now(),
    );

    // Firebase Analytics: ゲーム開始
    _firebaseService.logGameStart(
      difficulty: state.settings.difficulty.name,
      gameMode: state.settings.mode.name,
    );

    _startTimer();
  }

  /// ピースを配置（Firebase統合）
  void placePiece(String pieceId, PiecePosition position) {
    if (state.status != GameStatus.playing) return;

    final pieces = state.pieces.map((piece) {
      if (piece.id == pieceId) {
        return piece.copyWith(boardPosition: position);
      }
      return piece;
    }).toList();

    state = state.copyWith(pieces: pieces, moves: state.moves + 1);

    // 完了チェック
    _checkGameCompletion();
  }

  /// ピースを回転
  void rotatePiece(String pieceId) {
    if (state.status != GameStatus.playing) return;

    final pieces = state.pieces.map((piece) {
      if (piece.id == pieceId) {
        return piece.copyWith(rotation: (piece.rotation + 1) % 4);
      }
      return piece;
    }).toList();

    state = state.copyWith(pieces: pieces);
  }

  /// ピースを盤面から取り除く
  void removePiece(String pieceId) {
    if (state.status != GameStatus.playing) return;

    final pieces = state.pieces.map((piece) {
      if (piece.id == pieceId) {
        return piece.copyWith(boardPosition: null);
      }
      return piece;
    }).toList();

    state = state.copyWith(pieces: pieces);
  }

  /// ゲーム一時停止
  void pauseGame() {
    if (state.status == GameStatus.playing) {
      _stopTimer();
      state = state.copyWith(status: GameStatus.paused);

      // パフォーマンストレース一時停止
      _gameTrace?.putAttribute('paused', 'true');
    }
  }

  /// ゲーム再開
  void resumeGame() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
      _startTimer();

      // パフォーマンストレース再開
      _gameTrace?.putAttribute('resumed', 'true');
    }
  }

  /// ゲームリセット
  void resetGame() {
    _stopTimer();

    // 現在のトレース終了
    _gameTrace?.putAttribute('reset', 'true');
    _gameTrace?.stop();

    final resetPieces = state.pieces.map((piece) {
      return piece.copyWith(boardPosition: null, rotation: 0);
    }).toList();

    state = state.copyWith(
      pieces: resetPieces,
      status: GameStatus.playing,
      moves: 0,
      elapsedSeconds: 0,
      hintsUsed: 0,
      startTime: DateTime.now(),
    );

    // 新しいトレース開始
    _gameTrace = _firebaseService.startTrace('game_session');
    _gameTrace?.start();

    _startTimer();
  }

  /// ヒント使用（Firebase連携）
  void useHint() {
    if (state.status != GameStatus.playing) return;

    final unplacedPieces = state.pieces.where((p) => !p.isPlaced).toList();
    if (unplacedPieces.isNotEmpty) {
      state = state.copyWith(hintsUsed: state.hintsUsed + 1);

      // Firebase Analytics: ヒント使用
      _firebaseService.logEvent(
        name: 'hint_used',
        parameters: {
          'game_id': state.gameId,
          'difficulty': state.settings.difficulty.name,
          'current_moves': state.moves,
          'hints_total': state.hintsUsed,
        },
      );
    }
  }

  /// タイマー開始
  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == GameStatus.playing) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);

        // 制限時間チェック
        if (state.isTimeLimitExceeded) {
          _stopTimer();
          _completeGame(false);
        }
      }
    });
  }

  /// タイマー停止
  void _stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// ゲーム完了チェック
  void _checkGameCompletion() {
    if (state.isCompleted) {
      _stopTimer();
      _completeGame(true);
    } else if (state.isMoveLimitExceeded) {
      _stopTimer();
      _completeGame(false);
    }
  }

  /// ゲーム完了処理（Firebase連携）
  void _completeGame(bool isSuccess) {
    state = state.copyWith(
      status: isSuccess ? GameStatus.completed : GameStatus.failed,
    );

    // パフォーマンストレース終了
    _gameTrace?.putAttribute('success', isSuccess.toString());
    _gameTrace?.putAttribute('moves', state.moves.toString());
    _gameTrace?.putAttribute('time_seconds', state.elapsedSeconds.toString());
    _gameTrace?.stop();

    // Firebase Analytics: ゲーム完了
    _firebaseService.logGameComplete(
      difficulty: state.settings.difficulty.name,
      moves: state.moves,
      timeSeconds: state.elapsedSeconds,
      hintsUsed: state.hintsUsed,
      isSuccess: isSuccess,
    );

    // Firebase Analytics: カスタムイベント
    if (isSuccess) {
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
    }
  }

  /// ゲーム効率計算
  double _calculateGameEfficiency() {
    final idealMoves = state.pieces.length; // 理想的な手数
    final actualMoves = state.moves;
    return (idealMoves / actualMoves * 100).clamp(0, 100);
  }

  @override
  void dispose() {
    _stopTimer();
    _gameTrace?.stop();
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
  }

  /// スナップ位置を計算
  PiecePosition? findSnapPosition({
    required PuzzlePiece piece,
    required PiecePosition targetPosition,
    required List<PuzzlePiece> otherPieces,
    required int gridSize,
    double snapThreshold = 0.5,
  }) {
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

  GameStatsNotifier(this._firebaseService) : super(const GameStats());

  void recordGameCompletion({
    required GameDifficulty difficulty,
    required int moves,
    required int timeSeconds,
    required int hintsUsed,
  }) {
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

    // Firebase Analytics: 新記録達成
    if (isNewRecord) {
      _firebaseService.logEvent(
        name: 'new_best_time',
        parameters: {
          'difficulty': difficulty.name,
          'best_time_seconds': timeSeconds,
          'previous_best': currentBest ?? 0,
        },
      );
    }

    // Firebase Analytics: 統計更新
    _firebaseService.logEvent(
      name: 'player_stats_update',
      parameters: {
        'games_played': state.gamesPlayed,
        'completion_rate': state.completionRate,
        'average_time': state.averageTime,
        'average_moves': state.averageMoves,
      },
    );
  }

  void recordGameStart() {
    state = GameStats(
      gamesPlayed: state.gamesPlayed + 1,
      gamesCompleted: state.gamesCompleted,
      totalMoves: state.totalMoves,
      totalTime: state.totalTime,
      hintsUsed: state.hintsUsed,
      bestTimes: state.bestTimes,
    );
  }
}
