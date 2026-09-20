class AppConfig {
  AppConfig._();

  static const String googleMapsApiKey = '';
  static const String geminiApiKey = '';
  static const String openWeatherApiKey = '';
  static const String appName = 'EcoWell';

  /// Default geofence radius in meters. Individual places can override this
  /// via `GreenSpace.radiusMeters` (see lib/data/seed_data.dart).
  static const double geofenceRadiusMeters = 150;
  static const int minAge = 18;
  static const int maxAge = 60;

  static const double defaultLatitude = 6.9532;
  static const double defaultLongitude = 126.2157;
}
