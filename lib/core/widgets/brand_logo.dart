import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "Sira Tech" wordmark + "Creative Studio" subtitle.
/// Once the Cairo/Lemonada font files are bundled, switch fontFamily here.
class BrandLogo extends StatelessWidget {
  final double scale;
  final bool center;
  const BrandLogo({super.key, this.scale = 1.0, this.center = true});

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          'Sira Tech',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 30 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.gold,
            // fontFamily: 'Lemonada', // uncomment after bundling display font
          ),
        ),
        SizedBox(height: 2 * scale),
        Container(
          width: 120 * scale,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.gold.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          'CREATIVE STUDIO',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 10.5 * scale,
            letterSpacing: 4.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
