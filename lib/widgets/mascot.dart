import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Maskotka e-Strażnika. Asset: `assets/images/mascot.png`.
/// Jeśli assetu nie ma, używamy fallbackowej ikony.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/mascot.png',
        fit: BoxFit.contain,
        errorBuilder: (context, _, __) => Container(
          decoration: BoxDecoration(
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
    );
  }
}
