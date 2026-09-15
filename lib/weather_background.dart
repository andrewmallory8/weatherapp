import 'package:flutter/material.dart';

/// Groups WMO weather codes into visual backgrounds.
enum WeatherScene { clear, cloudy, fog, rain, snow, storm }

WeatherScene weatherScene(int code) {
  if (code >= 95 && code <= 99) return WeatherScene.storm;
  if (code >= 71 && code <= 77 || code == 85 || code == 86) {
    return WeatherScene.snow;
  }
  if (code >= 51 && code <= 67 || code >= 80 && code <= 82) {
    return WeatherScene.rain;
  }
  if (code == 45 || code == 48) return WeatherScene.fog;
  if (code >= 2 && code <= 3) return WeatherScene.cloudy;
  return WeatherScene.clear;
}

class WeatherBackground extends StatelessWidget {
  const WeatherBackground({
    super.key,
    required this.code,
    required this.isDay,
    required this.child,
  });

  final int? code;
  final bool isDay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scene = weatherScene(code ?? 0);
    final colors = code == null
        ? const [Color(0xFFF6F5EF), Color(0xFFF6F5EF)]
        : isDay
        ? switch (scene) {
            WeatherScene.clear => const [Color(0xFFF8E5AE), Color(0xFFFAF7EB)],
            WeatherScene.cloudy => const [Color(0xFFD5E3E6), Color(0xFFF3F5EF)],
            WeatherScene.fog => const [Color(0xFFDADFDA), Color(0xFFF1F2EC)],
            WeatherScene.rain => const [Color(0xFFBCCFDC), Color(0xFFEAF0EF)],
            WeatherScene.snow => const [Color(0xFFD4E6F1), Color(0xFFF8FAFA)],
            WeatherScene.storm => const [Color(0xFFC5BDD6), Color(0xFFEBE8EF)],
          }
        : switch (scene) {
            WeatherScene.clear => const [Color(0xFFADBBD9), Color(0xFFE7E9F2)],
            WeatherScene.cloudy => const [Color(0xFFB0BED0), Color(0xFFE4E9EE)],
            WeatherScene.fog => const [Color(0xFFBCC3CE), Color(0xFFE5E8ED)],
            WeatherScene.rain => const [Color(0xFFA7B9CE), Color(0xFFE1E8EF)],
            WeatherScene.snow => const [Color(0xFFB9CDE2), Color(0xFFEDF2F7)],
            WeatherScene.storm => const [Color(0xFFB4ABC9), Color(0xFFE5E0EC)],
          };
    return AnimatedContainer(
      key: const ValueKey('weather-background'),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (code != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(painter: WeatherAtmosphere(scene, isDay)),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class WeatherAtmosphere extends CustomPainter {
  const WeatherAtmosphere(this.scene, this.isDay);
  final WeatherScene scene;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = Colors.white.withValues(alpha: .22);
    if (!isDay) {
      for (var i = 0; i < 24; i++) {
        final x = ((i * 137 + 29) % 997) / 997 * size.width;
        final y = ((i * 83 + 17) % 293).toDouble();
        canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 2 : 1, light);
      }
    }
    if (scene == WeatherScene.clear) {
      final center = Offset(size.width * .85, 95);
      canvas.drawCircle(center, 95, light);
      canvas.drawCircle(center, 64, light);
    } else if (scene == WeatherScene.fog) {
      for (var i = 0; i < 5; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-30 + i * 17, 50 + i * 42, size.width, 15),
            const Radius.circular(20),
          ),
          light,
        );
      }
    } else {
      for (var i = 0; i < 4; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * i / 3, 60 + (i % 2) * 40),
            width: 220,
            height: 85,
          ),
          light,
        );
      }
      if (scene == WeatherScene.rain || scene == WeatherScene.storm) {
        final rain = Paint()
          ..color = const Color(0xFF526D88).withValues(alpha: .09)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 32; i++) {
          final x = ((i * 137) % 997) / 997 * size.width;
          final y = 135 + ((i * 47) % 220).toDouble();
          canvas.drawLine(Offset(x, y), Offset(x - 7, y + 17), rain);
        }
      }
      if (scene == WeatherScene.snow) {
        for (var i = 0; i < 40; i++) {
          final x = ((i * 137) % 997) / 997 * size.width;
          final y = 130 + ((i * 47) % 250).toDouble();
          canvas.drawCircle(Offset(x, y), 2 + (i % 3).toDouble(), light);
        }
      }
    }
  }

  @override
  bool shouldRepaint(WeatherAtmosphere oldDelegate) =>
      scene != oldDelegate.scene || isDay != oldDelegate.isDay;
}
