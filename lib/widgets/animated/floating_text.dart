// lib/widgets/animated/floating_text.dart
import 'package:flutter/material.dart';

class FloatingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final Offset startOffset;
  final Offset endOffset;
  final VoidCallback? onComplete;

  const FloatingText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 2000),
    this.startOffset = Offset.zero,
    this.endOffset = const Offset(0, -50),
    this.onComplete,
  });

  @override
  State<FloatingText> createState() => _FloatingTextState();
}

class _FloatingTextState extends State<FloatingText>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
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
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                widget.text,
                style: widget.style,
              ),
            ),
          ),
        );
      },
    );
  }
}