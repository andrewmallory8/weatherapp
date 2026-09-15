import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const ink = Color(0xFF243C39);
const muted = Color(0xFF7D8880);
const paper = Color(0xFFF6F5EF);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
    home: const WeatherHome(),
  );
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});
  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  bool celsius = true;
  int city = 0;
  final cities = ['San Francisco', 'Chicago', 'New York'];
  final temperatures = [18, 22, 24];
  String temp(int value) =>
      '${celsius ? value : (value * 9 / 5 + 32).round()}°';

  @override
  Widget build(BuildContext context) {
    final current = temperatures[city];
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
                              side: const BorderSide(color: Color(0xFFD9DDD3)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined, size: 18),
                      const SizedBox(width: 7),
                      DropdownButton<int>(
                        value: city,
                        underline: const SizedBox(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                        items: List.generate(
                          cities.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(cities[i]),
                          ),
                        ),
                        onChanged: (value) => setState(() => city = value!),
                      ),
                    ],
                  ),
                  const Text(
                    'A little sunshine goes a long way.',
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
                                          const Text(
                                            'Mostly sunny',
                                            style: TextStyle(
                                              fontSize: 21,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Feels like ${temp(current - 1)}  ·  H:${temp(current + 3)}  L:${temp(current - 4)}',
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
                                      child: const CustomPaint(
                                        painter: SunPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                const Divider(color: Color(0xFFCDD7C0)),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome_outlined, size: 17),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Clear skies ahead. A lovely day to get outside.',
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
                      itemCount: 12,
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
                              i == 0
                                  ? 'Now'
                                  : '${(i + 10) > 12 ? i - 2 : i + 10} ${i + 10 >= 12 ? 'PM' : 'AM'}',
                              style: TextStyle(
                                color: i == 0 ? Colors.white70 : muted,
                                fontSize: 11,
                              ),
                            ),
                            Icon(
                              i > 8
                                  ? Icons.nightlight_round
                                  : i == 3 || i == 6
                                  ? Icons.cloud_outlined
                                  : Icons.wb_sunny_outlined,
                              color: i > 8 ? muted : const Color(0xFFD4A64A),
                              size: 27,
                            ),
                            Text(
                              temp(
                                current +
                                    [0, 1, 2, 3, 3, 2, 1, 0, -1, -2, -3, -3][i],
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
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Take a moment. Look up.\nSample weather · Made for your everyday',
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
                      ['Today', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    i == 2 || i == 3
                        ? Icons.cloud_outlined
                        : Icons.wb_sunny_outlined,
                    color: i == 2 || i == 3 ? muted : const Color(0xFFD4A64A),
                    size: 22,
                  ),
                  const SizedBox(width: 18),
                  Text(
                    temp(current - 4 + i % 3),
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
                    temp(current + 3 + i % 3),
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
          detail(Icons.air, 'WIND', '12', 'km/h', '↗  From the west'),
          detail(
            Icons.water_drop_outlined,
            'HUMIDITY',
            '64',
            '%',
            'Comfortable outdoors',
          ),
          detail(
            Icons.wb_sunny_outlined,
            'UV INDEX',
            '4',
            'Moderate',
            'A little SPF goes a long way',
          ),
          detail(
            Icons.wb_twilight,
            'SUNSET',
            '7:24',
            'PM',
            'Golden hour at 6:42 PM',
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
