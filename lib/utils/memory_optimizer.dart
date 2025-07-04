// lib/utils/memory_optimizer.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class MemoryOptimizer {
  static MemoryOptimizer? _instance;
  static MemoryOptimizer get instance => _instance ??= MemoryOptimizer._();
  MemoryOptimizer._();

  final Map<String, Uint8List> _imageCache = {};
  final Map<String, Paint> _paintCache = {};
  int _maxCacheSize = 50;

  /// 画像キャッシュ管理
  void cacheImage(String key, Uint8List imageData) {
    if (_imageCache.length >= _maxCacheSize) {
      _evictOldestImage();
    }
    _imageCache[key] = imageData;
  }

  Uint8List? getCachedImage(String key) {
    return _imageCache[key];
  }

  void _evictOldestImage() {
    if (_imageCache.isNotEmpty) {
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
    }
  }

  /// Paint オブジェクトの再利用
  Paint getPaint(String key, {
    required Color color,
    PaintingStyle style = PaintingStyle.fill,
    double strokeWidth = 1.0,
  }) {
    final cacheKey = '$key-${color.value}-${style.index}-$strokeWidth';
    
    if (_paintCache.containsKey(cacheKey)) {
      return _paintCache[cacheKey]!;
    }

    final paint = Paint()
      ..color = color
      ..style = style
      ..strokeWidth = strokeWidth;

    if (_paintCache.length >= _maxCacheSize) {
      _evictOldestPaint();
    }

    _paintCache[cacheKey] = paint;
    return paint;
  }

  void _evictOldestPaint() {
    if (_paintCache.isNotEmpty) {
      final oldestKey = _paintCache.keys.first;
      _paintCache.remove(oldestKey);
    }
  }

  /// メモリクリア
  void clearCache() {
    _imageCache.clear();
    _paintCache.clear();
    
    if (kDebugMode) {
      print('メモリキャッシュをクリアしました');
    }
  }

  /// メモリ使用量監視
  void logCacheStats() {
    if (!kDebugMode) return;

    final imageCount = _imageCache.length;
    final paintCount = _paintCache.length;
    
    print('Cache Stats - Images: $imageCount, Paints: $paintCount');
  }

  /// 重い処理の分割実行
  Future<void> processInChunks<T>(
    List<T> items,
    Future<void> Function(T) processor,
    {int chunkSize = 10}
  ) async {
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      
      for (final item in chunk) {
        await processor(item);
      }
      
      // フレーム間で処理を分割
      await Future.delayed(Duration.zero);
    }
  }
}