class AppConfig {
  AppConfig._();

  static const String googleMapsApiKey = '';
  static const String geminiApiKey = '';
  static const String openWeatherApiKey = '';
  static const String appName = 'EcoWell';

  /// OpenRouteService API key for foot-walking route polylines (free tier at
  /// openrouteservice.org). When empty or on request failure the app falls
  /// back to a straight-line route between origin and destination.
  static const String openRouteServiceApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImE1NTU3Y2M4ZDM1NTRkZjg5MDA4YmIwYmVmNGI0MzAyIiwiaCI6Im11cm11cjY0In0=';

  /// Default geofence radius in meters. Per-place circles can override this
  /// via `GreenSpace.radiusMeters`; exact shapes are set via
  /// `GreenSpace.polygonVertices` (see lib/data/seed_data.dart).
  static const double geofenceRadiusMeters = 150;
  static const int minAge = 18;
  static const int maxAge = 60;

  static const double defaultLatitude = 6.9532;
  static const double defaultLongitude = 126.2157;
}
