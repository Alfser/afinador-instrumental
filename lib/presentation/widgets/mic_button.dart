import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular capture button with a pulsing ring while [listening] is true —
/// gives the "actively recording" state some life instead of a static icon.
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.listening, required this.onPressed});

  final bool listening;
  final VoidCallback onPressed;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !oldWidget.listening) {
      _controller.repeat();
    } else if (!widget.listening && oldWidget.listening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Opacity(
                opacity: widget.listening ? (1 - t) * 0.5 : 0,
                child: Transform.scale(
                  scale: 1 + t * 0.5,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              );
            },
          ),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(
                  widget.listening ? Icons.mic : Icons.mic_none,
                  color: AppColors.bg,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
