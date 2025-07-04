// lib/screens/game_screen.dart - ピース除去機能対応版
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/puzzle_piece.dart';
import '../providers/game_providers.dart';
import '../services/att_service.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/piece_tray_widget.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/game_result_dialog.dart';
import '../widgets/att_dialog_widget.dart';
import '../services/admob_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _hintAnimationController;
  String? _hintPieceId;
  bool _hasCompletedFirstGame = false;

  @override
  void initState() {
    super.initState();
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // ゲーム開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).startNewGame();
    });
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    // ゲーム状態変化の監視
    ref.listen<GameState>(gameStateProvider, (previous, current) {
      if (previous?.status != current.status) {
        _handleGameStatusChange(previous, current);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('ブレインブロックス'),
        backgroundColor: const Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _showPauseMenu, icon: const Icon(Icons.pause)),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            if (isLandscape && screenWidth > 800) {
              return _buildLandscapeLayout(gameState, constraints);
            } else {
              return _buildPortraitLayout(gameState, constraints);
            }
          },
        ),
      ),
    );
  }

  /// 縦並びレイアウト
  Widget _buildPortraitLayout(GameState gameState, BoxConstraints constraints) {
    final screenHeight = constraints.maxHeight;
    final headerHeight = 90.0;
    final trayHeight = (screenHeight * 0.22).clamp(140.0, 220.0);

    return Column(
      children: [
        // ゲームヘッダー
        Container(
          height: headerHeight,
          child: GameHeaderWidget(
            gameState: gameState,
            onHintPressed: _useHint,
            onResetPressed: _resetGame,
          ),
        ),

        const SizedBox(height: 8),

        // メインゲーム盤面
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GameBoardWidget(
                  gameState: gameState,
                  hintPieceId: _hintPieceId,
                  hintAnimation: _hintAnimationController,
                  onPiecePlaced: _onPiecePlaced,
                  onPieceRemoved: _onPieceRemoved, // 🔥 新機能
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 下部ピーストレイ
        Container(
          height: trayHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PieceTrayWidget(
            pieces: gameState.pieces,
            onPieceSelected: _onPieceSelected,
            onPieceRotated: _onPieceRotated,
            isHorizontal: true,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 横画面レイアウト
  Widget _buildLandscapeLayout(
    GameState gameState,
    BoxConstraints constraints,
  ) {
    return Column(
      children: [
        // ゲームヘッダー
        GameHeaderWidget(
          gameState: gameState,
          onHintPressed: _useHint,
          onResetPressed: _resetGame,
        ),

        const SizedBox(height: 16),

        // メインゲーム領域（横並び）
        Expanded(
          child: Row(
            children: [
              // ゲーム盤面
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: GameBoardWidget(
                    gameState: gameState,
                    hintPieceId: _hintPieceId,
                    hintAnimation: _hintAnimationController,
                    onPiecePlaced: _onPiecePlaced,
                    onPieceRemoved: _onPieceRemoved, // 🔥 新機能
                  ),
                ),
              ),

              // ピーストレイ（縦）
              Expanded(
                flex: 2,
                child: PieceTrayWidget(
                  pieces: gameState.pieces,
                  onPieceSelected: _onPieceSelected,
                  onPieceRotated: _onPieceRotated,
                  isHorizontal: false,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ゲーム状態変化の監視
  void _handleGameStatusChange(GameState? previous, GameState current) {
    switch (current.status) {
      case GameStatus.completed:
        _onGameCompleted();
        _showResultDialog(true);
        break;
      case GameStatus.failed:
        _showResultDialog(false);
        break;
      default:
        break;
    }
  }

  void _onGameCompleted() {
    if (!_hasCompletedFirstGame) {
      _hasCompletedFirstGame = true;
      Future.delayed(const Duration(seconds: 2), () {
        _showATTDialogIfNeeded();
      });
    }
  }

  void _showATTDialogIfNeeded() {
    final attService = ref.read(attServiceProvider);
    if (attService.currentStatus == ATTStatus.notDetermined) {
      _showATTExplanationDialog();
    }
  }

  void _showATTExplanationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ATTExplanationDialog(onAccept: () {}, onDecline: () {}),
    );
  }

  /// ピース配置処理
  void _onPiecePlaced(String pieceId, PiecePosition position) {
    print('🎯 ピース配置コールバック: $pieceId at $position');

    try {
      ref.read(gameStateProvider.notifier).placePiece(pieceId, position);
      HapticFeedback.lightImpact();

      // 配置成功のフィードバック
      _showSuccessMessage('ピースを配置しました！');
    } catch (e) {
      print('❌ ピース配置エラー: $e');
      HapticFeedback.mediumImpact();
      _showErrorMessage('ピース配置に失敗しました');
    }
  }

  /// 🔥 新機能：ピース除去処理
  void _onPieceRemoved(String pieceId) {
    print('🔄 ピース除去コールバック: $pieceId');

    try {
      ref.read(gameStateProvider.notifier).removePiece(pieceId);
      HapticFeedback.mediumImpact();

      // 除去成功のフィードバック
      _showInfoMessage('ピースを取り外しました');
    } catch (e) {
      print('❌ ピース除去エラー: $e');
      HapticFeedback.heavyImpact();
      _showErrorMessage('ピース除去に失敗しました');
    }
  }

  void _onPieceSelected(String pieceId) {
    print('🎯 ピース選択: $pieceId');
    // 必要に応じて追加処理
  }

  void _onPieceRotated(String pieceId) {
    ref.read(gameStateProvider.notifier).rotatePiece(pieceId);
    HapticFeedback.selectionClick();

    // 回転フィードバック
    _showInfoMessage('ピースを回転しました');
  }

  /// 🎉 成功メッセージ表示
  void _showSuccessMessage(String message) {
    _showMessage(message, Colors.green);
  }

  /// ⚠️ エラーメッセージ表示
  void _showErrorMessage(String message) {
    _showMessage(message, Colors.red);
  }

  /// ℹ️ 情報メッセージ表示
  void _showInfoMessage(String message) {
    _showMessage(message, Colors.blue);
  }

  /// 共通メッセージ表示
  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getMessageIcon(color), color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 200, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// メッセージアイコン取得
  IconData _getMessageIcon(Color color) {
    if (color == Colors.green) return Icons.check_circle;
    if (color == Colors.red) return Icons.error;
    if (color == Colors.blue) return Icons.info;
    return Icons.notifications;
  }

  void _useHint() async {
    final gameState = ref.read(gameStateProvider);
    final unplacedPieces = gameState.pieces.where((p) => !p.isPlaced).toList();

    if (unplacedPieces.isNotEmpty) {
      final adService = ref.read(admobServiceProvider);
      final rewardEarned = await adService.showRewardedAd();

      if (rewardEarned) {
        setState(() {
          _hintPieceId = unplacedPieces.first.id;
        });

        _hintAnimationController.forward().then((_) {
          _hintAnimationController.reverse().then((_) {
            setState(() {
              _hintPieceId = null;
            });
          });
        });

        ref.read(gameStateProvider.notifier).useHint();
        _showInfoMessage('ヒントを表示しました！');
      }
    } else {
      _showInfoMessage('配置可能なピースがありません');
    }
  }

  void _resetGame() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームリセット'),
        content: const Text('現在の進行状況がリセットされます。\nよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(gameStateProvider.notifier).resetGame();
        _showInfoMessage('ゲームをリセットしました');
      }
    });
  }

  void _showPauseMenu() {
    ref.read(gameStateProvider.notifier).pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle, color: Color(0xFF2E86C1)),
            SizedBox(width: 8),
            Text('一時停止'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPauseMenuItem(
              icon: Icons.play_arrow,
              title: 'ゲーム再開',
              onTap: () {
                Navigator.of(context).pop();
                ref.read(gameStateProvider.notifier).resumeGame();
                _showInfoMessage('ゲームを再開しました');
              },
            ),
            _buildPauseMenuItem(
              icon: Icons.refresh,
              title: 'リスタート',
              onTap: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
            _buildPauseMenuItem(
              icon: Icons.settings,
              title: '設定',
              onTap: () {
                Navigator.of(context).pop();
                // 設定画面遷移（必要に応じて実装）
              },
            ),
            _buildPauseMenuItem(
              icon: Icons.home,
              title: 'メニューに戻る',
              onTap: () async {
                Navigator.of(context).pop();
                final adService = ref.read(admobServiceProvider);
                await adService.showInterstitialAd();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ポーズメニューアイテム構築
  Widget _buildPauseMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E86C1)),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showResultDialog(bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        isSuccess: isSuccess,
        gameState: ref.read(gameStateProvider),
        onPlayAgain: () {
          Navigator.of(context).pop();
          ref.read(gameStateProvider.notifier).startNewGame();
          _showInfoMessage('新しいゲームを開始しました！');
        },
        onBackToMenu: () async {
          Navigator.of(context).pop();
          final adService = ref.read(admobServiceProvider);
          await adService.showInterstitialAd();
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});
