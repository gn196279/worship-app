import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({
    super.key,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google_g.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

