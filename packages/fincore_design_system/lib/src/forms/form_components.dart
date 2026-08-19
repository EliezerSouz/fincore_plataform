import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:fincore_shared/fincore_shared.dart';
import '../theme/fincore_colors.dart';

// ─── Base Form Field ──────────────────────────────────────────────────────────

/// Estilo base padrão FINCORE para todos os campos de formulário.
InputDecoration _fincoreDecoration({
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
  String? errorText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    errorText: errorText,
    filled: true,
    fillColor: FincoreColors.background,
    labelStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
    hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
    errorStyle: TextStyle(color: FincoreColors.danger, fontSize: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: FincoreColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: FincoreColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: FincoreColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FincoreColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FincoreColors.danger, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ─── PhoneField ───────────────────────────────────────────────────────────────

/// Campo de formulário para telefone com máscara automática e validação.
///
/// Uso:
/// ```dart
/// PhoneField(
///   label: 'Telefone',
///   controller: _phoneController,
///   onChanged: (phone) => setState(() => _phone = phone),
/// )
/// ```
class PhoneField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final void Function(FincorePhone)? onChanged;
  final String? Function(String?)? validator;
  final bool required;
  final bool enabled;
  final String? initialValue;

  const PhoneField({
    super.key,
    this.label = 'Telefone',
    this.controller,
    this.onChanged,
    this.validator,
    this.required = true,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TelefoneInputFormatter(),
      ],
      decoration: _fincoreDecoration(
        label: label,
        hint: '(15) 99999-9999',
        prefix: const Icon(Icons.phone_outlined, size: 18),
      ),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
      validator: validator ??
          (required ? FincorePhoneValidator.formValidator : null),
      onChanged: onChanged != null
          ? (v) => onChanged!(FincorePhone.parse(v))
          : null,
    );
  }
}

// ─── CpfCnpjField ─────────────────────────────────────────────────────────────

/// Campo para CPF ou CNPJ com detecção automática e validação.
class CpfCnpjField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final void Function(FinCoreCpfCnpj)? onChanged;
  final bool required;
  final bool enabled;
  final String? initialValue;

  const CpfCnpjField({
    super.key,
    this.label = 'CPF / CNPJ',
    this.controller,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CpfOuCnpjFormatter(),
      ],
      decoration: _fincoreDecoration(
        label: label,
        hint: '000.000.000-00 ou 00.000.000/0001-00',
        prefix: const Icon(Icons.badge_outlined, size: 18),
      ),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
      validator: required
          ? (v) {
              final doc = FinCoreCpfCnpj.parse(v ?? '');
              if (!doc.isValid) return 'CPF ou CNPJ inválido';
              return null;
            }
          : null,
      onChanged: onChanged != null
          ? (v) => onChanged!(FinCoreCpfCnpj.parse(v))
          : null,
    );
  }
}

// ─── MoneyField ───────────────────────────────────────────────────────────────

/// Campo para valores monetários em BRL com máscara automática.
///
/// Retorna o valor em centavos via [onChanged].
class MoneyField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final void Function(int centavos)? onChanged;
  final bool required;
  final bool enabled;
  final int? initialCentavos;

  const MoneyField({
    super.key,
    this.label = 'Valor',
    this.controller,
    this.onChanged,
    this.required = true,
    this.enabled = true,
    this.initialCentavos,
  });

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _ctrl;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ownController = true;
      final initial = widget.initialCentavos != null
          ? FinCoreMoney.fromCentavos(widget.initialCentavos!).formattedRaw
          : '';
      _ctrl = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    if (_ownController) _ctrl.dispose();
    super.dispose();
  }

  int _parseCentavos(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        RealInputFormatter(moeda: true),
      ],
      decoration: _fincoreDecoration(
        label: widget.label,
        hint: '0,00',
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Text('R\$',
              style: TextStyle(
                  color: FincoreColors.textSecondary, fontSize: 13)),
        ),
      ),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
      validator: widget.required
          ? (v) {
              final centavos = _parseCentavos(v ?? '');
              return FincoreMoneyValidator.validate(centavos).formError;
            }
          : null,
      onChanged: widget.onChanged != null
          ? (v) => widget.onChanged!(_parseCentavos(v))
          : null,
    );
  }
}

