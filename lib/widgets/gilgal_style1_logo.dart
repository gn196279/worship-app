import 'package:flutter/material.dart';

class GilgalStyle1Logo extends StatelessWidget {
  final double size;
  final double radius;

  const GilgalStyle1Logo({
    super.key,
    this.size = 40,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFECC813),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFECC813).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.library_music,
          color: Color(0xFF1B190D),
          size: 24,
        ),
      ),
    );
  }
}

