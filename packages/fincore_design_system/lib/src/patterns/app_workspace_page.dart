import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';
import '../layout/layout_components.dart';

/// Um layout de tela padrão e padronizado para fluxos operacionais (Workspaces).
///
/// Oferece um cabeçalho (toolbar), linha de filtros, área principal e um painel lateral
/// recolhível para detalhes ou ações rápidas.
///
/// Exemplo de Uso:
/// ```dart
/// AppWorkspacePage(
///   toolbar: AppToolbar(title: 'Pedidos', subtitle: 'Lista de pedidos do dia'),
///   filters: Row(children: [SearchField(onSearch: ...)]),
///   body: PedidosListView(),
///   sidePanel: PedidoDetailView(),
///   statusBar: Text('Sincronizado há 2 min'),
/// )
/// ```
class AppWorkspacePage extends StatelessWidget {
  /// O cabeçalho da página (Tipicamente um [AppToolbar]).
  final Widget? toolbar;

  /// Linha de filtros (ex: botões de busca, chips de status, dropdowns).
  final Widget? filters;

  /// A área principal de trabalho (ex: ListView, Table, GridView).
  final Widget body;

  /// Painel lateral opcional para visualização ou edição de detalhes (ex: Detalhes do Pedido).
  final Widget? sidePanel;

  /// Largura do painel lateral. Padrão: 400.
  final double sidePanelWidth;

  /// Barra de status operacional inferior (ex: status de sincronização, contadores).
  final Widget? statusBar;

  /// Se deve exibir o painel lateral.
  final bool showSidePanel;

  /// Padding interno da página.
  final EdgeInsetsGeometry padding;

  const AppWorkspacePage({
    super.key,
    this.toolbar,
    this.filters,
    required this.body,
    this.sidePanel,
    this.sidePanelWidth = 400,
    this.statusBar,
    this.showSidePanel = true,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Toolbar (Cabeçalho principal)
          if (toolbar != null) toolbar!,

          // 2. Filtros e Pesquisas
          if (filters != null) ...[
            filters!,
            const SizedBox(height: 20),
          ],

          // 3. Área de Trabalho Principal + Painel de Detalhes Lateral
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Área Principal
                Expanded(child: body),

                // Painel de Detalhes Lateral (se fornecido e configurado para exibição)
                if (sidePanel != null && showSidePanel) ...[
                  const SizedBox(width: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: sidePanelWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: sidePanel!,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Barra de Status Inferior
          if (statusBar != null) ...[
            const SizedBox(height: 16),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 12),
            statusBar!,
          ],
        ],
      ),
    );
  }
}
