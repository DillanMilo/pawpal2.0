import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/theme.dart';

/// A quiet, fixed backdrop for the home dashboard.
///
/// The pattern intentionally stays behind the scrolling content so it adds
/// personality in the open space without competing with cards or controls.
class HomeBackdrop extends StatelessWidget {
  final Widget child;

  const HomeBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0, 0.34, 0.72, 1],
              colors: isDark
                  ? const [
                      Color(0xFF1A1626),
                      AppTheme.darkBackground,
                      Color(0xFF12191A),
                      AppTheme.darkBackground,
                    ]
                  : const [
                      Color(0xFFF2ECFF),
                      AppTheme.backgroundColor,
                      Color(0xFFF2FAF7),
                      AppTheme.backgroundColor,
                    ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const Key('home-background-pattern'),
                  painter: _HomePatternPainter(isDark: isDark),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _HomePatternPainter extends CustomPainter {
  final bool isDark;

  const _HomePatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? AppTheme.primaryLight : AppTheme.primaryDark)
          .withValues(alpha: isDark ? 0.075 : 0.05);
    final orbitPaint = Paint()
      ..color = (isDark ? AppTheme.accentMint : AppTheme.secondaryColor)
          .withValues(alpha: isDark ? 0.07 : 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const spacing = 38.0;
    for (var row = 0; row * spacing < size.height; row++) {
      final y = 24.0 + (row * spacing);
      final stagger = row.isEven ? 0.0 : spacing / 2;
      for (var column = 0; column * spacing < size.width; column++) {
        if ((row + column) % 3 != 0) continue;
        final x = 20.0 + stagger + (column * spacing);
        canvas.drawCircle(Offset(x, y), row.isEven ? 1.35 : 1.05, dotPaint);
      }
    }

    canvas.drawCircle(
      Offset(size.width + 18, size.height * 0.2),
      112,
      orbitPaint,
    );
    canvas.drawCircle(Offset(-38, size.height * 0.72), 84, orbitPaint);

    final pawPaint = Paint()
      ..color = (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
          .withValues(alpha: isDark ? 0.085 : 0.06);
    _drawPaw(
      canvas,
      Offset(size.width * 0.88, size.height * 0.38),
      0.9,
      -0.28,
      pawPaint,
    );
    _drawPaw(
      canvas,
      Offset(size.width * 0.12, size.height * 0.58),
      0.72,
      0.22,
      pawPaint,
    );
    _drawPaw(
      canvas,
      Offset(size.width * 0.78, size.height * 0.84),
      0.62,
      -0.12,
      pawPaint,
    );
  }

  void _drawPaw(
    Canvas canvas,
    Offset center,
    double scale,
    double rotation,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(scale);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 7), width: 22, height: 18),
      paint,
    );
    for (final toe in const [
      Offset(-10, -7),
      Offset(-3.5, -12),
      Offset(4.5, -12),
      Offset(11, -6),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: toe, width: 7, height: 9), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomePatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class HomeHeroPattern extends StatelessWidget {
  const HomeHeroPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(painter: _HomeHeroPatternPainter()),
      ),
    );
  }
}

class _HomeHeroPatternPainter extends CustomPainter {
  const _HomeHeroPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pawPaint = Paint()..color = Colors.white.withValues(alpha: 0.12);

    final trail = Path()
      ..moveTo(size.width * 0.56, size.height * 0.18)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.02,
        size.width * 0.8,
        size.height * 0.48,
        size.width * 1.04,
        size.height * 0.28,
      );
    canvas.drawPath(trail, linePaint);

    _drawPaw(
      canvas,
      Offset(size.width * 0.72, size.height * 0.2),
      0.48,
      -0.3,
      pawPaint,
    );
    _drawPaw(
      canvas,
      Offset(size.width * 0.88, size.height * 0.44),
      0.62,
      0.18,
      pawPaint,
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.09);
    for (var index = 0; index < 6; index++) {
      final angle = (math.pi * 2 / 6) * index;
      final center = Offset(
        size.width * 0.92 + math.cos(angle) * 38,
        size.height * 0.82 + math.sin(angle) * 38,
      );
      canvas.drawCircle(center, 2, dotPaint);
    }
  }

  void _drawPaw(
    Canvas canvas,
    Offset center,
    double scale,
    double rotation,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(scale);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 7), width: 22, height: 18),
      paint,
    );
    for (final toe in const [
      Offset(-10, -7),
      Offset(-3.5, -12),
      Offset(4.5, -12),
      Offset(11, -6),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: toe, width: 7, height: 9), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
