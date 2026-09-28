import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:drift/drift.dart' as d;
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
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
          OutlinedButton.icon(
            onPressed: () => _abrirHistoricoGeral(context),
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('Histórico de Lançamentos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: FincoreColors.primary,
              side: BorderSide(color: FincoreColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        const Spacer(),
        // Janela de Projeção de Reservas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.date_range_rounded, size: 14, color: FincoreColors.primary),
              const SizedBox(width: 6),
              const Text('Janela de Reservas:', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              _buildJanelaChip(ctrl, 7, '7 dias'),
              const SizedBox(width: 4),
              _buildJanelaChip(ctrl, 14, '14 dias'),
              const SizedBox(width: 4),
              _buildJanelaChip(ctrl, 30, '30 dias'),
              const SizedBox(width: 4),
              _buildJanelaChip(ctrl, 0, 'Tudo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJanelaChip(EstoqueController ctrl, int dias, String label) {
    final bool isSelected = ctrl.janelaProjecaoDias == dias;
    return InkWell(
      onTap: () => ctrl.setJanelaProjecaoDias(dias),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FincoreColors.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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

void _abrirHistoricoGeral(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const _HistoricoLancamentosModal(),
  );
}

/// Categorias de processos de negócio na linha do tempo de estoque
enum TipoProcessoEstoque {
  pedidoEntregue,
  pedidoParcial,
  pedidoCancelado,
  pedidoReservado,
  producao,
  inventario,
  perda,
  ajuste,
}

/// Modelo Agregado de Processo Operacional (Visão Operacional de Negócio)
class EstoqueProcessoData {
  final String key;
  final String? pedidoId;
  final String? numeroPedido;
  final String produtoId;
  final String nomeProduto;
  final DateTime dataPrimeiroEvento;
  final DateTime dataUltimoEvento;
  final List<MovimentacaoEstoqueData> movimentacoes;

  final int quantidadeReservadaTotal;
  final int quantidadeExpedidaTotal;
  final int quantidadeLiberadaTotal;
  final int quantidadeProduzidaTotal;
  final int reservaAtiva;
  final int impactoFisicoTotal;
  final TipoProcessoEstoque tipoProcesso;

  EstoqueProcessoData({
    required this.key,
    this.pedidoId,
    this.numeroPedido,
    required this.produtoId,
    required this.nomeProduto,
    required this.dataPrimeiroEvento,
    required this.dataUltimoEvento,
    required this.movimentacoes,
    required this.quantidadeReservadaTotal,
    required this.quantidadeExpedidaTotal,
    required this.quantidadeLiberadaTotal,
    required this.quantidadeProduzidaTotal,
    required this.reservaAtiva,
    required this.impactoFisicoTotal,
    required this.tipoProcesso,
  });

  /// Título de Negócio do Processo
  String get titulo {
    final ped = numeroPedido != null && numeroPedido!.isNotEmpty ? 'PEDIDO $numeroPedido' : 'PEDIDO';
    switch (tipoProcesso) {
      case TipoProcessoEstoque.pedidoEntregue:
        return '🔴 $ped — ENTREGUE';
      case TipoProcessoEstoque.pedidoParcial:
        return '🟡 $ped — ATENDIMENTO PARCIAL';
      case TipoProcessoEstoque.pedidoCancelado:
        return '🚫 $ped — CANCELADO';
      case TipoProcessoEstoque.pedidoReservado:
        return '⏳ $ped — RESERVADO';
      case TipoProcessoEstoque.producao:
        return '⚡ PRODUÇÃO DE ESTOQUE';
      case TipoProcessoEstoque.inventario:
        return '📋 AJUSTE DE INVENTÁRIO';
      case TipoProcessoEstoque.perda:
        return '⚠️ PERDA / AVARIA DE ESTOQUE';
      case TipoProcessoEstoque.ajuste:
        return '⚙️ AJUSTE MANUAL';
    }
  }

  /// Resumo claro do fluxo do processo para o usuário
  String get resumoFluxo {
    switch (tipoProcesso) {
      case TipoProcessoEstoque.pedidoEntregue:
        return '$quantidadeReservadaTotal un. reservadas ➔ $quantidadeExpedidaTotal un. entregues\nReserva consumida • Impacto físico: -$quantidadeExpedidaTotal un.';
      case TipoProcessoEstoque.pedidoParcial:
        return '$quantidadeReservadaTotal un. reservadas | $quantidadeExpedidaTotal un. expedidas | $reservaAtiva un. ainda reservadas';
      case TipoProcessoEstoque.pedidoCancelado:
        return '$quantidadeReservadaTotal un. de reserva liberadas (sem saída física)';
      case TipoProcessoEstoque.pedidoReservado:
        return '$quantidadeReservadaTotal un. comprometidas no estoque reservado (aguardando expedição)';
      case TipoProcessoEstoque.producao:
        return 'Adicionou $quantidadeProduzidaTotal un. ao estoque físico real';
      case TipoProcessoEstoque.inventario:
        final delta = movimentacoes.last.quantidadeDepois - movimentacoes.first.quantidadeAntes;
        final deltaStr = delta >= 0 ? '+$delta' : '$delta';
        return 'Contagem física atualizada de ${movimentacoes.first.quantidadeAntes} para ${movimentacoes.last.quantidadeDepois} un. (Ajuste: $deltaStr un.)';
      case TipoProcessoEstoque.perda:
        final qtd = movimentacoes.first.quantidade;
        return 'Registrou perda física de $qtd un. no depósito';
      case TipoProcessoEstoque.ajuste:
        return movimentacoes.first.motivo ?? 'Ajuste manual de estoque';
    }
  }

  /// Badge de impacto no estoque físico
  String get badgeImpactoFisico {
    if (tipoProcesso == TipoProcessoEstoque.pedidoCancelado) {
      return 'Físico: 0 un.';
    }
    if (impactoFisicoTotal > 0) {
      return 'Físico: +$impactoFisicoTotal un.';
    } else if (impactoFisicoTotal < 0) {
      return 'Físico: $impactoFisicoTotal un.';
    } else {
      return 'Físico: 0 un.';
    }
  }

  /// Semântica de cores oficial
  Color get corStatus {
    switch (tipoProcesso) {
      case TipoProcessoEstoque.pedidoEntregue:
        return const Color(0xFFEF4444); // VERMELHO (Saída Física)
      case TipoProcessoEstoque.pedidoParcial:
        return const Color(0xFFF59E0B); // AMARELO / ÂMBAR
      case TipoProcessoEstoque.pedidoCancelado:
        return const Color(0xFFEF4444); // VERMELHO
      case TipoProcessoEstoque.pedidoReservado:
        return const Color(0xFF3B82F6); // AZUL (Informação/Reserva Ativa)
      case TipoProcessoEstoque.producao:
        return const Color(0xFF10B981); // VERDE (Entrada Física)
      case TipoProcessoEstoque.inventario:
      case TipoProcessoEstoque.ajuste:
        return const Color(0xFF8B5CF6); // ROXO
      case TipoProcessoEstoque.perda:
        return const Color(0xFFEF4444); // VERMELHO
    }
  }

  IconData get iconeStatus {
    switch (tipoProcesso) {
      case TipoProcessoEstoque.pedidoEntregue:
        return Icons.local_shipping_rounded;
      case TipoProcessoEstoque.pedidoParcial:
        return Icons.hourglass_bottom_rounded;
      case TipoProcessoEstoque.pedidoCancelado:
        return Icons.cancel_outlined;
      case TipoProcessoEstoque.pedidoReservado:
        return Icons.bookmark_added_rounded;
      case TipoProcessoEstoque.producao:
        return Icons.precision_manufacturing_rounded;
      case TipoProcessoEstoque.inventario:
      case TipoProcessoEstoque.ajuste:
        return Icons.fact_check_outlined;
      case TipoProcessoEstoque.perda:
        return Icons.warning_amber_rounded; // Ícone próprio para Perda
    }
  }
}

/// Modal com a Linha do Tempo Operacional de Estoque (Agrupada por Processo) + Auditoria
class _HistoricoLancamentosModal extends StatefulWidget {
  const _HistoricoLancamentosModal();

  @override
  State<_HistoricoLancamentosModal> createState() => _HistoricoLancamentosModalState();
}

class _HistoricoLancamentosModalState extends State<_HistoricoLancamentosModal> {
  bool _loading = true;
  List<MovimentacaoEstoqueData> _movimentacoes = [];
  List<ProdutoData> _produtosList = [];
  Map<String, String> _produtosNomes = {};
  Map<String, String> _pedidosNumeros = {};

  // Filtros & Ordenação
  String _filtroTipo = 'TODOS'; // 'TODOS', 'PRODUCAO', 'EXPEDICAO', 'RESERVA', 'AJUSTE', 'PERDA'
  String? _produtoIdSelecionado; // null = Todos
  String _ordemCronologica = 'ASC'; // 'ASC' = Mais antigas primeiro (Recomendado auditoria), 'DESC' = Mais recentes primeiro
  String _periodoPreset = '30DIAS';
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();

  StreamSubscription? _syncSub;

  @override
  void initState() {
    super.initState();
    _aplicarPresetPeriodo('30DIAS', carregar: false);
    _carregarData();
    try {
      final syncService = DependencyInjection().get<SupabaseSyncService>();
      _syncSub = syncService.onDataSynced.listen((_) {
        if (mounted) _carregarData();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  void _aplicarPresetPeriodo(String preset, {bool carregar = true}) {
    final now = DateTime.now();
    DateTime inicio;
    DateTime fim = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case 'HOJE':
        inicio = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case '7DIAS':
        inicio = DateTime(now.year, now.month, now.day, 0, 0, 0).subtract(const Duration(days: 7));
        break;
      case 'MES_ATUAL':
        inicio = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case '30DIAS':
      default:
        inicio = DateTime(now.year, now.month, now.day, 0, 0, 0).subtract(const Duration(days: 30));
        break;
    }

    setState(() {
      _periodoPreset = preset;
      _dataInicio = inicio;
      _dataFim = fim;
    });

    if (carregar) {
      _carregarData();
    }
  }

  Future<void> _selecionarPeriodoCustomizado() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: FincoreColors.primary,
              onPrimary: Colors.white,
              surface: FincoreColors.surface,
              onSurface: FincoreColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _periodoPreset = 'CUSTOM';
        _dataInicio = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _dataFim = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _carregarData();
    }
  }

  Future<void> _carregarData() async {
    setState(() => _loading = true);
    final db = DependencyInjection().get<FincoreDatabase>();
    final tenantCtx = DependencyInjection().get<TenantContext>();
    final tenantId = tenantCtx.hasContext ? tenantCtx.tenantId : '';

    final prods = await (db.select(db.produtosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull())
          ..orderBy([(t) => d.OrderingTerm.asc(t.nome)]))
        .get();

    final Map<String, String> nomes = {
      for (final p in prods) p.id: p.nome,
    };

    final pedidos = await (db.select(db.pedidosTable)
          ..where((t) => t.tenantId.equals(tenantId)))
        .get();

    final Map<String, String> pedidosNumeros = {
      for (final p in pedidos)
        p.id: p.numeroPedido != null
            ? '#${p.numeroPedido.toString().padLeft(4, '0')}'
            : '#${p.id.substring(0, 4).toUpperCase()}',
    };

    final startUtc = _dataInicio.toUtc();
    final endUtc = _dataFim.toUtc();

    final movs = await (db.select(db.movimentacoesEstoqueTable)
          ..where((t) {
            d.Expression<bool> expr = t.tenantId.equals(tenantId) & t.deletedAt.isNull();
            if (_produtoIdSelecionado != null && _produtoIdSelecionado!.isNotEmpty) {
              expr = expr & t.produtoId.equals(_produtoIdSelecionado!);
            }
            expr = expr & t.dataHora.isBiggerOrEqualValue(startUtc);
            expr = expr & t.dataHora.isSmallerOrEqualValue(endUtc);
            return expr;
          })
          ..orderBy([(t) => d.OrderingTerm.asc(t.dataHora)])
          ..limit(500))
        .get();

    // Reconstrução matemática encadeada dos saldos por produto
    final Map<String, List<MovimentacaoEstoqueData>> movsPorProduto = {};
    for (final m in movs) {
      movsPorProduto.putIfAbsent(m.produtoId, () => []).add(m);
    }

    final List<MovimentacaoEstoqueData> movsCalculadas = [];

    for (final entry in movsPorProduto.entries) {
      final listProd = entry.value;
      listProd.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      int runningFisico = 0;
      int runningReserva = 0;

      for (final m in listProd) {
        final tipo = (m.tipo ?? '').toLowerCase();
        final isInventario = tipo.contains('inventario');
        final isReserva = tipo.contains('reserva') && !tipo.contains('liberacao');
        final isEntrada = !isReserva && !isInventario && (tipo.contains('entrada') || tipo.contains('positivo') || tipo.contains('producao') || tipo.contains('devolucao'));
        final isSaida = !isReserva && !isInventario && (tipo.contains('saida') || tipo.contains('expedicao') || tipo.contains('negativo') || tipo.contains('perda') || tipo.contains('descarte'));

        int qAntes;
        int qDepois;
        int resAntes = runningReserva;
        int resDepois = runningReserva;

        if (isInventario) {
          qAntes = runningFisico;
          qDepois = m.quantidadeDepois > 0 ? m.quantidadeDepois : m.quantidade;
          runningFisico = qDepois;
        } else if (isEntrada) {
          qAntes = runningFisico;
          qDepois = runningFisico + m.quantidade;
          runningFisico = qDepois;
        } else if (isSaida) {
          qAntes = runningFisico;
          qDepois = runningFisico - m.quantidade;
          runningFisico = qDepois;
          if (tipo.contains('expedicao') && runningReserva > 0) {
            resDepois = (runningReserva - m.quantidade).clamp(0, 999999);
            runningReserva = resDepois;
          }
        } else if (isReserva) {
          qAntes = runningFisico;
          qDepois = runningFisico;
          resAntes = runningReserva;
          resDepois = runningReserva + m.quantidade;
          runningReserva = resDepois;
        } else {
          qAntes = runningFisico;
          qDepois = runningFisico;
        }

        movsCalculadas.add(m.copyWith(
          quantidadeAntes: qAntes,
          quantidadeDepois: qDepois,
          quantidadeReservadaAntes: d.Value(resAntes),
          quantidadeReservadaDepois: d.Value(resDepois),
        ));
      }
    }

    if (mounted) {
      setState(() {
        _movimentacoes = movsCalculadas;
        _produtosList = prods;
        _produtosNomes = nomes;
        _pedidosNumeros = pedidosNumeros;
        _loading = false;
      });
    }
  }

  /// Agrupa os eventos técnicos brutos em PROCESSOS de negócio operacionais
  List<EstoqueProcessoData> _agruparProcessos(List<MovimentacaoEstoqueData> movsCalculadas) {
    final Map<String, List<MovimentacaoEstoqueData>> grupos = {};

    for (final m in movsCalculadas) {
      final String key;
      if (m.pedidoId != null && m.pedidoId!.isNotEmpty) {
        key = 'pedido_${m.pedidoId}_${m.produtoId}';
      } else {
        key = 'standalone_${m.id}';
      }
      grupos.putIfAbsent(key, () => []).add(m);
    }

    final List<EstoqueProcessoData> processos = [];

    for (final entry in grupos.entries) {
      final list = entry.value;
      list.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      final prime = list.first;
      final ult = list.last;
      final prodId = prime.produtoId;
      final nomeProd = _produtosNomes[prodId] ?? 'Produto Removido';
      final pedId = prime.pedidoId;
      final numPed = pedId != null ? _pedidosNumeros[pedId] : null;

      int resTotal = 0;
      int expTotal = 0;
      int libTotal = 0;
      int prodTotal = 0;

      for (final m in list) {
        final tipo = (m.tipo ?? '').toLowerCase();
        final isReserva = tipo.contains('reserva') && !tipo.contains('liberacao');
        final isExpedicao = tipo.contains('expedicao') || tipo.contains('saida');
        final isLiberacao = tipo.contains('liberacao') || tipo.contains('cancelamento');
        final isProducao = tipo.contains('producao') || (m.motivo?.contains('producao') ?? false);

        if (isReserva) resTotal += m.quantidade;
        if (isExpedicao && !tipo.contains('perda') && !tipo.contains('descarte')) expTotal += m.quantidade;
        if (isLiberacao) libTotal += m.quantidade;
        if (isProducao) prodTotal += m.quantidade;
      }

      final int resAtiva = (resTotal - expTotal - libTotal).clamp(0, 999999);

      final TipoProcessoEstoque tipoProc;
      final int impactoFisico;

      if (pedId != null && pedId.isNotEmpty) {
        if (expTotal >= resTotal && resTotal > 0) {
          tipoProc = TipoProcessoEstoque.pedidoEntregue;
          impactoFisico = -expTotal;
        } else if (expTotal > 0 && resAtiva > 0) {
          tipoProc = TipoProcessoEstoque.pedidoParcial;
          impactoFisico = -expTotal;
        } else if (libTotal > 0 && resAtiva == 0 && expTotal == 0) {
          tipoProc = TipoProcessoEstoque.pedidoCancelado;
          impactoFisico = 0;
        } else if (resAtiva > 0) {
          tipoProc = TipoProcessoEstoque.pedidoReservado;
          impactoFisico = 0;
        } else {
          tipoProc = expTotal > 0 ? TipoProcessoEstoque.pedidoEntregue : TipoProcessoEstoque.pedidoReservado;
          impactoFisico = -expTotal;
        }
      } else {
        final tipoRaw = (prime.tipo ?? '').toLowerCase();
        if (tipoRaw.contains('producao')) {
          tipoProc = TipoProcessoEstoque.producao;
          impactoFisico = prime.quantidade;
        } else if (tipoRaw.contains('inventario')) {
          tipoProc = TipoProcessoEstoque.inventario;
          impactoFisico = ult.quantidadeDepois - prime.quantidadeAntes;
        } else if (tipoRaw.contains('perda') || tipoRaw.contains('descarte')) {
          tipoProc = TipoProcessoEstoque.perda;
          impactoFisico = -prime.quantidade;
        } else {
          tipoProc = TipoProcessoEstoque.ajuste;
          impactoFisico = ult.quantidadeDepois - prime.quantidadeAntes;
        }
      }

      processos.add(EstoqueProcessoData(
        key: entry.key,
        pedidoId: pedId,
        numeroPedido: numPed,
        produtoId: prodId,
        nomeProduto: nomeProd,
        dataPrimeiroEvento: prime.dataHora,
        dataUltimoEvento: ult.dataHora,
        movimentacoes: list,
        quantidadeReservadaTotal: resTotal,
        quantidadeExpedidaTotal: expTotal,
        quantidadeLiberadaTotal: libTotal,
        quantidadeProduzidaTotal: prodTotal,
        reservaAtiva: resAtiva,
        impactoFisicoTotal: impactoFisico,
        tipoProcesso: tipoProc,
      ));
    }

    if (_ordemCronologica == 'DESC') {
      processos.sort((a, b) => b.dataUltimoEvento.compareTo(a.dataUltimoEvento));
    } else {
      processos.sort((a, b) => a.dataUltimoEvento.compareTo(b.dataUltimoEvento));
    }

    return processos;
  }

  void _abrirDetalhesProcesso(EstoqueProcessoData proc) {
    showDialog(
      context: context,
      builder: (_) => _DetalhesProcessoModal(
        processo: proc,
        pedidosNumeros: _pedidosNumeros,
      ),
    );
  }

  void _abrirComoChegamosAoSaldo(ProdutoData prod, List<MovimentacaoEstoqueData> movsProduto) {
    showDialog(
      context: context,
      builder: (_) => _ComoChegamosAoSaldoModal(
        produto: prod,
        movimentacoes: movsProduto,
        pedidosNumeros: _pedidosNumeros,
        processos: _agruparProcessos(movsProduto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosProcessos = _agruparProcessos(_movimentacoes);

    final processosFiltrados = todosProcessos.where((p) {
      if (_filtroTipo == 'TODOS') return true;
      if (_filtroTipo == 'PRODUCAO') return p.tipoProcesso == TipoProcessoEstoque.producao;
      if (_filtroTipo == 'EXPEDICAO') {
        return p.tipoProcesso == TipoProcessoEstoque.pedidoEntregue || p.tipoProcesso == TipoProcessoEstoque.pedidoParcial || p.quantidadeExpedidaTotal > 0;
      }
      if (_filtroTipo == 'RESERVA') {
        return p.tipoProcesso == TipoProcessoEstoque.pedidoReservado || p.tipoProcesso == TipoProcessoEstoque.pedidoParcial || p.quantidadeReservadaTotal > 0;
      }
      if (_filtroTipo == 'AJUSTE') {
        return p.tipoProcesso == TipoProcessoEstoque.inventario || p.tipoProcesso == TipoProcessoEstoque.ajuste;
      }
      if (_filtroTipo == 'PERDA') return p.tipoProcesso == TipoProcessoEstoque.perda;
      return true;
    }).toList();

    int entradasFisicas = 0;
    int saidasFisicas = 0;
    int countReservas = 0;
    int countAjustes = 0;

    for (final p in todosProcessos) {
      if (p.impactoFisicoTotal > 0) entradasFisicas += p.impactoFisicoTotal;
      if (p.impactoFisicoTotal < 0) saidasFisicas += p.impactoFisicoTotal.abs();
      if (p.quantidadeReservadaTotal > 0) countReservas++;
      if (p.tipoProcesso == TipoProcessoEstoque.inventario || p.tipoProcesso == TipoProcessoEstoque.ajuste) countAjustes++;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodoTexto = '${dateFormat.format(_dataInicio)} até ${dateFormat.format(_dataFim)}';
    final prodSelecionadoObj = _produtoIdSelecionado != null
        ? _produtosList.cast<ProdutoData?>().firstWhere((p) => p?.id == _produtoIdSelecionado, orElse: () => null)
        : null;

    final prodNome = prodSelecionadoObj?.nome;
    final tituloHeader = prodNome != null
        ? 'Linha do Tempo Operacional — $prodNome'
        : 'Linha do Tempo Operacional de Estoque — Todos os produtos';

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 960,
        height: 740,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: FincoreColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloHeader,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Processos operacionais de negócio • Agrupamento transparente sem dupla contagem • $periodoTexto',
                        style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Recarregar histórico',
                  icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textSecondary, size: 20),
                  onPressed: _carregarData,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 12),

            // Contexto compacto de produto
            if (prodSelecionadoObj != null) ...[
              _buildResumoProdutoTopo(prodSelecionadoObj, _movimentacoes),
              const SizedBox(height: 12),
            ],

            // Linha 1 de Filtros
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: FincoreColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          periodoTexto,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                        ),
                        const Spacer(),
                        _buildPeriodPresetBtn('HOJE', 'Hoje'),
                        _buildPeriodPresetBtn('7DIAS', '7 dias'),
                        _buildPeriodPresetBtn('30DIAS', '30 dias'),
                        _buildPeriodPresetBtn('MES_ATUAL', 'Este Mês'),
                        InkWell(
                          onTap: _selecionarPeriodoCustomizado,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _periodoPreset == 'CUSTOM' ? FincoreColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.date_range_rounded,
                              size: 14,
                              color: _periodoPreset == 'CUSTOM' ? Colors.white : FincoreColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Seletor por Produto
                SizedBox(
                  width: 250,
                  height: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _produtoIdSelecionado,
                        isExpanded: true,
                        dropdownColor: FincoreColors.surface,
                        hint: const Text('Todos os Produtos', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: FincoreColors.textMuted),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Todos os Produtos',
                              style: TextStyle(fontSize: 11, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ..._produtosList.map((p) {
                            return DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text(
                                p.nome,
                                style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _produtoIdSelecionado = val;
                          });
                          _carregarData();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Controle de Ordenação Cronológica (Recomendado: ASC / Mais antigas primeiro)
                SizedBox(
                  width: 180,
                  height: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _ordemCronologica,
                        isExpanded: true,
                        dropdownColor: FincoreColors.surface,
                        icon: Icon(Icons.sort_rounded, color: FincoreColors.primary, size: 16),
                        items: const [
                          DropdownMenuItem(
                            value: 'ASC',
                            child: Text('Mais antigas primeiro', style: TextStyle(fontSize: 11, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold)),
                          ),
                          DropdownMenuItem(
                            value: 'DESC',
                            child: Text('Mais recentes primeiro', style: TextStyle(fontSize: 11, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _ordemCronologica = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Linha 2 de Filtros: Chips e Totais
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildFilterChip('TODOS', 'Todos (${processosFiltrados.length})'),
                      _buildFilterChip('PRODUCAO', 'Produção'),
                      _buildFilterChip('EXPEDICAO', 'Expedições / Entregas'),
                      _buildFilterChip('RESERVA', 'Reservas Ativas / Pedidos'),
                      _buildFilterChip('AJUSTE', 'Ajustes / Inventário'),
                      _buildFilterChip('PERDA', 'Perdas'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Resumo Semântico do Período
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Entradas físicas acumuladas no período',
                        child: Text(
                          'Entradas: +$entradasFisicas un',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('|', style: TextStyle(color: FincoreColors.border, fontSize: 11)),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Saídas físicas acumuladas no período',
                        child: Text(
                          'Saídas: -$saidasFisicas un',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('|', style: TextStyle(color: FincoreColors.border, fontSize: 11)),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Processos com reservas no período',
                        child: Text(
                          'Reservas: $countReservas procs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('|', style: TextStyle(color: FincoreColors.border, fontSize: 11)),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Ajustes e inventários no período',
                        child: Text(
                          'Ajustes: $countAjustes procs',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Linha do Tempo de Processos Operacionais
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : processosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 40, color: FincoreColors.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhum processo operacional encontrado',
                                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Nenhum processo de estoque corresponde aos filtros selecionados.',
                                style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: FincoreColors.border),
                            borderRadius: BorderRadius.circular(8),
                            color: FincoreColors.background.withValues(alpha: 0.5),
                          ),
                          child: ListView.builder(
                            itemCount: processosFiltrados.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, i) {
                              final proc = processosFiltrados[i];
                              final isLast = i == processosFiltrados.length - 1;
                              return _buildProcessCard(proc, isLast: isLast);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Resumo Superior com Hierarquia Visual Clara (FÍSICO / RESERVADO / DISPONÍVEL)
  Widget _buildResumoProdutoTopo(ProdutoData prod, List<MovimentacaoEstoqueData> movsProduto) {
    final int fisico = movsProduto.isNotEmpty ? movsProduto.last.quantidadeDepois : 0;
    final int reservado = movsProduto.isNotEmpty ? (movsProduto.last.quantidadeReservadaDepois ?? 0) : 0;
    final int disponivel = fisico - reservado;
    final String ultimaMovStr = movsProduto.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(movsProduto.last.dataHora.toLocal())
        : 'Sem registros';
    final String ultimoTipo = movsProduto.isNotEmpty ? (movsProduto.last.tipo ?? 'Movimentação') : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: FincoreColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                prod.nome.toUpperCase(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: FincoreColors.primary, letterSpacing: 0.5),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Último registro: $ultimoTipo ($ultimaMovStr)',
                  style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _abrirComoChegamosAoSaldo(prod, movsProduto),
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: const Text('Como chegamos a este saldo?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FincoreColors.primary,
                  side: BorderSide(color: FincoreColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetricCard(
                  label: 'FÍSICO',
                  value: '$fisico un.',
                  tooltip: 'Quantidade fisicamente armazenada no depósito/freezer.',
                  color: FincoreColors.textPrimary,
                  bgColor: FincoreColors.surface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderMetricCard(
                  label: 'RESERVADO',
                  value: '$reservado un.',
                  tooltip: 'Quantidade comprometida com pedidos pendentes que ainda não foram expedidos.',
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderMetricCard(
                  label: 'DISPONÍVEL',
                  value: '$disponivel un.',
                  tooltip: 'Quantidade livre para novos pedidos (FÍSICO - RESERVADO).',
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetricCard({
    required String label,
    required String value,
    required String tooltip,
    required Color color,
    required Color bgColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                ),
                const Spacer(),
                Icon(Icons.info_outline_rounded, size: 12, color: color.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // Visual do Card de Processo Operacional na Timeline
  Widget _buildProcessCard(EstoqueProcessoData proc, {required bool isLast}) {
    final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(proc.dataUltimoEvento.toLocal());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conector Visual da Linha do Tempo
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: proc.corStatus.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: proc.corStatus, width: 2),
                  ),
                  child: Center(
                    child: Icon(proc.iconeStatus, size: 11, color: proc.corStatus),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: FincoreColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Conteúdo do Card de Processo Operacional
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge de Status do Processo com Semântica Oficial
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: proc.corStatus.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: proc.corStatus.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          proc.titulo,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: proc.corStatus),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dataStr,
                        style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                      ),
                      const Spacer(),

                      // Badge de Impacto Físico
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Text(
                          proc.badgeImpactoFisico,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: proc.impactoFisicoTotal < 0
                                ? const Color(0xFFEF4444)
                                : (proc.impactoFisicoTotal > 0 ? const Color(0xFF10B981) : FincoreColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Produto e Detalhes do Fluxo
                  Text(
                    proc.nomeProduto,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proc.resumoFluxo,
                    style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: FincoreColors.border, height: 1),
                  const SizedBox(height: 6),

                  // Ação e Eventos Internos
                  Row(
                    children: [
                      Icon(Icons.layers_outlined, size: 12, color: FincoreColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${proc.movimentacoes.length} ${proc.movimentacoes.length == 1 ? "evento interno registrado" : "eventos internos registrados"}',
                        style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _abrirDetalhesProcesso(proc),
                        child: Row(
                          children: [
                            Text(
                              'Ver detalhes do processo',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 16, color: FincoreColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPresetBtn(String preset, String label) {
    final isSel = _periodoPreset == preset;
    return InkWell(
      onTap: () => _aplicarPresetPeriodo(preset),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isSel ? FincoreColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSel ? Border.all(color: FincoreColors.primary, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? FincoreColors.primary : FincoreColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSel = _filtroTipo == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSel ? Colors.white : FincoreColors.textSecondary,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSel,
      selectedColor: FincoreColors.primary,
      backgroundColor: FincoreColors.background,
      onSelected: (_) => setState(() => _filtroTipo = value),
    );
  }
}

/// Modal de Consulta de Pedido em Modo Somente Leitura (Sem navegação forçada para Central de Pedidos)
class _ConsultaPedidoModal extends StatefulWidget {
  final String pedidoId;
  final String? numeroPedido;

  const _ConsultaPedidoModal({
    required this.pedidoId,
    this.numeroPedido,
  });

  @override
  State<_ConsultaPedidoModal> createState() => _ConsultaPedidoModalState();
}

class _ConsultaPedidoModalState extends State<_ConsultaPedidoModal> {
  bool _loading = true;
  PedidoData? _pedido;
  List<ItemPedidoData> _itens = [];
  Map<String, String> _produtosNomes = {};

  @override
  void initState() {
    super.initState();
    _carregarPedido();
  }

  Future<void> _carregarPedido() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final tenantId = tenantCtx.hasContext ? tenantCtx.tenantId : '';

      final ped = await (db.select(db.pedidosTable)
            ..where((t) => t.id.equals(widget.pedidoId) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();

      final itemRows = await (db.select(db.itensPedidoTable)
            ..where((t) => t.pedidoId.equals(widget.pedidoId) & t.deletedAt.isNull()))
          .get();

      final prods = await (db.select(db.produtosTable)
            ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
          .get();

      final Map<String, String> nomes = {
        for (final p in prods) p.id: p.nome,
      };

      if (mounted) {
        setState(() {
          _pedido = ped;
          _itens = itemRows;
          _produtosNomes = nomes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ped = _pedido;
    final numPedStr = widget.numeroPedido ?? (ped?.numeroPedido != null ? '#${ped!.numeroPedido.toString().padLeft(4, "0")}' : '#${widget.pedidoId.substring(0, 4).toUpperCase()}');
    final statusStr = (ped?.status ?? 'ENTREGUE').toUpperCase();
    final clienteStr = ped?.clienteNomeAvulso ?? 'Balcão / Consumidor';
    final dtRef = ped?.dataHoraEntregaPrevista ?? ped?.dataHoraCriacao;
    final dataStr = dtRef != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dtRef.toLocal())
        : 'Data não informada';

    final isEntregue = statusStr.contains('ENTREGUE') || statusStr.contains('CONCLUIDO');
    final isCancelado = statusStr.contains('CANCEL');

    final Color statusColor = isEntregue
        ? const Color(0xFFEF4444) // Identidade vermelha de saída física
        : (isCancelado ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));

    int totalCentavos = (ped?.valorTotalCentavos ?? 0.0).round();
    if (totalCentavos <= 0) {
      for (final item in _itens) {
        totalCentavos += (item.quantidade * item.valorUnitarioCentavos).round();
      }
    }
    final totalReaisStr = (totalCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',');

    double totalQtd = 0;
    for (final item in _itens) {
      totalQtd += item.quantidade;
    }
    final totalQtdStr = (totalQtd % 1 == 0) ? totalQtd.toInt().toString() : totalQtd.toStringAsFixed(1);
    final totalExpedidaStr = isEntregue ? totalQtdStr : '0';

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Identificação do Pedido
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'PEDIDO $numPedStr • MODO CONSULTA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Text(
                          'Status: $statusStr',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Corpo em ScrollView
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Cliente / Data / Origem
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Cliente', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
                                      Text(clienteStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Data do Pedido', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
                                      Text(dataStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Origem / Canal', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
                                      const Text('Balcão / POS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Itens do Pedido
                          const Text('Itens do Pedido', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: FincoreColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.5),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: FincoreColors.background),
                                  children: const [
                                    Padding(padding: EdgeInsets.all(8), child: Text('Produto', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Qtd', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Valor Unit.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Subtotal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                  ],
                                ),
                                ..._itens.map((item) {
                                  final nomeProd = _produtosNomes[item.produtoId] ?? 'Produto';
                                  final unitReais = (item.valorUnitarioCentavos / 100.0).toStringAsFixed(2).replaceAll('.', ',');
                                  final subtotalReais = ((item.quantidade * item.valorUnitarioCentavos) / 100.0).toStringAsFixed(2).replaceAll('.', ',');
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(8), child: Text(nomeProd, style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('${(item.quantidade % 1 == 0) ? item.quantidade.toInt() : item.quantidade} un', style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('R\$ $unitReais', style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('R\$ $subtotalReais', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total do Pedido: R\$ $totalReaisStr',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FincoreColors.primary),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. Linha do Tempo Operacional
                          const Text('Linha do Tempo Operacional', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildCheckstep('Criado', true),
                              _buildStepConnector(true),
                              _buildCheckstep('Reserva', true),
                              _buildStepConnector(true),
                              _buildCheckstep('Preparação', true),
                              _buildStepConnector(!isCancelado),
                              _buildCheckstep('Expedição', !isCancelado),
                              _buildStepConnector(isEntregue),
                              _buildCheckstep('Entregue', isEntregue),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 5. Explicação Detalhada das Etapas
                          const Text('Detalhamento das Etapas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                          const SizedBox(height: 8),
                          _buildStepDetailCard(
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: '✓ CRIADO',
                            subtitle: dataStr,
                            description: 'Pedido registrado no sistema.',
                            impactText: 'Impacto: Nenhum impacto no estoque.',
                            impactBgColor: FincoreColors.background,
                          ),
                          const SizedBox(height: 8),
                          _buildStepDetailCard(
                            icon: Icons.bookmark_added_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: '🟡 RESERVA',
                            subtitle: dataStr,
                            description: '$totalQtdStr un. de produtos foram comprometidas para este pedido.',
                            impactText: 'Impacto: Físico: não altera  |  Reservado: +$totalQtdStr un.  |  Disponível: -$totalQtdStr un.',
                            impactBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 8),
                          _buildStepDetailCard(
                            icon: Icons.outdoor_grill_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            title: 'PREPARAÇÃO',
                            subtitle: 'Cozinha / Produção',
                            description: 'Pedido separado/preparado para atendimento.',
                            impactText: 'Impacto: Nenhuma movimentação física.',
                            impactBgColor: FincoreColors.background,
                          ),
                          const SizedBox(height: 8),
                          _buildStepDetailCard(
                            icon: Icons.local_shipping_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: '🔴 EXPEDIÇÃO',
                            subtitle: dataStr,
                            description: '$totalExpedidaStr un. foram retiradas fisicamente do estoque.',
                            impactText: 'Impacto: Físico: -$totalExpedidaStr un.  |  Reserva: -$totalExpedidaStr un. (Reserva consumida)',
                            impactBgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 8),
                          _buildStepDetailCard(
                            icon: isEntregue ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
                            iconColor: isEntregue ? const Color(0xFFEF4444) : FincoreColors.textMuted,
                            title: '✓ ENTREGUE',
                            subtitle: isEntregue ? dataStr : 'Pendente',
                            description: isEntregue ? 'Pedido concluído com sucesso.' : 'Aguardando entrega.',
                            impactText: isEntregue
                                ? 'Resultado: $totalQtdStr un. reservadas  →  $totalExpedidaStr un. expedidas  →  0 un. de reserva ativa'
                                : 'Resultado: Reserva permanece ativa até a expedição.',
                            impactBgColor: isEntregue ? const Color(0xFFEF4444).withValues(alpha: 0.1) : FincoreColors.background,
                          ),
                          const SizedBox(height: 20),

                          // 6. Impacto deste Pedido no Estoque (Tabela por Produto)
                          const Text('Impacto deste Pedido no Estoque', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Rastreabilidade individual de cada produto do pedido', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: FincoreColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.8),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: FincoreColors.background),
                                  children: const [
                                    Padding(padding: EdgeInsets.all(8), child: Text('PRODUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('RESERVADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('EXPEDIDO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('IMPACTO FÍSICO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                                  ],
                                ),
                                ..._itens.map((item) {
                                  final nomeProd = _produtosNomes[item.produtoId] ?? 'Produto';
                                  final qtdItemStr = (item.quantidade % 1 == 0) ? item.quantidade.toInt().toString() : item.quantidade.toStringAsFixed(1);
                                  final expedidoStr = isEntregue ? '$qtdItemStr un.' : '0 un.';
                                  final impactoFisicoStr = isEntregue ? '-$qtdItemStr un.' : '0 un.';
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(8), child: Text(nomeProd, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('$qtdItemStr un.', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(expedidoStr, style: TextStyle(fontSize: 11, color: isEntregue ? const Color(0xFFEF4444) : FincoreColors.textMuted, fontWeight: FontWeight.bold))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(impactoFisicoStr, style: TextStyle(fontSize: 11, color: isEntregue ? const Color(0xFFEF4444) : FincoreColors.textMuted, fontWeight: FontWeight.w900))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 7. Resumo Final do Impacto
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FincoreColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'IMPACTO TOTAL NO ESTOQUE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: FincoreColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 10,
                                      children: [
                                        _buildResumoMetrica(
                                          label: 'Itens expedidos',
                                          valor: '$totalExpedidaStr un.',
                                          cor: isEntregue ? const Color(0xFFEF4444) : FincoreColors.textMuted,
                                        ),
                                        _buildResumoMetrica(
                                          label: 'Saída física',
                                          valor: isEntregue ? '-$totalQtdStr un.' : '0 un.',
                                          cor: isEntregue ? const Color(0xFFEF4444) : FincoreColors.textMuted,
                                        ),
                                        _buildResumoMetrica(
                                          label: 'Reservas consumidas',
                                          valor: '$totalExpedidaStr un.',
                                          cor: const Color(0xFFF59E0B),
                                        ),
                                        _buildResumoMetrica(
                                          label: 'Reservas ativas deste pedido',
                                          valor: isEntregue ? '0 un.' : '$totalQtdStr un.',
                                          cor: isEntregue ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 8. Fechar Consulta (Ação única)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Fechar Consulta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStepDetailCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required String impactText,
    required Color impactBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FincoreColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
                    const Spacer(),
                    Text(subtitle, style: const TextStyle(fontSize: 9, color: FincoreColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: impactBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    impactText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoMetrica({required String label, required String valor, required Color cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
        const SizedBox(height: 2),
        Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: cor)),
      ],
    );
  }

  Widget _buildCheckstep(String label, bool active) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: active ? const Color(0xFF10B981) : FincoreColors.textMuted,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: active ? FincoreColors.textPrimary : FincoreColors.textMuted, fontWeight: active ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 12),
        color: active ? const Color(0xFF10B981) : FincoreColors.border,
      ),
    );
  }
}

/// Modal de Detalhamento do Processo (Exibe a Cadeia Completa de Eventos Internos do Pedido)
class _DetalhesProcessoModal extends StatelessWidget {
  final EstoqueProcessoData processo;
  final Map<String, String> pedidosNumeros;

  const _DetalhesProcessoModal({
    required this.processo,
    required this.pedidosNumeros,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final p = processo;
    final temPedido = p.pedidoId != null && p.pedidoId!.isNotEmpty;
    final numPed = p.numeroPedido ?? (temPedido ? '#${p.pedidoId!.substring(0, 4).toUpperCase()}' : null);

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Modal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.corStatus.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.corStatus.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    p.titulo,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.corStatus),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              p.nomeProduto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Rastreabilidade da cadeia de eventos internos do processo',
              style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 14),

            // Detalhamento dos Eventos Internos com Semântica Clara
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...p.movimentacoes.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final m = entry.value;
                      final tipoRaw = (m.tipo ?? '').toLowerCase();

                      final isReserva = tipoRaw.contains('reserva') && !tipoRaw.contains('liberacao');
                      final isExpedicao = tipoRaw.contains('expedicao') || tipoRaw.contains('saida');
                      final isLiberacao = tipoRaw.contains('liberacao') || tipoRaw.contains('cancelamento');
                      final isProducao = tipoRaw.contains('producao');
                      final isInventario = tipoRaw.contains('inventario');

                      final String eventTitle;
                      final String impactStr;
                      final String infoExtra;
                      final Color eventColor;
                      final IconData eventIcon;

                      if (isReserva) {
                        eventTitle = '🟡 RESERVA';
                        impactStr = 'Impacto: Reservado +${m.quantidade} un. | Disponível -${m.quantidade} un.';
                        infoExtra = 'Informação: ${m.quantidade} un. comprometidas. Estoque físico NÃO foi alterado.';
                        eventColor = const Color(0xFFF59E0B);
                        eventIcon = Icons.bookmark_added_rounded;
                      } else if (isExpedicao) {
                        eventTitle = '🔴 EXPEDIÇÃO / SAÍDA FÍSICA';
                        impactStr = 'Impacto: Físico -${m.quantidade} un.';
                        infoExtra = 'Informação: ${m.quantidade} un. expedidas. ${m.quantidade} un. da reserva ativa foram consumidas.';
                        eventColor = const Color(0xFFEF4444);
                        eventIcon = Icons.local_shipping_rounded;
                      } else if (isLiberacao) {
                        eventTitle = '🚫 LIBERAÇÃO / CANCELAMENTO DE RESERVA';
                        impactStr = 'Impacto: Reservado -${m.quantidade} un. | Disponível +${m.quantidade} un.';
                        infoExtra = 'Informação: Reserva liberada. Estoque físico NÃO foi alterado.';
                        eventColor = const Color(0xFFEF4444);
                        eventIcon = Icons.cancel_outlined;
                      } else if (isProducao) {
                        eventTitle = '⚡ PRODUÇÃO / ENTRADA FÍSICA';
                        impactStr = 'Impacto: Físico +${m.quantidade} un. | Disponível +${m.quantidade} un.';
                        infoExtra = 'Informação: Adicionou ${m.quantidade} un. ao estoque físico real.';
                        eventColor = const Color(0xFF10B981);
                        eventIcon = Icons.precision_manufacturing_rounded;
                      } else if (isInventario) {
                        final delta = m.quantidadeDepois - m.quantidadeAntes;
                        eventTitle = '📋 AJUSTE DE INVENTÁRIO';
                        impactStr = 'Impacto: Ajuste ${delta >= 0 ? '+' : ''}$delta un. no estoque físico';
                        infoExtra = 'Informação: Contagem física atualizada de ${m.quantidadeAntes} para ${m.quantidadeDepois} un.';
                        eventColor = const Color(0xFF8B5CF6);
                        eventIcon = Icons.fact_check_outlined;
                      } else {
                        eventTitle = '⚙️ MOVIMENTAÇÃO DE ESTOQUE';
                        impactStr = m.motivo ?? 'Movimentação técnica';
                        infoExtra = 'Informação: Registro técnico interno.';
                        eventColor = FincoreColors.primary;
                        eventIcon = Icons.swap_horiz_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: eventColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(eventIcon, size: 14, color: eventColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'ETAPA $idx • $eventTitle',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: eventColor),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dateFormat.format(m.dataHora.toLocal()),
                                        style: const TextStyle(fontSize: 9, color: FincoreColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    impactStr,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    infoExtra,
                                    style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Quadro de Resultado do Processo
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.corStatus.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.corStatus.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESULTADO CONSOLIDADO DO PROCESSO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: p.corStatus, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildResultCardItem('Reserva Ativa', '${p.reservaAtiva} un.', p.reservaAtiva > 0 ? const Color(0xFFF59E0B) : FincoreColors.textMuted),
                              _buildResultCardItem('Qtd Entregue', '${p.quantidadeExpedidaTotal} un.', const Color(0xFFEF4444)),
                              _buildResultCardItem('Impacto Físico Final', p.badgeImpactoFisico, p.impactoFisicoTotal < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ações (Consultar Pedido em Modo Somente Leitura)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (temPedido) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => _ConsultaPedidoModal(
                          pedidoId: p.pedidoId!,
                          numeroPedido: numPed,
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: Text('Ver Pedido ${numPed ?? ""}', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FincoreColors.primary,
                      side: BorderSide(color: FincoreColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fechar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCardItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

/// Modal do recurso 'Como chegamos a este saldo?' (Reconstrução agrupada por Processo)
class _ComoChegamosAoSaldoModal extends StatelessWidget {
  final ProdutoData produto;
  final List<MovimentacaoEstoqueData> movimentacoes;
  final Map<String, String> pedidosNumeros;
  final List<EstoqueProcessoData> processos;

  const _ComoChegamosAoSaldoModal({
    required this.produto,
    required this.movimentacoes,
    required this.pedidosNumeros,
    required this.processos,
  });

  @override
  Widget build(BuildContext context) {
    final listProcs = List<EstoqueProcessoData>.from(processos)
      ..sort((a, b) => a.dataUltimoEvento.compareTo(b.dataUltimoEvento));

    final int fisicoAtual = movimentacoes.isNotEmpty ? movimentacoes.last.quantidadeDepois : 0;
    final int reservadoAtual = movimentacoes.isNotEmpty ? (movimentacoes.last.quantidadeReservadaDepois ?? 0) : 0;
    final int disponivelAtual = fisicoAtual - reservadoAtual;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: FincoreColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Como chegamos a este saldo?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      Text(
                        'Reconstrução lógica por Processos — ${produto.nome}',
                        style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: FincoreColors.border, height: 1),
            const SizedBox(height: 12),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo Inicial
                    _buildStepRow(
                      icon: Icons.flag_rounded,
                      color: FincoreColors.primary,
                      title: 'Saldo Inicial (Base de Auditoria)',
                      subtitle: movimentacoes.isNotEmpty
                          ? 'Antes das movimentações do período'
                          : 'Nenhum lançamento no período',
                      badge: 'Físico: ${movimentacoes.isNotEmpty ? movimentacoes.first.quantidadeAntes : 0} un',
                    ),
                    const SizedBox(height: 8),

                    // Sequência de Processos Operacionais
                    ...listProcs.map((proc) {
                      final dataStr = DateFormat('dd/MM HH:mm').format(proc.dataUltimoEvento.toLocal());
                      final title = '${proc.titulo} ($dataStr)';

                      return _buildStepRow(
                        icon: proc.iconeStatus,
                        color: proc.corStatus,
                        title: title,
                        subtitle: proc.resumoFluxo,
                        badge: proc.badgeImpactoFisico,
                      );
                    }),
                    const SizedBox(height: 8),

                    // Saldo Atual Final
                    _buildStepRow(
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Saldo Atual Final',
                      subtitle: 'Posição consolidada e reconciliada no estoque',
                      badge: 'Físico: $fisicoAtual un | Res: $reservadoAtual un | Disp: $disponivelAtual un',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Entendido', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    bool isBold = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isBold ? color : FincoreColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
