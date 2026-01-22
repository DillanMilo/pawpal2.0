import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Fun & Modern Color Palette
  static const Color primaryColor = Color(0xFF7B61FF); // Vibrant Purple
  static const Color primaryLight = Color(0xFF9E8BFF);
  static const Color primaryDark = Color(0xFF5A41D9);

  // Secondary - Playful Mint/Teal
  static const Color secondaryColor = Color(0xFF00D2B4);
  static const Color secondaryLight = Color(0xFF33DBC3);
  static const Color secondaryDark = Color(0xFF00A68F);

  // Accent Colors - Energetic & Warm
  static const Color accentColor = Color(0xFFFFD541); // Bright Yellow
  static const Color accentPeach = Color(0xFFFF9F87);
  static const Color accentLavender = Color(0xFFB19DFF);
  static const Color accentMint = Color(0xFF98FFD9);
  static const Color accentRose = Color(0xFFFF7EB3);

  // Status Colors
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF00D2B4);
  static const Color warningColor = Color(0xFFFFD541);

  // Background - Soft & Clean
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFEDF1F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6C727A);
  static const Color textLight = Color(0xFFA9B0B8);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B61FF), Color(0xFF9E8BFF)],
  );

  static const LinearGradient playfulGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B61FF), Color(0xFF00D2B4)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7EB3), Color(0xFFFFD541)],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D2B4), Color(0xFF00A68F)],
  );

  // Pet Category Colors - Vibrant but harmonious
  static const Map<String, Color> petCategoryColors = {
    'Dog': Color(0xFF7B61FF),
    'Cat': Color(0xFFFF7EB3),
    'Bird': Color(0xFFFFD541),
    'Fish': Color(0xFF00D2B4),
    'Rabbit': Color(0xFFFF9F87),
    'Hamster': Color(0xFFB19DFF),
    'Guinea Pig': Color(0xFF98FFD9),
    'Reptile': Color(0xFF5A41D9),
    'Other': Color(0xFFEDF1F7),
  };

  // Activity Type Colors
  static const Map<String, Color> activityColors = {
    'Walk': Color(0xFF00D2B4),
    'Play': Color(0xFFFFD541),
    'Train': Color(0xFF7B61FF),
    'Feed': Color(0xFF98FFD9),
    'Groom': Color(0xFFFF9F87),
    'Vet Visit': Color(0xFFFF5252),
    'Social': Color(0xFF74B9FF),
    'Rest': Color(0xFFEDF1F7),
  };

  // Box Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF7B61FF).withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: const Color(0xFF7B61FF).withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  // Borders
  static Border get thickBorder => Border.all(
        color: Colors.black,
        width: 2.5,
      );

  static Border get thinBorder => Border.all(
        color: dividerColor,
        width: 1.5,
      );

  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: primaryColor, width: 2.5),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: dividerColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        hintStyle: GoogleFonts.outfit(color: textLight, fontSize: 16),
        labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

// Custom animated gradient background widget
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          const Color(0xFFFFFBF5),
          const Color(0xFFFFE8D6),
          const Color(0xFFFFF5EE),
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(
                0.5 + (_controller.value * 0.5),
                1.0 + (_controller.value * 0.2),
              ),
              colors: colors,
              stops: [
                0.0,
                0.5 + (_controller.value * 0.2),
                1.0,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Glassmorphism card decoration
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}
