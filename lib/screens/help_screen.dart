// lib/screens/help_screen.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('ヘルプ'),
        backgroundColor: const Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'ゲームの目的',
              'ランダムに生成されたピースを正方形の盤面に隙間なく配置することがゴールです。',
              Icons.flag,
            ),
            
            _buildSection(
              '基本操作',
              '• ピースをドラッグして盤面に配置\n• ピースをタップして90度回転\n• 配置済みピースをタップして取り除き',
              Icons.touch_app,
            ),
            
            _buildSection(
              '難易度について',
              '• 初級 (5×5): 小さな盤面で基本操作を学習\n• 中級 (7×7): 程よい難しさでスキルアップ\n• 上級 (10×10): 本格的なパズルに挑戦',
              Icons.trending_up,
            ),
            
            _buildSection(
              'ヒント機能',
              'ヒントボタンを押すと、未配置ピースの正しい配置場所が点線で表示されます。',
              Icons.lightbulb,
            ),
            
            _buildSection(
              '脳トレ効果',
              '• 空間認識能力の向上\n• 論理的思考力の育成\n• 集中力・注意力の強化\n• ストレス軽減・リラックス効果',
              Icons.psychology,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E86C1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2E86C1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E86C1),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}