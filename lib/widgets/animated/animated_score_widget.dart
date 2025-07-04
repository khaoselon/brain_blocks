// lib/widgets/animated/animated_score_widget.dart
import 'package:flutter/material.dart';

class AnimatedScoreWidget extends StatefulWidget {
  final int score;
  final String label;
  final Color color;
  final Duration animationDuration;

  const AnimatedScoreWidget({
    super.key,
    required this.score,
    required this.label,
    this.color = const Color(0xFF2E86C1),
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<AnimatedScoreWidget> createState() => _AnimatedScoreWidgetState();
}

class _AnimatedScoreWidgetState extends State<AnimatedScoreWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<int> _scoreAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.score != widget.score) {
      _scoreAnimation = IntTween(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                Text(
                  _scoreAnimation.value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}