// lib/widgets/att_dialog_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/att_service.dart';

class ATTExplanationDialog extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ATTExplanationDialog({super.key, this.onAccept, this.onDecline});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('プライバシーについて'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'より良い体験を提供するため、パーソナライズされた広告を表示したいと思います。',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.star,
            title: 'あなたに関連性の高い広告',
            description: '興味のある内容の広告が表示されます',
          ),
          _buildBenefitItem(
            icon: Icons.monetization_on,
            title: 'アプリの継続的な改善',
            description: '広告収益でアプリをより良くできます',
          ),
          _buildBenefitItem(
            icon: Icons.security,
            title: 'プライバシーの保護',
            description: '個人情報は安全に保護されます',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '「許可しない」を選択しても、一般的な広告は表示されます',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDecline?.call();
            _requestATTPermission(context, expectAccept: false);
          },
          child: const Text('今はしない'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept?.call();
            _requestATTPermission(context, expectAccept: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('理解しました'),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestATTPermission(
    BuildContext context, {
    required bool expectAccept,
  }) async {
    try {
      final status = await ATTService.instance.requestTrackingPermission();

      if (context.mounted) {
        _showResultFeedback(context, status, expectAccept);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('設定に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultFeedback(
    BuildContext context,
    ATTStatus status,
    bool expectAccept,
  ) {
    String message;
    Color backgroundColor;

    switch (status) {
      case ATTStatus.authorized:
        message = 'パーソナライズされた広告が有効になりました';
        backgroundColor = Colors.green;
        break;
      case ATTStatus.denied:
        message = '一般的な広告が表示されます';
        backgroundColor = Colors.blue;
        break;
      default:
        message = '設定が完了しました';
        backgroundColor = Colors.grey;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: status == ATTStatus.denied
            ? SnackBarAction(
                label: '設定変更',
                textColor: Colors.white,
                onPressed: () {
                  _openAppSettings();
                },
              )
            : null,
      ),
    );
  }

  void _openAppSettings() {
    // 設定アプリを開く（iOS）
    // 実際の実装では url_launcher や app_settings パッケージを使用
    //if (mounted) {
    HapticFeedback.lightImpact();
  }
}

//}
