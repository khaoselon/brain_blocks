// lib/services/storage_service.dart - Hive対応完全版（安定性強化）
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

/// 🔥 修正：Hiveベースのストレージサービス（安定性強化版）
class StorageService {
  static bool _isInitialized = false;
  static Box<AppSettings>? _settingsBox;
  static Box? _gameStatsBox;

  /// ストレージサービス初期化
  static Future<void> init() async {
    try {
      print('💾 Hiveストレージサービス初期化開始');

      // Hive初期化
      await Hive.initFlutter();

      // アダプター登録（重複チェック）
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(AppSettingsAdapter());
        print('✅ AppSettingsAdapter登録完了');
      }

      // ボックス開く（エラーハンドリング強化）
      try {
        _settingsBox = await Hive.openBox<AppSettings>('settings');
        print('✅ settings box 開放完了');
      } catch (e) {
        print('❌ settings box 開放エラー: $e');
        // ボックス削除して再試行
        await Hive.deleteBoxFromDisk('settings');
        _settingsBox = await Hive.openBox<AppSettings>('settings');
        print('✅ settings box 再作成完了');
      }

      try {
        _gameStatsBox = await Hive.openBox('game_stats');
        print('✅ game_stats box 開放完了');
      } catch (e) {
        print('❌ game_stats box 開放エラー: $e');
        // ボックス削除して再試行
        await Hive.deleteBoxFromDisk('game_stats');
        _gameStatsBox = await Hive.openBox('game_stats');
        print('✅ game_stats box 再作成完了');
      }

      _isInitialized = true;
      print('✅ Hiveストレージサービス初期化完了');
    } catch (e) {
      print('❌ Hiveストレージサービス初期化エラー: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 初期化状態チェック
  static bool get isInitialized => _isInitialized;

  /// Settings Box取得
  static Box<AppSettings>? get settingsBox => _settingsBox;

  /// Game Stats Box取得
  static Box? get gameStatsBox => _gameStatsBox;

  /// 🔥 新機能：AppSettings専用メソッド
  static Future<bool> saveAppSettings(AppSettings settings) async {
    try {
      if (!_isInitialized || _settingsBox == null) {
        print('⚠️ ストレージ未初期化 - AppSettings保存スキップ');
        return false;
      }

      await _settingsBox!.put('app_settings', settings);
      print('💾 AppSettings保存完了');
      return true;
    } catch (e) {
      print('❌ AppSettings保存エラー: $e');
      return false;
    }
  }

  static AppSettings? getAppSettings() {
    try {
      if (!_isInitialized || _settingsBox == null) {
        print('⚠️ ストレージ未初期化 - AppSettings読み込みスキップ');
        return null;
      }

      final settings = _settingsBox!.get('app_settings');
      print('📖 AppSettings読み込み: ${settings != null ? "成功" : "null"}');
      return settings;
    } catch (e) {
      print('❌ AppSettings読み込みエラー: $e');
      return null;
    }
  }

  /// 🔥 新機能：安全な文字列保存
  static Future<bool> saveString(
    String boxName,
    String key,
    String value,
  ) async {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - 文字列保存スキップ: $boxName.$key');
        return false;
      }

      final box = await _getOrCreateBox(boxName);
      await box.put(key, value);
      print('💾 文字列保存完了: $boxName.$key');
      return true;
    } catch (e) {
      print('❌ 文字列保存エラー: $boxName.$key, $e');
      return false;
    }
  }

  /// 🔥 新機能：安全な文字列読み込み
  static String? getString(String boxName, String key, {String? defaultValue}) {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - 文字列読み込みスキップ: $boxName.$key');
        return defaultValue;
      }

