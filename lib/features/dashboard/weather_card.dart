import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/weather_service.dart';
import '../../models/weather.dart';
import '../../providers/weather_provider.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/weather'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: weatherAsync.when(
            loading: () => const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading weather...'),
              ],
            ),
            error: (e, _) => _WeatherFallback(
              message: 'Weather is unavailable right now.',
              onRetry: () => ref.invalidate(weatherProvider),
            ),
            data: (weather) {
              if (weather == null) {
                return const _WeatherFallback(
                  message: 'Weather service not configured.',
                );
              }
              return _WeatherHeader(weather: weather);
            },
          ),
        ),
      ),
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  final Weather weather;

  const _WeatherHeader({required this.weather});

  @override
  Widget build(BuildContext context) {
    final icon = weather.isRainy
        ? Icons.umbrella
        : weather.isClear
            ? Icons.wb_sunny
            : weather.isCloudy
                ? Icons.cloud
                : Icons.cloud_queue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place, size: 16, color: Color(0xFF2E7D32)),
            SizedBox(width: 4),
            Text(
              'Mati City',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFEF6C00)),
            const SizedBox(width: 12),
            Text(
              '${weather.tempC.round()}°C',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                weather.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          weatherSuggestion(weather),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _WeatherFallback extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _WeatherFallback({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cloud_off, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (onRetry != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRetry,
            tooltip: 'Retry',
          ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }
}