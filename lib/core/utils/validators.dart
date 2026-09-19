import 'package:flutter/services.dart';

import '../config/app_config.dart';

class Validators {
  Validators._();

  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your age';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Enter a valid age';
    if (age < AppConfig.minAge) return 'You must be at least ${AppConfig.minAge} years old';
    if (age > AppConfig.maxAge) return 'Maximum age is ${AppConfig.maxAge}';
    return null;
  }

  static List<TextInputFormatter> get ageFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ];
}