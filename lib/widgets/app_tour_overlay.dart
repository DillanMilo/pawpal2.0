import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/theme.dart';

class AppTourStep {
  const AppTourStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class AppTourOverlay extends StatefulWidget {
  const AppTourOverlay({
    super.key,
    required this.steps,
    required this.anchorKeys,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final List<AppTourStep> steps;
  final List<GlobalKey> anchorKeys;
  final int currentStep;
  final Future<void> Function() onNext;
  final Future<void> Function() onBack;
  final Future<void> Function() onSkip;

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay> {
  final _cardFocus = FocusNode(debugLabel: 'App tour card');
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _requestFocus();
  }

  @override
  void didUpdateWidget(covariant AppTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) _requestFocus();
  }

  @override
  void dispose() {
    _cardFocus.dispose();
    super.dispose();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cardFocus.requestFocus();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    await action();
    if (mounted) setState(() => _working = false);
  }

  Rect? _anchorRect(Size viewport) {
    if (widget.currentStep >= widget.anchorKeys.length) return null;
    final context = widget.anchorKeys[widget.currentStep].currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    try {
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final visible = rect.intersect(Offset.zero & viewport);
      if (visible.width < 20 || visible.height < 20) return null;
      return rect.inflate(7);
    } on AssertionError {
      // An anchor can exist one frame before an ancestor has completed layout.
      // The centered card is the safe fallback for that frame.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[widget.currentStep];
    final isLast = widget.currentStep == widget.steps.length - 1;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final anchor = _anchorRect(viewport);
          final safeTop = MediaQuery.paddingOf(context).top + 16;
          final safeBottom = MediaQuery.paddingOf(context).bottom + 16;
          final cardWidth = math.min(380.0, viewport.width - 32);
          const estimatedCardHeight = 276.0;
          final left = anchor == null
              ? (viewport.width - cardWidth) / 2
              : (anchor.center.dx - cardWidth / 2).clamp(
                  16.0,
                  viewport.width - cardWidth - 16,
                );
          final availableAbove = anchor == null ? 0.0 : anchor.top - safeTop;
          final top =
              anchor != null && availableAbove > estimatedCardHeight + 18
              ? anchor.top - estimatedCardHeight - 18
              : ((viewport.height - estimatedCardHeight) / 2).clamp(
                  safeTop,
                  viewport.height - estimatedCardHeight - safeBottom,
                );

          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _SpotlightPainter(anchor)),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: cardWidth,
                  child: Semantics(
                    scopesRoute: true,
                    explicitChildNodes: true,
                    liveRegion: true,
                    label:
                        'PawPal tour, step ${widget.currentStep + 1} of ${widget.steps.length}',
                    child: Focus(
                      focusNode: _cardFocus,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground(context),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.actionBlueGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(step.icon, color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.currentStep + 1} / ${widget.steps.length}',
                                  style: TextStyle(
                                    color: AppTheme.secondaryText(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    height: 1.45,
                                    color: AppTheme.secondaryText(context),
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < widget.steps.length;
                                  index++
                                )
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: index == widget.currentStep ? 22 : 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: index == widget.currentStep
                                          ? AppTheme.primaryColor
                                          : AppTheme.primaryColor.withValues(
                                              alpha: 0.2,
                                            ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 44),
                                  ),
                                  onPressed: _working
                                      ? null
                                      : () => _run(widget.onSkip),
                                  child: const Text('Skip tour'),
                                ),
                                const Spacer(),
                                if (widget.currentStep > 0)
                                  IconButton(
                                    tooltip: 'Previous tour step',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 42,
                                      height: 44,
                                    ),
                                    onPressed: _working
                                        ? null
                                        : () => _run(widget.onBack),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: _working
                                      ? null
                                      : () => _run(widget.onNext),
                                  child: Text(isLast ? 'Finish' : 'Next'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.spotlight);

  final Rect? spotlight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (spotlight != null) {
      path.addRRect(
        RRect.fromRectAndRadius(spotlight!, const Radius.circular(22)),
      );
      path.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = const Color(0xB8171420));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.spotlight != spotlight;
}
