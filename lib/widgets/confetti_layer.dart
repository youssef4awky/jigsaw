import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiLayer extends StatelessWidget {
  const ConfettiLayer({
    required this.controller,
    super.key,
  });

  final ConfettiController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: pi / 4,
              emissionFrequency: 0.03,
              numberOfParticles: 22,
              gravity: 0.25,
              shouldLoop: false,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: pi - (pi / 4),
              emissionFrequency: 0.03,
              numberOfParticles: 22,
              gravity: 0.25,
              shouldLoop: false,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: pi / 2,
              emissionFrequency: 0.02,
              numberOfParticles: 35,
              gravity: 0.32,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
