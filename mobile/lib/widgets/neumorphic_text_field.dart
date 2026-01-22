import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'neumorphic_container.dart';

class NeumorphicTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;

  const NeumorphicTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontSize: AppConstants.fontM,
          ),
        ),
      ),
    );
  }
}
