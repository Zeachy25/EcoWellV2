import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visit.dart';
import 'visits_provider.dart';

class WeeklyStreakDay {
  final String label;
  final DateTime date;
  final bool isCompleted;
  final bool isToday;
  final bool isPast;

  const WeeklyStreakDay({
    required this.label,
    required this.date,
    required this.isCompleted,
    required this.isToday,
    required this.isPast,
  });
}

final currentStreakProvider = Provider<int>((ref) {
  final visits = ref.watch(visitsProvider).value ?? const <Visit>[];
  return computeVisitStreak(visits);
});

final weeklyStreakProvider = Provider<List<WeeklyStreakDay>>((ref) {
  final visits = ref.watch(visitsProvider).value ?? const <Visit>[];
  return computeWeeklyStreak(visits);
});

int computeVisitStreak(List<Visit> visits) {
  if (visits.isEmpty) return 0;
  final dates = visits
      .map((v) => DateUtils.dateOnly(v.startTime))
      .toSet();
  final today = DateUtils.dateOnly(DateTime.now());
  var day = today;
  if (!dates.contains(today)) {
    day = today.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (dates.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

List<WeeklyStreakDay> computeWeeklyStreak(List<Visit> visits, [DateTime? now]) {
  final current = now ?? DateTime.now();
  final today = DateUtils.dateOnly(current);
  // Dart DateTime.weekday: 1 = Monday, 7 = Sunday
  final monday = today.subtract(Duration(days: current.weekday - 1));

  final visitedDates = visits
      .map((v) => DateUtils.dateOnly(v.startTime))
      .toSet();

  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return List.generate(7, (i) {
    final dayDate = monday.add(Duration(days: i));
    final isToday = dayDate == today;
    final isCompleted = visitedDates.contains(dayDate);
    final isPast = dayDate.isBefore(today);

    return WeeklyStreakDay(
      label: labels[i],
      date: dayDate,
      isCompleted: isCompleted,
      isToday: isToday,
      isPast: isPast,
    );
  });
}