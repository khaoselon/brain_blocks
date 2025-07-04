// lib/models/app_settings.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Hive生成が必要な場合のpart文（コメントアウト）
part 'app_settings.g.dart';

// 一時的にHiveアノテーションをコメントアウトして、通常のクラスとして定義
@HiveType(typeId: 0)
class AppSettings {
  // @HiveField(0)
  bool soundEnabled;

  // @HiveField(1)
  bool hapticsEnabled;

  // @HiveField(2)
  bool colorBlindFriendly;

  // @HiveField(3)
  String defaultDifficulty;

  // @HiveField(4)
  bool adFree;

  // @HiveField(5)
  bool personalizedAds;

  // @HiveField(6)
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

  // JSON変換メソッド（Hiveの代替）
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
    return AppSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      hapticsEnabled: json['hapticsEnabled'] ?? true,
      colorBlindFriendly: json['colorBlindFriendly'] ?? false,
      defaultDifficulty: json['defaultDifficulty'] ?? 'easy',
      adFree: json['adFree'] ?? false,
      personalizedAds: json['personalizedAds'] ?? true,
      themeMode: json['themeMode'] ?? 0,
    );
  }
}
