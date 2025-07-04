// lib/widgets/game_header_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GameHeaderWidget extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onHintPressed;
  final VoidCallback onResetPressed;

  const GameHeaderWidget({
    super.key,
    required this.gameState,
    required this.onHintPressed,
    required this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 難易度表示
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameState.settings.difficulty.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E86C1),
                  ),
                ),
                Text(
                  _getGameModeText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 統計情報
          Row(
            children: [
              _buildStatItem('手数', gameState.moves.toString()),
              const SizedBox(width: 16),
              _buildStatItem('時間', _formatTime(gameState.elapsedSeconds)),
              if (gameState.settings.mode == GameMode.moves && 
                  gameState.remainingMoves != null) ...[
                const SizedBox(width: 16),
                _buildStatItem('残り', gameState.remainingMoves!.toString()),
              ],
              if (gameState.settings.mode == GameMode.timer && 
                  gameState.remainingTime != null) ...[
                const SizedBox(width: 16),
                _buildStatItem('残り', _formatTime(gameState.remainingTime!)),
              ],
            ],
          ),
          
          const SizedBox(width: 16),
          
          // アクションボタン
          Row(
            children: [
              IconButton(
                onPressed: onHintPressed,
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'ヒント (${gameState.hintsUsed}回使用)',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF3CD),
                  foregroundColor: const Color(0xFF856404),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onResetPressed,
                icon: const Icon(Icons.refresh),
                tooltip: 'リセット',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFD1ECF1),
                  foregroundColor: const Color(0xFF0C5460),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E86C1),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getGameModeText() {
    switch (gameState.settings.mode) {
      case GameMode.moves:
        return '手数制限: ${gameState.settings.maxMoves ?? "無制限"}';
      case GameMode.timer:
        return '制限時間: ${_formatTime(gameState.settings.timeLimit ?? 0)}';
      case GameMode.unlimited:
        return '無制限モード';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}