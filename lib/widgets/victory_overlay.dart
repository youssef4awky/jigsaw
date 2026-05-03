import 'package:flutter/material.dart';

import 'stars_widget.dart';

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({
    required this.stars,
    required this.elapsed,
    required this.onContinue,
    super.key,
  });

  final int stars;
  final Duration elapsed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10151F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Puzzle Completed!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                ),
                const SizedBox(height: 10),
                StarsWidget(stars: stars, size: 40, animated: true),
                const SizedBox(height: 10),
                Text(
                  'Time: $minutes:$seconds',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 16),
                const Text(
                  'قناع توت عنخ آمون\nقطعة أثرية مصرية شهيرة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onContinue,
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
