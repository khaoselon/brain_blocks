// lib/screens/game_screen.dart - 不具合修正版
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

  // 🔥 修正：広告処理中フラグ
  bool _isProcessingAd = false;
  // 🔥 修正：ダイアログ表示中フラグ
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // ゲーム開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(gameStateProvider.notifier).startNewGame();
        print('✅ 新しいゲーム開始');
      } catch (e) {
        print('❌ ゲーム開始エラー: $e');
        _showErrorMessage('ゲーム開始に失敗しました');
      }
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
          IconButton(
            onPressed: _isDialogShowing
                ? null
                : _showPauseMenu, // 🔥 修正：ダイアログ表示中は無効
            icon: const Icon(Icons.pause),
          ),
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
                  onPieceRemoved: _onPieceRemoved, // 🔥 修正：ピース除去機能
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
                    onPieceRemoved: _onPieceRemoved, // 🔥 修正
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
        // 🔥 修正：少し遅延してからダイアログ表示
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDialogShowing) {
            _showResultDialog(true);
          }
        });
        break;
      case GameStatus.failed:
        // 🔥 修正：少し遅延してからダイアログ表示
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDialogShowing) {
            _showResultDialog(false);
          }
        });
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
    if (_isDialogShowing) return; // 🔥 修正：重複防止

    final attService = ref.read(attServiceProvider);
    if (attService.currentStatus == ATTStatus.notDetermined) {
      _showATTExplanationDialog();
    }
  }

  void _showATTExplanationDialog() {
    if (_isDialogShowing) return; // 🔥 修正：重複防止

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ATTExplanationDialog(
        onAccept: () {
          setState(() {
            _isDialogShowing = false;
          });
        },
        onDecline: () {
          setState(() {
            _isDialogShowing = false;
          });
        },
      ),
    ).then((_) {
      setState(() {
        _isDialogShowing = false;
      });
    });
  }

  /// ピース配置処理
  void _onPiecePlaced(String pieceId, PiecePosition position) {
    print('🎯 ピース配置コールバック: $pieceId at $position');

    try {
      ref.read(gameStateProvider.notifier).placePiece(pieceId, position);
      HapticFeedback.lightImpact();
      _showSuccessMessage('ピースを配置しました！');
    } catch (e) {
      print('❌ ピース配置エラー: $e');
      HapticFeedback.mediumImpact();
      _showErrorMessage('ピース配置に失敗しました');
    }
  }

  /// 🔥 修正：ピース除去処理
  void _onPieceRemoved(String pieceId) {
    print('🔄 ピース除去コールバック: $pieceId');

    try {
      ref.read(gameStateProvider.notifier).removePiece(pieceId);
      HapticFeedback.mediumImpact();
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
    try {
      ref.read(gameStateProvider.notifier).rotatePiece(pieceId);
      HapticFeedback.selectionClick();
      _showInfoMessage('ピースを回転しました');
    } catch (e) {
      print('❌ ピース回転エラー: $e');
      _showErrorMessage('ピース回転に失敗しました');
    }
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
    if (_isProcessingAd) return; // 🔥 修正：広告処理中は無効

    final gameState = ref.read(gameStateProvider);
    final unplacedPieces = gameState.pieces.where((p) => !p.isPlaced).toList();

    if (unplacedPieces.isNotEmpty) {
      setState(() {
        _isProcessingAd = true;
      });

      try {
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
      } catch (e) {
        print('❌ ヒント広告エラー: $e');
        _showErrorMessage('ヒント表示に失敗しました');
      } finally {
        setState(() {
          _isProcessingAd = false;
        });
      }
    } else {
      _showInfoMessage('配置可能なピースがありません');
    }
  }

  /// 🔥 修正：リセット機能の改善
  void _resetGame() {
    if (_isDialogShowing) return; // 🔥 修正：ダイアログ表示中は無効

    setState(() {
      _isDialogShowing = true;
    });

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Color(0xFF2E86C1)),
            SizedBox(width: 8),
            Text('ゲームリセット'),
          ],
        ),
        content: const Text('現在の進行状況がリセットされます。\nよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86C1),
              foregroundColor: Colors.white,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    ).then((confirmed) {
      setState(() {
        _isDialogShowing = false;
      });

      if (confirmed == true) {
        try {
          // 🔥 修正：状態をリセットしてから新しいゲーム開始
          ref.read(gameStateProvider.notifier).resetGame();
          _showInfoMessage('ゲームをリセットしました');
          print('✅ ゲームリセット成功');
        } catch (e) {
          print('❌ ゲームリセットエラー: $e');
          _showErrorMessage('ゲームリセットに失敗しました');
        }
      }
    });
  }

  /// 🔥 修正：ポーズメニューの改善
  void _showPauseMenu() {
    if (_isDialogShowing || _isProcessingAd) return; // 🔥 修正：重複防止

    try {
      ref.read(gameStateProvider.notifier).pauseGame();
      print('✅ ゲーム一時停止');
    } catch (e) {
      print('❌ ゲーム一時停止エラー: $e');
    }

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // 🔥 修正：戻るボタンで閉じる時の処理
          _resumeGameFromPause();
          return true;
        },
        child: AlertDialog(
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
                  _resumeGameFromPause();
                },
              ),
              _buildPauseMenuItem(
                icon: Icons.refresh,
                title: 'リスタート',
                onTap: () {
                  Navigator.of(context).pop();
                  _resetGameFromPause();
                },
              ),
              _buildPauseMenuItem(
                icon: Icons.settings,
                title: '設定',
                onTap: () {
                  Navigator.of(context).pop();
                  _resumeGameFromPause();
                  _showInfoMessage('設定機能は準備中です');
                },
              ),
              _buildPauseMenuItem(
                icon: Icons.home,
                title: 'メニューに戻る',
                onTap: () {
                  Navigator.of(context).pop();
                  _backToMenuFromPause();
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      setState(() {
        _isDialogShowing = false;
      });
    });
  }

  /// 🔥 新機能：ポーズから再開
  void _resumeGameFromPause() {
    try {
      ref.read(gameStateProvider.notifier).resumeGame();
      _showInfoMessage('ゲームを再開しました');
      print('✅ ゲーム再開');
    } catch (e) {
      print('❌ ゲーム再開エラー: $e');
      _showErrorMessage('ゲーム再開に失敗しました');
    }
  }

  /// 🔥 新機能：ポーズからリセット
  void _resetGameFromPause() {
    // まず再開してからリセット処理
    try {
      ref.read(gameStateProvider.notifier).resumeGame();
    } catch (e) {
      print('⚠️ 再開処理でエラー: $e');
    }

    // リセット処理
    Future.delayed(const Duration(milliseconds: 100), () {
      _resetGame();
    });
  }

  /// 🔥 修正：メニューに戻る処理の改善
  void _backToMenuFromPause() async {
    if (_isProcessingAd) return; // 🔥 修正：広告処理中は無効

    setState(() {
      _isProcessingAd = true;
    });

    try {
      print('🏠 メニューに戻る処理開始');

      // 先にゲームを再開状態にする
      ref.read(gameStateProvider.notifier).resumeGame();

      // 広告表示
      final adService = ref.read(admobServiceProvider);
      await adService.showInterstitialAd();

      print('✅ 広告表示完了、画面遷移開始');

      // 画面遷移
      if (mounted) {
        Navigator.of(context).pop();
        print('✅ メニューに戻る処理完了');
      }
    } catch (e) {
      print('❌ メニューに戻るエラー: $e');
      if (mounted) {
        _showErrorMessage('メニューに戻る処理でエラーが発生しました');
        // エラー時でも画面遷移
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _isProcessingAd = false;
      });
    }
  }

  /// ポーズメニューアイテム構築
  Widget _buildPauseMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2E86C1)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 修正：結果ダイアログ表示の改善
  void _showResultDialog(bool isSuccess) {
    if (_isDialogShowing) return; // 🔥 修正：重複防止

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        isSuccess: isSuccess,
        gameState: ref.read(gameStateProvider),
        onPlayAgain: () {
          Navigator.of(context).pop();
          _playAgainFromResult();
        },
        onBackToMenu: () {
          Navigator.of(context).pop();
          _backToMenuFromResult();
        },
      ),
    ).then((_) {
      setState(() {
        _isDialogShowing = false;
      });
    });
  }

  /// 🔥 新機能：結果画面からもう一度プレイ
  void _playAgainFromResult() {
    try {
      ref.read(gameStateProvider.notifier).startNewGame();
      _showInfoMessage('新しいゲームを開始しました！');
      print('✅ 新しいゲーム開始（結果画面から）');
    } catch (e) {
      print('❌ 新しいゲーム開始エラー: $e');
      _showErrorMessage('新しいゲーム開始に失敗しました');
    }
  }

  /// 🔥 新機能：結果画面からメニューに戻る
  void _backToMenuFromResult() async {
    if (_isProcessingAd) return;

    setState(() {
      _isProcessingAd = true;
    });

    try {
      print('🏠 結果画面からメニューに戻る');

      final adService = ref.read(admobServiceProvider);
      await adService.showInterstitialAd();

      if (mounted) {
        Navigator.of(context).pop();
        print('✅ 結果画面からメニューに戻る完了');
      }
    } catch (e) {
      print('❌ 結果画面からメニューに戻るエラー: $e');
      if (mounted) {
        _showErrorMessage('メニューに戻る処理でエラーが発生しました');
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _isProcessingAd = false;
      });
    }
  }
}

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});
