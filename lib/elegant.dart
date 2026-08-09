import 'package:flutter/material.dart';
import 'dart:math' as math;

class ElegantBackground extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;

  const ElegantBackground({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  State<ElegantBackground> createState() => _ElegantBackgroundState();
}

class _ElegantBackgroundState extends State<ElegantBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12)
    )..repeat();

    // 1163 x 1304
    // 11.63 x 13.04
    double screenCrossAhead = (math.log(math.sqrt(math.pow(widget.width / 100, 2) + math.pow(widget.height / 100, 2))) / 10) * math.sqrt(32) * 60;

    for (int i = 0; i < screenCrossAhead; i++) {
      _particles.add(Particle(
          math.Random().nextDouble(),
          math.Random().nextDouble(),
          math.Random().nextDouble() * 2 * math.pi,
          math.Random().nextDouble() * 2 + 1.5
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8BA9D6),
                    Color(0xFFC0A2DE),
                    Color(0xFFEBA6C6)
                  ]
              )
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: FluidPainter(_controller.value, _particles),
              size: Size.infinite,
            );
          },
        ),
        widget.child
      ],
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double phase;
  final double size;

  Particle(this.x, this.y, this.phase, this.size);
}

class FluidPainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  FluidPainter(this.animationValue, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final double time = animationValue * 2 * math.pi;

    _drawWave(
      canvas: canvas, size: size, time: time,
      color: Colors.white.withOpacity(0.12),
      amplitude: 50.0, frequency: 2.0, yOffsetPercent: 0.25, phaseOffset: 0.0,
    );
    _drawWave(
      canvas: canvas, size: size, time: time,
      color: const Color(0xFF9B63F8).withOpacity(0.15),
      amplitude: 70.0, frequency: 1.5, yOffsetPercent: 0.6, phaseOffset: math.pi / 2,
    );
    _drawWave(
      canvas: canvas, size: size, time: time,
      color: Colors.white.withOpacity(0.18),
      amplitude: 60.0, frequency: 2.2, yOffsetPercent: 0.85, phaseOffset: math.pi,
    );

    final goldPaint = Paint()
      ..color = const Color(0xFFF9DDA4).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    _drawGoldenCurves(canvas, size, time, goldPaint);

    // _drawOrchidFlower(
    //   canvas: canvas,
    //   center: Offset(size.width * 0.15, size.height * 0.8),
    //   scale: 1.2,
    //   rotation: math.pi / 6,
    //   time: time,
    //   paint: goldPaint,
    // );
    //
    // // 우측 상단 중간 꽃
    // _drawOrchidFlower(
    //   canvas: canvas,
    //   center: Offset(size.width * 0.9, size.height * 0.2),
    //   scale: 0.9,
    //   rotation: -math.pi / 3,
    //   time: time,
    //   paint: goldPaint,
    // );

    _drawOrchidFlower(
      canvas: canvas,
      center: Offset(size.width * 0.15, size.height * 0.8),
      scale: 1.2,
      rotation: math.pi / 6,
      time: time,
      paint: goldPaint,
    );

    // 우측 상단 중간 꽃
    _drawOrchidFlower(
      canvas: canvas,
      center: Offset(size.width * 0.9, size.height * 0.2),
      scale: 0.9,
      rotation: -math.pi / 3,
      time: time,
      paint: goldPaint,
    );

    for (var particle in particles) {
      final double px = particle.x * size.width;
      final double py = particle.y * size.height;
      final double opacity = (math.sin(time * 3 + particle.phase) + 1) / 2 * 0.7;

      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(Offset(px, py), particle.size, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), particle.size * 0.4, corePaint);
    }
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double time,
    required Color color,
    required double amplitude,
    required double frequency,
    required double yOffsetPercent,
    required double phaseOffset,
  }) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * yOffsetPercent);

    for (double i = 0; i <= size.width; i++) {
      final double waveY = math.sin((i / size.width) * math.pi * frequency + time + phaseOffset) * amplitude;
      path.lineTo(i, size.height * yOffsetPercent + waveY);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGoldenCurves(Canvas canvas, Size size, double time, Paint paint) {
    final path1 = Path();
    path1.moveTo(-50, size.height * 0.2);
    path1.cubicTo(
        size.width * 0.3, size.height * 0.1 + math.sin(time) * 30,
        size.width * 0.6, size.height * 0.4 + math.cos(time) * 40,
        size.width + 50, size.height * 0.3
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(-50, size.height * 0.8);
    path2.cubicTo(
        size.width * 0.4, size.height * 0.9 - math.cos(time) * 30,
        size.width * 0.7, size.height * 0.5 - math.sin(time) * 40,
        size.width + 50, size.height * 0.7
    );
    canvas.drawPath(path2, paint);
  }

  void _drawOrchidFlower({
    required Canvas canvas,
    required Offset center,
    required double scale,
    required double rotation,
    required double time,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation + math.sin(time) * 0.03);
    canvas.scale(scale);

    void drawPetal(double angle, double width, double length, double breath) {
      canvas.save();
      canvas.rotate(angle);
      final path = Path();
      path.moveTo(0, 0);

      path.cubicTo(
          width + breath, -length * 0.3,
          width + breath, -length * 0.8,
          0, -length - breath
      );
      path.cubicTo(
          -width - breath, -length * 0.8,
          -width - breath, -length * 0.3,
          0, 0
      );

      path.moveTo(0, 0);
      path.quadraticBezierTo(width * 0.2, -length * 0.5, 0, -length * 0.85);
      path.moveTo(0, 0);
      path.quadraticBezierTo(-width * 0.2, -length * 0.5, 0, -length * 0.85);

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    double b = math.sin(time * 2) * 2.0;

    drawPetal(0, 25, 90, b);
    drawPetal(math.pi * 0.75, 20, 80, b);
    drawPetal(-math.pi * 0.75, 20, 80, b);

    drawPetal(math.pi * 0.4, 40, 75, -b);
    drawPetal(-math.pi * 0.4, 40, 75, -b);

    final centerPath = Path();
    centerPath.moveTo(0, 0);
    centerPath.cubicTo(15, 15, -15, 15, 0, 0);
    canvas.drawPath(centerPath, paint);

    canvas.restore();
  }

  void _drawOrchidFlowerPolar({
    required Canvas canvas,
    required Offset center,
    required double scale,
    required double rotation,
    required double time,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation + math.sin(time) * 0.03);
    canvas.scale(scale);

    void drawPolarLayer(double Function(double) radiusFunc, {int segments = 360}) {
      final path = Path();
      for (int i = 0; i <= segments; i++) {
        final double theta = (i / segments) * 2 * math.pi;
        final double r = radiusFunc(theta);

        final double x = r * math.cos(theta - math.pi / 2);
        final double y = r * math.sin(theta - math.pi / 2);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    final double breath = math.sin(time * 2) * 3.0;
    final double breathAlt = math.cos(time * 2) * 3.0;

    drawPolarLayer((theta) {
      final double baseShape = math.pow(math.cos(1.5 * theta).abs(), 1.2).toDouble();
      return (90.0 + breath) * baseShape;
    });

    drawPolarLayer((theta) {
      final double baseShape = math.pow(math.sin(theta).abs(), 1.5).toDouble();
      final double modifier = 1.0 - 0.2 * math.cos(2 * theta);
      return (80.0 + breathAlt) * baseShape * modifier;
    });

    drawPolarLayer((theta) {
      final double baseShape = math.pow((1 - math.cos(theta)) / 2, 2.5).toDouble();
      final double ruffle = 1.0 + 0.12 * math.sin(15 * theta + time * 4);
      return (75.0 + breath) * baseShape * ruffle;
    }, segments: 500);

    drawPolarLayer((theta) {
      return 12.0 + 2.0 * math.sin(3 * theta);
    });

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is FluidPainter) {
      return oldDelegate.animationValue != animationValue;
    }
    return true;
  }
}