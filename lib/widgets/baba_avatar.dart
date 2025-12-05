import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceColor,
        border: Border.all(color: AppColors.primaryGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Body (Red Dress)
            Positioned(
              bottom: -size * 0.1,
              child: Container(
                width: size * 0.6,
                height: size * 0.5,
                decoration: BoxDecoration(
                  color: Colors.red[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
            // Head
            Positioned(
              top: size * 0.15,
              child: Container(
                width: size * 0.4,
                height: size * 0.45,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD180), // Skin tone
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Hair
            Positioned(
              top: size * 0.15,
              child: Container(
                width: size * 0.45,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
            // Hand Blessing (Right side)
            Positioned(
              right: size * 0.15,
              top: size * 0.4,
              child: Container(
                width: size * 0.2,
                height: size * 0.25,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD180), // Skin tone
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.back_hand, size: 20, color: Colors.brown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
