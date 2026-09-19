import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visit.dart';
import 'visits_provider.dart';

final currentStreakProvider = Provider<int>((ref) {
  final visits = ref.watch(visitsProvider).value ?? const <Visit>[];
  return computeVisitStreak(visits);
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