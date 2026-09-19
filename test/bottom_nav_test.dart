import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecowell/features/shared/ecowell_bottom_nav.dart';

void main() {
  testWidgets('EcoWellBottomNav renders tabs and center FAB with expected icons',
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

    // Tap on Explore/Nature tab (index 1)
    await tester.tap(find.byIcon(Icons.eco_rounded));
    await tester.pumpAndSettle();
    expect(selectedTab, 1);

    // Tap on Map tab (index 2)
    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pumpAndSettle();
    expect(selectedTab, 2);

    // Tap on Dashboard tab (index 3)
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(selectedTab, 3);
  });
}
