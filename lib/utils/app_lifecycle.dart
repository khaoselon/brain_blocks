// lib/utils/app_lifecycle.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../models/game_state.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleHandler(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print('App Lifecycle State: $state');
    }

    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        // iOS 13+ のみ
        break;
    }
  }

  void _onAppPaused() {
    // ゲーム一時停止
    final gameState = ref.read(gameStateProvider);
    if (gameState.status == GameStatus.playing) {
      ref.read(gameStateProvider.notifier).pauseGame();
    }

    // BGM停止
    AudioService.instance.stopBGM();

    // 自動保存
    _autoSave();
  }

  void _onAppResumed() {
    // 必要に応じてゲーム再開促進
    // BGM再開（設定に応じて）
  }

  void _onAppInactive() {
    // タスクスイッチャー表示時など
  }

  void _onAppDetached() {
    // アプリ終了時のクリーンアップ
    _cleanup();
  }

  void _autoSave() {
    try {
      // ゲーム状態の自動保存
      // ローカルストレージに保存
    } catch (e) {
      if (kDebugMode) {
        print('自動保存エラー: $e');
      }
    }
  }

  void _cleanup() {
    // リソースの解放
    AdMobService.instance.dispose();
    AudioService.instance.dispose();
  }
}
