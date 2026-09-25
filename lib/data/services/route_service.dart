import 'dart:async';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// A foot-walking route returned by OpenRouteService.
class OrsRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const OrsRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// OpenRouteService routing profiles.
enum OrsProfile {
  drivingCar('driving-car'),
  footWalking('foot-walking');

  final String value;
  const OrsProfile(this.value);
}

/// OpenRouteService route preference ("shortest" minimizes distance and uses
/// the road/highway network of the profile).
enum OrsPreference {
  recommended('recommended'),
  fastest('fastest'),
  shortest('shortest');

  final String value;
  const OrsPreference(this.value);
}

/// Fetches a route between two coordinates using OpenRouteService.
///
/// Returns null when no API key is configured or the request fails or times
/// out, so callers can fall back to [straightLineRoute]. An [http.Client] can
/// be injected for testing.
Future<OrsRoute?> fetchRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
  OrsProfile profile = OrsProfile.drivingCar,
  OrsPreference preference = OrsPreference.shortest,
  http.Client? client,
}) async {
  final key = AppConfig.openRouteServiceApiKey;
  if (key.isEmpty) return null;

  final uri = Uri.parse(
    'https://api.openrouteservice.org/v2/directions/${profile.value}/geojson',
  );
  final c = client ?? http.Client();
  try {
    final response = await c
        .post(
          uri,
          headers: {
            'Authorization': key,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'coordinates': [
              [originLng, originLat],
              [destLng, destLat],
            ],
            'preference': preference.value,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseOrsDirectionsJson(json);
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Parses an OpenRouteService GeoJSON directions response into an [OrsRoute].
/// Returns null when the payload has no LineString geometry.
OrsRoute? parseOrsDirectionsJson(Map<String, dynamic> json) {
  final features = json['features'] as List<dynamic>?;
  if (features == null || features.isEmpty) return null;

  final feature = features.first as Map<String, dynamic>;
  final geometry = feature['geometry'] as Map<String, dynamic>?;
  if (geometry == null) return null;

  final coordinates = geometry['coordinates'] as List<dynamic>?;
  if (coordinates == null || coordinates.length < 2) return null;

  final points = coordinates.map((c) {
    final pair = (c as List<dynamic>).cast<num>();
    return LatLng(pair[1].toDouble(), pair[0].toDouble());
  }).toList();

  double distance = 0;
  double duration = 0;
  final properties = feature['properties'] as Map<String, dynamic>?;
  final summary = properties?['summary'] as Map<String, dynamic>?;
  if (summary != null) {
    final d = summary['distance'];
    final t = summary['duration'];
    if (d is num) distance = d.toDouble();
    if (t is num) duration = t.toDouble();
  }

  return OrsRoute(
    points: points,
    distanceMeters: distance,
    durationSeconds: duration,
  );
}

/// A minimal straight-line route between two coordinates used as a fallback
/// when OpenRouteService is unavailable.
List<LatLng> straightLineRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) {
  return [
    LatLng(originLat, originLng),
    LatLng(destLat, destLng),
  ];
}