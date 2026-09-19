class Weather {
  final double tempC;
  final double feelsLikeC;
  final int humidity;
  final double windMps;
  final String condition;
  final String description;

  const Weather({
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windMps,
    required this.condition,
    required this.description,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? const {};
    final weatherList = json['weather'] as List<dynamic>? ?? const [];
    final wind = json['wind'] as Map<String, dynamic>? ?? const {};
    return Weather(
      tempC: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windMps: (wind['speed'] as num?)?.toDouble() ?? 0,
      condition: (weatherList.isNotEmpty
              ? (weatherList.first as Map<String, dynamic>)['main'] as String?
              : null) ??
          'Unknown',
      description: (weatherList.isNotEmpty
              ? (weatherList.first as Map<String, dynamic>)['description'] as String?
              : null) ??
          '',
    );
  }

  bool get isRainy =>
      condition == 'Rain' || condition == 'Drizzle' || condition == 'Thunderstorm';
  bool get isClear => condition == 'Clear';
  bool get isCloudy => condition == 'Clouds' || condition == 'Mist' || condition == 'Fog';
}