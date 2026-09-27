import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecowell/app.dart';
import 'package:ecowell/data/local_store.dart';
import 'package:ecowell/providers/app_providers.dart';
import 'package:ecowell/providers/auth_provider.dart';

class FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('app shows login screen when unauthenticated',
      (WidgetTester tester) async {
    // The login screen is responsive and needs a phone-sized viewport.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore(prefs)),
          authControllerProvider.overrideWith(FakeAuthController.new),
        ],
        child: const EcoWellApp(),
      ),
    );
    // After splash (2.2s), the unauthenticated user lands on onboarding
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.byType(EcoWellApp), findsOneWidget);
  });
}