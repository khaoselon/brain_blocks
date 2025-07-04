// lib/main.dart - 最終修正版（SharedPreferences対応・安定性強化）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

// Services
import 'services/storage_service.dart';
import 'services/admob_service.dart';
import 'services/audio_service.dart';
import 'services/att_service.dart';
import 'services/firebase_service.dart';

// Providers
import 'providers/settings_providers.dart';

// Screens
import 'screens/home_screen.dart';

// Utils
import 'utils/error_handler.dart';
import 'utils/performance_monitor.dart';
import 'utils/app_lifecycle.dart';

// Localization
import 'l10n/app_localizations.dart';

void main() async {
  // 初期化
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 アプリ初期化開始');

  // 🔥 修正：エラーハンドリング設定（最優先）
  ErrorHandler.initialize();

  // 🔥 修正：Firebase初期化（エラーハンドリング強化）
  FirebaseService? firebaseService;
  try {
    firebaseService = FirebaseService.instance;
    await firebaseService.initialize();
    print('✅ Firebase初期化完了');
  } catch (e) {
    print('⚠️ Firebase初期化失敗（続行可能）: $e');
    // Firebase初期化失敗でもアプリは続行
  }

  // システムUI設定
  await _setupSystemUI();

  // その他サービス初期化
  await _initializeServices();

  print('✅ アプリ初期化完了');

  // アプリ起動
  runApp(const ProviderScope(child: BrainBlocksApp()));
}

Future<void> _setupSystemUI() async {
  try {
    // ステータスバー設定
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 画面向き設定
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    print('✅ システムUI設定完了');
  } catch (e) {
    print('❌ システムUI設定エラー: $e');
  }
}

Future<void> _initializeServices() async {
  try {
    // 🔥 修正：Hiveベースのストレージ初期化
    await StorageService.init();
    print('✅ Hiveストレージサービス初期化完了');

    print('✅ 全サービスの初期化が完了しました');
  } catch (e) {
    print('❌ サービス初期化エラー: $e');
    ErrorHandler.reportError('サービス初期化エラー', e);
    // エラーでもアプリは続行
  }
}

class BrainBlocksApp extends ConsumerStatefulWidget {
  const BrainBlocksApp({super.key});

  @override
  ConsumerState<BrainBlocksApp> createState() => _BrainBlocksAppState();
}

class _BrainBlocksAppState extends ConsumerState<BrainBlocksApp> {
  late AppLifecycleHandler _lifecycleHandler;
  FirebaseService? _firebaseService;

