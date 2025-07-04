// lib/widgets/game_result_dialog.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';

class GameResultDialog extends StatefulWidget {
  final bool isSuccess;
  final GameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const GameResultDialog({
    super.key,
    required this.isSuccess,
    required this.gameState,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // 背景
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
            
            // ダイアログ
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildDialog(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー（アニメーション）
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isSuccess
                      ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]
                      : [const Color(0xFFFF5722), const Color(0xFFFF7043)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: widget.isSuccess
                    ? Lottie.asset(
                        'assets/lottie/success.json',
                        width: 80,
                        height: 80,
                        repeat: false,
                      )
                    : const Icon(
                        Icons.refresh,
                        size: 60,
                        color: Colors.white,
                      ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // タイトル
                  Text(
                    widget.isSuccess ? 'おめでとうございます！' : 'もう一度挑戦！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isSuccess 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 統計情報
                  _buildStatsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // アクションボタン
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.timer,
                label: '時間',
                value: _formatTime(widget.gameState.elapsedSeconds),
                color: const Color(0xFF2196F3),
              ),
              _buildStatItem(
                icon: Icons.touch_app,
                label: '手数',
                value: widget.gameState.moves.toString(),
                color: const Color(0xFF9C27B0),
              ),
              _buildStatItem(
                icon: Icons.lightbulb,
                label: 'ヒント',
                value: widget.gameState.hintsUsed.toString(),
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
          
          if (widget.isSuccess) ...[
            const SizedBox(height: 16),
            _buildPerformanceRating(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

  Widget _buildPerformanceRating() {
    final rating = _calculateRating();
    final stars = _getStarCount(rating);
    
    return Column(
      children: [
        const Text(
          'パフォーマンス',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Icon(
              index < stars ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            );
          }),
        ),
        Text(
          rating,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onPlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86C1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'もう一度プレイ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: widget.onBackToMenu,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E86C1),
              side: const BorderSide(color: Color(0xFF2E86C1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'メニューに戻る',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateRating() {
    if (!widget.isSuccess) return '';
    
    final difficulty = widget.gameState.settings.difficulty;
    final moves = widget.gameState.moves;
    final time = widget.gameState.elapsedSeconds;
    final hints = widget.gameState.hintsUsed;
    
    // 基準値（難易度別）
    final baseMoves = difficulty.gridSize * difficulty.gridSize ~/ 2;
    final baseTime = difficulty.gridSize * 30; // 秒
    
    int score = 100;
    
    // 手数ペナルティ
    if (moves > baseMoves) {
      score -= (moves - baseMoves) * 2;
    }
    
    // 時間ペナルティ
    if (time > baseTime) {
      score -= (time - baseTime) ~/ 10;
    }
    
    // ヒントペナルティ
    score -= hints * 10;
    
    score = score.clamp(0, 100);
    
    if (score >= 90) return '完璧!';
    if (score >= 70) return 'とても良い';
    if (score >= 50) return '良い';
    return '頑張りました';
  }

  int _getStarCount(String rating) {
    switch (rating) {
      case '完璧!':
        return 3;
      case 'とても良い':
        return 2;
      case '良い':
        return 1;
      default:
        return 0;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

