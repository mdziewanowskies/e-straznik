import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mascot.dart';

/// Pull-to-refresh używający maskotki e-Strażnika zamiast spinnera.
/// Maskotka:
///  - wjeżdża w dół wraz z ściąganiem,
///  - lekko się skaluje przy mocnym pull-down,
///  - obraca się podczas trwającego odświeżania,
///  - daje haptic feedback przy wyzwoleniu.
class MascotRefreshIndicator extends StatelessWidget {
  const MascotRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  static const double _indicatorSize = 64;
  static const double _maxExtent = 110;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: 90,
      onStateChanged: (change) {
        // Subtelny haptic gdy użytkownik wciągnie wystarczająco daleko.
        if (change.didChange(to: IndicatorState.armed)) {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, child, controller) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final value = controller.value.clamp(0.0, 1.5);
                // Maskotka pojawia się od 0, jest wciągana wraz z value.
                final dy = value * _maxExtent - _indicatorSize;
                final scale = 0.7 + (value.clamp(0.0, 1.0) * 0.3);
                final opacity = value.clamp(0.0, 1.0);
                return Positioned(
                  top: dy,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: _Mascot(controller: controller),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // Lista zjeżdża w dół, by zrobić miejsce na maskotkę.
                final offset = controller.value.clamp(0.0, 1.0) * _maxExtent;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _Mascot extends StatefulWidget {
  const _Mascot({required this.controller});
  final IndicatorController controller;

  @override
  State<_Mascot> createState() => _MascotState();
}

class _MascotState extends State<_Mascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulse);
    widget.controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    if (widget.controller.state == IndicatorState.loading) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      if (_pulse.isAnimating) {
        _pulse.stop();
        _pulse.value = 0;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Mascot(size: 56, glow: true),
    );
  }
}
