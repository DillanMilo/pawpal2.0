import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Minimal, soft color palette
  static const Color inkColor = Color(0xFF171717);
  static const Color primaryColor = Color(0xFF9D7BEA);
  static const Color primaryLight = Color(0xFFEFE7FF);
  static const Color primaryDark = Color(0xFF6D54B5);

  // Secondary - fresh mint
  static const Color secondaryColor = Color(0xFF69B99D);
  static const Color secondaryLight = Color(0xFFE9F9E7);
  static const Color secondaryDark = Color(0xFF327B69);

  // Accent Colors - muted service tones
  static const Color accentColor = Color(0xFFF2C94C);
  static const Color accentPeach = Color(0xFFEFA37A);
  static const Color accentLavender = Color(0xFFA88BEA);
  static const Color accentMint = Color(0xFF8DDDBD);
  static const Color accentRose = Color(0xFFE78DAE);

  // Status Colors
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF2C9F7B);
  static const Color warningColor = Color(0xFFE9B949);

  // Background - Soft & Clean
  static const Color backgroundColor = Color(0xFFFBFAFE);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E4EF);
  static const Color softLavender = Color(0xFFF2ECFF);
  static const Color softMint = Color(0xFFEAFBE6);
  static const Color softBlush = Color(0xFFFFEEF5);

  // Text Colors
  static const Color textPrimary = inkColor;
  static const Color textSecondary = Color(0xFF56525F);
  static const Color textLight = Color(0xFF918C9E);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA88BEA), Color(0xFFEFE7FF)],
  );

  static const LinearGradient playfulGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAFBE6), Color(0xFFF2ECFF)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEEF5), Color(0xFFFFF4DC)],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE7F8FF), Color(0xFFEAFBE6)],
  );

  // Pet Category Colors - Vibrant but harmonious
  static const Map<String, Color> petCategoryColors = {
    'Dog': Color(0xFF9D7BEA),
    'Cat': Color(0xFFE78DAE),
    'Bird': Color(0xFFF2C94C),
    'Fish': Color(0xFF69B99D),
    'Rabbit': Color(0xFFEFA37A),
    'Hamster': Color(0xFFA88BEA),
    'Guinea Pig': Color(0xFF8DDDBD),
    'Reptile': Color(0xFF6D54B5),
    'Other': Color(0xFFB8B3C7),
  };

  // Activity Type Colors
  static const Map<String, Color> activityColors = {
    'Walk': Color(0xFF69B99D),
    'Play': Color(0xFFF2C94C),
    'Train': Color(0xFF9D7BEA),
    'Feed': Color(0xFF8DDDBD),
    'Groom': Color(0xFFEFA37A),
    'Vet Visit': Color(0xFFFF5252),
    'Social': Color(0xFF74B9FF),
    'Rest': Color(0xFFEDF1F7),
  };

  // Box Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF171717).withValues(alpha: 0.05),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF171717).withValues(alpha: 0.09),
      blurRadius: 34,
      offset: const Offset(0, 16),
    ),
  ];

  // Borders
  static Border get thickBorder =>
      Border.all(color: const Color(0xFFE8E4EF), width: 1.2);

  static Border get thinBorder => Border.all(color: dividerColor, width: 1.0);

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.16),
      blurRadius: 22,
      offset: const Offset(0, 10),
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
        surfaceContainerLowest: backgroundColor,
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
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: dividerColor, width: 1.4),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: dividerColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
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
        backgroundColor: inkColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkCard = Color(0xFF252536);
  static const Color darkDivider = Color(0xFF2E2E42);
  static const Color darkTextPrimary = Color(0xFFF1F1F3);
  static const Color darkTextSecondary = Color(0xFFB0B0C0);
  static const Color darkTextLight = Color(0xFF8888A0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: darkSurface,
        surfaceContainerLowest: darkBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: primaryLight, width: 2.5),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: darkDivider, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryLight, width: 2.5),
        ),
        hintStyle: GoogleFonts.outfit(color: darkTextLight, fontSize: 16),
        labelStyle: GoogleFonts.outfit(color: darkTextSecondary, fontSize: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextLight,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    final colors =
        widget.colors ??
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
              stops: [0.0, 0.5 + (_controller.value * 0.2), 1.0],
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
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}
