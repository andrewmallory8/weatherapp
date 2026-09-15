import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherapp/weather_background.dart';

void main() {
  test('Weather codes select rain, snow, fog and storm scenes', () {
    for (final code in [0, 1]) {
      expect(weatherScene(code), WeatherScene.clear);
    }
    for (final code in [2, 3]) {
      expect(weatherScene(code), WeatherScene.cloudy);
    }
    for (final code in [45, 48]) {
      expect(weatherScene(code), WeatherScene.fog);
    }
    for (final code in [51, 57, 61, 67, 80, 82]) {
      expect(weatherScene(code), WeatherScene.rain);
    }
    for (final code in [71, 77, 85, 86]) {
      expect(weatherScene(code), WeatherScene.snow);
    }
    for (final code in [95, 96, 99]) {
      expect(weatherScene(code), WeatherScene.storm);
    }
  });

  testWidgets('Backgrounds change for day/night without blocking interaction', (
    tester,
  ) async {
    var taps = 0;
    for (final code in [null, 0, 3, 45, 61, 71, 95]) {
      BoxDecoration? day;
      for (final isDay in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WeatherBackground(
                code: code,
                isDay: isDay,
                child: Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Search'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final background = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('weather-background')),
        );
        final decoration = background.decoration as BoxDecoration;
        if (isDay) day = decoration;
        if (!isDay && code != null) expect(decoration, isNot(day));
        await tester.tap(find.text('Search'));
        expect(tester.takeException(), isNull);
      }
    }
    expect(taps, 14);
  });
}
