// lib/models/app_settings.dart - Hive対応完全版（メソッド完備）
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Hive生成が必要な場合のpart文
part 'app_settings.g.dart';

// 🔥 修正：Hiveアノテーション復活（安定性は保持）
@HiveType(typeId: 0)
class AppSettings {
  @HiveField(0)
  bool soundEnabled;

  @HiveField(1)
  bool hapticsEnabled;

  @HiveField(2)
  bool colorBlindFriendly;

  @HiveField(3)
  String defaultDifficulty;

  @HiveField(4)
  bool adFree;

  @HiveField(5)
  bool personalizedAds;

  @HiveField(6)
  int themeMode; // ThemeMode.index

  AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.colorBlindFriendly = false,
    this.defaultDifficulty = 'easy',
    this.adFree = false,
    this.personalizedAds = true,
    this.themeMode = 0, // ThemeMode.system
  });

  ThemeMode get themeModeEnum => ThemeMode.values[themeMode];
  set themeModeEnum(ThemeMode mode) => themeMode = mode.index;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? colorBlindFriendly,
    String? defaultDifficulty,
    bool? adFree,
    bool? personalizedAds,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      colorBlindFriendly: colorBlindFriendly ?? this.colorBlindFriendly,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      adFree: adFree ?? this.adFree,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      themeMode: themeMode?.index ?? this.themeMode,
    );
  }

  // 🔥 修正：JSON変換メソッド（Hiveの代替として使用）
  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'colorBlindFriendly': colorBlindFriendly,
      'defaultDifficulty': defaultDifficulty,
      'adFree': adFree,
      'personalizedAds': personalizedAds,
      'themeMode': themeMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    try {
      return AppSettings(
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        colorBlindFriendly: json['colorBlindFriendly'] as bool? ?? false,
        defaultDifficulty: json['defaultDifficulty'] as String? ?? 'easy',
        adFree: json['adFree'] as bool? ?? false,
        personalizedAds: json['personalizedAds'] as bool? ?? true,
        themeMode: json['themeMode'] as int? ?? 0,
      );
    } catch (e) {
      print('❌ AppSettings.fromJson エラー: $e');
      // エラー時はデフォルト値を返す
      return AppSettings();
    }
  }

  /// 🔥 新機能：設定の妥当性チェック
  bool isValid() {
    try {
      // 基本的な妥当性チェック
      if (themeMode < 0 || themeMode >= ThemeMode.values.length) {
        return false;
      }

      if (!['easy', 'medium', 'hard'].contains(defaultDifficulty)) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ 設定妥当性チェックエラー: $e');
      return false;
    }
  }

  /// 🔥 新機能：設定をデフォルト値で修正
  AppSettings fixInvalidValues() {
    return AppSettings(
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
      colorBlindFriendly: colorBlindFriendly,
      defaultDifficulty: ['easy', 'medium', 'hard'].contains(defaultDifficulty)
          ? defaultDifficulty
          : 'easy',
      adFree: adFree,
      personalizedAds: personalizedAds,
      themeMode: (themeMode >= 0 && themeMode < ThemeMode.values.length)
          ? themeMode
          : 0,
    );
  }

  @override
  String toString() {
    return 'AppSettings(soundEnabled: $soundEnabled, hapticsEnabled: $hapticsEnabled, '
        'colorBlindFriendly: $colorBlindFriendly, defaultDifficulty: $defaultDifficulty, '
        'adFree: $adFree, personalizedAds: $personalizedAds, themeMode: $themeMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.soundEnabled == soundEnabled &&
        other.hapticsEnabled == hapticsEnabled &&
        other.colorBlindFriendly == colorBlindFriendly &&
        other.defaultDifficulty == defaultDifficulty &&
        other.adFree == adFree &&
        other.personalizedAds == personalizedAds &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      soundEnabled,
      hapticsEnabled,
      colorBlindFriendly,
      defaultDifficulty,
      adFree,
      personalizedAds,
      themeMode,
    );
  }
}
