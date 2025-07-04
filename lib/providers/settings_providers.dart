// lib/providers/settings_providers.dart - Hive対応完全版（安定性強化）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  Box<AppSettings>? _settingsBox;
  bool _isInitialized = false;

  AppSettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  /// 🔥 修正：Hiveを使用した設定読み込み（安定性強化）
  Future<void> _loadSettings() async {
    try {
      print('📱 Hive設定読み込み開始');

      // StorageServiceの初期化を待つ
      int retryCount = 0;
      const maxRetries = 50; // 5秒間待機
      while (!StorageService.isInitialized && retryCount < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 100));
        retryCount++;
      }

      if (!StorageService.isInitialized) {
        print('⚠️ StorageService初期化タイムアウト - デフォルト設定使用');
        state = AppSettings();
        _isInitialized = true;
        return;
      }

      _settingsBox = StorageService.settingsBox;

      if (_settingsBox != null) {
        final savedSettings = _settingsBox!.get(_settingsKey);

        if (savedSettings != null) {
          print('✅ 保存済み設定発見');

          // 設定の妥当性チェック
          if (savedSettings.isValid()) {
            state = savedSettings;
            print('✅ Hive設定読み込み完了: $savedSettings');
          } else {
            print('⚠️ 不正な設定値を検出、修正して適用');
            state = savedSettings.fixInvalidValues();
            await _saveSettings(); // 修正した設定を保存
          }
        } else {
          print('📱 デフォルト設定を使用');
          state = AppSettings();
          await _saveSettings(); // デフォルト設定を保存
        }
      } else {
        print('❌ settingsBox が null - デフォルト設定使用');
        state = AppSettings();
      }

      _isInitialized = true;
      print('✅ Hive設定プロバイダー初期化完了');
    } catch (e, stackTrace) {
      print('❌ Hive設定読み込みエラー: $e');
      print('スタックトレース: $stackTrace');

      // エラー時はデフォルト設定を使用
      state = AppSettings();
      _isInitialized = true;

      // デフォルト設定を保存試行
      try {
        await _saveSettings();
      } catch (saveError) {
        print('❌ デフォルト設定保存エラー: $saveError');
      }
    }
  }

  /// 🔥 修正：Hiveを使用した設定保存（安定性強化）
  Future<void> _saveSettings() async {
    if (!_isInitialized) {
      print('⚠️ 設定プロバイダー未初期化 - 保存スキップ');
      return;
    }

    try {
      // StorageServiceの専用メソッドを使用
      final success = await StorageService.saveAppSettings(state);

      if (success) {
        print('✅ Hive設定保存完了');
      } else {
        print('❌ Hive設定保存失敗');
      }
    } catch (e) {
      print('❌ Hive設定保存エラー: $e');

      // エラー時は直接Boxへのアクセスを試行
      try {
        _settingsBox = StorageService.settingsBox;
        if (_settingsBox != null) {
          await _settingsBox!.put(_settingsKey, state);
          print('✅ Hive設定保存完了（フォールバック）');
        }
      } catch (fallbackError) {
        print('❌ フォールバック保存も失敗: $fallbackError');
      }
    }
  }

  /// 🔥 修正：設定更新メソッド群（エラーハンドリング強化）
  Future<void> updateSoundEnabled(bool enabled) async {
    try {
      state = state.copyWith(soundEnabled: enabled);
      await _saveSettings();
      print('🔊 サウンド設定更新: $enabled');
    } catch (e) {
      print('❌ サウンド設定更新エラー: $e');
    }
  }

  Future<void> updateHapticsEnabled(bool enabled) async {
    try {
      state = state.copyWith(hapticsEnabled: enabled);
      await _saveSettings();
      print('📳 ハプティクス設定更新: $enabled');
    } catch (e) {
      print('❌ ハプティクス設定更新エラー: $e');
    }
  }

  Future<void> updateColorBlindFriendly(bool enabled) async {
    try {
      state = state.copyWith(colorBlindFriendly: enabled);
      await _saveSettings();
      print('🎨 色覚バリアフリー設定更新: $enabled');
    } catch (e) {
      print('❌ 色覚バリアフリー設定更新エラー: $e');
    }
  }

  Future<void> updateDefaultDifficulty(String difficulty) async {
    try {
      // 妥当性チェック
      if (!['easy', 'medium', 'hard'].contains(difficulty)) {
        print('❌ 不正な難易度: $difficulty');
        return;
      }

      state = state.copyWith(defaultDifficulty: difficulty);
      await _saveSettings();
      print('🎯 デフォルト難易度更新: $difficulty');
    } catch (e) {
      print('❌ デフォルト難易度更新エラー: $e');
    }
  }

  Future<void> updateAdFree(bool adFree) async {
    try {
      state = state.copyWith(adFree: adFree);
      await _saveSettings();
      print('📺 広告除去設定更新: $adFree');
    } catch (e) {
      print('❌ 広告除去設定更新エラー: $e');
    }
  }

  Future<void> updatePersonalizedAds(bool enabled) async {
    try {
      state = state.copyWith(personalizedAds: enabled);
      await _saveSettings();
      print('🎯 パーソナライズ広告設定更新: $enabled');
    } catch (e) {
      print('❌ パーソナライズ広告設定更新エラー: $e');
    }
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    try {
      state = state.copyWith(themeMode: themeMode);
      await _saveSettings();
      print('🌙 テーマモード更新: ${themeMode.name}');
    } catch (e) {
      print('❌ テーマモード更新エラー: $e');
    }
  }

  /// 🔥 修正：全設定リセット（Hive対応強化版）
  Future<void> resetAllData() async {
    try {
      print('🗑️ 全設定リセット開始');

      // デフォルト設定に戻す
      state = AppSettings();

      // Hiveからも削除
      try {
        final success = await StorageService.resetAllSettings();
        if (success) {
          print('✅ Hive設定削除完了');
        }
      } catch (e) {
        print('❌ Hive設定削除エラー: $e');
        // 直接削除を試行
        try {
          _settingsBox = StorageService.settingsBox;
          if (_settingsBox != null) {
            await _settingsBox!.delete(_settingsKey);
            print('✅ Hive設定削除完了（フォールバック）');
          }
        } catch (fallbackError) {
          print('❌ フォールバック削除も失敗: $fallbackError');
        }
      }

      // デフォルト設定を保存
      await _saveSettings();

      print('✅ 全設定リセット完了');
    } catch (e) {
      print('❌ 全設定リセットエラー: $e');

      // エラー時でもデフォルト設定は適用
      state = AppSettings();
    }
  }

  /// 🔥 新機能：設定の手動同期
  Future<void> syncSettings() async {
    try {
      await _saveSettings();
      print('🔄 Hive設定同期完了');
    } catch (e) {
      print('❌ Hive設定同期エラー: $e');
    }
  }

  /// 🔥 新機能：設定の妥当性チェックと修正
  Future<void> validateAndFixSettings() async {
    try {
      if (!state.isValid()) {
        print('⚠️ 設定に不正な値を検出、修正中...');
        state = state.fixInvalidValues();
        await _saveSettings();
        print('✅ 設定修正完了');
      }
    } catch (e) {
      print('❌ 設定検証・修正エラー: $e');
    }
  }

  /// 🔥 新機能：強制再読み込み
  Future<void> forceReload() async {
    try {
      print('🔄 設定強制再読み込み開始');
      _isInitialized = false;
      await _loadSettings();
      print('✅ 設定強制再読み込み完了');
    } catch (e) {
      print('❌ 設定強制再読み込みエラー: $e');
    }
  }

  /// 初期化状態チェック
  bool get isInitialized => _isInitialized;

  /// 設定のデバッグ情報出力
  void debugPrintSettings() {
    print('=== 現在のHive設定 ===');
    print('サウンド: ${state.soundEnabled}');
    print('ハプティクス: ${state.hapticsEnabled}');
    print('色覚バリアフリー: ${state.colorBlindFriendly}');
    print('デフォルト難易度: ${state.defaultDifficulty}');
    print('広告除去: ${state.adFree}');
    print('パーソナライズ広告: ${state.personalizedAds}');
    print('テーマモード: ${state.themeModeEnum.name}');
    print('初期化状態: $_isInitialized');
    print('BoxNull: ${_settingsBox == null}');
    print('==================');
  }
}
