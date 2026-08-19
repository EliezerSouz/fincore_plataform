import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class CrudHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? filters;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final Widget? trailing;

  const CrudHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchPlaceholder = 'Pesquisar...',
    this.onSearchChanged,
    this.filters,
    this.actionLabel,
    this.onActionPressed,
    this.actionIcon,
    this.trailing,
  });

  @override
  State<CrudHeader> createState() => _CrudHeaderState();
}

class _CrudHeaderState extends State<CrudHeader> {
  Timer? _debounce;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged?.call(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: FincoreColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Linha 2: Busca + Filtros + Botão Contextual Novo (Responsivo via Wrap)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Busca e Filtros
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.onSearchChanged != null)
                  Container(
                    width: 240,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onChanged,
                      style: TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.searchPlaceholder,
                        hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, size: 16, color: FincoreColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if (widget.filters != null && widget.filters!.isNotEmpty)
                  ...widget.filters!,
              ],
            ),
            // Botão Novo contextual com degradê
            if (widget.actionLabel != null && widget.onActionPressed != null)
              Container(
                decoration: BoxDecoration(
                  gradient: FincoreColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: widget.onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(widget.actionIcon ?? Icons.add, color: Colors.white, size: 16),
                  label: Text(
                    widget.actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
