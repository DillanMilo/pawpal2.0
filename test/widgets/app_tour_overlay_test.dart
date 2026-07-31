import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/widgets/app_tour_overlay.dart';

void main() {
  const steps = [
    AppTourStep(
      title: 'Home base',
      description: 'Everything for today.',
      icon: Icons.home,
    ),
    AppTourStep(
      title: 'Pet profile',
      description: 'Care details live here.',
      icon: Icons.pets,
    ),
  ];

  testWidgets('supports Next, Back, progress, and Skip', (tester) async {
    final firstAnchor = GlobalKey();
    final secondAnchor = GlobalKey();
    var current = 0;
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(key: firstAnchor, width: 64, height: 64),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(key: secondAnchor, width: 64, height: 64),
                ),
                AppTourOverlay(
                  steps: steps,
                  anchorKeys: [firstAnchor, secondAnchor],
                  currentStep: current,
                  onNext: () async => setState(() => current = 1),
                  onBack: () async => setState(() => current = 0),
                  onSkip: () async => setState(() => skipped = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home base'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pet profile'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous tour step'));
    await tester.pumpAndSettle();
    expect(find.text('Home base'), findsOneWidget);

    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(skipped, isTrue);
  });

  testWidgets('uses a safe centered fallback when an anchor is unavailable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AppTourOverlay(
                steps: steps,
                anchorKeys: [GlobalKey(), GlobalKey()],
                currentStep: 0,
                onNext: () async {},
                onBack: () async {},
                onSkip: () async {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home base'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
