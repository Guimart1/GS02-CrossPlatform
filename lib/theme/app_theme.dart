import 'package:flutter/material.dart';

/// Identidade visual do GeoFluxo:
/// Fundo branco puro, sombras suaves em camadas e traços vetoriais ("riscos")
/// em azul-cobalto e ciano simulando fluxo hídrico, relevo e integração de dados.
class AppColors {
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);

  static const Color primary = Color(0xFF1D4ED8); // Azul-cobalto integração
  static const Color accent = Color(0xFF0EA5E9); // Ciano fluxo hídrico
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF475569);
  static const Color streakMuted = Color(0xFFCBD5E1);

  // Semântica de risco territorial
  static const Color low = Color(0xFF059669);
  static const Color moderate = Color(0xFFD97706);
  static const Color high = Color(0xFFEA580C);
  static const Color critical = Color(0xFFDC2626);
}

class AppTheme {
  static List<BoxShadow> softShadow({bool highContrast = false}) {
    if (highContrast) {
      return const [];
    }
    return [
      BoxShadow(
        color: AppColors.ink.withValues(alpha: 0.05),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static ThemeData light({bool highContrast = false}) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.canvas,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        primary: highContrast ? Colors.black : AppColors.primary,
        secondary: highContrast ? const Color(0xFF0369A1) : AppColors.accent,
        surface: AppColors.canvas,
        onSurface: highContrast ? Colors.black : AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: highContrast ? Colors.black : AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: highContrast ? Colors.black : AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        indicatorColor: (highContrast ? Colors.black : AppColors.primary)
            .withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (highContrast ? Colors.black : AppColors.primary)
                : AppColors.inkMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : AppColors.border,
            width: highContrast ? 1.8 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : AppColors.border,
            width: highContrast ? 1.8 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : AppColors.primary,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
