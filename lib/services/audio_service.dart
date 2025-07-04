// lib/services/audio_service.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';

enum SoundEffect { tap, place, rotate, success, failure, hint, button }

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  bool _isInitialized = false;
  late WidgetRef _ref;

  /// 音声サービス初期化
  Future<void> initialize(WidgetRef ref) async {
    _ref = ref;
    _isInitialized = true;

    // 音声ファイルをプリロード（実際のファイルがある場合）
    await _preloadSounds();
  }

  /// 音声ファイルのプリロード
  Future<void> _preloadSounds() async {
    try {
      // 実際の音声ファイルがある場合のプリロード処理
      // await rootBundle.load('assets/sounds/tap.wav');
      // await rootBundle.load('assets/sounds/place.wav');
      // 等々...
    } catch (e) {
      print('音声ファイルの読み込みに失敗: $e');
    }
  }

  /// 効果音再生
  Future<void> playSound(SoundEffect effect) async {
    if (!_isInitialized) return;

    final settings = _ref.read(appSettingsProvider);
    if (!settings.soundEnabled) return;

    try {
      // システム効果音とハプティックフィードバックを組み合わせ
      switch (effect) {
        case SoundEffect.tap:
        case SoundEffect.button:
          await _playSystemSound(SystemSoundType.click);
          await _playHapticFeedback(HapticFeedbackType.lightImpact);
          break;
        case SoundEffect.place:
          await _playHapticFeedback(HapticFeedbackType.lightImpact);
          break;
        case SoundEffect.rotate:
          await _playHapticFeedback(HapticFeedbackType.selectionClick);
          break;
        case SoundEffect.success:
          await _playHapticFeedback(HapticFeedbackType.heavyImpact);
          break;
        case SoundEffect.failure:
          await _playHapticFeedback(HapticFeedbackType.mediumImpact);
          break;
        case SoundEffect.hint:
          await _playHapticFeedback(HapticFeedbackType.lightImpact);
          break;
      }
    } catch (e) {
      print('効果音再生エラー: $e');
    }
  }

  /// システム効果音再生
  Future<void> _playSystemSound(SystemSoundType sound) async {
    await SystemSound.play(sound);
  }

  /// 触覚フィードバック
  Future<void> _playHapticFeedback(HapticFeedbackType feedback) async {
    final settings = _ref.read(appSettingsProvider);
    if (!settings.hapticsEnabled) return;

    switch (feedback) {
      case HapticFeedbackType.lightImpact:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// BGM再生（将来実装）
  Future<void> playBGM() async {
    // 実装予定：バックグラウンドミュージック
  }

  /// BGM停止
  Future<void> stopBGM() async {
    // 実装予定
  }

  /// 音量設定
  void setVolume(double volume) {
    // 実装予定
  }

  /// リソース解放
  void dispose() {
    // 実装予定：音声リソースの解放
  }
}

// AudioServiceプロバイダー
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

// ハプティックフィードバックタイプ enum
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}
