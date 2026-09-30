import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecowell/data/local_store.dart';
import 'package:ecowell/features/streak/daily_streak_dialog.dart';
import 'package:ecowell/features/streak/widgets/confetti_overlay.dart';
import 'package:ecowell/features/streak/widgets/streak_flame_painter.dart';
import 'package:ecowell/models/visit.dart';
import 'package:ecowell/providers/app_providers.dart';
import 'package:ecowell/providers/streak_provider.dart';

void main() {
  group('Weekly Streak Computation', () {
    test('computeWeeklyStreak correctly identifies 7 days and completed visits', () {
      final now = DateTime(2026, 9, 28); // A Monday
      final monday = DateTime(2026, 9, 28, 10, 0);
      final wednesday = DateTime(2026, 9, 30, 14, 0);

      final visits = [
        Visit(
          id: 'v-1',
          greenSpaceId: 'gs-1',
          greenSpaceName: 'Dahican Beach',
          latitude: 6.95,
          longitude: 126.25,
          startTime: monday,
          endTime: monday.add(const Duration(minutes: 30)),
          preScore: 10,
          postScore: 4,
          stressReduction: 6,
          quietRating: 5,
          preAnswers: const [2, 2, 2, 2],
          postAnswers: const [1, 1, 1, 1],
        ),
        Visit(
          id: 'v-2',
          greenSpaceId: 'gs-1',
          greenSpaceName: 'Dahican Beach',
          latitude: 6.95,
          longitude: 126.25,
          startTime: wednesday,
          endTime: wednesday.add(const Duration(minutes: 30)),
          preScore: 10,
          postScore: 4,
          stressReduction: 6,
          quietRating: 5,
          preAnswers: const [2, 2, 2, 2],
          postAnswers: const [1, 1, 1, 1],
        ),
      ];

      final days = computeWeeklyStreak(visits, now);

      expect(days.length, 7);
      expect(days[0].label, 'Mon');
      expect(days[0].isCompleted, isTrue);
      expect(days[0].isToday, isTrue);

      expect(days[1].label, 'Tue');
      expect(days[1].isCompleted, isFalse);

      expect(days[2].label, 'Wed');
      expect(days[2].isCompleted, isTrue);

      expect(days[6].label, 'Sun');
      expect(days[6].isCompleted, isFalse);
    });
  });

  group('Daily Streak Dialog Widget Tests', () {
    testWidgets('renders flame, DAY label, weekly 7-day card, and confetti', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(LocalStore(prefs)),
            currentStreakProvider.overrideWithValue(1),
          ],
          child: const MaterialApp(
            home: DailyStreakDialog(streakOverride: 1),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify flame widget and painter
      expect(find.byType(StreakFlameWidget), findsOneWidget);
      expect(find.byType(ConfettiOverlay), findsOneWidget);

      // Verify "DAY" label
      expect(find.text('DAY'), findsOneWidget);

      // Verify 7-day week labels
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Verify motivational text
      expect(find.text('Nice work!'), findsOneWidget);
      expect(find.text("Let's make it Day 2 tomorrow"), findsOneWidget);

      // Verify action button
      expect(find.text('Awesome, Keep Going!'), findsOneWidget);
    });

    testWidgets('renders DAYS label when streak is greater than 1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(LocalStore(prefs)),
            currentStreakProvider.overrideWithValue(5),
          ],
          child: const MaterialApp(
            home: DailyStreakDialog(streakOverride: 5),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('You are on fire!'), findsOneWidget);
      expect(find.text("Let's make it Day 6 tomorrow"), findsOneWidget);
    });
  });
}
