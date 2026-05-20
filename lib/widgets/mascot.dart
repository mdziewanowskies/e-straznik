import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Maskotka e-Strażnika z opcjonalną poświatą.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 120, this.glow = true});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.45),
                    AppColors.teal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          Image.asset(
            'assets/images/mascot.png',
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradientHero,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.shield_moon_outlined,
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
