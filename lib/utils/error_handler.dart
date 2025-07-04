// lib/utils/error_handler.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ErrorHandler {
  static bool _isInitialized = false;
  static FirebaseService? _firebaseService;

  static void initialize({FirebaseService? firebaseService}) {
    if (_isInitialized) return;

    _firebaseService = firebaseService;

    // Flutterフレームワークエラーのキャッチ
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        _logError('Flutter Error', details.exception, details.stack);
      }
    };

    // 非同期エラーのキャッチ
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true;
    };

    _isInitialized = true;
  }

  static void _logError(String type, Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      developer.log(
        '$type: $error',
        name: 'Error',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // 本番環境ではFirebase Crashlyticsに送信
      _firebaseService?.reportError(
        message: '$type: $error',
        error: error,
        stackTrace: stackTrace,
        fatal: true,
      );
    }
  }

  /// 手動エラーレポート
  static void reportError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logError('Manual Report', error ?? message, stackTrace);
  }

  /// ユーザーフレンドリーなエラーダイアログ
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ネットワークエラーハンドリング
  static String getNetworkErrorMessage(Object error) {
    if (error.toString().contains('SocketException')) {
      return 'インターネット接続を確認してください';
    } else if (error.toString().contains('TimeoutException')) {
      return '接続がタイムアウトしました。しばらくしてから再試行してください';
    } else if (error.toString().contains('HttpException')) {
      return 'サーバーエラーが発生しました。しばらくしてから再試行してください';
    } else {
      return 'エラーが発生しました。アプリを再起動してください';
    }
  }
}
