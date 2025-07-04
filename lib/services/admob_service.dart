// lib/services/admob_service.dart - ATT対応版
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/att_service.dart';

class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._();
  AdMobService._();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  // パーソナライズ広告設定
  bool _personalizedAds = false;

  // テスト用広告ID（本番では実際のIDに変更）
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  /// AdMob初期化（ATT対応）
  Future<void> initialize({WidgetRef? ref}) async {
    // iOS の場合、ATT ステータス確認後に初期化
    if (Platform.isIOS) {
      await _initializeWithATT();
    } else {
      await _initializeAndroid();
    }
  }

  /// iOS用初期化（ATT対応）
  Future<void> _initializeWithATT() async {
    try {
      // ATTサービスが初期化されるまで待機
      final attService = ATTService.instance;

      // RequestConfigurationでパーソナライズ設定
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: kDebugMode ? ['test-device-id'] : null,
      );

      // MobileAds初期化
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      // ATTステータスに基づいて広告読み込み
      _personalizedAds = attService.currentStatus == ATTStatus.authorized;

      if (kDebugMode) {
        print('AdMob iOS初期化完了 - パーソナライズ: $_personalizedAds');
      }

      await _loadAllAds();
    } catch (e) {
      if (kDebugMode) {
        print('AdMob iOS初期化エラー: $e');
      }
    }
  }

  /// Android用初期化
  Future<void> _initializeAndroid() async {
    try {
      await MobileAds.instance.initialize();
      _personalizedAds = true; // Androidではデフォルトでパーソナライズ有効

      if (kDebugMode) {
        print('AdMob Android初期化完了');
      }

      await _loadAllAds();
    } catch (e) {
      if (kDebugMode) {
        print('AdMob Android初期化エラー: $e');
      }
    }
  }

  /// パーソナライズ広告設定更新
  void updatePersonalizedAdsConfig(bool personalizedAds) {
    _personalizedAds = personalizedAds;

    if (kDebugMode) {
      print('パーソナライズ広告設定更新: $personalizedAds');
    }

    // 既存の広告を破棄して再読み込み
    _disposeAllAds();
    _loadAllAds();
  }

  /// 全広告読み込み
  Future<void> _loadAllAds() async {
    await Future.wait([
      _loadBannerAd(),
      _loadInterstitialAd(),
      _loadRewardedAd(),
    ]);
  }

  /// バナー広告読み込み（ATT対応）
  Future<void> _loadBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: _createAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          if (kDebugMode) print('バナー広告読み込み完了');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          if (kDebugMode) print('バナー広告読み込み失敗: $error');
        },
        onAdImpression: (ad) {
          if (kDebugMode) print('バナー広告インプレッション');
          _trackAdImpression('banner');
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// インタースティシャル広告読み込み（ATT対応）
  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: _createAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          if (kDebugMode) print('インタースティシャル広告読み込み完了');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdShowedFullScreenContent: (ad) {
                  if (kDebugMode) print('インタースティシャル広告表示');
                },
                onAdDismissedFullScreenContent: (ad) {
                  if (kDebugMode) print('インタースティシャル広告閉じる');
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  if (kDebugMode) print('インタースティシャル広告表示失敗: $error');
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  _loadInterstitialAd();
                },
                onAdImpression: (ad) {
                  if (kDebugMode) print('インタースティシャル広告インプレッション');
                  _trackAdImpression('interstitial');
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          if (kDebugMode) print('インタースティシャル広告読み込み失敗: $error');
        },
      ),
    );
  }

  /// リワード広告読み込み（ATT対応）
  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: _createAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          if (kDebugMode) print('リワード広告読み込み完了');

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) print('リワード広告表示');
            },
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) print('リワード広告閉じる');
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) print('リワード広告表示失敗: $error');
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
            onAdImpression: (ad) {
              if (kDebugMode) print('リワード広告インプレッション');
              _trackAdImpression('rewarded');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          if (kDebugMode) print('リワード広告読み込み失敗: $error');
        },
      ),
    );
  }

  /// ATT対応のAdRequest作成
  AdRequest _createAdRequest() {
    final extras = <String, String>{};

    // iOSでパーソナライズが無効の場合
    if (Platform.isIOS && !_personalizedAds) {
      extras['npa'] = '1'; // Non-Personalized Ads
    }

    return AdRequest(
      keywords: ['puzzle', 'brain', 'game', 'casual'],
      contentUrl: 'https://brainblocks.app',
      nonPersonalizedAds: !_personalizedAds,
      extras: extras,
    );
  }

  /// 広告インプレッション追跡
  void _trackAdImpression(String adType) {
    // ATTが必要な場合、適切なタイミングでダイアログ表示
    if (Platform.isIOS) {
      final attService = ATTService.instance;
      if (attService.currentStatus == ATTStatus.notDetermined) {
        // 広告表示前にATTダイアログ表示（重要）
        attService.showDialogIfAppropriate(trigger: ATTTrigger.adImpression);
      }
    }
  }

  /// インタースティシャル広告表示（ATT考慮）
  Future<void> showInterstitialAd() async {
    // iOS かつ ATT未決定の場合、先にダイアログ表示
    if (Platform.isIOS) {
      final attService = ATTService.instance;
      if (attService.currentStatus == ATTStatus.notDetermined) {
        await attService.showDialogIfAppropriate(
          trigger: ATTTrigger.adImpression,
        );

        // ダイアログ表示後、広告設定を更新
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      if (kDebugMode) print('インタースティシャル広告が読み込まれていません');
    }
  }

  /// リワード広告表示（ATT考慮）
  Future<bool> showRewardedAd() async {
    // iOS かつ ATT未決定の場合、先にダイアログ表示
    if (Platform.isIOS) {
      final attService = ATTService.instance;
      if (attService.currentStatus == ATTStatus.notDetermined) {
        await attService.showDialogIfAppropriate(
          trigger: ATTTrigger.adImpression,
        );

        // ダイアログ表示後、広告設定を更新
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      bool rewardEarned = false;

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          if (kDebugMode) print('リワード獲得: ${reward.amount} ${reward.type}');
        },
      );

      return rewardEarned;
    } else {
      if (kDebugMode) print('リワード広告が読み込まれていません');
      return false;
    }
  }

  /// バナー広告ウィジェット取得 - 修正版
  Widget? getBannerAdWidget() {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
  }

  /// 全広告破棄
  void _disposeAllAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
  }

  /// 広告状態チェック
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isPersonalizedAdsEnabled => _personalizedAds;

  /// リソース解放
  void dispose() {
    _disposeAllAds();
  }
}
