import 'package:flutter/material.dart';

class BabaAvatar extends StatelessWidget {
  final double size;
  final bool animate;

  const BabaAvatar({
    super.key,
    this.size = 100,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border radius based on size.
    // > 50 (e.g. 120, 150) -> 16
    // <= 50 (e.g. 32, 40) -> 10
    final double radius = size > 50 ? 16 : 10;

    return Container(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
