import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps a screen with a confetti burst that can be triggered on demand
/// (e.g. when a habit's streak hits a milestone). Purely decorative - it
/// never blocks input (IgnorePointer) and disposes its controller cleanly.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.child, this.controllerKey});

  final Widget child;
  final GlobalKey<CelebrationOverlayState>? controllerKey;

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _controller =
      ConfettiController(duration: const Duration(seconds: 2));

  void play() => _controller.play();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controller,
                blastDirection: 1.5708, // straight down (radians)
                emissionFrequency: 0.08,
                numberOfParticles: 16,
                maxBlastForce: 12,
                minBlastForce: 6,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.general,
                  AppColors.trading,
                  AppColors.success,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
