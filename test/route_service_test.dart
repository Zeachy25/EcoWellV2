import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ecowell/data/services/route_service.dart';

class _FakeClient extends http.BaseClient {
  final int statusCode;
  final String body;
  http.BaseRequest? lastRequest;

  _FakeClient({required this.statusCode, required this.body});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(body.codeUnits),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw Exception('network down');
  }
}

Map<String, dynamic> _sampleOrsJson() => {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [126.2157, 6.9532],
          [126.2257, 6.9632],
        ],
      },
      'properties': {
        'summary': {'distance': 1420.5, 'duration': 894.2},
        'segments': [
          {
            'steps': [
              {
                'distance': 1420.5,
                'duration': 894.2,
                'instructions': 'Head north',
                'name': 'Main Street',
                'geometry': {
                  'coordinates': [
                    [126.2157, 6.9532],
                    [126.2257, 6.9632],
                  ],
                },
                'maneuver': {
                  'type': 'depart',
                  'bearing_after': 20,
                  'location': [126.2157, 6.9532],
                },
              },
            ],
          },
        ],
      },
    },
  ],
};

void main() {
  group('parseOrsDirectionsJson', () {
    test('parses LineString coordinates into LatLng + summary', () {
      final route = parseOrsDirectionsJson(_sampleOrsJson());

      expect(route, isNotNull);
      expect(route!.points.length, 2);
      expect(route.points.first.latitude, 6.9532);
      expect(route.points.first.longitude, 126.2157);
      expect(route.points.last.latitude, 6.9632);
      expect(route.points.last.longitude, 126.2257);
      expect(route.distanceMeters, 1420.5);
      expect(route.durationSeconds, 894.2);
      expect(route.steps, hasLength(1));
      expect(route.steps.single.instruction, 'Head north');
      expect(route.steps.single.maneuverType, 'depart');
      expect(route.steps.single.points, hasLength(2));
    });

    test('returns null when there are no features', () {
      expect(parseOrsDirectionsJson({'features': <dynamic>[]}), isNull);
    });

    test('returns null when geometry is missing', () {
      expect(
        parseOrsDirectionsJson({
          'features': [
            {'geometry': null},
          ],
        }),
        isNull,
      );
    });

    test('returns null when coordinates have fewer than two points', () {
      expect(
        parseOrsDirectionsJson({
          'features': [
            {
              'geometry': {
                'coordinates': [
                  [126.2157, 6.9532],
                ],
              },
            },
          ],
        }),
        isNull,
      );
    });
  });

  group('straightLineRoute', () {
    test('returns the two endpoints in order', () {
      final route = straightLineRoute(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(route.length, 2);
      expect(route.first.latitude, 1);
      expect(route.first.longitude, 2);
      expect(route.last.latitude, 3);
      expect(route.last.longitude, 4);
    });
  });

  group('fetchRoute', () {
    test(
      'requests foot-walking with recommended preference by default',
      () async {
        final client = _FakeClient(
          statusCode: 200,
          body: jsonEncode(_sampleOrsJson()),
        );

        await fetchRoute(
          originLat: 6.9532,
          originLng: 126.2157,
          destLat: 6.9632,
          destLng: 126.2257,
          client: client,
        );

        expect(client.lastRequest, isNotNull);
        expect(
          client.lastRequest!.url.path,
          contains('/directions/foot-walking/geojson'),
        );
        final request = client.lastRequest! as http.Request;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['preference'], 'recommended');
        expect(body['instructions'], isTrue);
        expect(body['geometry'], isTrue);
      },
    );

    test('parses a 200 response into an OrsRoute', () async {
      final client = _FakeClient(
        statusCode: 200,
        body: jsonEncode(_sampleOrsJson()),
      );

      final route = await fetchRoute(
        originLat: 6.9532,
        originLng: 126.2157,
        destLat: 6.9632,
        destLng: 126.2257,
        client: client,
      );

      expect(route, isNotNull);
      expect(route!.points.length, 2);
      expect(route.distanceMeters, 1420.5);
    });

    test('returns null on a non-200 response', () async {
      final client = _FakeClient(statusCode: 403, body: 'forbidden');

      final route = await fetchRoute(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
        client: client,
      );

      expect(route, isNull);
    });

    test('returns null when the request throws', () async {
      final route = await fetchRoute(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
        client: _ThrowingClient(),
      );

      expect(route, isNull);
    });
  });
}
