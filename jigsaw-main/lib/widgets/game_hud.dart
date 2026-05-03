import 'package:flutter/material.dart';

import 'stars_widget.dart';
import 'timer_widget.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.elapsed,
    required this.currentStars,
    required this.onRestart,
    required this.onPauseToggle,
    required this.onHint,
    required this.onShuffleAgain,
    required this.paused,
    super.key,
  });

  final Duration elapsed;
  final int currentStars;
  final VoidCallback onRestart;
  final VoidCallback onPauseToggle;
  final VoidCallback onHint;
  final VoidCallback onShuffleAgain;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TimerWidget(elapsed: elapsed),
              const Spacer(),
              StarsWidget(stars: currentStars),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _HudButton(icon: Icons.refresh_rounded, label: 'Restart', onTap: onRestart),
              _HudButton(
                icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: paused ? 'Resume' : 'Pause',
                onTap: onPauseToggle,
              ),
              _HudButton(icon: Icons.lightbulb_rounded, label: 'Hint', onTap: onHint),
              _HudButton(icon: Icons.shuffle_rounded, label: 'Shuffle', onTap: onShuffleAgain),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
