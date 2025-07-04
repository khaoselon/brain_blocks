// lib/screens/game_screen.dart - ATT統合版
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
        child: Column(
          children: [
            // ゲームヘッダー（タイマー、手数など）
            GameHeaderWidget(
              gameState: gameState,
              onHintPressed: _useHint,
              onResetPressed: _resetGame,
            ),

            const SizedBox(height: 16),

            // メインゲーム領域
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

                  // ピーストレイ
                  Expanded(
                    flex: 2,
                    child: PieceTrayWidget(
                      pieces: gameState.pieces,
                      onPieceSelected: _onPieceSelected,
                      onPieceRotated: _onPieceRotated,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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

  /// ゲーム完了時の処理（ATT重要ポイント）
  void _onGameCompleted() {
    // 初回ゲーム完了の場合、ATTダイアログ表示のベストタイミング
    if (!_hasCompletedFirstGame) {
      _hasCompletedFirstGame = true;

      // 少し遅延してからATTダイアログを表示
      Future.delayed(const Duration(seconds: 2), () {
        _showATTDialogIfNeeded();
      });
    }
  }

  /// ATTダイアログ表示判定
  void _showATTDialogIfNeeded() {
    final attService = ref.read(attServiceProvider);

    // iOS でATT未決定の場合のみ表示
    if (attService.currentStatus == ATTStatus.notDetermined) {
      _showATTExplanationDialog();
    }
  }

  /// ATT説明ダイアログ表示
  void _showATTExplanationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ユーザーが明示的に選択するまで閉じない
      builder: (context) => ATTExplanationDialog(
        onAccept: () {
          // ユーザーが理解した場合の処理
        },
        onDecline: () {
          // ユーザーが拒否した場合の処理
        },
      ),
    );
  }

  void _onPiecePlaced(String pieceId, PiecePosition position) {
    ref.read(gameStateProvider.notifier).placePiece(pieceId, position);
    HapticFeedback.lightImpact();
  }

  void _onPieceSelected(String pieceId) {
    // ピース選択時の処理（ハイライトなど）
  }

  void _onPieceRotated(String pieceId) {
    ref.read(gameStateProvider.notifier).rotatePiece(pieceId);
    HapticFeedback.selectionClick();
  }

  void _useHint() async {
    final gameState = ref.read(gameStateProvider);
    final unplacedPieces = gameState.pieces.where((p) => !p.isPlaced).toList();

    if (unplacedPieces.isNotEmpty) {
      // リワード広告表示（ATT考慮済み）
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
                // 設定画面への遷移
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('メニューに戻る'),
              onTap: () async {
                Navigator.of(context).pop();

                // インタースティシャル広告表示（ATT考慮済み）
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

          // インタースティシャル広告表示（ATT考慮済み）
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
