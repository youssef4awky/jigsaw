import 'package:flutter/material.dart';

class StarsWidget extends StatelessWidget {
  const StarsWidget({
    required this.stars,
    this.size = 28,
    this.animated = false,
    super.key,
  });

  final int stars;
  final double size;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index < stars;
        final icon = Icon(
          Icons.star_rounded,
          color: active ? Colors.amber : Colors.white24,
          size: size,
        );
        if (!animated) return icon;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: active ? 1 : 0.9),
          duration: Duration(milliseconds: 380 + (index * 130)),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: icon,
        );
      }),
    );
  }
}
