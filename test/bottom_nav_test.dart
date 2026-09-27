import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecowell/features/shared/ecowell_ai_mascot.dart';
import 'package:ecowell/features/shared/ecowell_bottom_nav.dart';

void main() {
  testWidgets('EcoWellBottomNav renders the tabs and the center FAB',
      (WidgetTester tester) async {
    int selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: EcoWellBottomNav(
            currentIndex: selectedTab,
            onTabSelected: (index) {
              selectedTab = index;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);

    // The mascot is draggable, so it lives in a screen-wide overlay instead of
    // inside the nav's bounded Stack, where it could not be moved freely.
    expect(find.byType(EcoWellAiButton), findsNothing);
    expect(find.byType(EcoWellAiMascotIcon), findsNothing);

    // Tap on Explore/Nature tab (index 1)
    await tester.tap(find.byIcon(Icons.eco_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selectedTab, 1);

    // Tap on Map tab (index 2)
    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selectedTab, 2);

    // Tap on Dashboard tab (index 3)
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selectedTab, 3);
  });
}
