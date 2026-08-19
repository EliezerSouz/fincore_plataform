import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';

/// Campo de texto padronizado do FINCORE com suporte a validação via Form.
class FincoreTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hint;
  final int maxLines;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Validator compatível com [Form]. Retorna `null` se válido,
  /// ou uma mensagem de erro string se inválido.
  final String? Function(String?)? validator;

  /// Se true, exibe um asterisco vermelho (*) após o label indicando campo obrigatório.
  final bool isRequired;

  /// Se true, o campo não pode ser editado pelo usuário.
  final bool readOnly;

  /// Se false, desabilita a edição e ajusta a opacidade visual do campo.
  final bool enabled;

  /// Se true, oculta o texto digitado (util para senhas).
  final bool obscureText;

  const FincoreTextField({
    super.key,
    this.controller,
    this.label = '',
    this.prefixIcon,
    this.suffixIcon,
    String? hintText,
    String? hint,
    this.maxLines = 1,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
  }) : hint = hintText ?? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: FincoreColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 12,
                    color: FincoreColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly || !enabled,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? FincoreColors.textPrimary : FincoreColors.textMuted,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 14),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: (!enabled || readOnly) ? FincoreColors.background : FincoreColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: FincoreColors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: FincoreColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.danger, width: 2.0),
            ),
            errorStyle: const TextStyle(
              color: FincoreColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
