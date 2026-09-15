import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weatherapp/main.dart';
import 'package:weatherapp/weather_service.dart';

Map<String, dynamic> forecast() => {
  'current': {
    'time': '2026-09-15T10:15',
    'temperature_2m': 22,
    'apparent_temperature': 21,
    'weather_code': 3,
    'is_day': 1,
    'wind_speed_10m': 12,
    'relative_humidity_2m': 64,
  },
  'hourly': {
    'time': List.generate(
      48,
      (i) => DateTime(2026, 9, 15, i).toIso8601String(),
    ),
    'temperature_2m': List.filled(48, 23),
    'weather_code': List.filled(48, 3),
    'is_day': List.filled(48, 1),
  },
  'daily': {
    'time': List.generate(
      7,
      (i) => DateTime(2026, 9, 15 + i).toIso8601String(),
    ),
    'temperature_2m_max': List.filled(7, 24),
    'temperature_2m_min': List.filled(7, 16),
    'weather_code': List.filled(7, 3),
    'uv_index_max': [4],
    'sunset': ['2026-09-15T19:24'],
  },
};
final cities = {
  'results': [
    {
      'name': 'London',
      'admin1': 'England',
      'country': 'United Kingdom',
      'latitude': 51.5,
      'longitude': -0.12,
    },
    {
      'name': 'London',
      'admin1': 'Ontario',
      'country': 'Canada',
      'latitude': 42.98,
      'longitude': -81.24,
    },
  ],
};
Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  test('AQI categories handle boundaries and missing values', () {
    for (final entry in {
      0: 'Good',
      50: 'Good',
      51: 'Moderate',
      100: 'Moderate',
      101: 'Unhealthy for sensitive groups',
      150: 'Unhealthy for sensitive groups',
      151: 'Unhealthy',
      200: 'Unhealthy',
      201: 'Very unhealthy',
      300: 'Very unhealthy',
      301: 'Hazardous',
    }.entries) {
      expect(
        AirQuality({
          'current': {'us_aqi': entry.key},
        }).category,
        entry.value,
      );
    }
    expect(
      AirQuality({
        'current': {'us_aqi': null},
      }).category,
      'Unavailable',
    );
    expect(
      AirQuality({
        'current': {'pm2_5': -1},
      }).value('pm2_5'),
      isNull,
    );
  });

  testWidgets('Air quality failure preserves weather and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    final service = WeatherService(
      client: MockClient((request) async {
        if (request.url.host.startsWith('geocoding')) {
          return http.Response(jsonEncode(cities), 200);
        }
        if (request.url.host.startsWith('air-quality')) {
          expect(request.url.queryParameters['latitude'], '51.5');
          expect(request.url.queryParameters['current'], 'us_aqi,pm2_5,pm10');
          if (++attempts == 1) return http.Response('', 503);
          return http.Response(
            jsonEncode({
              'current': {'us_aqi': 42, 'pm2_5': 8.2, 'pm10': null},
            }),
            200,
          );
        }
        return http.Response(jsonEncode(forecast()), 200);
      }),
    );
    addTearDown(service.close);
    await tester.pumpWidget(MyApp(service: service));
    await search(tester, 'London');
    await tester.tap(find.text('England, United Kingdom'));
    await tester.pumpAndSettle();
    expect(find.text('22°'), findsOneWidget);
    expect(
      find.byTooltip('Air quality unavailable. Tap to retry.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('AIR QUALITY'));
    await tester.tap(find.text('AIR QUALITY'));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    expect(find.byTooltip('US AQI · Good'), findsOneWidget);
    final windTile = find
        .ancestor(of: find.text('WIND'), matching: find.byType(Container))
        .first;
    final airTile = find
        .ancestor(
          of: find.text('AIR QUALITY'),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.getSize(airTile), tester.getSize(windTile));
    expect(tester.getTopLeft(airTile).dx, tester.getTopLeft(windTile).dx);
  });

  testWidgets(
    'Search selects an unlisted city and updates all weather at mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = WeatherService(
        client: MockClient((request) async {
          if (request.url.host.startsWith('geocoding')) {
            expect(request.url.queryParameters['name'], 'London');
            return http.Response(jsonEncode(cities), 200);
          }
          expect(request.url.queryParameters['latitude'], '51.5');
          expect(request.url.queryParameters['timezone'], 'auto');
          return http.Response(jsonEncode(forecast()), 200);
        }),
      );
      addTearDown(service.close);
      await tester.pumpWidget(MyApp(service: service));
      expect(find.text('Your next forecast starts here'), findsOneWidget);
      expect(find.text('°C'), findsNothing);
      expect(find.text('°F'), findsNothing);
      await search(tester, 'London');
      expect(find.text('England, United Kingdom'), findsOneWidget);
      expect(find.text('Ontario, Canada'), findsOneWidget);
      await tester.tap(find.text('England, United Kingdom'));
      await tester.pumpAndSettle();
      expect(find.text('London, England, United Kingdom'), findsOneWidget);
      expect(find.text('Overcast'), findsOneWidget);
      expect(find.text('22°'), findsOneWidget);
      await tester.tap(find.text('°F'));
      await tester.pumpAndSettle();
      expect(find.text('72°'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(find.text('7:24 PM'), findsOneWidget);
    },
  );

  testWidgets('Empty queries, no matches and search failure are actionable', (
    tester,
  ) async {
    final service = WeatherService(
      client: MockClient(
        (request) async => request.url.queryParameters['name'] == 'Unknown'
            ? http.Response('{}', 200)
            : http.Response('', 503),
      ),
    );
    addTearDown(service.close);
    await tester.pumpWidget(MyApp(service: service));
    await search(tester, ' ');
    expect(find.text('Enter at least 2 characters to search.'), findsOneWidget);
    await search(tester, 'Unknown');
    expect(find.text('No cities found. Try another spelling.'), findsOneWidget);
    await search(tester, 'Paris');
    expect(
      find.text('Couldn’t search cities. Check your connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Failed weather requests retain selectable results for retry', (
    tester,
  ) async {
    var attempts = 0;
    final service = WeatherService(
      client: MockClient((request) async {
        if (request.url.host.startsWith('geocoding')) {
          return http.Response(jsonEncode(cities), 200);
        }
        return ++attempts == 1
            ? http.Response('', 503)
            : http.Response(jsonEncode(forecast()), 200);
      }),
    );
    addTearDown(service.close);
    await tester.pumpWidget(MyApp(service: service));
    await search(tester, 'London');
    await tester.tap(find.text('England, United Kingdom'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn’t load weather. Select the city to retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('England, United Kingdom'));
    await tester.pumpAndSettle();
    expect(find.text('22°'), findsOneWidget);
  });

  testWidgets('Editing the query ignores stale search responses', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final service = WeatherService(client: MockClient((_) => pending.future));
    addTearDown(service.close);
    await tester.pumpWidget(MyApp(service: service));
    await tester.enterText(find.byType(TextField), 'London');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text('Searching cities…'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Paris');
    pending.complete(http.Response(jsonEncode(cities), 200));
    await tester.pumpAndSettle();
    expect(find.text('England, United Kingdom'), findsNothing);
  });
}
