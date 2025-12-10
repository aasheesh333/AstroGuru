import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BabaAvatar extends StatelessWidget {
  final double size;

  const BabaAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(size > 50 ? 16 : 10),
        border: Border.all(color: AppColors.primaryGold, width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
