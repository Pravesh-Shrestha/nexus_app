import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B0C10);
  static const Color surface = Color(0xFF16171D);
  static const Color surfaceHighlight = Color(0xFF1C1D24);
  static const Color iconContainer = Color(0xFF15161A);

  // Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color secondaryPurple = Color(0xFF4B39EF);
  
  // Gradients
  static const LinearGradient authButtonGradient = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF), Color(0xFF8A2BE2)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFF4B39EF)],
  );
  
  static RadialGradient backgroundGlow(AlignmentGeometry center) {
    return RadialGradient(
      center: center,
      radius: 1.5,
      colors: [
        const Color(0xFF4B39EF).withValues(alpha: 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
  }

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color textMuted = Colors.white30;
  
  // Borders
  static const Color borderLight = Colors.white10;
  static const Color borderMedium = Colors.white30;
}