// ─── PostalCodeField ──────────────────────────────────────────────────────────

/// Campo para CEP com máscara `#####-###` e validação.
class PostalCodeField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final void Function(FincorePostalCode)? onChanged;
  final bool required;
  final bool enabled;

  const PostalCodeField({
    super.key,
    this.label = 'CEP',
    this.controller,
    this.onChanged,
    this.required = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CepInputFormatter(),
      ],
      decoration: _fincoreDecoration(
        label: label,
        hint: '00000-000',
        prefix: const Icon(Icons.location_on_outlined, size: 18),
      ),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
      validator: required ? FincorePostalCodeValidator.formValidator : null,
      onChanged: onChanged != null
          ? (v) => onChanged!(FincorePostalCode.parse(v))
          : null,
    );
  }
}

// ─── SearchField ──────────────────────────────────────────────────────────────

/// Campo de busca com debounce, ícone e botão de limpar.
class SearchField extends StatefulWidget {
  final String hint;
  final void Function(String) onSearch;
  final Duration debounceDuration;
  final bool autofocus;

  const SearchField({
    super.key,
    this.hint = 'Buscar...',
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.autofocus = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _ctrl = TextEditingController();
  Future<void>? _debounce;

  void _onChanged(String value) {
    _debounce?.ignore();
    Future.delayed(widget.debounceDuration, () {
      if (mounted) widget.onSearch(value);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      decoration: _fincoreDecoration(
        label: '',
        hint: widget.hint,
        prefix: const Icon(Icons.search, size: 18),
        suffix: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: FincoreColors.textMuted,
                  onPressed: () {
                    _ctrl.clear();
                    widget.onSearch('');
                  },
                )
              : const SizedBox.shrink(),
        ),
      ).copyWith(labelText: null, hintText: widget.hint),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
    );
  }
}

// ─── QuantityField ────────────────────────────────────────────────────────────

/// Campo numérico com botões de incremento/decremento.
class QuantityField extends StatefulWidget {
  final String label;
  final int initialValue;
  final int min;
  final int? max;
  final void Function(int) onChanged;

  const QuantityField({
    super.key,
    this.label = 'Quantidade',
    this.initialValue = 1,
    this.min = 1,
    this.max,
    required this.onChanged,
  });

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment() {
    if (widget.max != null && _value >= widget.max!) return;
    setState(() => _value++);
    widget.onChanged(_value);
  }

  void _decrement() {
    if (_value <= widget.min) return;
    setState(() => _value--);
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: TextStyle(
                color: FincoreColors.textMuted, fontSize: 12),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: _decrement,
              enabled: _value > widget.min,
            ),
            const SizedBox(width: 12),
            Text(
              _value.toString(),
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _StepButton(
              icon: Icons.add,
              onTap: _increment,
              enabled: widget.max == null || _value < widget.max!,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? FincoreColors.primary.withOpacity(0.15)
              : FincoreColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? FincoreColors.primary.withOpacity(0.4) : FincoreColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? FincoreColors.primary : FincoreColors.textMuted,
        ),
      ),
    );
  }
}

// ─── TextAreaField ────────────────────────────────────────────────────────────

/// Campo de texto multi-linha com contador de caracteres.
class TextAreaField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final int maxLines;
  final int? maxLength;
  final bool required;
  final String? hint;

  const TextAreaField({
    super.key,
    required this.label,
    this.controller,
    this.maxLines = 4,
    this.maxLength,
    this.required = false,
    this.hint,
  });

  @override
  State<TextAreaField> createState() => _TextAreaFieldState();
}

class _TextAreaFieldState extends State<TextAreaField> {
  late TextEditingController _ctrl;
  bool _ownCtrl = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ctrl = TextEditingController();
      _ownCtrl = true;
    }
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_ownCtrl) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      decoration: _fincoreDecoration(
        label: widget.label,
        hint: widget.hint,
      ).copyWith(
        counterText: widget.maxLength != null
            ? '${_ctrl.text.length}/${widget.maxLength}'
            : null,
        counterStyle: TextStyle(
            color: FincoreColors.textMuted, fontSize: 11),
      ),
      style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
      validator: widget.required
          ? (v) => FincoreStringValidator.formValidatorRequired(v,
              fieldName: widget.label)
          : null,
    );
  }
}
