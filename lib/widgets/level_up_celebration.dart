import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/pet_progression.dart';
import '../utils/theme.dart';

Future<void> showLevelUpCelebration(
  BuildContext context, {
  required String petName,
  required PetLevelUpTransition transition,
}) async {
  await HapticFeedback.lightImpact();
  if (!context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: 260.ms,
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
    pageBuilder: (_, _, _) =>
        _LevelUpCelebration(petName: petName, transition: transition),
  );
}

class _LevelUpCelebration extends StatefulWidget {
  const _LevelUpCelebration({required this.petName, required this.transition});

  final String petName;
  final PetLevelUpTransition transition;

  @override
  State<_LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<_LevelUpCelebration> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 4), _close);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.transition.unlockedRewards;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.homeHeroGradient),
        child: SafeArea(
          child: Stack(
            children: [
              for (final burst in _bursts)
                Align(
                  alignment: burst.alignment,
                  child: Icon(burst.icon, color: burst.color, size: burst.size)
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 350.ms)
                      .then(delay: 280.ms)
                      .fadeOut(duration: 650.ms)
                      .scale(
                        begin: const Offset(0.35, 0.35),
                        end: const Offset(1.35, 1.35),
                        duration: 1000.ms,
                        curve: Curves.easeOut,
                      )
                      .rotate(begin: -0.12, end: 0.12, duration: 1000.ms),
                ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.accentColor,
                            size: 54,
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.2, 0.2),
                            duration: 650.ms,
                            curve: Curves.elasticOut,
                          )
                          .rotate(begin: -0.15, end: 0),
                      const SizedBox(height: 16),
                      const Text(
                        'LEVEL UP!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${widget.petName} reached Level ${widget.transition.newLevel}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.transition.title,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (unlocked.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'NEW REWARD',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${unlocked.first.emoji ?? '✨'} ${unlocked.first.name}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (unlocked.length > 1)
                                Text(
                                  '+${unlocked.length - 1} more unlocked',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      FilledButton(
                        onPressed: _close,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 34,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Keep caring'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Burst {
  const _Burst(this.alignment, this.icon, this.color, this.size);

  final Alignment alignment;
  final IconData icon;
  final Color color;
  final double size;
}

const _bursts = [
  _Burst(Alignment(-0.82, -0.78), Icons.star_rounded, Color(0xFFF2C94C), 32),
  _Burst(Alignment(0.76, -0.72), Icons.auto_awesome, Color(0xFF8DDDBD), 30),
  _Burst(Alignment(-0.7, -0.18), Icons.circle, Color(0xFFE78DAE), 16),
  _Burst(Alignment(0.82, -0.08), Icons.star_rounded, Color(0xFFEFA37A), 24),
  _Burst(Alignment(-0.76, 0.58), Icons.auto_awesome, Color(0xFFA88BEA), 26),
  _Burst(Alignment(0.72, 0.68), Icons.circle, Color(0xFF4FB8FF), 18),
];
