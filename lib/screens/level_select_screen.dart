// lib/screens/level_select_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStats = ref.watch(gameStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('難易度選択'),
        backgroundColor: const Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'パズルの難易度を選択してください',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2E86C1),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDifficultyCard(
                      context,
                      ref,
                      GameDifficulty.easy,
                      gameStats,
                    ),
                    _buildDifficultyCard(
                      context,
                      ref,
                      GameDifficulty.medium,
                      gameStats,
                    ),
                    _buildDifficultyCard(
                      context,
                      ref,
                      GameDifficulty.hard,
                      gameStats,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    WidgetRef ref,
    GameDifficulty difficulty,
    GameStats stats,
  ) {
    final bestTime = stats.bestTimes[difficulty];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startGame(context, ref, difficulty),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getDifficultyColor(difficulty).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 難易度アイコン
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getDifficultyColor(difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDifficultyIcon(difficulty),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // 難易度情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      difficulty.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E86C1),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      _getDifficultyDescription(difficulty),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    if (bestTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ベスト: ${_formatTime(bestTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 進行度表示
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _getDifficultyColor(difficulty),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return const Color(0xFF4CAF50);
      case GameDifficulty.medium:
        return const Color(0xFFFF9800);
      case GameDifficulty.hard:
        return const Color(0xFFFF5722);
    }
  }

  IconData _getDifficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.sentiment_satisfied;
      case GameDifficulty.medium:
        return Icons.sentiment_neutral;
      case GameDifficulty.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  String _getDifficultyDescription(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return '初心者向け・基本ルールに慣れよう';
      case GameDifficulty.medium:
        return '中級者向け・少し複雑なパズル';
      case GameDifficulty.hard:
        return '上級者向け・本格的なチャレンジ';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startGame(BuildContext context, WidgetRef ref, GameDifficulty difficulty) {
    // ゲーム設定更新
    ref.read(gameSettingsProvider.notifier).updateDifficulty(difficulty);
    
    // ゲーム画面へ遷移
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }
}