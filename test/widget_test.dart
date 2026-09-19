import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecowell/app.dart';
import 'package:ecowell/data/local_store.dart';
import 'package:ecowell/providers/app_providers.dart';

void main() {
  testWidgets('app shows login screen when unauthenticated',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore(prefs)),
        ],
        child: const EcoWellApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('EcoWell'), findsWidgets);
  });
}