  @override
  void initState() {
    super.initState();

    _firebaseService = FirebaseService.instance;

    // 重要：サービス初期化の順序
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 1. 設定プロバイダーの初期化完了を待つ
        await _waitForSettingsInitialization();

        // 2. ATTサービス初期化（iOS のみ、AdMob より先）
        await ATTService.instance.initialize(ref);

        // 3. AdMob初期化（ATT状態を考慮）
        await AdMobService.instance.initialize(ref: ref);

        // 4. 音声サービス初期化
        await AudioService.instance.initialize(ref);

        // 5. パフォーマンス監視開始
        PerformanceMonitor.instance.startMonitoring();

        // 6. Firebase Analytics: アプリ起動（安全版）
        await _logAppOpen();

        // 7. Remote Configの値確認
        _checkRemoteConfigFlags();

        print('✅ 全サービス初期化完了');
      } catch (e) {
        print('❌ サービス初期化エラー: $e');
        ErrorHandler.reportError('ポストフレーム初期化エラー', e);
      }
    });

    // ライフサイクル監視
    _lifecycleHandler = AppLifecycleHandler(ref);
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
  }

  /// 🔥 新機能：設定プロバイダーの初期化完了を待つ
  Future<void> _waitForSettingsInitialization() async {
    const maxWaitTime = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    while (!ref.read(appSettingsProvider.notifier).isInitialized) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        print('⚠️ 設定初期化タイムアウト（続行）');
        break;
      }
      await Future.delayed(checkInterval);
    }

    print('✅ 設定プロバイダー初期化完了確認');
  }

  /// Firebase Analytics アプリ起動ログ（安全版）
  Future<void> _logAppOpen() async {
    if (_firebaseService == null || !_firebaseService!.isInitialized) {
      print('⚠️ Firebase未初期化 - アプリ起動ログスキップ');
      return;
    }

    try {
      await _firebaseService!.logEvent(
        name: 'app_open',
        parameters: {
          'app_version': '1.0.0',
          'platform': Theme.of(context).platform.name,
        },
      );
      print('✅ Firebase Analytics ログ送信成功');
    } catch (e) {
      print('❌ Firebase Analytics ログ送信エラー: $e');
    }
  }

  /// Remote Configフラグ確認
  void _checkRemoteConfigFlags() {
    if (_firebaseService == null || !_firebaseService!.isInitialized) {
      print('⚠️ Firebase未初期化 - Remote Config確認スキップ');
      return;
    }

    try {
      // メンテナンスモード確認
      if (_firebaseService!.isMaintenanceMode) {
        _showMaintenanceDialog();
        return;
      }

      // 強制アップデート確認
      if (_firebaseService!.isForceUpdateRequired) {
        _showForceUpdateDialog();
        return;
      }

      print('✅ Remote Config確認完了');
    } catch (e) {
      print('❌ Remote Config確認エラー: $e');
    }
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('メンテナンス中'),
        content: Text(
          _firebaseService?.maintenanceMessage ?? 'メンテナンス中です。しばらくお待ちください。',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('アップデートが必要です'),
        content: const Text('新しいバージョンが利用可能です。\nアップデートしてからご利用ください。'),
        actions: [
          TextButton(
            onPressed: () {
              // ストアへ誘導
              // launch('https://apps.apple.com/app/brain-blocks/...');
            },
            child: const Text('アップデート'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(_lifecycleHandler);
      PerformanceMonitor.instance.stopMonitoring();
      print('✅ BrainBlocksApp dispose完了');
    } catch (e) {
      print('❌ BrainBlocksApp dispose エラー: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'ブレインブロックス',
      debugShowCheckedModeBanner: false,

      // テーマ設定
      theme: _buildLightTheme(appSettings.colorBlindFriendly),
      darkTheme: _buildDarkTheme(appSettings.colorBlindFriendly),
      themeMode: appSettings.themeModeEnum,

      // Firebase Analytics Navigator Observer（安全版）
      navigatorObservers: _buildNavigatorObservers(),

      // 国際化設定
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
        Locale('ko', 'KR'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('es', 'ES'),
        Locale('pt', 'PT'),
        Locale('de', 'DE'),
        Locale('it', 'IT'),
      ],

      home: const HomeScreen(),
    );
  }

  /// Navigator Observers を安全に構築
  List<NavigatorObserver> _buildNavigatorObservers() {
    final observers = <NavigatorObserver>[];

    // Firebase Analytics Observer（初期化済みの場合のみ）
    if (_firebaseService?.isInitialized == true &&
        _firebaseService?.analytics != null) {
      try {
        observers.add(
          FirebaseAnalyticsObserver(analytics: _firebaseService!.analytics!),
        );
        print('✅ Firebase Analytics Observer追加');
      } catch (e) {
        print('❌ Firebase Analytics Observer追加エラー: $e');
      }
    }

    return observers;
  }

  ThemeData _buildLightTheme(bool colorBlindFriendly) {
    final colorScheme = colorBlindFriendly
        ? _getColorBlindFriendlyColorScheme(Brightness.light)
        : _getDefaultColorScheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'NotoSansJP',

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(bool colorBlindFriendly) {
    final colorScheme = colorBlindFriendly
        ? _getColorBlindFriendlyColorScheme(Brightness.dark)
        : _getDefaultColorScheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'NotoSansJP',

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ColorScheme _getDefaultColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF2E86C1),
        onPrimary: Colors.white,
        secondary: Color(0xFF3498DB),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF212529),
        background: Color(0xFFF8F9FA),
        onBackground: Color(0xFF212529),
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFF5DADE2),
        onPrimary: Color(0xFF1B2631),
        secondary: Color(0xFF85C1E9),
        onSecondary: Color(0xFF1B2631),
        surface: Color(0xFF2C3E50),
        onSurface: Color(0xFFECF0F1),
        background: Color(0xFF1B2631),
        onBackground: Color(0xFFECF0F1),
      );
    }
  }

  ColorScheme _getColorBlindFriendlyColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF0173B2),
        onPrimary: Colors.white,
        secondary: Color(0xFFDE8F05),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF212529),
        background: Color(0xFFF8F9FA),
        onBackground: Color(0xFF212529),
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFF56B4E9),
        onPrimary: Color(0xFF1B2631),
        secondary: Color(0xFFF0E442),
        onSecondary: Color(0xFF1B2631),
        surface: Color(0xFF2C3E50),
        onSurface: Color(0xFFECF0F1),
        background: Color(0xFF1B2631),
        onBackground: Color(0xFFECF0F1),
      );
    }
  }
}
