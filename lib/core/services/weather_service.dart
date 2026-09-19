import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/weather.dart';
import '../../models/weather_forecast_day.dart';

class WeatherService {
  final String apiKey;

  WeatherService(this.apiKey);

  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Weather> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather request failed (${response.statusCode})');
    }
    return Weather.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<WeatherForecastDay>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Forecast request failed (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['list'] as List<dynamic>? ?? const [];

    final byDay = <String, WeatherForecastDay>{};
    for (final entry in list) {
      final item = entry as Map<String, dynamic>;
      final dt = DateTime.tryParse(item['dt_txt'] as String? ?? '');
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month}-${dt.day}';
      final temp = ((item['main'] as Map<String, dynamic>?)?['temp'] as num?)
          ?.toDouble() ?? 0;
      final conditionList = item['weather'] as List<dynamic>? ?? const [];
      final condition = conditionList.isNotEmpty
          ? (conditionList.first as Map<String, dynamic>)['main'] as String?
          : null;
      final existing = byDay[key];
      if (existing == null || temp > existing.tempC) {
        byDay[key] = WeatherForecastDay(
          date: dt,
          tempC: temp,
          condition: condition ?? 'Unknown',
        );
      }
    }

    final days = byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return days.take(5).toList();
  }
}

String weatherSuggestion(Weather weather) {
  if (weather.isRainy) {
    return 'Rain expected. Choose a green space with shelter or bring an umbrella.';
  }
  if (weather.isClear) {
    return 'Clear skies — a perfect time for a relaxing nature visit.';
  }
  if (weather.isCloudy) {
    return 'Mild, cloudy conditions are comfortable for an outdoor walk.';
  }
  return 'Check conditions before heading out and dress for the weather.';
}