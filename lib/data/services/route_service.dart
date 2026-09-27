import 'dart:async';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/utils/geo.dart';

class OrsRouteStep {
  const OrsRouteStep({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instruction,
    this.maneuverType,
    this.maneuverBearing,
    this.maneuverLocation,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String instruction;
  final String? maneuverType;
  final double? maneuverBearing;
  final LatLng? maneuverLocation;
}

class OrsRoute {
  const OrsRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<OrsRouteStep> steps;
}

enum OrsProfile {
  drivingCar('driving-car'),
  footWalking('foot-walking');

  final String value;
  const OrsProfile(this.value);
}

enum OrsPreference {
  recommended('recommended'),
  fastest('fastest'),
  shortest('shortest');

  final String value;
  const OrsPreference(this.value);
}

typedef OrsRouteFetcher =
    Future<OrsRoute?> Function({
      required double originLat,
      required double originLng,
      required double destLat,
      required double destLng,
    });

Future<OrsRoute?> fetchRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
  OrsProfile profile = OrsProfile.footWalking,
  OrsPreference preference = OrsPreference.recommended,
  http.Client? client,
}) async {
  final key = AppConfig.openRouteServiceApiKey;
  if (key.isEmpty) return null;

  final uri = Uri.parse(
    'https://api.openrouteservice.org/v2/directions/${profile.value}/geojson',
  );
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          uri,
          headers: {'Authorization': key, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'coordinates': [
              [originLng, originLat],
              [destLng, destLat],
            ],
            'preference': preference.value,
            'instructions': true,
            'geometry': true,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return parseOrsDirectionsJson(decoded);
  } catch (_) {
    return null;
  } finally {
    if (client == null) httpClient.close();
  }
}

OrsRoute? parseOrsDirectionsJson(Map<String, dynamic> json) {
  final rawFeatures = json['features'];
  if (rawFeatures is! List || rawFeatures.isEmpty) return null;
  final rawFeature = rawFeatures.first;
  if (rawFeature is! Map) return null;
  final feature = Map<String, dynamic>.from(rawFeature);
  final rawGeometry = feature['geometry'];
  if (rawGeometry is! Map) return null;
  final geometry = Map<String, dynamic>.from(rawGeometry);
  final points = _parseCoordinates(geometry['coordinates']);
  if (points == null || points.length < 2) return null;

  final rawProperties = feature['properties'];
  final properties = rawProperties is Map
      ? Map<String, dynamic>.from(rawProperties)
      : <String, dynamic>{};
  final rawSummary = properties['summary'];
  final summary = rawSummary is Map
      ? Map<String, dynamic>.from(rawSummary)
      : <String, dynamic>{};
  final summaryDistance = _asDouble(summary['distance']);
  final summaryDuration = _asDouble(summary['duration']);
  final distance = summaryDistance > 0
      ? summaryDistance
      : _geometryDistance(points);
  final duration = summaryDuration > 0 ? summaryDuration : 0.0;

  return OrsRoute(
    points: points,
    distanceMeters: distance,
    durationSeconds: duration,
    steps: _parseSteps(properties['segments']),
  );
}

List<LatLng>? _parseCoordinates(dynamic rawCoordinates) {
  if (rawCoordinates is! List || rawCoordinates.length < 2) return null;
  final points = <LatLng>[];
  for (final rawCoordinate in rawCoordinates) {
    if (rawCoordinate is! List || rawCoordinate.length < 2) return null;
    final longitude = _asDouble(rawCoordinate[0]);
    final latitude = _asDouble(rawCoordinate[1]);
    if (!_validCoordinate(longitude, latitude)) return null;
    points.add(LatLng(latitude, longitude));
  }
  return points;
}

bool _validCoordinate(double longitude, double latitude) {
  return longitude.isFinite &&
      latitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180 &&
      latitude >= -90 &&
      latitude <= 90;
}

List<OrsRouteStep> _parseSteps(dynamic rawSegments) {
  if (rawSegments is! List) return const [];
  final steps = <OrsRouteStep>[];
  for (final rawSegment in rawSegments) {
    if (rawSegment is! Map) continue;
    final segment = Map<String, dynamic>.from(rawSegment);
    final rawSteps = segment['steps'];
    if (rawSteps is! List) continue;
    for (final rawStep in rawSteps) {
      if (rawStep is! Map) continue;
      final step = Map<String, dynamic>.from(rawStep);
      final rawGeometry = step['geometry'];
      final stepPoints = rawGeometry is Map
          ? _parseCoordinates(
              Map<String, dynamic>.from(rawGeometry)['coordinates'],
            )
          : null;
      final rawManeuver = step['maneuver'];
      final maneuver = rawManeuver is Map
          ? Map<String, dynamic>.from(rawManeuver)
          : <String, dynamic>{};
      final rawLocation = maneuver['location'];
      final maneuverLongitude = rawLocation is List && rawLocation.length >= 2
          ? _asNullableDouble(rawLocation[0])
          : null;
      final maneuverLatitude = rawLocation is List && rawLocation.length >= 2
          ? _asNullableDouble(rawLocation[1])
          : null;
      final maneuverLocation =
          maneuverLongitude != null &&
              maneuverLatitude != null &&
              _validCoordinate(maneuverLongitude, maneuverLatitude)
          ? LatLng(maneuverLatitude, maneuverLongitude)
          : null;
      final rawInstruction = step['instructions'];
      final rawName = step['name'];
      final instruction =
          rawInstruction is String && rawInstruction.trim().isNotEmpty
          ? rawInstruction
          : rawName is String && rawName.trim().isNotEmpty
          ? rawName
          : 'Continue';
      steps.add(
        OrsRouteStep(
          points: stepPoints ?? const [],
          distanceMeters: _asDouble(step['distance']),
          durationSeconds: _asDouble(step['duration']),
          instruction: instruction,
          maneuverType: maneuver['type'] is String
              ? maneuver['type'] as String
              : null,
          maneuverBearing: _asNullableDouble(
            maneuver['bearing_after'] ?? maneuver['bearing'],
          ),
          maneuverLocation: maneuverLocation,
        ),
      );
    }
  }
  return steps;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

double _geometryDistance(List<LatLng> points) {
  var total = 0.0;
  for (var index = 1; index < points.length; index++) {
    total += distanceMeters(
      points[index - 1].latitude,
      points[index - 1].longitude,
      points[index].latitude,
      points[index].longitude,
    );
  }
  return total;
}

List<LatLng> straightLineRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) {
  return [LatLng(originLat, originLng), LatLng(destLat, destLng)];
}
