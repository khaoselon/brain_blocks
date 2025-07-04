// lib/widgets/animated/confetti_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final List<Color> colors;
  final bool autoStart;

  const ConfettiWidget({
    super.key,
    this.particleCount = 50,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ],
    this.autoStart = true,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _generateParticles();

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return ConfettiParticle(
        color: widget.colors[_random.nextInt(widget.colors.length)],
        startX: _random.nextDouble(),
        startY: _random.nextDouble() * 0.3, // 上部から開始
        velocityX: (_random.nextDouble() - 0.5) * 2,
        velocityY: _random.nextDouble() * 2 + 1,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        size: _random.nextDouble() * 8 + 4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      final t = progress;
      final gravity = 0.5;
      
      // 物理計算
      final x = particle.startX * size.width + particle.velocityX * t * size.width * 0.1;
      final y = particle.startY * size.height + 
                 particle.velocityY * t * size.height * 0.1 + 
                 gravity * t * t * size.height * 0.1;
      
      // 画面外に出たら描画しない
      if (x < -particle.size || x > size.width + particle.size ||
          y < -particle.size || y > size.height + particle.size) {
        continue;
      }

      final rotation = particle.rotation + particle.rotationSpeed * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      paint.color = particle.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      // 長方形の紙吹雪
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}