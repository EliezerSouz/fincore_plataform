import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import '../controllers/estoque_controller.dart';
import '../controllers/planejamento_controller.dart';
import 'producao_page.dart';

/// Tela Operacional de Estoque de Produtos Acabados
///
/// Apresenta o estado real de estoque físico, reservas e disponibilidade,
/// com alertas explicativos, cobertura de produção e ações diretas.
class EstoquePage extends StatefulWidget {
  static String? filtroProdutoId;

  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  late EstoqueController _controller;
  String _filtroSelecionado = 'TODOS'; // 'TODOS', 'ACAO', 'CRITICOS', 'ATENCAO', 'PRODUCAO', 'NORMAIS'
  String _buscaTexto = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = DependencyInjection().get<EstoqueController>();

    final String? prodId = EstoquePage.filtroProdutoId;
    if (prodId != null) {
      EstoquePage.filtroProdutoId = null; // reset
      _controller.addListener(() {
        final item = _controller.itens.where((i) => i.estoque.produtoId == prodId).firstOrNull;
        if (item != null && _searchController.text.isEmpty) {
          setState(() {
            _buscaTexto = item.nomeProduto.toLowerCase();
            _searchController.text = item.nomeProduto;
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _controller),
        ChangeNotifierProvider.value(value: planeCtrl),
      ],
      child: Consumer2<EstoqueController, PlanoProducaoController>(
        builder: (context, ctrl, planeCtrl, _) {
          return Scaffold(
            backgroundColor: FincoreColors.background,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(ctrl, planeCtrl),
                Expanded(
                  child: ctrl.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ctrl.error != null
                          ? Center(
                              child: Text(
                                ctrl.error!,
                                style: const TextStyle(color: FincoreColors.danger),
                              ),
                            )
                          : _buildContent(ctrl, planeCtrl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Header Limpo e Informativo ────────────────────────────────────────────

  Widget _buildHeader(EstoqueController ctrl, PlanoProducaoController planeCtrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: FincoreColors.surface,
        border: Border(bottom: BorderSide(color: FincoreColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: FincoreColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${ctrl.itens.length} produtos monitorados',
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text('•', style: TextStyle(color: FincoreColors.textMuted)),
                Text(
                  '${ctrl.itensCriticos.length} críticos',
                  style: TextStyle(
                    color: ctrl.itensCriticos.isNotEmpty ? const Color(0xFFE05C5C) : FincoreColors.textMuted,
                    fontSize: 12,
                    fontWeight: ctrl.itensCriticos.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const Text('•', style: TextStyle(color: FincoreColors.textMuted)),
                Text(
                  '${ctrl.itensBaixos.length} em atenção',
                  style: TextStyle(
                    color: ctrl.itensBaixos.isNotEmpty ? const Color(0xFFF59E0B) : FincoreColors.textMuted,
                    fontSize: 12,
                    fontWeight: ctrl.itensBaixos.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const Text('•', style: TextStyle(color: FincoreColors.textMuted)),
                Text(
                  '${ctrl.itensNormais.length} normais',
                  style: const TextStyle(
                    color: FincoreColors.success,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Campo de busca rápida
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _buscaTexto = val.trim().toLowerCase()),
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: FincoreColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: FincoreColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textSecondary, size: 20),
            onPressed: () {
              ctrl.refresh();
              planeCtrl.refresh();
            },
            tooltip: 'Atualizar dados de estoque',
          ),
        ],
      ),
    );
  }

  // ─── Conteúdo Principal ────────────────────────────────────────────────────

  Widget _buildContent(EstoqueController ctrl, PlanoProducaoController planeCtrl) {
    if (ctrl.itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FincoreColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, color: FincoreColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum produto com controle de estoque ativo',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ative "Controla Estoque" no cadastro dos seus produtos.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Filtragem dos itens
    final itensFiltrados = ctrl.itens.where((i) {
      if (_buscaTexto.isNotEmpty && !i.nomeProduto.toLowerCase().contains(_buscaTexto)) {
        return false;
      }
      switch (_filtroSelecionado) {
        case 'ACAO':
          return i.precisaAcao;
        case 'CRITICOS':
          return i.status == EstoqueStatus.critico;
        case 'ATENCAO':
          return i.status == EstoqueStatus.baixo;
        case 'PRODUCAO':
          return i.producaoPlanejada > 0;
        case 'NORMAIS':
          return i.status == EstoqueStatus.normal;
        case 'TODOS':
        default:
          return true;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filtros Rápidos
          _buildFiltrosChips(ctrl),
          const SizedBox(height: 12),

          // 2. Seção de Alertas Operacionais Explicativos (mostra se houver itens que precisam de atenção)
          if (ctrl.itensPrecisamAcao.isNotEmpty && (_filtroSelecionado == 'TODOS' || _filtroSelecionado == 'ACAO' || _filtroSelecionado == 'CRITICOS' || _filtroSelecionado == 'ATENCAO')) ...[
            _buildSecaoAlertas(ctrl, planeCtrl),
            const SizedBox(height: 14),
          ],

          // 3. Tabela Hierárquica de Produtos
          Expanded(
            child: _buildTabelaEstoque(itensFiltrados, ctrl, planeCtrl),
          ),
        ],
      ),
    );
  }

  // ─── 2. Alertas Explicativos Acionáveis ─────────────────────────────────────

  Widget _buildSecaoAlertas(EstoqueController ctrl, PlanoProducaoController planeCtrl) {
    final itensAlerta = ctrl.itensPrecisamAcao;
    final totalCriticos = itensAlerta.where((i) => i.status == EstoqueStatus.critico).length;
    final totalAtencao = itensAlerta.where((i) => i.status == EstoqueStatus.baixo).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE05C5C).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE05C5C).withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05C5C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE05C5C)),
              ),
              const SizedBox(width: 8),
              const Text(
                'ALERTAS DE ESTOQUE — AÇÃO OPERACIONAL NECESSÁRIA',
                style: TextStyle(
                  color: Color(0xFFE05C5C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05C5C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCriticos crítico${totalCriticos != 1 ? 's' : ''} • $totalAtencao em atenção',
                  style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: itensAlerta.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = itensAlerta[idx];
                final isCritico = item.status == EstoqueStatus.critico;
                final statusColor = isCritico ? const Color(0xFFE05C5C) : const Color(0xFFF59E0B);
                
                final String metricasTexto;
                if (item.deficitAtual > 0) {
                  metricasTexto = 'Déficit atual de ${item.deficitAtual} ${item.unidade} (Físico: ${item.quantidadeAtual} • Reservado: ${item.quantidadeReservada}) • Planejado: ${item.producaoPlanejada}';
                } else if (item.producaoPlanejada > 0) {
                  metricasTexto = 'Disponível ${item.quantidadeDisponivel} • ${isCritico ? 'Crítico' : 'Mínimo'} ${isCritico ? item.quantidadeCritica : item.quantidadeMinima} • Produção planejada ${item.producaoPlanejada}';
                } else {
                  metricasTexto = 'Disponível ${item.quantidadeDisponivel} • Mínimo ${item.quantidadeMinima} • Faltam ${item.deficitMinimo > 0 ? item.deficitMinimo : item.deficitAtual} ${item.unidade} para o mínimo';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCritico ? Icons.error_rounded : Icons.warning_amber_rounded,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCritico ? 'CRÍTICO' : 'ATENÇÃO',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.nomeProduto,
                              style: const TextStyle(
                                color: FincoreColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              metricasTexto,
                              style: TextStyle(
                                color: isCritico && item.deficitAtual > 0
                                    ? const Color(0xFFE05C5C)
                                    : FincoreColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isCritico && item.deficitAtual > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (item.producaoPlanejada > 0)
                        OutlinedButton.icon(
                          onPressed: () => _abrirVerPlanejamento(context, planeCtrl, item),
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: Text('Ver planejamento (${item.producaoPlanejada})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _abrirPlanejarProducao(context, planeCtrl, item),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: Text(
                            item.sugestaoProducao > 0 ? 'Planejar produção (${item.sugestaoProducao})' : 'Planejar produção',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCritico ? const Color(0xFFE05C5C) : FincoreColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Filtros Rápidos ───────────────────────────────────────────────────

  Widget _buildFiltrosChips(EstoqueController ctrl) {
    return Row(
      children: [
        _buildChip('Todos (${ctrl.itens.length})', 'TODOS'),
        const SizedBox(width: 6),
        _buildChip('Críticos (${ctrl.itensCriticos.length})', 'CRITICOS', badgeColor: const Color(0xFFE05C5C)),
        const SizedBox(width: 6),
        _buildChip('Atenção (${ctrl.itensBaixos.length})', 'ATENCAO', badgeColor: const Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        _buildChip('Normais (${ctrl.itensNormais.length})', 'NORMAIS', badgeColor: FincoreColors.success),
        const SizedBox(width: 6),
        _buildChip('Com produção (${ctrl.itensComProducao.length})', 'PRODUCAO', badgeColor: const Color(0xFF3B82F6)),
        const SizedBox(width: 6),
        _buildChip('Precisa de ação (${ctrl.itensPrecisamAcao.length})', 'ACAO', badgeColor: const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _buildChip(String label, String key, {Color? badgeColor}) {
    final isSelected = _filtroSelecionado == key;
    return InkWell(
      onTap: () => setState(() => _filtroSelecionado = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? FincoreColors.primary)
              : FincoreColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? FincoreColors.primary)
                : FincoreColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FincoreColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─── 4. Tabela Operacional de Estoque ───────────────────────────────────────

  Widget _buildTabelaEstoque(
    List<EstoqueItem> itens,
    EstoqueController ctrl,
    PlanoProducaoController planeCtrl,
  ) {
    if (itens.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto encontrado para o filtro selecionado.',
          style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
        ),
      );
    }

    final tituloTabela = switch (_filtroSelecionado) {
      'CRITICOS' => 'PRODUTOS CRÍTICOS',
      'ATENCAO' => 'PRODUTOS EM ATENÇÃO',
      'NORMAIS' => 'PRODUTOS NORMAIS',
      'PRODUCAO' => 'PRODUTOS COM PRODUÇÃO PLANEJADA',
      'ACAO' => 'PRODUTOS QUE PRECISAM DE AÇÃO',
      _ => 'TODOS OS PRODUTOS',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            tituloTabela,
            style: const TextStyle(
              color: FincoreColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Column(
              children: [
                // Cabeçalho da Tabela
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: FincoreColors.surfaceElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border(bottom: BorderSide(color: FincoreColors.border)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 5),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildHeaderCell('PRODUTO', 'Nome cadastrado do item comercial'),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('FÍSICO', 'Saldo real presente no freezer/armazém', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('RESERVADO', 'Quantidade comprometida por pedidos existentes', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('DISPONÍVEL', 'Saldo livre para novos pedidos = Físico - Reservado', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('MÍNIMO', 'Estoque mínimo de segurança operacional', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('PRODUÇÃO', 'Quantidade prevista em planejamentos de produção ativos', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('PROJETADO', 'Estoque físico + produção planejada - reservas', align: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildHeaderCell('SITUAÇÃO', 'Classificação operacional de risco', align: TextAlign.center),
                      ),
                      const SizedBox(
                        width: 110,
                        child: Text(
                          'AÇÕES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Linhas da Tabela
                Expanded(
                  child: ListView.separated(
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                    itemBuilder: (context, i) {
                      final item = itens[i];
                      return _buildLinhaProduto(item, ctrl, planeCtrl);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, String tooltip, {TextAlign align = TextAlign.start}) {
    return Tooltip(
      message: tooltip,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          color: FincoreColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLinhaProduto(
    EstoqueItem item,
    EstoqueController ctrl,
    PlanoProducaoController planeCtrl,
  ) {
    final isCritico = item.status == EstoqueStatus.critico;
    final isBaixo = item.status == EstoqueStatus.baixo;

    final statusColor = switch (item.status) {
      EstoqueStatus.critico => const Color(0xFFE05C5C),
      EstoqueStatus.baixo => const Color(0xFFF59E0B),
      EstoqueStatus.normal => FincoreColors.success,
      EstoqueStatus.producaoNecessaria => const Color(0xFF3B82F6),
    };

    final statusLabel = switch (item.status) {
      EstoqueStatus.critico => 'Crítico',
      EstoqueStatus.baixo => 'Atenção',
      EstoqueStatus.normal => 'Normal',
      EstoqueStatus.producaoNecessaria => 'Produção Nec.',
    };

    final statusIcon = switch (item.status) {
      EstoqueStatus.critico => Icons.error_outline_rounded,
      EstoqueStatus.baixo => Icons.warning_amber_rounded,
      EstoqueStatus.normal => Icons.check_circle_outline_rounded,
      EstoqueStatus.producaoNecessaria => Icons.precision_manufacturing_outlined,
    };

    final rowBgColor = isCritico
        ? const Color(0xFFE05C5C).withValues(alpha: 0.06)
        : isBaixo
            ? const Color(0xFFF59E0B).withValues(alpha: 0.04)
            : Colors.transparent;

    return Container(
      color: rowBgColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Indicador de cor
          Container(
            width: 5,
            height: 36,
            decoration: BoxDecoration(
              color: isCritico
                  ? const Color(0xFFE05C5C)
                  : isBaixo
                      ? const Color(0xFFF59E0B)
                      : (item.corEtiqueta != null
                          ? Color(int.tryParse('0xFF${item.corEtiqueta!.replaceAll('#', '')}') ?? 0xFF6C63FF)
                          : FincoreColors.primary),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),

          // Coluna: Produto
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.nomeProduto,
                  style: TextStyle(
                    color: isCritico ? const Color(0xFFE05C5C) : FincoreColors.textPrimary,
                    fontSize: 13,
                    fontWeight: isCritico ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unidade: ${item.unidade}',
                  style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          // Coluna: Físico
          Expanded(
            flex: 2,
            child: Tooltip(
              message: 'Estoque físico real no freezer: ${item.quantidadeAtual} ${item.unidade}',
              child: Text(
                '${item.quantidadeAtual}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Coluna: Reservado
          Expanded(
            flex: 2,
            child: Tooltip(
              message: 'Quantidade comprometida por pedidos existentes: ${item.quantidadeReservada} ${item.unidade}',
              child: Text(
                '${item.quantidadeReservada}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.quantidadeReservada > 0 ? const Color(0xFFF59E0B) : FincoreColors.textMuted,
                  fontSize: 13,
                  fontWeight: item.quantidadeReservada > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // Coluna: Disponível
          Expanded(
            flex: 2,
            child: Tooltip(
              message: item.deficitAtual > 0
                  ? 'Estoque disponível para novos pedidos.\n\n${item.quantidadeAtual} físico - ${item.quantidadeReservada} reservado = ${item.quantidadeAtual - item.quantidadeReservada}.\nO sistema limita a disponibilidade comercial a 0.\n\nDéficit atual: ${item.deficitAtual} ${item.unidade}.'
                  : 'Estoque disponível para novos pedidos.\n\n${item.quantidadeAtual} físico - ${item.quantidadeReservada} reservado = ${item.quantidadeDisponivel} ${item.unidade}.',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item.quantidadeDisponivel}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.deficitAtual > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE05C5C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'déficit ${item.deficitAtual}',
                        style: const TextStyle(
                          color: Color(0xFFE05C5C),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Coluna: Mínimo
          Expanded(
            flex: 2,
            child: Tooltip(
              message: 'Estoque Mínimo: ${item.quantidadeMinima} ${item.unidade}\nEstoque Crítico: ${item.quantidadeCritica} ${item.unidade}',
              child: Text(
                '${item.quantidadeMinima}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
            ),
          ),

          // Coluna: Produção
          Expanded(
            flex: 2,
            child: Tooltip(
              message: item.producaoPlanejada > 0
                  ? 'Quantidade prevista em planejamentos de produção ativos: ${item.producaoPlanejada} ${item.unidade}.'
                  : 'Nenhuma produção planejada para este produto.',
              child: Text(
                item.producaoPlanejada > 0 ? '+${item.producaoPlanejada}' : '0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.producaoPlanejada > 0 ? const Color(0xFF3B82F6) : FincoreColors.textMuted,
                  fontSize: 13,
                  fontWeight: item.producaoPlanejada > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // Coluna: Projetado
          Expanded(
            flex: 2,
            child: Tooltip(
              message: 'Estoque físico + produção planejada - reservas.\n\n${item.quantidadeAtual} + ${item.producaoPlanejada} - ${item.quantidadeReservada} = ${item.estoqueProjetado} ${item.unidade}.\n${item.estoqueProjetado < 0 ? '\nExistem ${-item.estoqueProjetado} ${item.unidade} em falta após a produção planejada.' : ''}',
              child: Text(
                '${item.estoqueProjetado}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.estoqueProjetado < 0
                      ? const Color(0xFFE05C5C)
                      : (item.estoqueProjetado < item.quantidadeMinima
                          ? const Color(0xFFF59E0B)
                          : FincoreColors.success),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Coluna: Situação
          Expanded(
            flex: 2,
            child: Tooltip(
              message: item.motivoStatus,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Coluna: Ações
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.producaoPlanejada > 0)
                  IconButton(
                    icon: const Icon(Icons.precision_manufacturing_outlined, color: Color(0xFF3B82F6), size: 18),
                    tooltip: 'Ver Planejamento Ativo',
                    onPressed: () => _abrirVerPlanejamento(context, planeCtrl, item),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded, color: FincoreColors.primary, size: 18),
                    tooltip: 'Planejar Produção',
                    onPressed: () => _abrirPlanejarProducao(context, planeCtrl, item),
                  ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: FincoreColors.textSecondary, size: 18),
                  tooltip: 'Ajustar Saldo Físico / Inventário',
                  onPressed: () => _mostrarAjuste(context, ctrl, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ações de Planejamento e Ajuste ────────────────────────────────────────

  void _abrirPlanejarProducao(
    BuildContext context,
    PlanoProducaoController planeCtrl,
    EstoqueItem item,
  ) {
    showDialog(
      context: context,
      builder: (_) => CriarPlanoDialog(
        planeCtrl: planeCtrl,
        estoqueCtrl: _controller,
        produtoIdPreSelecionado: item.estoque.produtoId,
        quantidadePreSelecionada: item.sugestaoProducao > 0 ? item.sugestaoProducao : null,
      ),
    );
  }

  void _abrirVerPlanejamento(
    BuildContext context,
    PlanoProducaoController planeCtrl,
    EstoqueItem item,
  ) {
    final planosProduto = planeCtrl.planosAtivos
        .where((p) => p.produtoId == item.estoque.produtoId)
        .toList();

    showDialog(
      context: context,
      builder: (_) => _DialogDetalhesPlanejamento(
        item: item,
        planos: planosProduto,
      ),
    );
  }

  void _mostrarAjuste(BuildContext context, EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _DialogAjusteEstoque(
        nomeProduto: item.nomeProduto,
        quantidadeAtual: item.quantidadeAtual,
        unidade: item.unidade,
        onConfirm: (quantidade, tipo, motivo) async {
          await ctrl.ajustarEstoque(
            produtoId: item.estoque.produtoId,
            quantidade: quantidade,
            tipo: tipo,
            motivo: motivo,
          );
        },
      ),
    );
  }
}

// ─── Diálogo de Detalhes dos Planos de Produção Ativos ────────────────────────

class _DialogDetalhesPlanejamento extends StatelessWidget {
  final EstoqueItem item;
  final List<PlanoProducaoData> planos;

  const _DialogDetalhesPlanejamento({
    required this.item,
    required this.planos,
  });

  @override
  Widget build(BuildContext context) {
    final formatadorData = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF3B82F6), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Planejamento Ativo — ${item.nomeProduto}',
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Planejado: ${item.producaoPlanejada} ${item.unidade}',
                    style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${planos.length} campanha${planos.length > 1 ? 's' : ''} ativa${planos.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (planos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhum plano ativo encontrado para este produto.',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: planos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = planos[i];
                    final progresso = p.quantidadePlanejada > 0
                        ? (p.quantidadeProduzida / p.quantidadePlanejada).clamp(0.0, 1.0)
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FincoreColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Data: ${formatadorData.format(p.dataPlano.toLocal())}',
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.status.toUpperCase().replaceAll('_', ' '),
                                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Planejado: ${p.quantidadePlanejada} ${item.unidade}',
                                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                'Produzido: ${p.quantidadeProduzida} ${item.unidade} (${(progresso * 100).toInt()}%)',
                                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progresso,
                            backgroundColor: FincoreColors.border,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ProducaoPage.initialTab = 2; // Abre a aba Planejamento
            ProducaoPage.filtroProdutoId = item.estoque.produtoId; // Filtra por este produto
            Navigator.of(context).pop();
            FincoreShell.selectTab(context, 'producao');
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text('Ir para Gestão de Produção', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ─── Diálogo de Ajuste Manual de Estoque ─────────────────────────────────────

class _DialogAjusteEstoque extends StatefulWidget {
  final String nomeProduto;
  final int quantidadeAtual;
  final String unidade;
  final Future<void> Function(int quantidade, String tipo, String motivo) onConfirm;

  const _DialogAjusteEstoque({
    required this.nomeProduto,
    required this.quantidadeAtual,
    required this.unidade,
    required this.onConfirm,
  });

  @override
  State<_DialogAjusteEstoque> createState() => _DialogAjusteEstoqueState();
}

class _DialogAjusteEstoqueState extends State<_DialogAjusteEstoque> {
  String _tipo = 'entrada';
  final _qCtrl = TextEditingController();
  final _mCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: FincoreColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ajustar Estoque — ${widget.nomeProduto}',
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo Físico Atual:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                  Text(
                    '${widget.quantidadeAtual} ${widget.unidade}',
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Tipo de Movimentação:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _tipo,
              isExpanded: true,
              dropdownColor: FincoreColors.surface,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: FincoreColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada (compra/recebimento)')),
                DropdownMenuItem(value: 'ajuste_positivo', child: Text('Ajuste Positivo (+)')),
                DropdownMenuItem(value: 'ajuste_negativo', child: Text('Ajuste Negativo / Quebra (-)')),
                DropdownMenuItem(value: 'inventario', child: Text('Inventário (definir saldo)')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            const Text('Quantidade:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            TextField(
              controller: _qCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Quantidade (${widget.unidade})',
                hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: FincoreColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Motivo / Justificativa:', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            TextField(
              controller: _mCtrl,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Entrada de fornecedor, contagem de inventário...',
                hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: FincoreColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final qty = int.tryParse(_qCtrl.text);
                  if (qty == null || qty <= 0) return;
                  setState(() => _loading = true);
                  await widget.onConfirm(qty, _tipo, _mCtrl.text.isEmpty ? _tipo : _mCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar Ajuste', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
