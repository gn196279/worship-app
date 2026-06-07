import 'dart:math' as math;

import 'package:flutter/material.dart';

class GilgalLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  const GilgalLogo({
    super.key,
    this.size = 96,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final ringThickness = size * 0.12;
    final crossWidth = size * 0.06;
    final crossHeight = size * 0.5;
    final crossArmWidth = size * 0.36;
    final crossArmHeight = size * 0.06;
    final noteSize = size * 0.22;
    final noteBorder = ringThickness * 0.35;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 4,
            child: CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                color: primaryColor,
                strokeWidth: ringThickness,
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: crossWidth,
                    height: crossHeight,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(crossWidth),
                    ),
                  ),
                ),
                Positioned(
                  top: size * 0.18,
                  left: (size - crossArmWidth) / 2,
                  child: Container(
                    width: crossArmWidth,
                    height: crossArmHeight,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(crossArmHeight),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.06,
                  right: size * 0.12,
                  child: Container(
                    width: noteSize,
                    height: noteSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: Center(
                      child: Container(
                        width: noteSize - (noteBorder * 2),
                        height: noteSize - (noteBorder * 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: backgroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw a 270° ring (leave a 90° gap).
    const startAngle = -math.pi / 2;
    const sweepAngle = 1.5 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

