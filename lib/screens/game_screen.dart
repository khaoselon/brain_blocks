// lib/screens/game_screen.dart - ドラッグ&ドロップ対応版
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
            // 🔧 改善：画面サイズに応じたレイアウト選択
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // 大きな横画面の場合は従来レイアウト、それ以外は新レイアウト
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

  /// 🎨 新しい縦並びレイアウト（メイン）
  Widget _buildPortraitLayout(GameState gameState, BoxConstraints constraints) {
    final screenHeight = constraints.maxHeight;

    // レイアウト比率を動的計算
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

        // 🔥 改善：メインゲーム盤面（最大化）
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0, // 正方形を保持
                child: GameBoardWidget(
                  gameState: gameState,
                  hintPieceId: _hintPieceId,
                  hintAnimation: _hintAnimationController,
                  onPiecePlaced: _onPiecePlaced,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 🔥 改善：下部ピーストレイ（横スクロール）
        Container(
          height: trayHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PieceTrayWidget(
            pieces: gameState.pieces,
            onPieceSelected: _onPieceSelected,
            onPieceRotated: _onPieceRotated,
            isHorizontal: true, // 🔥 重要：横向きレイアウト
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 🎨 横画面レイアウト（大画面用）
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
                  isHorizontal: false, // 縦向きレイアウト
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // 以下、既存のメソッドは変更なし
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

  /// 🔧 改善：ピース配置処理
  void _onPiecePlaced(String pieceId, PiecePosition position) {
    print('🎯 ピース配置コールバック: $pieceId at $position');

    try {
      ref.read(gameStateProvider.notifier).placePiece(pieceId, position);
      HapticFeedback.lightImpact();

      // 配置成功のフィードバック
      _showPlacementSuccess();
    } catch (e) {
      print('❌ ピース配置エラー: $e');
      HapticFeedback.mediumImpact();
    }
  }

  void _onPieceSelected(String pieceId) {
    // ピース選択時の処理（必要に応じて実装）
    print('🎯 ピース選択: $pieceId');
  }

  void _onPieceRotated(String pieceId) {
    ref.read(gameStateProvider.notifier).rotatePiece(pieceId);
    HapticFeedback.selectionClick();

    // 回転フィードバック
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ピースを回転しました'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: const Color(0xFF2E86C1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 200, left: 20, right: 20),
      ),
    );
  }

  /// 🎉 配置成功時のフィードバック
  void _showPlacementSuccess() {
    // 軽微な成功フィードバック（オプション）
    // 必要に応じて実装
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
      }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセット'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(gameStateProvider.notifier).resetGame();
      }
    });
  }

  void _showPauseMenu() {
    ref.read(gameStateProvider.notifier).pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('一時停止'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('ゲーム再開'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(gameStateProvider.notifier).resumeGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('リスタート'),
              onTap: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('メニューに戻る'),
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
