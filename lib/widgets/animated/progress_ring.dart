// lib/widgets/animated/progress_ring.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Duration animationDuration;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.color = const Color(0xFF2E86C1),
    this.backgroundColor = const Color(0xFFE9ECEF),
    this.animationDuration = const Duration(milliseconds: 500),
    this.child,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ProgressRingPainter(
                  progress: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  color: widget.color,
                  backgroundColor: widget.backgroundColor,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景円
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // プログレス円
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 上から開始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}