// lib/services/firebase_service.dart - 安全性強化版
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/error_handler.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  // nullable に変更して初期化失敗時の安全性を確保
  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  FirebaseRemoteConfig? _remoteConfig;
  FirebasePerformance? _performance;

  bool _isInitialized = false;

  // safe getters - 初期化されていない場合はnullを返す
  FirebaseAnalytics? get analytics => _analytics;
  FirebaseCrashlytics? get crashlytics => _crashlytics;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;
  FirebasePerformance? get performance => _performance;

  bool get isInitialized => _isInitialized;

  /// 🔥 修正：Firebase初期化（安全性強化）
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Firebase既に初期化済み');
      return;
    }

    try {
      print('🔥 Firebase初期化開始');

      // Firebase Core初期化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase Core初期化完了');

      // 各サービス初期化（個別のtry-catch）
      await _initializeAnalytics();
      await _initializeCrashlytics();
      await _initializeRemoteConfig();
      await _initializePerformance();

      _isInitialized = true;
      print('✅ Firebase初期化完了');
    } catch (e, stackTrace) {
      print('❌ Firebase初期化エラー: $e');
      print('スタックトレース: $stackTrace');

      // 初期化失敗時はnullオブジェクトを設定
      _initializeFallbackServices();

      // 🔥 重要：Firebase初期化失敗はアプリクラッシュさせない
      // _isInitializedはfalseのままにして、後続処理で安全に動作させる
      print('⚠️ Firebase初期化失敗 - フォールバックモードで継続');
    }
  }

  /// フォールバック：Firebase初期化失敗時の処理
  void _initializeFallbackServices() {
    // 初期化失敗時は全てnullのまま
    _analytics = null;
    _crashlytics = null;
    _remoteConfig = null;
    _performance = null;
    _isInitialized = false; // 🔥 修正：falseのまま

    print('⚠️ Firebase初期化失敗 - フォールバックモードで動作');
  }

  /// Analytics初期化
  Future<void> _initializeAnalytics() async {
    try {
      _analytics = FirebaseAnalytics.instance;

      // デフォルト設定
      await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);

      // ユーザープロパティ設定
      await _analytics!.setUserProperty(name: 'app_version', value: '1.0.0');

      print('✅ Firebase Analytics初期化完了');
    } catch (e) {
      print('❌ Firebase Analytics初期化エラー: $e');
      _analytics = null;
    }
  }

  /// Crashlytics初期化
  Future<void> _initializeCrashlytics() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // デバッグ時は無効
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Flutter エラーをCrashlyticsに送信
      if (!kDebugMode) {
        FlutterError.onError = (FlutterErrorDetails details) {
          _crashlytics?.recordFlutterFatalError(details);
        };

        // 非同期エラーをキャッチ
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics?.recordError(error, stack, fatal: true);
          return true;
        };
      }

      print('✅ Firebase Crashlytics初期化完了');
    } catch (e) {
      print('❌ Firebase Crashlytics初期化エラー: $e');
      _crashlytics = null;
    }
  }

  /// Remote Config初期化
  Future<void> _initializeRemoteConfig() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // デフォルト値設定
      await _remoteConfig!.setDefaults({
        'feature_daily_challenge_enabled': false,
        'feature_online_ranking_enabled': false,
        'max_hints_per_game': 3,
        'ad_interstitial_frequency': 3, // ゲーム3回に1回
        'tutorial_skip_enabled': true,
        'difficulty_unlock_progressive': true,
        'social_sharing_enabled': true,
        'maintenance_mode': false,
        'maintenance_message': 'メンテナンス中です。しばらくお待ちください。',
        'force_update_required': false,
        'min_supported_version': '1.0.0',
        'new_feature_announcement': '',
      });

      // 設定値取得頻度
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration(
            hours: kDebugMode ? 0 : 1, // デバッグ時は即座、本番は1時間
          ),
        ),
      );

      // 初回fetch
      try {
        await _remoteConfig!.fetchAndActivate();
        print('✅ Remote Config値取得完了');
        if (kDebugMode) {
          _logRemoteConfigValues();
        }
      } catch (e) {
        print('❌ Remote Config取得エラー: $e');
      }

      print('✅ Firebase Remote Config初期化完了');
    } catch (e) {
      print('❌ Firebase Remote Config初期化エラー: $e');
      _remoteConfig = null;
    }
  }

  /// Performance Monitoring初期化
  Future<void> _initializePerformance() async {
    try {
      _performance = FirebasePerformance.instance;

      // データ収集設定
      await _performance!.setPerformanceCollectionEnabled(!kDebugMode);

      print('✅ Firebase Performance初期化完了');
    } catch (e) {
      print('❌ Firebase Performance初期化エラー: $e');
      _performance = null;
    }
  }

  /// 🔥 修正：アナリティクスイベント送信（完全安全版）
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) {
      print('⚠️ Analytics未初期化 - イベント送信スキップ: $name');
      return;
    }

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      if (kDebugMode) print('✅ Analytics event送信: $name');
    } catch (e) {
      print('❌ Analytics event送信エラー: $e');
    }
  }

  /// ゲーム関連イベント
  Future<void> logGameStart({
    required String difficulty,
    required String gameMode,
  }) async {
    await logEvent(
      name: 'game_start',
      parameters: {'difficulty': difficulty, 'game_mode': gameMode},
    );
  }

  Future<void> logGameComplete({
    required String difficulty,
    required int moves,
    required int timeSeconds,
    required int hintsUsed,
    required bool isSuccess,
  }) async {
    await logEvent(
      name: 'game_complete',
      parameters: {
        'difficulty': difficulty,
        'moves': moves,
        'time_seconds': timeSeconds,
        'hints_used': hintsUsed,
        'success': isSuccess,
      },
    );
  }

  Future<void> logAdImpression({
    required String adType,
    required String placement,
  }) async {
    await logEvent(
      name: 'ad_impression',
      parameters: {'ad_type': adType, 'placement': placement},
    );
  }

  Future<void> logPurchase({
    required String itemId,
    required double value,
    required String currency,
  }) async {
    await logEvent(
      name: 'purchase',
      parameters: {'item_id': itemId, 'value': value, 'currency': currency},
    );
  }

  /// 🔥 修正：カスタムクラッシュレポート（完全安全版）
  Future<void> reportError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) async {
    if (!_isInitialized || _crashlytics == null) {
      print('⚠️ Crashlytics未初期化 - エラー報告スキップ: $message');
      return;
    }

    try {
      await _crashlytics!.recordError(
        error ?? message,
        stackTrace,
        fatal: fatal,
        information: [message],
      );
      if (kDebugMode) print('✅ Crashlytics報告: $message');
    } catch (e) {
      print('❌ Crashlytics報告エラー: $e');
    }
  }

  /// 🔥 修正：ユーザー情報設定（完全安全版）
  Future<void> setUserId(String userId) async {
    try {
      if (_analytics != null) {
        await _analytics!.setUserId(id: userId);
      }
      if (_crashlytics != null) {
        await _crashlytics!.setUserIdentifier(userId);
      }
      if (kDebugMode) print('✅ ユーザーID設定: $userId');
    } catch (e) {
      print('❌ ユーザーID設定エラー: $e');
    }
  }

  /// 🔥 修正：パフォーマンストレース開始（完全安全版）
  Trace? startTrace(String name) {
    if (!_isInitialized || _performance == null) {
      print('⚠️ Performance未初期化 - トレース開始スキップ: $name');
      return null;
    }

    try {
      final trace = _performance!.newTrace(name);
      if (kDebugMode) print('✅ パフォーマンストレース開始: $name');
      return trace;
    } catch (e) {
      print('❌ パフォーマンストレース開始エラー: $e');
      return null;
    }
  }

  /// Remote Config値取得ヘルパー（安全版）
  bool getBoolConfig(String key) {
    if (!_isInitialized || _remoteConfig == null) {
      // デフォルト値を返す
      return _getDefaultBoolValue(key);
    }
    try {
      return _remoteConfig!.getBool(key);
    } catch (e) {
      print('❌ RemoteConfig bool取得エラー: $e');
      return _getDefaultBoolValue(key);
    }
  }

  int getIntConfig(String key) {
    if (!_isInitialized || _remoteConfig == null) {
      return _getDefaultIntValue(key);
    }
    try {
      return _remoteConfig!.getInt(key);
    } catch (e) {
      print('❌ RemoteConfig int取得エラー: $e');
      return _getDefaultIntValue(key);
    }
  }

  String getStringConfig(String key) {
    if (!_isInitialized || _remoteConfig == null) {
      return _getDefaultStringValue(key);
    }
    try {
      return _remoteConfig!.getString(key);
    } catch (e) {
      print('❌ RemoteConfig string取得エラー: $e');
      return _getDefaultStringValue(key);
    }
  }

  /// デフォルト値設定
  bool _getDefaultBoolValue(String key) {
    switch (key) {
      case 'feature_daily_challenge_enabled':
      case 'feature_online_ranking_enabled':
      case 'maintenance_mode':
      case 'force_update_required':
        return false;
      case 'tutorial_skip_enabled':
      case 'difficulty_unlock_progressive':
      case 'social_sharing_enabled':
        return true;
      default:
        return false;
    }
  }

  int _getDefaultIntValue(String key) {
    switch (key) {
      case 'max_hints_per_game':
        return 3;
      case 'ad_interstitial_frequency':
        return 3;
      default:
        return 0;
    }
  }

  String _getDefaultStringValue(String key) {
    switch (key) {
      case 'maintenance_message':
        return 'メンテナンス中です。しばらくお待ちください。';
      case 'min_supported_version':
        return '1.0.0';
      case 'new_feature_announcement':
        return '';
      default:
        return '';
    }
  }

  /// デバッグ用：Remote Config値出力
  void _logRemoteConfigValues() {
    if (!kDebugMode || !_isInitialized || _remoteConfig == null) return;

    final keys = [
      'feature_daily_challenge_enabled',
      'feature_online_ranking_enabled',
      'max_hints_per_game',
      'ad_interstitial_frequency',
      'maintenance_mode',
      'force_update_required',
    ];

    print('=== Remote Config Values ===');
    for (final key in keys) {
      try {
        final value = _remoteConfig!.getValue(key);
        print('$key: ${value.asString()}');
      } catch (e) {
        print('$key: エラー($e)');
      }
    }
    print('===========================');
  }

  /// メンテナンスモードチェック
  bool get isMaintenanceMode => getBoolConfig('maintenance_mode');
  String get maintenanceMessage => getStringConfig('maintenance_message');

  /// 強制アップデートチェック
  bool get isForceUpdateRequired => getBoolConfig('force_update_required');
  String get minSupportedVersion => getStringConfig('min_supported_version');

  /// 機能フラグ
  bool get isDailyChallengeEnabled =>
      getBoolConfig('feature_daily_challenge_enabled');
  bool get isOnlineRankingEnabled =>
      getBoolConfig('feature_online_ranking_enabled');
  int get maxHintsPerGame => getIntConfig('max_hints_per_game');
  int get adInterstitialFrequency => getIntConfig('ad_interstitial_frequency');
}

// Firebaseサービスプロバイダー
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});
