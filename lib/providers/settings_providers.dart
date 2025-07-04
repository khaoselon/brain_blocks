// lib/providers/settings_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  late Box<AppSettings> _settingsBox;

  AppSettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox<AppSettings>('settings');
    final savedSettings = _settingsBox.get('app_settings');
    if (savedSettings != null) {
      state = savedSettings;
    }
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('app_settings', state);
  }

  void updateSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _saveSettings();
  }

  void updateHapticsEnabled(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
    _saveSettings();
  }

  void updateColorBlindFriendly(bool enabled) {
    state = state.copyWith(colorBlindFriendly: enabled);
    _saveSettings();
  }

  void updateDefaultDifficulty(String difficulty) {
    state = state.copyWith(defaultDifficulty: difficulty);
    _saveSettings();
  }

  void updateAdFree(bool adFree) {
    state = state.copyWith(adFree: adFree);
    _saveSettings();
  }

  void updatePersonalizedAds(bool enabled) {
    state = state.copyWith(personalizedAds: enabled);
    _saveSettings();
  }

  void updateThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    _saveSettings();
  }

  Future<void> resetAllData() async {
    state = AppSettings();
    await _saveSettings();
  }
}

