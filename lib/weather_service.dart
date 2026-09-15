import 'dart:convert';

import 'package:http/http.dart' as http;

class City {
  const City(this.name, this.region, this.latitude, this.longitude);
  final String name, region;
  final double latitude, longitude;
  String get label => region.isEmpty ? name : '$name, $region';
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather service unavailable');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<City>> search(String query) async {
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query,
        'count': '8',
        'language': 'en',
        'format': 'json',
      }),
    );
    return [
      for (final item in json['results'] as List? ?? [])
        City(
          item['name'] as String,
          [
            item['admin1'],
            item['country'],
          ].whereType<String>().toSet().join(', '),
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        ),
    ];
  }

  Future<AirQuality> airQuality(City city) async => AirQuality(
    await _get(
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'current': 'us_aqi,pm2_5,pm10',
        'timezone': 'auto',
      }),
    ),
  );

  Future<Weather> forecast(City city) async => Weather(
    await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'timezone': 'auto',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day',
        'hourly': 'temperature_2m,weather_code,is_day',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunset,uv_index_max',
        'forecast_days': '7',
      }),
    ),
  );
}

class Weather {
  Weather(this.data);
  final Map<String, dynamic> data;
  Map<String, dynamic> get current => data['current'] as Map<String, dynamic>;
  Map<String, dynamic> get daily => data['daily'] as Map<String, dynamic>;
  Map<String, dynamic> get hourly => data['hourly'] as Map<String, dynamic>;
  int get temperature => (current['temperature_2m'] as num).round();
  int get code => (current['weather_code'] as num).toInt();
  int dayValue(String key, int i) => (daily[key][i] as num).round();
  List<int> get hours {
    final now = DateTime.parse(current['time'] as String);
    return [
      for (int i = 0; i < (hourly['time'] as List).length; i++)
        if (!DateTime.parse(hourly['time'][i] as String).isBefore(now)) i,
    ].take(24).toList();
  }
}

String condition(int code) => switch (code) {
  0 => 'Clear sky',
  1 => 'Mostly sunny',
  2 => 'Partly cloudy',
  3 => 'Overcast',
  45 || 48 => 'Foggy',
  >= 51 && <= 57 => 'Drizzle',
  >= 61 && <= 67 => 'Rain',
  >= 71 && <= 77 => 'Snow',
  >= 80 && <= 82 => 'Rain showers',
  85 || 86 => 'Snow showers',
  >= 95 => 'Thunderstorms',
  _ => 'Weather conditions',
};

class AirQuality {
  AirQuality(Map<String, dynamic> data)
    : current = data['current'] as Map<String, dynamic>;
  final Map<String, dynamic> current;
  num? value(String key) {
    final value = current[key];
    return value is num && value.isFinite && value >= 0 ? value : null;
  }

  int? get aqi => value('us_aqi')?.round();
  String get category {
    final index = aqi;
    if (index == null) return 'Unavailable';
    if (index <= 50) return 'Good';
    if (index <= 100) return 'Moderate';
    if (index <= 150) return 'Unhealthy for sensitive groups';
    if (index <= 200) return 'Unhealthy';
    if (index <= 300) return 'Very unhealthy';
    return 'Hazardous';
  }
}
