import 'package:flutter/material.dart';
import '../icons.dart';

class AppSearch extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AppSearch({
    super.key,
    this.hint = 'Pesquisar...',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(AppIcons.search),
        isDense: true,
      ),
    );
  }
}
