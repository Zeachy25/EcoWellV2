import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecowell/features/explore/explore_map_screen.dart';

void main() {
  testWidgets('ExploreMapScreen renders search bar, controls, and recommended cards without exceptions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ExploreMapScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify search bar and placeholder
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Find a calm space...'), findsOneWidget);

    // Verify Recommended for You header
    expect(find.text('Recommended for You'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);

    // Verify place card text
    expect(find.text('Guang-guang Mangrove Park and Nursery'), findsOneWidget);
  });
}
