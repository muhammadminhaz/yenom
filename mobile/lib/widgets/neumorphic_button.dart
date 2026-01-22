import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'neumorphic_container.dart';

class NeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double? width;
  final double height;
  final double borderRadius;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isPrimary = false,
    this.width,
    this.height = 50,
    this.borderRadius = AppConstants.radiusM,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreenDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(child: child),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: NeumorphicContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
        child: Center(child: child),
      ),
    );
  }
}
