// lib/widgets/animated/game_transition_widget.dart
import 'package:flutter/material.dart';

class GameTransitionWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool show;

  const GameTransitionWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.show = true,
  });

  @override
  State<GameTransitionWidget> createState() => _GameTransitionWidgetState();
}

class _GameTransitionWidgetState extends State<GameTransitionWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GameTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}