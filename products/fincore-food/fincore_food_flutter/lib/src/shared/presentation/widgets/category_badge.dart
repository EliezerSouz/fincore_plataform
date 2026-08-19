import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';

/// Cores Semânticas de Categorias — Mapeadas para Adaptação Automática de Temas (Claro/Escuro).
enum CategorySemanticColor {
  orange(label: 'Laranja Fincore', token: 'orange', lightHex: '#EA580C', darkHex: '#F97316'),
  blue(label: 'Azul Elétrico', token: 'blue', lightHex: '#2563EB', darkHex: '#3B82F6'),
  green(label: 'Verde Sucesso', token: 'green', lightHex: '#16A34A', darkHex: '#10B981'),
  purple(label: 'Roxo Nobre', token: 'purple', lightHex: '#9333EA', darkHex: '#A855F7'),
  red(label: 'Vermelho Alerta', token: 'red', lightHex: '#DC2626', darkHex: '#EF4444'),
  teal(label: 'Ciano Teal', token: 'teal', lightHex: '#0D9488', darkHex: '#14B8A6'),
  amber(label: 'Amarelo Dourado', token: 'amber', lightHex: '#D97706', darkHex: '#F59E0B'),
  emerald(label: 'Esmeralda', token: 'emerald', lightHex: '#059669', darkHex: '#34D399'),
  indigo(label: 'Índigo', token: 'indigo', lightHex: '#4F46E5', darkHex: '#6366F1'),
  rose(label: 'Rosa Comercial', token: 'rose', lightHex: '#E11D48', darkHex: '#F43F5E');

  final String label;
  final String token;
  final String lightHex;
  final String darkHex;

  const CategorySemanticColor({
    required this.label,
    required this.token,
    required this.lightHex,
    required this.darkHex,
  });

  /// Resolve a cor física adequada com base no estado do tema (Escuro/Claro).
  Color resolveColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hex = isDark ? darkHex : lightHex;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  static CategorySemanticColor fromToken(String? token) {
    if (token == null || token.trim().isEmpty) return CategorySemanticColor.orange;
    final clean = token.trim().toLowerCase().replaceAll('#', '');
    return CategorySemanticColor.values.firstWhere(
      (c) => c.token == clean || c.name == clean,
      orElse: () => CategorySemanticColor.orange,
    );
  }
}

/// Componente [CategoryBadge] — Identidade Visual Reutilizável em Todo o ERP.
/// Usado em Produtos, Pedidos, KDS Cozinha, Estoque, Relatórios e Dashboards.
class CategoryBadge extends StatelessWidget {
  final String label;
  final String? colorToken;
  final IconData? icon;
  final bool isCompact;

  const CategoryBadge({
    super.key,
    required this.label,
    this.colorToken,
    this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = CategorySemanticColor.fromToken(colorToken);
    final color = semantic.resolveColor(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isCompact ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
