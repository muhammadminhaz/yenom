import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isInset;
  final BoxShape shape;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppConstants.radiusM,
    this.isInset = false,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color shadowLight = isDark ? AppColors.darkShadowLight : AppColors.lightShadow;
    final Color shadowDark = isDark ? AppColors.darkShadowDark : AppColors.darkShadow;

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        shape: shape,
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            offset: isInset ? const Offset(1, 1) : const Offset(-4, -4),
            blurRadius: isInset ? 2 : 10,
            spreadRadius: isInset ? 1 : 0,
          ),
          BoxShadow(
            color: shadowDark,
            offset: isInset ? const Offset(-1, -1) : const Offset(4, 4),
            blurRadius: isInset ? 2 : 10,
            spreadRadius: isInset ? 1 : 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
