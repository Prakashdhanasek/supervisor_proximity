import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Context-aware color helper. Access via `AppTheme.of(context)`.
/// Shares the exact palette of the driver app so the two products match.
class AppColors {
  final Brightness _brightness;
  const AppColors._(this._brightness);

  bool get isDark => _brightness == Brightness.dark;

  Color get surface => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get card => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  Color get cardBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
}

class AppTheme {
  static AppColors of(BuildContext context) =>
      AppColors._(Theme.of(context).brightness);

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accentSoft = Color(0xFF60A5FA);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration cardDecoration(BuildContext context, {Color? borderColor}) {
    final c = AppTheme.of(context);
    return BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? c.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ThemeData _base(Brightness b) {
    final isDark = b == Brightness.dark;
    final text = isDark
        ? GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.poppinsTextTheme();
    return ThemeData(
      brightness: b,
      primaryColor: primary,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: isDark
          ? const ColorScheme.dark(primary: primary, secondary: primary, surface: Color(0xFF1E293B), error: danger)
          : const ColorScheme.light(primary: primary, secondary: primary, surface: Color(0xFFFFFFFF), error: danger),
      textTheme: text,
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme => _base(Brightness.light);
  static ThemeData get darkTheme => _base(Brightness.dark);
}
