// lib/utils/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // ゲーム設定
  static const int maxHintsPerGame = 3;
  static const int defaultTimeLimit = 300; // 5分
  static const int defaultMoveLimit = 100;

  // アニメーション時間
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 800);

  // 色定義 - 修正版
  static const Color primaryColor = Color(0xFF2E86C1);
  static const Color secondaryColor = Color(0xFF3498DB);
  static const Color successColor = Color(0xFF28B463);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);

  // サイズ定義
  static const double buttonHeight = 48.0;
  static const double cardRadius = 12.0;
  static const double defaultPadding = 16.0;

  // パフォーマンス設定
  static const int maxParticles = 100;
  static const double targetFPS = 60.0;
  static const int maxCacheSize = 50;

  // ネットワーク設定
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}
