// lib/models/game_state.dart
import 'package:equatable/equatable.dart';
import 'puzzle_piece.dart';

enum GameDifficulty { easy, medium, hard }

extension GameDifficultyExtension on GameDifficulty {
  int get gridSize {
    switch (this) {
      case GameDifficulty.easy:
        return 5;
      case GameDifficulty.medium:
        return 7;
      case GameDifficulty.hard:
        return 10;
    }
  }

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return '初級 (5×5)';
      case GameDifficulty.medium:
        return '中級 (7×7)';
      case GameDifficulty.hard:
        return '上級 (10×10)';
    }
  }
}

enum GameMode { moves, timer, unlimited }

class GameSettings extends Equatable {
  final GameDifficulty difficulty;
  final GameMode mode;
  final int? maxMoves; // 手数制限（null=無制限）
  final int? timeLimit; // 秒単位（null=無制限）
  final bool soundEnabled;
  final bool hapticsEnabled;

  const GameSettings({
    required this.difficulty,
    required this.mode,
    this.maxMoves,
    this.timeLimit,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  @override
  List<Object?> get props => [
    difficulty,
    mode,
    maxMoves,
    timeLimit,
    soundEnabled,
    hapticsEnabled,
  ];

  GameSettings copyWith({
    GameDifficulty? difficulty,
    GameMode? mode,
    int? maxMoves,
    int? timeLimit,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return GameSettings(
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      maxMoves: maxMoves ?? this.maxMoves,
      timeLimit: timeLimit ?? this.timeLimit,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

enum GameStatus { setup, playing, paused, completed, failed }

class GameState extends Equatable {
  final String gameId;
  final GameSettings settings;
  final List<PuzzlePiece> pieces;
  final GameStatus status;
  final int moves;
  final int elapsedSeconds;
  final int hintsUsed;
  final DateTime? startTime;

  const GameState({
    required this.gameId,
    required this.settings,
    required this.pieces,
    this.status = GameStatus.setup,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.hintsUsed = 0,
    this.startTime,
  });

  @override
  List<Object?> get props => [
    gameId,
    settings,
    pieces,
    status,
    moves,
    elapsedSeconds,
    hintsUsed,
    startTime,
  ];

  GameState copyWith({
    GameSettings? settings,
    List<PuzzlePiece>? pieces,
    GameStatus? status,
    int? moves,
    int? elapsedSeconds,
    int? hintsUsed,
    DateTime? startTime,
  }) {
    return GameState(
      gameId: gameId,
      settings: settings ?? this.settings,
      pieces: pieces ?? this.pieces,
      status: status ?? this.status,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      startTime: startTime ?? this.startTime,
    );
  }

  /// ゲーム完了チェック
  bool get isCompleted {
    final gridSize = settings.difficulty.gridSize;
    final placedCells = <PiecePosition>{};

    for (final piece in pieces) {
      if (piece.isPlaced) {
        placedCells.addAll(piece.getBoardCells());
      }
    }

    // 全てのセルが埋まっているかチェック
    return placedCells.length == gridSize * gridSize;
  }

  /// 制限時間・手数チェック
  bool get isTimeLimitExceeded {
    final limit = settings.timeLimit;
    return limit != null && elapsedSeconds >= limit;
  }

  bool get isMoveLimitExceeded {
    final limit = settings.maxMoves;
    return limit != null && moves >= limit;
  }

  /// 残り時間・手数
  int? get remainingTime {
    final limit = settings.timeLimit;
    return limit != null ? (limit - elapsedSeconds).clamp(0, limit) : null;
  }

  int? get remainingMoves {
    final limit = settings.maxMoves;
    return limit != null ? (limit - moves).clamp(0, limit) : null;
  }
}
