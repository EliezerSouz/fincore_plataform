import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helpText;
  final bool isRequired;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helpText,
    this.isRequired = false,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.text.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTypography.text.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              )
            else
              Text(
                ' (opcional)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          readOnly: readOnly,
          style: AppTypography.text,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
        if (helpText != null && errorText == null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            helpText!,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
