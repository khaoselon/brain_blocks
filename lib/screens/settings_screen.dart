import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import '../services/att_service.dart';
import '../models/app_settings.dart';
import '../widgets/att_dialog_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final attService = ref.watch(attServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ゲーム設定
            _buildSettingsGroup(
              title: 'ゲーム設定',
              icon: Icons.gamepad,
              children: [
                _buildSwitchTile(
                  title: 'サウンド',
                  subtitle: 'BGM・効果音の再生',
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSoundEnabled(value);
                  },
                  icon: settings.soundEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                ),

                _buildSwitchTile(
                  title: '触覚フィードバック',
                  subtitle: 'バイブレーション機能',
                  value: settings.hapticsEnabled,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateHapticsEnabled(value);
                  },
                  icon: settings.hapticsEnabled
                      ? Icons.vibration
                      : Icons.phone_android,
                ),

                _buildListTile(
                  title: 'デフォルト難易度',
                  subtitle: _getDifficultyName(settings.defaultDifficulty),
                  icon: Icons.tune,
                  onTap: () => _showDifficultyDialog(context, ref, settings),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // プライバシー・広告設定（ATT統合）
            _buildSettingsGroup(
              title: 'プライバシー・広告設定',
              icon: Icons.privacy_tip,
              children: [
                // ATT設定（iOSのみ表示）
                if (Platform.isIOS &&
                    attService.currentStatus != ATTStatus.notSupported) ...[
                  _buildATTStatusTile(context, ref, attService),

                  if (attService.currentStatus != ATTStatus.notDetermined)
                    _buildListTile(
                      title: 'トラッキング設定を変更',
                      subtitle: 'システム設定でトラッキング許可を変更',
                      icon: Icons.settings,
                      onTap: () => _showATTSettingsDialog(context),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                    ),
                ],

                _buildListTile(
                  title: '広告除去',
                  subtitle: settings.adFree
                      ? '購入済み - 広告非表示'
                      : '¥370 - すべての広告を非表示',
                  icon: settings.adFree
                      ? Icons.check_circle
                      : Icons.remove_circle,
                  onTap: settings.adFree
                      ? null
                      : () => _showPurchaseDialog(context),
                  trailing: settings.adFree
                      ? const Icon(Icons.check, color: Colors.green)
                      : const Icon(Icons.shopping_cart),
                ),

                // パーソナライズ広告設定（ATT状態に応じて表示）
                if (!settings.adFree)
                  _buildPersonalizedAdsSettings(ref, settings, attService),
              ],
            ),

            const SizedBox(height: 24),

            // アクセシビリティ設定
            _buildSettingsGroup(
              title: 'アクセシビリティ',
              icon: Icons.accessibility,
              children: [
                _buildSwitchTile(
                  title: '色覚バリアフリーモード',
                  subtitle: '色の識別をより明確に',
                  value: settings.colorBlindFriendly,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateColorBlindFriendly(value);
                  },
                  icon: Icons.palette,
                ),

                _buildListTile(
                  title: 'テーマ',
                  subtitle: _getThemeName(ThemeMode.values[settings.themeMode]),
                  icon: Icons.brightness_6,
                  onTap: () => _showThemeDialog(context, ref, settings),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // アプリ情報
            _buildSettingsGroup(
              title: 'アプリ情報',
              icon: Icons.info,
              children: [
                _buildListTile(
                  title: 'バージョン',
                  subtitle: '1.0.0 (1)',
                  icon: Icons.app_registration,
                  onTap: null,
                ),

                _buildListTile(
                  title: 'プライバシーポリシー',
                  subtitle: 'データの取り扱いについて',
                  icon: Icons.privacy_tip,
                  onTap: () => _showPrivacyPolicy(context),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),

                _buildListTile(
                  title: 'お問い合わせ',
                  subtitle: 'サポート・フィードバック',
                  icon: Icons.contact_support,
                  onTap: () => _showContactDialog(context),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // データ管理
            _buildSettingsGroup(
              title: 'データ管理',
              icon: Icons.storage,
              children: [
                _buildListTile(
                  title: 'データをリセット',
                  subtitle: '統計情報と設定を初期化',
                  icon: Icons.restore,
                  onTap: () => _showResetDialog(context, ref),
                  trailing: const Icon(Icons.warning, color: Colors.orange),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ATTステータス表示タイル
  Widget _buildATTStatusTile(
    BuildContext context,
    WidgetRef ref,
    ATTService attService,
  ) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (attService.currentStatus) {
      case ATTStatus.authorized:
        statusText = '許可済み';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ATTStatus.denied:
        statusText = '拒否済み';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case ATTStatus.restricted:
        statusText = '制限中';
        statusColor = Colors.orange;
        statusIcon = Icons.block;
        break;
      case ATTStatus.notDetermined:
        statusText = '未設定';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
      default:
        statusText = '非対応';
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'アプリトラッキング',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attService.getStatusDescription(),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (attService.currentStatus == ATTStatus.notDetermined) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showATTExplanationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('設定する'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// パーソナライズ広告設定
  Widget _buildPersonalizedAdsSettings(
    WidgetRef ref,
    AppSettings settings,
    ATTService attService,
  ) {
    bool canToggle = true;
    String subtitle = 'より関連性の高い広告を表示';

    // iOS の ATT 状態に応じて設定可能性を判定
    if (Platform.isIOS) {
      switch (attService.currentStatus) {
        case ATTStatus.denied:
        case ATTStatus.restricted:
          canToggle = false;
          subtitle = 'トラッキングが許可されていないため無効';
          break;
        case ATTStatus.notDetermined:
          canToggle = false;
          subtitle = 'トラッキング許可を先に設定してください';
          break;
        default:
          break;
      }
    }

    return Opacity(
      opacity: canToggle ? 1.0 : 0.6,
      child: _buildSwitchTile(
        title: 'パーソナライズ広告',
        subtitle: subtitle,
        value: settings.personalizedAds && canToggle,
        onChanged: canToggle
            ? (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .updatePersonalizedAds(value);
              }
            : null,
        icon: Icons.person,
      ),
    );
  }

  /// ATT説明ダイアログ表示
  void _showATTExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ATTExplanationDialog(),
    );
  }

  /// ATT設定変更ダイアログ
  void _showATTSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('トラッキング設定'),
        content: const Text(
          'トラッキング許可の設定を変更するには、\n'
          'iOSの「設定」→「プライバシーとセキュリティ」→「トラッキング」\n'
          'から本アプリの設定を変更してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 実際の実装では url_launcher で設定アプリを開く
              // await launchUrl(Uri.parse('app-settings:'));
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E86C1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E86C1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E86C1),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E86C1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '初級 (5×5)';
      case 'medium':
        return '中級 (7×7)';
      case 'hard':
        return '上級 (10×10)';
      default:
        return '初級 (5×5)';
    }
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'ライト';
      case ThemeMode.dark:
        return 'ダーク';
      case ThemeMode.system:
        return 'システム設定に従う';
    }
  }

  void _showDifficultyDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デフォルト難易度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('初級 (5×5)'),
              value: 'easy',
              groupValue: settings.defaultDifficulty,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateDefaultDifficulty(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('中級 (7×7)'),
              value: 'medium',
              groupValue: settings.defaultDifficulty,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateDefaultDifficulty(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('上級 (10×10)'),
              value: 'hard',
              groupValue: settings.defaultDifficulty,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateDefaultDifficulty(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライト'),
              value: ThemeMode.light,
              groupValue: ThemeMode.values[settings.themeMode], // ← ここを修正
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).updateThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('ダーク'),
              value: ThemeMode.dark,
              groupValue: ThemeMode.values[settings.themeMode], // ここも修正
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).updateThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('システム設定に従う'),
              value: ThemeMode.system,
              groupValue: ThemeMode.values[settings.themeMode], // ここを修正
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).updateThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('広告除去'),
        content: const Text(
          '¥370の一回限りの購入で、すべての広告を非表示にできます。\n\n'
          '• バナー広告の除去\n'
          '• インタースティシャル広告の除去\n'
          '• より快適なゲーム体験',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showComingSoon(context, 'アプリ内購入');
            },
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データリセット'),
        content: const Text(
          'すべての統計情報と設定が削除されます。\n'
          'この操作は取り消せません。\n\n'
          '本当にリセットしますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(appSettingsProvider.notifier).resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('データをリセットしました'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showComingSoon(context, 'プライバシーポリシー');
  }

  void _showContactDialog(BuildContext context) {
    _showComingSoon(context, 'お問い合わせ');
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('この機能は今後のアップデートで追加予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
