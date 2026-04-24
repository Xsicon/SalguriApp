import 'dart:ui';

class AppColors {
  AppColors._();

  // ─── Primary Palette ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);       // Blue
  static const Color primaryDark = Color(0xFF1D4ED8);    // Darker blue
  static const Color primaryLight = Color(0xFF93C5FD);   // Light blue
  static const Color primarySoft = Color(0xFFDBEAFE);   // Very soft blue

  // ─── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFF59E0B);         // Warm Gold
  static const Color accentLight = Color(0xFFFDE68A);    // Light gold
  static const Color accentSoft = Color(0xFFFEF3C7);     // Very soft gold

  // ─── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFFF8FAFC);        // Cool white
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);    // Dark slate
  static const Color textSecondary = Color(0xFF64748B);  // Muted slate
  static const Color textMuted = Color(0xFF94A3B8);      // Light slate
  static const Color border = Color(0xFFE2E8F0);         // Subtle border
  static const Color divider = Color(0xFFF1F5F9);        // Very subtle divider

  // ─── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  // ─── Glass Effect ───────────────────────────────────────────────────────────
  static const Color glassBg = Color(0xCCFFFFFF);        // 80% white
  static const Color glassBorder = Color(0x33FFFFFF);     // 20% white
  static const Color glassShadow = Color(0x0A0F172A);    // Very subtle shadow

  // White opacity variants
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);
}
