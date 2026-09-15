import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_service.dart';

void main() => runApp(const MyApp());

const ink = Color(0xFF243C39);
const muted = Color(0xFF7D8880);
const paper = Color(0xFFF6F5EF);

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.service});
  final WeatherService? service;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Daylight · Weather',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: ink),
      fontFamily: 'Helvetica',
      textTheme: const TextTheme(bodyMedium: TextStyle(color: ink)),
    ),
    home: WeatherHome(service: service),
  );
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key, this.service});
  final WeatherService? service;
  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  bool celsius = true;
  final searchController = TextEditingController();
  late final WeatherService service = widget.service ?? WeatherService();
  City? selectedCity;
  Weather? weather;
  List<City> results = [];
  bool searching = false;
  bool loading = false;
  String? message;
  int request = 0;

  @override
  void dispose() {
    searchController.dispose();
    if (widget.service == null) service.close();
    super.dispose();
  }

  void clearSearch() {
    request++;
    setState(() {
      results = [];
      searching = false;
      loading = false;
      message = null;
    });
  }

  Future<void> search() async {
    final query = searchController.text.trim();
    final id = ++request;
    setState(() {
      results = [];
      loading = false;
      searching = query.length >= 2;
      message = query.length < 2
          ? 'Enter at least 2 characters to search.'
          : null;
    });
    if (query.length < 2) return;
    try {
      final matches = await service.search(query);
      if (!mounted || id != request) return;
      setState(() {
        results = matches;
        searching = false;
        message = matches.isEmpty
            ? 'No cities found. Try another spelling.'
            : null;
      });
    } catch (_) {
      if (!mounted || id != request) return;
      setState(() {
        searching = false;
        message =
            'Couldn’t search cities. Check your connection and try again.';
      });
    }
  }

  Future<void> selectCity(City city) async {
    final id = ++request;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final forecast = await service.forecast(city);
      if (!mounted || id != request) return;
      setState(() {
        selectedCity = city;
        weather = forecast;
        results = [];
        loading = false;
        searchController.text = city.name;
      });
    } catch (_) {
      if (!mounted || id != request) return;
      setState(() {
        loading = false;
        message = 'Couldn’t load weather. Select the city to retry.';
      });
    }
  }

  String clockTime(String value) {
    final time = DateTime.parse(value);
    return '${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  IconData weatherIcon(int code, {bool night = false}) {
    if (code >= 95) return Icons.thunderstorm_outlined;
    if (code >= 71 && code <= 77 || code == 85 || code == 86) {
      return Icons.ac_unit;
    }
    if (code >= 51) return Icons.water_drop_outlined;
    if (code >= 2) return Icons.cloud_outlined;
    return night ? Icons.nightlight_round : Icons.wb_sunny_outlined;
  }

  String temp(int value) =>
      '${celsius ? value : (value * 9 / 5 + 32).round()}°';

  @override
  Widget build(BuildContext context) {
    final current = weather?.temperature ?? 0;
    final hours = weather?.hours ?? <int>[];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 27, color: ink),
                      const SizedBox(width: 9),
                      const Text(
                        'daylight',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      if (weather != null)
                        Semantics(
                          label: 'Temperature unit',
                          child: SizedBox(
                            width: 110,
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: true, label: Text('°C')),
                                ButtonSegment(value: false, label: Text('°F')),
                              ],
                              selected: {celsius},
                              showSelectedIcon: false,
                              onSelectionChanged: (value) =>
                                  setState(() => celsius = value.first),
                              style: SegmentedButton.styleFrom(
                                minimumSize: const Size(48, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                selectedBackgroundColor: ink,
                                selectedForegroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFD9DDD3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                    onChanged: (_) => clearSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search for any city',
                      labelText: 'Search city',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search cities',
                        onPressed: search,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFD9DDD3)),
                      ),
                    ),
                  ),
                  if (searching || loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        loading ? 'Loading weather…' : 'Searching cities…',
                      ),
                    ),
                  ],
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(liveRegion: true, child: Text(message!)),
                    ),
                  if (results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final city in results)
                              ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(city.name),
                                subtitle: Text(city.region),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: loading ? null : () => selectCity(city),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (weather == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.travel_explore, size: 64, color: muted),
                            SizedBox(height: 20),
                            Text(
                              'Your next forecast starts here',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Search a city, then choose a matching location.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (weather != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 18),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            selectedCity!.label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Weather in your city’s local time.',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDDC),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          children: [
                            Positioned(
                              right: -45,
                              bottom: -140,
                              child: Container(
                                width: 450,
                                height: 320,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFDDE6CE),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 7,
                                        color: Color(0xFF73885E),
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'CURRENT WEATHER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.7,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              temp(current),
                                              style: TextStyle(
                                                fontSize:
                                                    constraints.maxWidth < 400
                                                    ? 88
                                                    : 112,
                                                height: 1,
                                                letterSpacing: -7,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              condition(weather!.code),
                                              style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Feels like ${temp((weather!.current['apparent_temperature'] as num).round())}  ·  H:${temp(weather!.dayValue('temperature_2m_max', 0))}  L:${temp(weather!.dayValue('temperature_2m_min', 0))}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF677563),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: constraints.maxWidth < 400
                                            ? 95
                                            : 180,
                                        height: 150,
                                        child:
                                            weather!.code <= 1 &&
                                                weather!.current['is_day'] == 1
                                            ? const CustomPaint(
                                                painter: SunPainter(),
                                              )
                                            : Icon(
                                                weatherIcon(
                                                  weather!.code,
                                                  night:
                                                      weather!
                                                          .current['is_day'] ==
                                                      0,
                                                ),
                                                size: 80,
                                                color: muted,
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  const Divider(color: Color(0xFFCDD7C0)),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 17,
                                      ),
                                      SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          'A fresh forecast for wherever your day takes you.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    sectionTitle('The next 24 hours', 'HOURLY FORECAST'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 134,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hours.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => Container(
                          width: 77,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? ink
                                : Colors.white.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(22),
                            border: i == 0
                                ? null
                                : Border.all(color: const Color(0xFFE6E8DF)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                clockTime(
                                  weather!.hourly['time'][hours[i]] as String,
                                ),
                                style: TextStyle(
                                  color: i == 0 ? Colors.white70 : muted,
                                  fontSize: 11,
                                ),
                              ),
                              Icon(
                                weatherIcon(
                                  (weather!.hourly['weather_code'][hours[i]]
                                          as num)
                                      .toInt(),
                                  night:
                                      weather!.hourly['is_day'][hours[i]] == 0,
                                ),
                                color: const Color(0xFFD4A64A),
                                size: 27,
                              ),
                              Text(
                                temp(
                                  (weather!.hourly['temperature_2m'][hours[i]]
                                          as num)
                                      .round(),
                                ),
                                style: TextStyle(
                                  color: i == 0 ? Colors.white : ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final forecast = forecastCard(current);
                        final details = detailsCard();
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              forecast,
                              const SizedBox(height: 26),
                              details,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: forecast),
                            const SizedBox(width: 24),
                            Expanded(child: details),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Weather: Open-Meteo · Locations: GeoNames',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 11, height: 1.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, String eyebrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: muted,
          fontSize: 9,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -.5,
        ),
      ),
    ],
  );

  Widget forecastCard(int current) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('A look ahead', '7-DAY FORECAST'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFFE6E8DF)),
        ),
        child: Column(
          children: List.generate(
            7,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  SizedBox(
                    width: 53,
                    child: Text(
                      i == 0
                          ? 'Today'
                          : [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][DateTime.parse(
                                  weather!.daily['time'][i] as String,
                                ).weekday -
                                1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    weatherIcon(weather!.dayValue('weather_code', i)),
                    color: i == 2 || i == 3 ? muted : const Color(0xFFD4A64A),
                    size: 22,
                  ),
                  const SizedBox(width: 18),
                  Text(
                    temp(weather!.dayValue('temperature_2m_min', i)),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEDE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: .65 + i % 3 * .1,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBACBA0), Color(0xFFE5BE69)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    temp(weather!.dayValue('temperature_2m_max', i)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget detailsCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('It’s all in the details', 'TODAY’S HIGHLIGHTS'),
      const SizedBox(height: 16),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          detail(
            Icons.air,
            'WIND',
            '${weather!.current['wind_speed_10m']}',
            'km/h',
            'Current wind speed',
          ),
          detail(
            Icons.water_drop_outlined,
            'HUMIDITY',
            '${weather!.current['relative_humidity_2m']}',
            '%',
            'Relative humidity',
          ),
          detail(
            Icons.wb_sunny_outlined,
            'UV INDEX',
            '${weather!.daily['uv_index_max'][0] ?? '—'}',
            '',
            'Daily maximum',
          ),
          detail(
            Icons.wb_twilight,
            'SUNSET',
            weather!.daily['sunset'][0] == null
                ? '—'
                : clockTime(weather!.daily['sunset'][0] as String),
            '',
            'Local time',
          ),
        ],
      ),
    ],
  );

  Widget detail(
    IconData icon,
    String label,
    String value,
    String unit,
    String note,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDEFE6),
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 5),
                Text(unit, style: const TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
        ),
        Text(note, style: const TextStyle(fontSize: 10, color: muted)),
      ],
    ),
  );
}

class SunPainter extends CustomPainter {
  const SunPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .29;
    canvas.drawCircle(
      center,
      radius * 1.65,
      Paint()..color = const Color(0xFFE6CB76).withValues(alpha: .12),
    );
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()..color = const Color(0xFFE6CB76).withValues(alpha: .16),
    );
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * radius * 1.2,
        center + direction * radius * 1.4,
        Paint()
          ..color = const Color(0xFFD5AE50)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF8DE8A), Color(0xFFE6BC57)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
