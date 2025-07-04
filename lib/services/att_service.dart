// lib/services/att_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import '../services/admob_service.dart';

enum ATTStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notSupported, // Android or old iOS
}

class ATTService {
  static ATTService? _instance;
  static ATTService get instance => _instance ??= ATTService._();
  ATTService._();

  late WidgetRef _ref;
  ATTStatus _currentStatus = ATTStatus.notDetermined;
  bool _hasShownDialog = false;

  ATTStatus get currentStatus => _currentStatus;
  bool get hasShownDialog => _hasShownDialog;

  /// ATTサービス初期化
  Future<void> initialize(WidgetRef ref) async {
    _ref = ref;

    if (!Platform.isIOS) {
      _currentStatus = ATTStatus.notSupported;
      return;
    }

    // iOS 14.5未満の場合はサポートされない
    final iosVersion = await _getIOSVersion();
    if (iosVersion < 14.5) {
      _currentStatus = ATTStatus.notSupported;
      return;
    }

    // 現在のステータス取得
    await _updateCurrentStatus();

    if (kDebugMode) {
      print('ATT初期化完了 - ステータス: $_currentStatus');
    }
  }

  /// 現在のATTステータス更新
  Future<void> _updateCurrentStatus() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _currentStatus = _convertStatus(status);

      // 設定に反映
      final personalizedAds = _currentStatus == ATTStatus.authorized;
      _ref
          .read(appSettingsProvider.notifier)
          .updatePersonalizedAds(personalizedAds);

      // AdMobに設定を反映
      AdMobService.instance.updatePersonalizedAdsConfig(personalizedAds);
    } catch (e) {
      if (kDebugMode) {
        print('ATTステータス取得エラー: $e');
      }
      _currentStatus = ATTStatus.notSupported;
    }
  }

  /// トラッキング許可ダイアログ表示
  Future<ATTStatus> requestTrackingPermission() async {
    if (!Platform.isIOS || _currentStatus == ATTStatus.notSupported) {
      return _currentStatus;
    }

    if (_currentStatus != ATTStatus.notDetermined) {
      return _currentStatus;
    }

    try {
      if (kDebugMode) {
        print('ATT許可ダイアログ表示中...');
      }

      final status =
          await AppTrackingTransparency.requestTrackingAuthorization();
      _currentStatus = _convertStatus(status);
      _hasShownDialog = true;

      // 結果をログ出力
      if (kDebugMode) {
        print('ATT許可結果: $_currentStatus');
      }

      // 設定とAdMobを更新
      await _updatePersonalizedAdsSettings();

      return _currentStatus;
    } catch (e) {
      if (kDebugMode) {
        print('ATT許可ダイアログエラー: $e');
      }
      return _currentStatus;
    }
  }

  /// 適切なタイミングでATTダイアログを表示
  Future<void> showDialogIfAppropriate({
    required ATTTrigger trigger,
    bool force = false,
  }) async {
    if (!_shouldShowDialog(trigger) && !force) {
      return;
    }

    // 他のダイアログとの競合を避けるための遅延
    await Future.delayed(const Duration(milliseconds: 500));

    await requestTrackingPermission();
  }

  /// ATTダイアログ表示判定
  bool _shouldShowDialog(ATTTrigger trigger) {
    // iOSでない、またはサポートされていない場合
    if (!Platform.isIOS || _currentStatus == ATTStatus.notSupported) {
      return false;
    }

    // 既にダイアログを表示済み
    if (_hasShownDialog) {
      return false;
    }

    // すでに決定済み（アプリ削除→再インストール以外では発生しない）
    if (_currentStatus != ATTStatus.notDetermined) {
      return false;
    }

    // トリガーに応じた表示判定
    switch (trigger) {
      case ATTTrigger.firstGameComplete:
        return true; // 初回ゲーム完了後は適切なタイミング
      case ATTTrigger.settingsManual:
        return true; // 設定からの手動表示
      case ATTTrigger.adImpression:
        return true; // 広告表示前（重要）
      case ATTTrigger.appLaunch:
        return false; // アプリ起動時は推奨されない
    }
  }

  /// パーソナライズ広告設定更新
  Future<void> _updatePersonalizedAdsSettings() async {
    final personalizedAds = _currentStatus == ATTStatus.authorized;

    // 設定保存
    _ref
        .read(appSettingsProvider.notifier)
        .updatePersonalizedAds(personalizedAds);

    // AdMob設定更新
    AdMobService.instance.updatePersonalizedAdsConfig(personalizedAds);
  }

  /// ステータス変換 - 修正版
  ATTStatus _convertStatus(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.notDetermined:
        return ATTStatus.notDetermined;
      case TrackingStatus.restricted:
        return ATTStatus.restricted;
      case TrackingStatus.denied:
        return ATTStatus.denied;
      case TrackingStatus.authorized:
        return ATTStatus.authorized;
      // TrackingStatus.notSupportedの場合を追加
      default:
        return ATTStatus.notSupported;
    }
  }

  /// iOSバージョン取得（簡易版）
  Future<double> _getIOSVersion() async {
    try {
      // 実際の実装では device_info_plus などを使用
      return 15.0; // デフォルトで対応版とする
    } catch (e) {
      return 15.0;
    }
  }

  /// ユーザーフレンドリーなステータス文字列取得
  String getStatusDescription() {
    switch (_currentStatus) {
      case ATTStatus.authorized:
        return 'パーソナライズされた広告が表示されます';
      case ATTStatus.denied:
        return '一般的な広告が表示されます';
      case ATTStatus.restricted:
        return '広告のトラッキングが制限されています';
      case ATTStatus.notDetermined:
        return 'トラッキング許可が未決定です';
      case ATTStatus.notSupported:
        return 'この機能はサポートされていません';
    }
  }

  /// 設定アプリへの誘導が必要かチェック
  bool get canChangeInSettings {
    return _currentStatus == ATTStatus.denied && _hasShownDialog;
  }
}

/// ATTダイアログ表示トリガー
enum ATTTrigger {
  firstGameComplete, // 初回ゲーム完了後（推奨）
  settingsManual, // 設定からの手動表示
  adImpression, // 広告表示前
  appLaunch, // アプリ起動時（非推奨）
}

// ATTサービスプロバイダー
final attServiceProvider = Provider<ATTService>((ref) {
  return ATTService.instance;
});
