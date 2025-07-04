// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../providers/game_providers.dart';
import '../services/admob_service.dart';
import '../screens/help_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _titleAnimationController,
            curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
          ),
        );

    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // アニメーション開始
    _titleAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _buttonAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStats = ref.watch(gameStatsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E86C1), Color(0xFF3498DB), Color(0xFF5DADE2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // タイトルロゴ
                      _buildTitleSection(),

                      const SizedBox(height: 60),

                      // メインメニューボタン
                      _buildMainMenuButtons(),

                      const SizedBox(height: 40),

                      // 統計情報カード
                      _buildStatsCard(gameStats),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // バナー広告
              _buildBannerAd(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return SlideTransition(
      position: _titleSlideAnimation,
      child: FadeTransition(
        opacity: _titleFadeAnimation,
        child: Column(
          children: [
            // アプリアイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.extension,
                size: 60,
                color: Color(0xFF2E86C1),
              ),
            ),

            const SizedBox(height: 24),

            // アプリ名
            const Text(
              'ブレインブロックス',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'パズルで脳を鍛えよう',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuButtons() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: Column(
        children: [
          _buildMenuButton(
            icon: Icons.play_arrow,
            title: 'ゲーム開始',
            subtitle: 'パズルに挑戦',
            onTap: () => _navigateToLevelSelect(),
            primary: true,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMenuButton(
                  icon: Icons.today,
                  title: '日替わり',
                  subtitle: 'デイリーチャレンジ',
                  onTap: () => _showComingSoon('日替わりチャレンジ'),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildMenuButton(
                  icon: Icons.leaderboard,
                  title: 'ランキング',
                  subtitle: 'ベストスコア',
                  onTap: () => _showComingSoon('ランキング'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMenuButton(
                  icon: Icons.help_outline,
                  title: 'ヘルプ',
                  subtitle: '遊び方',
                  onTap: () => _showHelp(),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildMenuButton(
                  icon: Icons.settings,
                  title: '設定',
                  subtitle: 'ゲーム設定',
                  onTap: () => _navigateToSettings(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary ? Colors.white : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary
                      ? const Color(0xFF2E86C1)
                      : const Color(0xFF2E86C1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: primary ? 32 : 24,
                  color: primary ? Colors.white : const Color(0xFF2E86C1),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: TextStyle(
                  fontSize: primary ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E86C1),
                ),
              ),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: primary ? 14 : 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(GameStats stats) {
    return FadeTransition(
      opacity: _buttonScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '統計情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E86C1),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '総プレイ回数',
                    stats.gamesPlayed.toString(),
                    Icons.gamepad,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'クリア率',
                    '${(stats.completionRate * 100).toInt()}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '平均時間',
                    '${stats.averageTime.toInt()}秒',
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均手数',
                    stats.averageMoves.toInt().toString(),
                    Icons.touch_app,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E86C1), size: 24),
        const SizedBox(height: 4),
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBannerAd() {
    final bannerAd = AdMobService.instance.getBannerAdWidget();
    if (bannerAd != null) {
      return Container(margin: const EdgeInsets.only(top: 8), child: bannerAd);
    }
    return const SizedBox.shrink();
  }

  void _navigateToLevelSelect() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LevelSelectScreen()));
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('この機能は今後のアップデートで追加予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpScreen()));
  }
}
