// lib/features/badges/presentation/confetti_overlay.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Wrap any widget with this to show confetti when [play] is true.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.play, required this.child});
  final bool play;
  final Widget child;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.play) _controller.play();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _controller.play();
  }

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
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFF5A623),
              Color(0xFF4A90D9),
              Color(0xFF5BA55B),
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}
