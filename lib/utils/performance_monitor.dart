// lib/utils/performance_monitor.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._();
  PerformanceMonitor._();

  final List<double> _frameTimes = [];
  Timer? _monitorTimer;
  bool _isMonitoring = false;

  /// パフォーマンス監視開始
  void startMonitoring() {
    if (_isMonitoring || !kDebugMode) return;

    _isMonitoring = true;
    _frameTimes.clear();

    // フレーム時間監視
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // 定期的な統計出力
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportStats();
    });

    developer.log('パフォーマンス監視開始', name: 'Performance');
  }

  /// パフォーマンス監視停止
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    // SchedulerBinding.instance.removePersistentFrameCallback(_onFrame);
    _monitorTimer?.cancel();
    _monitorTimer = null;

    developer.log('パフォーマンス監視停止', name: 'Performance');
  }

  void _onFrame(Duration timestamp) {
    if (!_isMonitoring) return;

    final frameTime = timestamp.inMicroseconds / 1000.0; // ms
    _frameTimes.add(frameTime);

    // 過去100フレームのデータのみ保持
    if (_frameTimes.length > 100) {
      _frameTimes.removeAt(0);
    }
  }

  void _reportStats() {
    if (_frameTimes.isEmpty) return;

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgFrameTime;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);

    developer.log(
      'FPS: ${fps.toStringAsFixed(1)}, '
      'Avg: ${avgFrameTime.toStringAsFixed(1)}ms, '
      'Min: ${minFrameTime.toStringAsFixed(1)}ms, '
      'Max: ${maxFrameTime.toStringAsFixed(1)}ms',
      name: 'Performance',
    );

    // 警告レベルのチェック
    if (fps < 30) {
      developer.log(
        '⚠️ 低FPS検出: ${fps.toStringAsFixed(1)}',
        name: 'Performance',
      );
    }
    if (maxFrameTime > 50) {
      developer.log(
        '⚠️ フレーム遅延検出: ${maxFrameTime.toStringAsFixed(1)}ms',
        name: 'Performance',
      );
    }
  }

  /// メモリ使用量監視
  void logMemoryUsage(String context) {
    if (!kDebugMode) return;

    // Dart VMのメモリ統計（開発環境のみ）
    final info = developer.Service.getIsolateId(Isolate.current);
    developer.log('メモリ使用量チェック: $context', name: 'Memory');
  }

  /// カスタムタイマー
  void timeOperation(String name, Function operation) {
    if (!kDebugMode) {
      operation();
      return;
    }

    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();

    developer.log('$name: ${stopwatch.elapsedMilliseconds}ms', name: 'Timing');
  }
}
