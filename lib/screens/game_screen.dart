// lib/screens/game_screen.dart - レイアウト改善版（ピーストレイを下部に配置）
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
            // 🔧 改善：レスポンシブレイアウト
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // 画面サイズに応じてレイアウトを調整
            if (isLandscape && screenWidth > 800) {
              // 大きな横画面：従来の横並びレイアウト
              return _buildLandscapeLayout(gameState, constraints);
            } else {
              // 縦画面・小さな横画面：新しい縦並びレイアウト
              return _buildPortraitLayout(gameState, constraints);
            }
          },
        ),
      ),
    );
  }

  /// 🎨 新しい縦並びレイアウト（ピーストレイ下部配置）
  Widget _buildPortraitLayout(GameState gameState, BoxConstraints constraints) {
    final screenHeight = constraints.maxHeight;
    final screenWidth = constraints.maxWidth;

    // レイアウト比率を計算
    final headerHeight = 80.0; // ゲームヘッダーの高さ
    final trayHeight = (screenHeight * 0.25).clamp(
      120.0,
      200.0,
    ); // ピーストレイの高さ（画面の25%、最小120px、最大200px）
    final boardHeight =
        screenHeight - headerHeight - trayHeight - 32; // 余白を考慮したゲーム盤面の高さ

    return Column(
      children: [
        // ゲームヘッダー
        SizedBox(
          height: headerHeight,
          child: GameHeaderWidget(
            gameState: gameState,
            onHintPressed: _useHint,
            onResetPressed: _resetGame,
          ),
        ),

        const SizedBox(height: 16),

        // メインゲーム盤面
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GameBoardWidget(
                gameState: gameState,
                hintPieceId: _hintPieceId,
                hintAnimation: _hintAnimationController,
                onPiecePlaced: _onPiecePlaced,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 新機能：ピーストレイを下部に配置
        Container(
          height: trayHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBottomPieceTray(gameState),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 🎨 横画面レイアウト（大画面用：従来通り）
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
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 🔥 新機能：下部ピーストレイ
  Widget _buildBottomPieceTray(GameState gameState) {
    final unplacedPieces = gameState.pieces.where((p) => !p.isPlaced).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2), // 上向きの影
          ),
        ],
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2E86C1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.extension, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ピース (${unplacedPieces.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (unplacedPieces.isNotEmpty)
                  Text(
                    '左右にスクロール',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // ピース一覧（横スクロール）
          Expanded(
            child: unplacedPieces.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 32,
                          color: Colors.green,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '全ピース配置完了！',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: unplacedPieces.map((piece) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: _buildBottomPieceItem(piece),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 🔥 新機能：下部ピースアイテム
  Widget _buildBottomPieceItem(PuzzlePiece piece) {
    const cellSize = 16.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: piece.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: piece.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ピースプレビュー
          Expanded(
            child: Draggable<String>(
              data: piece.id,
              dragAnchorStrategy: pointerDragAnchorStrategy,

              onDragStarted: () {
                print('🚀 下部トレイからドラッグ開始: ${piece.id}');
                HapticFeedback.lightImpact();
              },

              onDragEnd: (details) {
                print('🏁 下部トレイドラッグ終了: ${piece.id}');
              },

              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: _buildPiecePreview(piece, cellSize * 2),
                  ),
                ),
              ),

              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildPiecePreview(piece, cellSize),
              ),

              child: _buildPiecePreview(piece, cellSize),
            ),
          ),

          const SizedBox(height: 4),

          // 回転ボタン
          GestureDetector(
            onTap: () {
              _onPieceRotated(piece.id);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: piece.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rotate_right, size: 16, color: piece.color),
            ),
          ),
        ],
      ),
    );
  }

  /// ピースプレビュー作成
  Widget _buildPiecePreview(PuzzlePiece piece, double cellSize) {
    final rotatedCells = piece.getRotatedCells();
    if (rotatedCells.isEmpty) return const SizedBox.shrink();

    final minX = rotatedCells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final minY = rotatedCells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxX = rotatedCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = rotatedCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final width = (maxX - minX + 1) * cellSize;
    final height = (maxY - minY + 1) * cellSize;

    return Container(
      width: width.clamp(32.0, 80.0), // 最小・最大サイズを制限
      height: height.clamp(32.0, 80.0),
      child: CustomPaint(
        painter: _SimplePiecePainter(piece: piece, cellSize: cellSize),
      ),
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

  void _onPiecePlaced(String pieceId, PiecePosition position) {
    ref.read(gameStateProvider.notifier).placePiece(pieceId, position);
    HapticFeedback.lightImpact();
  }

  void _onPieceSelected(String pieceId) {
    // ピース選択時の処理
  }

  void _onPieceRotated(String pieceId) {
    ref.read(gameStateProvider.notifier).rotatePiece(pieceId);
    HapticFeedback.selectionClick();
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

/// シンプルなピースペインター
class _SimplePiecePainter extends CustomPainter {
  final PuzzlePiece piece;
  final double cellSize;

  const _SimplePiecePainter({required this.piece, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cells = piece.getRotatedCells();

    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );

      // 塗りつぶし
      paint
        ..color = piece.color
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, paint);

      // 境界線
      paint
        ..color = piece.color.withOpacity(0.8)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_SimplePiecePainter oldDelegate) {
    return oldDelegate.piece != piece || oldDelegate.cellSize != cellSize;
  }
}
