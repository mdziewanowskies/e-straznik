import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — granat
  static const primary = Color(0xFF1B2A4E);
  static const primaryFg = Color(0xFFF5F7FB);

  // Teal / zieleń maskotki (akcent)
  static const teal = Color(0xFF22C39A);
  static const accent = Color(0xFFD6F3E2);

  // Tło / powierzchnie (light)
  static const background = Color(0xFFF7F9FC);
  static const foreground = Color(0xFF111827);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFEEF2F7);
  static const mutedFg = Color(0xFF6B7280);
  static const border = Color(0xFFE4E8EF);

  // Statusy
  static const success = Color(0xFF22C36B);
  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFE5484D);

  // Sidebar / dark surfaces
  static const sidebar = Color(0xFF101A33);
  static const sidebarFg = Color(0xFFE6ECF5);

  // Dark surfaces
  static const darkBackground = Color(0xFF0E1628);
  static const darkCard = Color(0xFF162038);

  // Gradient hero (granat → teal)
  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101A33), Color(0xFF1B2A4E), Color(0xFF22C39A)],
    stops: [0.0, 0.55, 1.0],
  );

  static Color statusColor(String? status) {
    switch (status) {
      case 'red':
        return danger;
      case 'yellow':
        return warning;
      case 'ok':
      default:
        return success;
    }
  }

  static Color severityColor(String? severity) {
    switch (severity) {
      case 'critical':
        return danger;
      case 'warning':
        return warning;
      case 'info':
      default:
        return primary;
    }
  }
}
