import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/config/app_config.dart';
import '../core/services/weather_service.dart';
import '../models/weather.dart';
import '../models/weather_forecast_day.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(AppConfig.openWeatherApiKey);
});

Future<(double, double)> _currentCoordinates() async {
  var latitude = AppConfig.defaultLatitude;
  var longitude = AppConfig.defaultLongitude;
  try {
    final position = await Geolocator.getCurrentPosition();
    latitude = position.latitude;
    longitude = position.longitude;
  } catch (_) {}
  return (latitude, longitude);
}

final weatherProvider = FutureProvider<Weather?>((ref) async {
  if (AppConfig.openWeatherApiKey.isEmpty) return null;
  final (latitude, longitude) = await _currentCoordinates();
  final service = ref.watch(weatherServiceProvider);
  return service.fetchCurrent(latitude: latitude, longitude: longitude);
});

final weatherForecastProvider =
    FutureProvider<List<WeatherForecastDay>>((ref) async {
  if (AppConfig.openWeatherApiKey.isEmpty) return const [];
  final (latitude, longitude) = await _currentCoordinates();
  final service = ref.watch(weatherServiceProvider);
  return service.fetchForecast(latitude: latitude, longitude: longitude);
});