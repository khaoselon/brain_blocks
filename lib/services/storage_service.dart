// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // アダプター登録
    Hive.registerAdapter(AppSettingsAdapter());

    // ボックスを開く
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox('game_stats');
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
