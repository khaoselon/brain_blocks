// lib/screens/game_screen.dart - ゲーム開始問題修正版
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
  // 🔥 新機能：ゲーム初期化状態管理
  bool _isGameInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 🔥 修正：より確実なゲーム開始処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  /// 🔥 新機能：ゲーム初期化処理
  Future<void> _initializeGame() async {
    if (_isInitializing) {
      print('⚠️ 既にゲーム初期化中です');
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      print('🎮 ゲーム画面初期化開始');

      // プロバイダーの状態を確認
      final gameState = ref.read(gameStateProvider);
      print('   現在のゲーム状態: ${gameState.status}');
      print('   現在のピース数: ${gameState.pieces.length}');

      // 設定を確認
      final gameSettings = ref.read(gameSettingsProvider);
      print(
        '   ゲーム設定: ${gameSettings.difficulty.name} (${gameSettings.difficulty.gridSize}×${gameSettings.difficulty.gridSize})',
      );

      // 🔥 重要：ゲーム状態に応じて適切に初期化
      if (gameState.status == GameStatus.setup || gameState.pieces.isEmpty) {
        print('🚀 新しいゲームを開始');
        ref.read(gameStateProvider.notifier).startNewGame();
      } else if (gameState.status == GameStatus.paused) {
        print('⏸️ 一時停止状態から再開');
        ref.read(gameStateProvider.notifier).resumeGame();
      } else if (gameState.status == GameStatus.playing) {
        print('✅ 既にゲームが進行中');
      } else {
        print('🔄 不明な状態からゲームを強制開始');
        ref.read(gameStateProvider.notifier).forceStartGame();
      }

      // 初期化完了まで少し待機
      await Future.delayed(const Duration(milliseconds: 500));

      // 初期化後の状態を確認
      final finalState = ref.read(gameStateProvider);
      print('   初期化後の状態: ${finalState.status}');
      print('   初期化後のピース数: ${finalState.pieces.length}');
      print(
        '   未配置ピース数: ${finalState.pieces.where((p) => !p.isPlaced).length}',
      );

      if (finalState.pieces.isNotEmpty &&
          finalState.status == GameStatus.playing) {
        setState(() {
          _isGameInitialized = true;
        });
        print('✅ ゲーム初期化成功');
        _showMessage('ゲームを開始しました！', Colors.green);
      } else {
        print('❌ ゲーム初期化失敗、再試行します');
        await _retryGameInitialization();
      }
    } catch (e, stackTrace) {
      print('❌ ゲーム初期化エラー: $e');
      print('スタックトレース: $stackTrace');
      await _retryGameInitialization();
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// 🔥 新機能：ゲーム初期化の再試行
  Future<void> _retryGameInitialization() async {
    print('🔄 ゲーム初期化を再試行');

    try {
      // 強制的に新しいゲームを開始
      ref.read(gameStateProvider.notifier).startNewGame();

      // 少し待機
      await Future.delayed(const Duration(milliseconds: 1000));

      final retryState = ref.read(gameStateProvider);
      print('   再試行後の状態: ${retryState.status}');
      print('   再試行後のピース数: ${retryState.pieces.length}');

      if (retryState.pieces.isNotEmpty) {
        setState(() {
          _isGameInitialized = true;
        });
        print('✅ ゲーム初期化再試行成功');
        _showMessage('ゲームを再開しました', Colors.blue);
      } else {
        print('❌ ゲーム初期化再試行も失敗');
        _showErrorMessage('ゲーム開始に失敗しました。リセットしてください。');
      }
    } catch (e) {
      print('❌ ゲーム初期化再試行エラー: $e');
      _showErrorMessage('ゲーム初期化に失敗しました');
    }
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

      // 🔥 新機能：ピース数の変化を監視
      if (previous != null && previous.pieces.length != current.pieces.length) {
        print(
          '📊 ピース数変化: ${previous.pieces.length} → ${current.pieces.length}',
        );
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
        child: _isInitializing
            ? _buildLoadingScreen() // 🔥 新機能：ローディング画面
            : !_isGameInitialized
            ? _buildErrorScreen() // 🔥 新機能：エラー画面
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
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

  /// 🔥 新機能：ローディング画面
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E86C1)),
          ),
          const SizedBox(height: 24),
          const Text(
            'ゲームを準備中...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E86C1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'パズルピースを生成しています',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 🔥 新機能：エラー画面
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'ゲーム開始に失敗しました',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'パズルの生成でエラーが発生しました。\n以下のボタンから再試行してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // 再試行ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isInitializing
                    ? null
                    : () {
                        setState(() {
                          _isGameInitialized = false;
                        });
                        _initializeGame();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E86C1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 強制リセットボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isInitializing
                    ? null
                    : () {
                        _forceResetGame();
                      },
                icon: const Icon(Icons.restart_alt),
                label: const Text('強制リセット'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // メニューに戻るボタン
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('メニューに戻る'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 新機能：強制リセット
  void _forceResetGame() async {
    try {
      print('🔧 強制リセット実行');

      setState(() {
        _isInitializing = true;
        _isGameInitialized = false;
      });

      // 確実にリセット
      ref.read(gameStateProvider.notifier).resetGame();

      // 少し待機
      await Future.delayed(const Duration(milliseconds: 1000));

      // 状態確認
      final resetState = ref.read(gameStateProvider);
      print('   リセット後の状態: ${resetState.status}');
      print('   リセット後のピース数: ${resetState.pieces.length}');

      if (resetState.pieces.isNotEmpty &&
          resetState.status == GameStatus.playing) {
        setState(() {
          _isGameInitialized = true;
        });
        _showMessage('ゲームを強制リセットしました', Colors.green);
      } else {
        _showErrorMessage('強制リセットに失敗しました');
      }
    } catch (e) {
      print('❌ 強制リセットエラー: $e');
      _showErrorMessage('強制リセットでエラーが発生しました');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
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

  /// 🔥 完全修正：リセット機能の改善
  void _resetGame() {
    if (_isDialogShowing) return; // ダイアログ表示中は無効

    setState(() {
      _isDialogShowing = true;
    });

    showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🔥 修正：バリア無効化
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Color(0xFF2E86C1)),
            SizedBox(width: 8),
            Text('ゲームリセット'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('現在の進行状況がリセットされ、\n新しいパズルが生成されます。'),
            SizedBox(height: 8),
            Text(
              'この操作は取り消せません。',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
            child: const Text('リセット実行'),
          ),
        ],
      ),
    ).then((confirmed) {
      setState(() {
        _isDialogShowing = false;
      });

      if (confirmed == true) {
        try {
          print('🔄 ユーザーがリセットを確認 - 実行開始');

          // 🔥 重要：resetGameメソッドを呼び出し
          ref.read(gameStateProvider.notifier).resetGame();

          // 🔥 修正：成功メッセージと触覚フィードバック
          HapticFeedback.mediumImpact();
          _showSuccessMessage('新しいパズルでゲームをリセットしました！');

          print('✅ ゲームリセット成功');
        } catch (e, stackTrace) {
          print('❌ ゲームリセットエラー: $e');
          print('スタックトレース: $stackTrace');

          // エラー時のフォールバック処理
          HapticFeedback.heavyImpact();
          _showErrorMessage('リセットに失敗しました。もう一度お試しください。');

          // 🔥 重要：エラー時は強制的に新しいゲームを開始
          try {
            Future.delayed(const Duration(milliseconds: 500), () {
              ref.read(gameStateProvider.notifier).startNewGame();
              _showInfoMessage('新しいゲームを開始しました');
            });
          } catch (fallbackError) {
            print('❌ フォールバック新ゲーム開始も失敗: $fallbackError');
            _showErrorMessage('ゲームの復旧に失敗しました。アプリを再起動してください。');
          }
        }
      }
    });
  }

  /// 🔥 修正：ポーズメニューの改善
  void _showPauseMenu() {
    if (_isDialogShowing || _isProcessingAd) return; // 重複防止

    try {
      // 🔥 重要：一時停止前にプレイ状態かチェック
      final currentState = ref.read(gameStateProvider);
      if (currentState.status == GameStatus.playing) {
        ref.read(gameStateProvider.notifier).pauseGame();
        print('✅ ゲーム一時停止（ポーズメニューから）');
      } else {
        print('⚠️ ゲームが既にプレイ状態ではありません: ${currentState.status}');
      }
    } catch (e) {
      print('❌ ゲーム一時停止エラー: $e');
      _showErrorMessage('一時停止に失敗しました');
      return; // エラー時はメニューを表示しない
    }

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // 戻るボタンで閉じる時の処理
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
                subtitle: '新しいパズルで開始', // 🔥 追加：説明
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

  /// 🔥 修正：ポーズから再開
  void _resumeGameFromPause() {
    try {
      final currentState = ref.read(gameStateProvider);
      if (currentState.status == GameStatus.paused) {
        ref.read(gameStateProvider.notifier).resumeGame();
        _showInfoMessage('ゲームを再開しました');
        print('✅ ゲーム再開');
      } else {
        print('⚠️ ゲームが一時停止状態ではありません: ${currentState.status}');
        // 強制的にプレイ状態にする
        if (currentState.status == GameStatus.setup) {
          ref.read(gameStateProvider.notifier).startNewGame();
          _showInfoMessage('新しいゲームを開始しました');
        }
      }
    } catch (e) {
      print('❌ ゲーム再開エラー: $e');
      _showErrorMessage('ゲーム再開に失敗しました');

      // エラー時は新しいゲームを開始
      try {
        ref.read(gameStateProvider.notifier).startNewGame();
        _showInfoMessage('新しいゲームを開始しました');
      } catch (fallbackError) {
        print('❌ フォールバック新ゲーム開始も失敗: $fallbackError');
      }
    }
  }

  /// 🔥 修正：ポーズからリセット
  void _resetGameFromPause() {
    try {
      // まず一時停止状態から再開
      final currentState = ref.read(gameStateProvider);
      if (currentState.status == GameStatus.paused) {
        ref.read(gameStateProvider.notifier).resumeGame();
      }
    } catch (e) {
      print('⚠️ 再開処理でエラー: $e');
    }

    // 少し遅延してからリセット処理
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _resetGame();
      }
    });
  }

  /// 🔥 修正：メニューに戻る処理の改善＊＊＊
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

  /// 🔥 修正：ポーズメニューアイテム構築（説明追加対応）
  Widget _buildPauseMenuItem({
    required IconData icon,
    required String title,
    String? subtitle, // 🔥 追加：説明文
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
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

  /// 🔥 修正：結果画面からもう一度プレイ
  void _playAgainFromResult() {
    try {
      ref.read(gameStateProvider.notifier).startNewGame();
      _showSuccessMessage('新しいパズルでゲームを開始しました！');
      print('✅ 新しいゲーム開始（結果画面から）');
    } catch (e) {
      print('❌ 新しいゲーム開始エラー: $e');
      _showErrorMessage('新しいゲーム開始に失敗しました');

      // エラー時はリセットを試行
      try {
        ref.read(gameStateProvider.notifier).resetGame();
        _showInfoMessage('ゲームをリセットしました');
      } catch (resetError) {
        print('❌ リセットも失敗: $resetError');
      }
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