      final box = Hive.box(boxName);
      final value = box.get(key, defaultValue: defaultValue) as String?;
      print('📖 文字列読み込み: $boxName.$key = ${value ?? "null"}');
      return value;
    } catch (e) {
      print('❌ 文字列読み込みエラー: $boxName.$key, $e');
      return defaultValue;
    }
  }

  /// 🔥 新機能：安全なint保存
  static Future<bool> saveInt(String boxName, String key, int value) async {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - int保存スキップ: $boxName.$key');
        return false;
      }

      final box = await _getOrCreateBox(boxName);
      await box.put(key, value);
      print('💾 int保存完了: $boxName.$key = $value');
      return true;
    } catch (e) {
      print('❌ int保存エラー: $boxName.$key, $e');
      return false;
    }
  }

  /// 🔥 新機能：安全なint読み込み
  static int getInt(String boxName, String key, {int defaultValue = 0}) {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - int読み込みスキップ: $boxName.$key');
        return defaultValue;
      }

      final box = Hive.box(boxName);
      final value = box.get(key, defaultValue: defaultValue) as int;
      print('📖 int読み込み: $boxName.$key = $value');
      return value;
    } catch (e) {
      print('❌ int読み込みエラー: $boxName.$key, $e');
      return defaultValue;
    }
  }

  /// 🔥 新機能：安全なbool保存
  static Future<bool> saveBool(String boxName, String key, bool value) async {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - bool保存スキップ: $boxName.$key');
        return false;
      }

      final box = await _getOrCreateBox(boxName);
      await box.put(key, value);
      print('💾 bool保存完了: $boxName.$key = $value');
      return true;
    } catch (e) {
      print('❌ bool保存エラー: $boxName.$key, $e');
      return false;
    }
  }

  /// 🔥 新機能：安全なbool読み込み
  static bool getBool(String boxName, String key, {bool defaultValue = false}) {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - bool読み込みスキップ: $boxName.$key');
        return defaultValue;
      }

      final box = Hive.box(boxName);
      final value = box.get(key, defaultValue: defaultValue) as bool;
      print('📖 bool読み込み: $boxName.$key = $value');
      return value;
    } catch (e) {
      print('❌ bool読み込みエラー: $boxName.$key, $e');
      return defaultValue;
    }
  }

  /// ボックス取得または作成
  static Future<Box> _getOrCreateBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      } else {
        return await Hive.openBox(boxName);
      }
    } catch (e) {
      print('❌ ボックス作成エラー: $boxName, $e');
      // エラー時は削除して再作成
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox(boxName);
    }
  }

  /// 🔥 新機能：キー削除
  static Future<bool> removeKey(String boxName, String key) async {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - キー削除スキップ: $boxName.$key');
        return false;
      }

      final box = await _getOrCreateBox(boxName);
      await box.delete(key);
      print('🗑️ キー削除完了: $boxName.$key');
      return true;
    } catch (e) {
      print('❌ キー削除エラー: $boxName.$key, $e');
      return false;
    }
  }

  /// 🔥 新機能：ボックス全クリア
  static Future<bool> clearBox(String boxName) async {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - ボックスクリアスキップ: $boxName');
        return false;
      }

      final box = await _getOrCreateBox(boxName);
      await box.clear();
      print('🗑️ ボックスクリア完了: $boxName');
      return true;
    } catch (e) {
      print('❌ ボックスクリアエラー: $boxName, $e');
      return false;
    }
  }

  /// 🔥 新機能：全設定リセット
  static Future<bool> resetAllSettings() async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.clear();
        print('🗑️ 全設定リセット完了');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 全設定リセットエラー: $e');
      return false;
    }
  }

  /// 🔥 新機能：ストレージ使用量デバッグ情報
  static void debugPrintStorageInfo() {
    try {
      if (!_isInitialized) {
        print('⚠️ ストレージ未初期化 - デバッグ情報取得不可');
        return;
      }

      print('=== Hiveストレージデバッグ情報 ===');

      if (_settingsBox != null) {
        print('Settings Box:');
        print('  キー数: ${_settingsBox!.length}');
        for (final key in _settingsBox!.keys) {
          print('  $key: ${_settingsBox!.get(key)}');
        }
      }

      if (_gameStatsBox != null) {
        print('Game Stats Box:');
        print('  キー数: ${_gameStatsBox!.length}');
        for (final key in _gameStatsBox!.keys) {
          print('  $key: ${_gameStatsBox!.get(key)}');
        }
      }

      print('============================');
    } catch (e) {
      print('❌ ストレージデバッグ情報取得エラー: $e');
    }
  }

  /// リソース解放
  static Future<void> close() async {
    try {
      print('🔒 Hiveストレージサービス終了開始');

      await _settingsBox?.close();
      await _gameStatsBox?.close();
      await Hive.close();

      _isInitialized = false;
      _settingsBox = null;
      _gameStatsBox = null;

      print('✅ Hiveストレージサービス終了完了');
    } catch (e) {
      print('❌ Hiveストレージサービス終了エラー: $e');
    }
  }
}
