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
    return Container(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
