import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/place_review.dart';
import '../models/visit.dart';

class LocalStore {
  static const _userKey = 'ecowell_user_v1';
  static const _visitsKey = 'ecowell_visits_v1';
  static const _reminderKey = 'ecowell_daily_reminder_v1';
  static const _reviewsKey = 'ecowell_user_reviews_v1';

  final SharedPreferences _prefs;

  LocalStore(this._prefs);

  AppUser? get currentUser {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  List<Visit> getVisits() {
    final raw = _prefs.getString(_visitsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Visit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveVisits(List<Visit> visits) async {
    await _prefs.setString(
      _visitsKey,
      jsonEncode(visits.map((v) => v.toJson()).toList()),
    );
  }

  bool get dailyReminderEnabled =>
      _prefs.getBool(_reminderKey) ?? false;

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _prefs.setBool(_reminderKey, enabled);
  }

  List<PlaceReview> getUserReviews() {
    final raw = _prefs.getString(_reviewsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addUserReview(PlaceReview review) async {
    final reviews = getUserReviews()..add(review);
    await _prefs.setString(
      _reviewsKey,
      jsonEncode(reviews.map((r) => r.toJson()).toList()),
    );
  }
}