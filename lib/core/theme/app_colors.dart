import 'package:flutter/material.dart';

/// Design tokens for BabyBloom, extracted from the welcome mockup.
/// Keep every color the app uses here so the palette stays consistent.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const primary = Color(0xFF4E4068); // deep plum (wordmark)
  static const primaryContainer = Color(0xFF665781);
  static const secondary = Color(0xFF68548F);
  static const secondaryContainer = Color(0xFFD3BBFE);

  // ── Surfaces & text ────────────────────────────────────
  static const background = Color(0xFFFDF8FC); // soft pink-white
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1D1B1E);
  static const onSurfaceVariant = Color(0xFF49454E);
  static const outlineVariant = Color(0xFFCBC4CE);

  // ── Accents ────────────────────────────────────────────
  static const lavender = Color(0xFFC3B1E1);
  static const lavenderLight = Color(0xFFA38BC4);

  // ── Gradients ──────────────────────────────────────────
  /// "Get Started" button — matches the CSS linear-gradient 135°.
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavenderLight, primaryContainer],
  );

  /// Page background — matches the CSS radial-gradient.
  static const backgroundGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.4,
    colors: [Color(0xFFFDF8FC), Color(0xFFF6EFFF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.4, 1.0],
  );
}
