import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/theme.dart';

enum SocialAuthProvider { google, apple }

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.provider,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final SocialAuthProvider provider;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == SocialAuthProvider.apple;
    final isDark = AppTheme.isDark(context);
    final backgroundColor = isApple
        ? (isDark ? Colors.white : const Color(0xFF050505))
        : AppTheme.cardBackground(context);
    final foregroundColor = isApple
        ? (isDark ? const Color(0xFF050505) : Colors.white)
        : AppTheme.primaryText(context);
    final borderColor = isApple
        ? (isDark ? Colors.white : const Color(0xFF050505))
        : (isDark ? AppTheme.darkDivider : const Color(0xFFDADCE0));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? const []
            : [
                BoxShadow(
                  color: const Color(
                    0xFF171717,
                  ).withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        height: compact ? 44 : 58,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.55),
            side: BorderSide(color: borderColor, width: 1.2),
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: compact ? 20 : 24,
                  child: isApple
                      ? Icon(
                          Icons.apple,
                          color: foregroundColor,
                          size: compact ? 22 : 26,
                        )
                      : SvgPicture.asset(
                          'assets/icons/google_g.svg',
                          semanticsLabel: 'Google',
                        ),
                ),
              ),
              Text(
                compact
                    ? (isApple ? 'Apple' : 'Google')
                    : (isApple
                          ? 'Continue with Apple'
                          : 'Continue with Google'),
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
