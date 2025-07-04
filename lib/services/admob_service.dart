// lib/services/admob_service.dart - 不具合修正版（フリーズ対策）
import 'dart:io';
import 'dart:async';
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

  // 🔥 修正：広告処理状態管理
  bool _isInterstitialShowing = false;
  bool _isRewardedShowing = false;
  bool _isInitialized = false;

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

  /// 🔥 修正：AdMob初期化（ATT対応・エラーハンドリング強化）
  Future<void> initialize({WidgetRef? ref}) async {
    if (_isInitialized) {
      print('✅ AdMob既に初期化済み');
      return;
    }

    try {
      print('🚀 AdMob初期化開始');

      // iOS の場合、ATT ステータス確認後に初期化
      if (Platform.isIOS) {
        await _initializeWithATT();
      } else {
        await _initializeAndroid();
      }

      _isInitialized = true;
      print('✅ AdMob初期化完了');
    } catch (e) {
      print('❌ AdMob初期化エラー: $e');
      _isInitialized = false;
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
      rethrow;
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
      rethrow;
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
    try {
      await Future.wait([
        _loadBannerAd(),
        _loadInterstitialAd(),
        _loadRewardedAd(),
      ]);
    } catch (e) {
      print('❌ 広告読み込みエラー: $e');
    }
  }

  /// バナー広告読み込み（ATT対応）
  Future<void> _loadBannerAd() async {
    try {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerAdLoaded = false;

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: _createAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            if (kDebugMode) print('✅ バナー広告読み込み完了');
          },
          onAdFailedToLoad: (ad, error) {
            _isBannerAdLoaded = false;
            ad.dispose();
            if (kDebugMode) print('❌ バナー広告読み込み失敗: $error');
          },
          onAdImpression: (ad) {
            if (kDebugMode) print('📊 バナー広告インプレッション');
            _trackAdImpression('banner');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      print('❌ バナー広告読み込みエラー: $e');
      _isBannerAdLoaded = false;
    }
  }

  /// 🔥 修正：インタースティシャル広告読み込み（フリーズ対策）
  Future<void> _loadInterstitialAd() async {
    try {
      // 既存の広告を破棄
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;

      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: _createAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            if (kDebugMode) print('✅ インタースティシャル広告読み込み完了');

            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
                  onAdShowedFullScreenContent: (ad) {
                    _isInterstitialShowing = true;
                    if (kDebugMode) print('📺 インタースティシャル広告表示開始');
                  },
                  onAdDismissedFullScreenContent: (ad) {
                    _isInterstitialShowing = false;
                    if (kDebugMode) print('✅ インタースティシャル広告終了');
                    ad.dispose();
                    _isInterstitialAdLoaded = false;

                    // 🔥 修正：非同期で次の広告を読み込み（UIブロックを防ぐ）
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _loadInterstitialAd();
                    });
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                    _isInterstitialShowing = false;
                    if (kDebugMode) print('❌ インタースティシャル広告表示失敗: $error');
                    ad.dispose();
                    _isInterstitialAdLoaded = false;

                    // エラー時も次の広告を読み込み
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _loadInterstitialAd();
                    });
                  },
                  onAdImpression: (ad) {
                    if (kDebugMode) print('📊 インタースティシャル広告インプレッション');
                    _trackAdImpression('interstitial');
                  },
                );
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            if (kDebugMode) print('❌ インタースティシャル広告読み込み失敗: $error');

            // 失敗時は少し遅延してリトライ
            Future.delayed(const Duration(seconds: 5), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('❌ インタースティシャル広告読み込みエラー: $e');
      _isInterstitialAdLoaded = false;
    }
  }

  /// 🔥 修正：リワード広告読み込み（フリーズ対策）
  Future<void> _loadRewardedAd() async {
    try {
      // 既存の広告を破棄
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _isRewardedAdLoaded = false;

      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: _createAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            if (kDebugMode) print('✅ リワード広告読み込み完了');

            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _isRewardedShowing = true;
                if (kDebugMode) print('📺 リワード広告表示開始');
              },
              onAdDismissedFullScreenContent: (ad) {
                _isRewardedShowing = false;
                if (kDebugMode) print('✅ リワード広告終了');
                ad.dispose();
                _isRewardedAdLoaded = false;

                // 🔥 修正：非同期で次の広告を読み込み
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadRewardedAd();
                });
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isRewardedShowing = false;
                if (kDebugMode) print('❌ リワード広告表示失敗: $error');
                ad.dispose();
                _isRewardedAdLoaded = false;

                // エラー時も次の広告を読み込み
                Future.delayed(const Duration(milliseconds: 1000), () {
                  _loadRewardedAd();
                });
              },
              onAdImpression: (ad) {
                if (kDebugMode) print('📊 リワード広告インプレッション');
                _trackAdImpression('rewarded');
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoaded = false;
            if (kDebugMode) print('❌ リワード広告読み込み失敗: $error');

            // 失敗時は少し遅延してリトライ
            Future.delayed(const Duration(seconds: 5), () {
              _loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      print('❌ リワード広告読み込みエラー: $e');
      _isRewardedAdLoaded = false;
    }
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

  /// 🔥 修正：インタースティシャル広告表示（フリーズ対策強化）
  Future<void> showInterstitialAd() async {
    if (!_isInitialized) {
      print('⚠️ AdMob未初期化 - インタースティシャル広告スキップ');
      return;
    }

    if (_isInterstitialShowing) {
      print('⚠️ インタースティシャル広告既に表示中');
      return;
    }

    // iOS かつ ATT未決定の場合、先にダイアログ表示
    if (Platform.isIOS) {
      try {
        final attService = ATTService.instance;
        if (attService.currentStatus == ATTStatus.notDetermined) {
          await attService.showDialogIfAppropriate(
            trigger: ATTTrigger.adImpression,
          );

          // ダイアログ表示後、広告設定を更新
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('⚠️ ATT処理エラー: $e');
      }
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      try {
        print('📺 インタースティシャル広告表示開始');
        await _interstitialAd!.show();
      } catch (e) {
        print('❌ インタースティシャル広告表示エラー: $e');
        _isInterstitialShowing = false;
      }
    } else {
      if (kDebugMode) print('⚠️ インタースティシャル広告が読み込まれていません');
    }
  }

  /// 🔥 修正：リワード広告表示（フリーズ対策強化）
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      print('⚠️ AdMob未初期化 - リワード広告スキップ');
      return false;
    }

    if (_isRewardedShowing) {
      print('⚠️ リワード広告既に表示中');
      return false;
    }

    // iOS かつ ATT未決定の場合、先にダイアログ表示
    if (Platform.isIOS) {
      try {
        final attService = ATTService.instance;
        if (attService.currentStatus == ATTStatus.notDetermined) {
          await attService.showDialogIfAppropriate(
            trigger: ATTTrigger.adImpression,
          );

          // ダイアログ表示後、広告設定を更新
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('⚠️ ATT処理エラー: $e');
      }
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      try {
        print('📺 リワード広告表示開始');
        bool rewardEarned = false;

        // 🔥 修正：タイムアウト付きで広告表示
        final completer = Completer<bool>();

        // タイムアウト設定（30秒）
        Timer? timeoutTimer = Timer(const Duration(seconds: 30), () {
          if (!completer.isCompleted) {
            print('⏰ リワード広告タイムアウト');
            completer.complete(false);
          }
        });

        await _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            rewardEarned = true;
            if (kDebugMode) print('🎁 リワード獲得: ${reward.amount} ${reward.type}');
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
        );

        // 広告が閉じられるまで待機
        final result = await completer.future;
        timeoutTimer?.cancel();

        return result;
      } catch (e) {
        print('❌ リワード広告表示エラー: $e');
        _isRewardedShowing = false;
        return false;
      }
    } else {
      if (kDebugMode) print('⚠️ リワード広告が読み込まれていません');
      return false;
    }
  }

  /// バナー広告ウィジェット取得 - 修正版
  Widget? getBannerAdWidget() {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return null;
  }

  /// 全広告破棄
  void _disposeAllAds() {
    try {
      _bannerAd?.dispose();
      _interstitialAd?.dispose();
      _rewardedAd?.dispose();
      _bannerAd = null;
      _interstitialAd = null;
      _rewardedAd = null;
      _isBannerAdLoaded = false;
      _isInterstitialAdLoaded = false;
      _isRewardedAdLoaded = false;
      _isInterstitialShowing = false;
      _isRewardedShowing = false;
    } catch (e) {
      print('❌ 広告破棄エラー: $e');
    }
  }

  /// 広告状態チェック
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isPersonalizedAdsEnabled => _personalizedAds;
  bool get isInitialized => _isInitialized;

  // 🔥 新機能：広告表示状態チェック
  bool get isInterstitialShowing => _isInterstitialShowing;
  bool get isRewardedShowing => _isRewardedShowing;
  bool get isAnyAdShowing => _isInterstitialShowing || _isRewardedShowing;

  /// リソース解放
  void dispose() {
    try {
      _disposeAllAds();
      _isInitialized = false;
      print('✅ AdMobService破棄完了');
    } catch (e) {
      print('❌ AdMobService破棄エラー: $e');
    }
  }
}
