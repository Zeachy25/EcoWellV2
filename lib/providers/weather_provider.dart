import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/services/weather_service.dart';
import '../data/services/location_tracking_service.dart';
import '../models/weather.dart';
import '../models/weather_forecast_day.dart';
import 'location_tracking_provider.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(AppConfig.openWeatherApiKey);
});

Future<(double, double)> _currentCoordinates(
  LocationTrackingService locationService,
) async {
  final position = await locationService.currentPosition();
  if (position == null) {
    return (AppConfig.defaultLatitude, AppConfig.defaultLongitude);
  }
  return (position.latitude, position.longitude);
}

final weatherProvider = FutureProvider<Weather?>((ref) async {
  if (AppConfig.openWeatherApiKey.isEmpty) return null;
  final locationService = ref.watch(locationTrackingServiceProvider);
  final (latitude, longitude) = await _currentCoordinates(locationService);
  final service = ref.watch(weatherServiceProvider);
  return service.fetchCurrent(latitude: latitude, longitude: longitude);
});

final weatherForecastProvider =
    FutureProvider<List<WeatherForecastDay>>((ref) async {
  if (AppConfig.openWeatherApiKey.isEmpty) return const [];
  final locationService = ref.watch(locationTrackingServiceProvider);
  final (latitude, longitude) = await _currentCoordinates(locationService);
  final service = ref.watch(weatherServiceProvider);
  return service.fetchForecast(latitude: latitude, longitude: longitude);
});