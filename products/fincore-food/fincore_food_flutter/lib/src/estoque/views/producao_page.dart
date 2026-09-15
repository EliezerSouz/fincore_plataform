import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';
import '../controllers/estoque_controller.dart';
import '../controllers/planejamento_controller.dart';


/// Tela de Gestão de Produção e Agenda de Reservas.
///
/// Painel A — Lista de produtos com:
///   Físico | Reservado | Disponível | Mínimo
///   Badge preditivo de necessidade de produção.
///
/// Painel B — Agenda: reservas futuras ordenadas por data de entrega.
class ProducaoPage extends StatefulWidget {
  static int? initialTab;
  static String? filtroProdutoId;

  const ProducaoPage({super.key});

  @override
  State<ProducaoPage> createState() => _ProducaoPageState();
}

class _ProducaoPageState extends State<ProducaoPage>
    with SingleTickerProviderStateMixin {
  late EstoqueController _controller;
  late PlanoProducaoController _planejamentoCtrl;
  late TabController _tabs;
  bool _mostrarTodosProdutos = false;
  String _filtroPlanos = 'ativos';
  bool _visualizarComoLista = false;

  @override
  void initState() {
    super.initState();
    _controller = DependencyInjection().get<EstoqueController>();
    _planejamentoCtrl = DependencyInjection().get<PlanoProducaoController>();
    
    int initialIndex = 0;
    if (ProducaoPage.initialTab != null) {
      initialIndex = ProducaoPage.initialTab!;
      ProducaoPage.initialTab = null;
    }
    _tabs = TabController(length: 3, vsync: this, initialIndex: initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.refresh();
        _planejamentoCtrl.refresh();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProducaoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ProducaoPage.initialTab != null) {
      _tabs.index = ProducaoPage.initialTab!;
      ProducaoPage.initialTab = null;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _controller),
        ChangeNotifierProvider.value(value: _planejamentoCtrl),
      ],
      child: Consumer2<EstoqueController, PlanoProducaoController>(
        builder: (context, ctrl, planejamento, _) {
          if (ProducaoPage.initialTab != null) {
            final targetTab = ProducaoPage.initialTab!;
            ProducaoPage.initialTab = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _tabs.animateTo(targetTab);
              }
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ctrl),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 16),
              if (ctrl.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildPainelProdutos(ctrl),
                      _buildPainelAgenda(ctrl),
                      _buildPainelPlanejamento(planejamento),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(EstoqueController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textMuted),
          onPressed: () {
            ctrl.refresh();
            _planejamentoCtrl.refresh();
          },
          tooltip: 'Atualizar',
        ),
        const SizedBox(width: 8),
        // Botão principal de produção
        Consumer<EstoqueController>(
          builder: (_, ctrl, __) => GestureDetector(
            onTap: () => _abrirRegistroProducao(ctrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FincoreColors.primary, FincoreColors.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: FincoreColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Registrar Produção',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          color: FincoreColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: FincoreColors.primary.withOpacity(0.4)),
        ),
        labelColor: FincoreColors.primary,
        unselectedLabelColor: FincoreColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          const Tab(text: 'Necessidades de Produção'),
          const Tab(text: 'Entregas Futuras'),
          Tab(
            child: Consumer<PlanoProducaoController>(
              builder: (_, p, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Planejamento'),
                  if (p.planosAtivos.isNotEmpty) ...
                    [
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: FincoreColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${p.planosAtivos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Painel A: Situação de Estoque ────────────────────────────────────────

  Widget _buildPainelProdutos(EstoqueController ctrl) {
    if (ctrl.itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: FincoreColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhum produto com controle de estoque ativo',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ative "Controla Estoque" no cadastro dos produtos.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final itensUrgentes = ctrl.itens.where((i) {
      return i.sugestaoProducao > 0;
    }).toList();

    final exibidos = _mostrarTodosProdutos ? ctrl.itens : itensUrgentes;

    if (exibidos.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: FincoreColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.success.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: FincoreColors.success, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Tudo em Dia!',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Os estoques estão em níveis adequados para a operação. Nenhuma necessidade imediata de produção detectada.',
                style: TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _mostrarTodosProdutos = true;
                  });
                },
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Visualizar Todos os Produtos'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: FincoreColors.primary),
                  foregroundColor: FincoreColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _mostrarTodosProdutos ? 'Todos os Produtos' : 'Necessidades de Produção Críticas',
              style: const TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_visualizarComoLista ? Icons.grid_view_rounded : Icons.list_rounded),
                  tooltip: _visualizarComoLista ? 'Visualizar como Cards' : 'Visualizar como Lista',
                  color: FincoreColors.primary,
                  onPressed: () {
                    setState(() {
                      _visualizarComoLista = !_visualizarComoLista;
                    });
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _mostrarTodosProdutos = !_mostrarTodosProdutos;
                    });
                  },
                  icon: Icon(
                    _mostrarTodosProdutos ? Icons.filter_list_rounded : Icons.list_alt_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _mostrarTodosProdutos ? 'Mostrar Apenas Críticos' : 'Mostrar Todos os Produtos',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_visualizarComoLista) {
                return ListView.separated(
                  itemCount: exibidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildNecessidadeListTile(exibidos[index]);
                  },
                );
              }
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);
              
              if (crossAxisCount > 1) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 180,
                  ),
                  itemCount: exibidos.length,
                  itemBuilder: (context, index) {
                    return _buildNecessidadeCard(exibidos[index]);
                  },
                );
              } else {
                return ListView.separated(
                  itemCount: exibidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildNecessidadeCard(exibidos[index]);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNecessidadeCard(EstoqueItem item) {
    final statusColor = _getEstoqueStatusColor(item.status);
    final bool precisaProduzir = item.sugestaoProducao > 0;

    String motivo = 'Estoque saudável';
    if (item.quantidadeDisponivel <= item.quantidadeCritica) {
      motivo = 'Estoque crítico!';
    } else if (item.quantidadeDisponivel < item.quantidadeMinima) {
      motivo = 'Estoque abaixo do mínimo';
    } else if (item.quantidadeReservada > 0) {
      motivo = 'Reservas de pedidos pendentes';
    }

    final cardBorderColor = precisaProduzir ? statusColor.withOpacity(0.5) : FincoreColors.border;

    return Tooltip(
      message: 'Toque para ver detalhes e histórico',
      child: InkWell(
        onTap: () => _mostrarDetalhesNecessidadeModal(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorderColor, width: precisaProduzir ? 1.5 : 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 3, right: 8),
                    decoration: BoxDecoration(
                      color: item.corEtiqueta != null
                          ? Color(int.tryParse('0xFF${item.corEtiqueta!.replaceAll('#', '')}') ?? statusColor.value)
                          : statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nomeProduto,
                          style: const TextStyle(
                            color: FincoreColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          motivo,
                          style: TextStyle(
                            color: precisaProduzir ? statusColor : FincoreColors.textMuted,
                            fontSize: 11,
                            fontWeight: precisaProduzir ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniMetric('Disponível', '${item.quantidadeDisponivel} ${item.unidade}'),
                  _buildMiniMetric('Mínimo', '${item.quantidadeMinima} ${item.unidade}'),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECOMENDADO',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        precisaProduzir ? 'PRODUZIR ${item.sugestaoProducao} ${item.unidade}' : 'Estoque OK',
                        style: TextStyle(
                          color: precisaProduzir ? const Color(0xFFE89F2A) : FincoreColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _abrirCriarPlanoParaProduto(_planejamentoCtrl, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Planejar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNecessidadeListTile(EstoqueItem item) {
    final statusColor = _getEstoqueStatusColor(item.status);
    final bool precisaProduzir = item.sugestaoProducao > 0;

    String motivo = 'Estoque saudável';
    if (item.quantidadeDisponivel <= item.quantidadeCritica) {
      motivo = 'Estoque crítico!';
    } else if (item.quantidadeDisponivel < item.quantidadeMinima) {
      motivo = 'Estoque abaixo do mínimo';
    } else if (item.quantidadeReservada > 0) {
      motivo = 'Reservas de pedidos pendentes';
    }

    final cardBorderColor = precisaProduzir ? statusColor.withOpacity(0.5) : FincoreColors.border;

    return Tooltip(
      message: 'Toque para ver detalhes e histórico',
      child: InkWell(
        onTap: () => _mostrarDetalhesNecessidadeModal(context, item),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorderColor, width: precisaProduzir ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.corEtiqueta != null
                      ? Color(int.tryParse('0xFF${item.corEtiqueta!.replaceAll('#', '')}') ?? statusColor.value)
                      : statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nomeProduto,
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$motivo · Disponível: ${item.quantidadeDisponivel} ${item.unidade} · Mínimo: ${item.quantidadeMinima} ${item.unidade}',
                      style: const TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'RECOMENDADO',
                    style: TextStyle(color: FincoreColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    precisaProduzir ? 'PRODUZIR ${item.sugestaoProducao} ${item.unidade}' : 'Estoque OK',
                    style: TextStyle(
                      color: precisaProduzir ? const Color(0xFFE89F2A) : FincoreColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _abrirCriarPlanoParaProduto(_planejamentoCtrl, item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Planejar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
        Text(value, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _mostrarDetalhesNecessidadeModal(BuildContext context, EstoqueItem item) {
    final statusColor = _getEstoqueStatusColor(item.status);
    final bool precisaProduzir = item.sugestaoProducao > 0;

    final pedidosRelacionados = _controller.reservasAgendadas
        .where((r) => r.movimentacao.produtoId == item.estoque.produtoId)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.corEtiqueta != null
                    ? Color(int.tryParse('0xFF${item.corEtiqueta!.replaceAll('#', '')}') ?? statusColor.value)
                    : statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.nomeProduto,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('MÉTRICAS DO ESTOQUE', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 8,
                    children: [
                      _buildPopupMetric('Estoque Físico', '${item.quantidadeAtual} ${item.unidade}'),
                      _buildPopupMetric('Reservado', '${item.quantidadeReservada} ${item.unidade}'),
                      _buildPopupMetric('Disponível', '${item.quantidadeDisponivel} ${item.unidade}', isBold: true),
                      _buildPopupMetric('Estoque Mínimo', '${item.quantidadeMinima} ${item.unidade}'),
                      _buildPopupMetric('Estoque Crítico', '${item.quantidadeCritica} ${item.unidade}'),
                      _buildPopupMetric('Estoque Segurança', '${item.quantidadeSeguranca} ${item.unidade}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('MOTIVO E RECOMENDAÇÃO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Text(
                  precisaProduzir
                      ? 'Déficit de ${item.quantidadeMinima - item.quantidadeDisponivel} ${item.unidade} detectado em relação ao estoque mínimo. Recomendado produzir um lote de ${item.sugestaoProducao} ${item.unidade} para reposição.'
                      : 'Estoque saudável. O saldo disponível de ${item.quantidadeDisponivel} ${item.unidade} é suficiente para cobrir o estoque mínimo configurado.',
                  style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12.5),
                ),
                if (pedidosRelacionados.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('PEDIDOS RESERVANDO ESTOQUE (${pedidosRelacionados.length})', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pedidosRelacionados.length,
                      separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                      itemBuilder: (context, idx) {
                        final r = pedidosRelacionados[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Entrega: ${DateFormat('dd/MM — HH:mm').format(r.dataEntrega.toLocal())}',
                                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '${r.quantidade} ${item.unidade}',
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirHistorico(_controller, item);
            },
            child: const Text('Histórico'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirConfigurar(_controller, item);
            },
            child: const Text('Configurar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirCriarPlanoParaProduto(_planejamentoCtrl, item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary, foregroundColor: Colors.white),
            child: const Text('Planejar Produção'),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMetric(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 9.5)),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            color: FincoreColors.textPrimary,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getEstoqueStatusColor(EstoqueStatus s) {
    switch (s) {
      case EstoqueStatus.normal:
        return FincoreColors.success;
      case EstoqueStatus.baixo:
        return const Color(0xFFE89F2A);
      case EstoqueStatus.critico:
        return const Color(0xFFE05C5C);
      case EstoqueStatus.producaoNecessaria:
        return const Color(0xFF6C63FF);
    }
  }

  // ─── Painel B: Agenda de Reservas ─────────────────────────────────────────

  Widget _buildPainelAgenda(EstoqueController ctrl) {
    if (ctrl.reservasAgendadas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined,
                color: FincoreColors.success, size: 48),
            SizedBox(height: 16),
            Text(
              'Nenhuma entrega futura com estoque reservado',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'As reservas aparecem aqui ao confirmar pedidos com data futura.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupa por data de entrega
    final Map<String, List<ReservaAgendada>> porData = {};
    for (final r in ctrl.reservasAgendadas) {
      final key = DateFormat('dd/MM/yyyy — EEEE', 'pt_BR').format(r.dataEntrega);
      porData.putIfAbsent(key, () => []).add(r);
    }

    return ListView.builder(
      itemCount: porData.length,
      itemBuilder: (context, i) {
        final dataKey = porData.keys.elementAt(i);
        final reservasDoDia = porData[dataKey]!;

        // Total por produto naquele dia
        final Map<String, int> totalPorProduto = {};
        for (final r in reservasDoDia) {
          totalPorProduto[r.nomeProduto] =
              (totalPorProduto[r.nomeProduto] ?? 0) + r.quantidade;
        }

        final dataEntrega = reservasDoDia.first.dataEntrega;
        final diasAte = dataEntrega.difference(DateTime.now()).inDays;
        final urgente = diasAte <= 1;
        final atencao = diasAte <= 3 && diasAte > 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: urgente
                ? const Color(0xFFE05C5C).withOpacity(0.06)
                : atencao
                    ? const Color(0xFFE89F2A).withOpacity(0.06)
                    : FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgente
                  ? const Color(0xFFE05C5C).withOpacity(0.3)
                  : atencao
                      ? const Color(0xFFE89F2A).withOpacity(0.3)
                      : FincoreColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      urgente
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today_rounded,
                      size: 16,
                      color: urgente
                          ? const Color(0xFFE05C5C)
                          : atencao
                              ? const Color(0xFFE89F2A)
                              : FincoreColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dataKey.toUpperCase(),
                        style: TextStyle(
                          color: urgente
                              ? const Color(0xFFE05C5C)
                              : atencao
                                  ? const Color(0xFFE89F2A)
                                  : FincoreColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    // Badge de urgência
                    if (urgente || atencao)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: urgente
                              ? const Color(0xFFE05C5C).withOpacity(0.15)
                              : const Color(0xFFE89F2A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          urgente ? '⚠️ Amanhã!' : 'Em $diasAte dias',
                          style: TextStyle(
                            color: urgente
                                ? const Color(0xFFE05C5C)
                                : const Color(0xFFE89F2A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: FincoreColors.border, height: 1),
              ...totalPorProduto.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.kitchen_rounded,
                            size: 14, color: FincoreColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                                color: FincoreColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${e.value} un',
                          style: TextStyle(
                            color: urgente
                                ? const Color(0xFFE05C5C)
                                : FincoreColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  // ─── Ações ────────────────────────────────────────────────────────────────

  void _abrirRegistroProducao(EstoqueController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _RegistrarProducaoDialog(
        controller: ctrl,
        produtoPreSelecionado: null,
      ),
    );
  }

  void _abrirHistorico(EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _HistoricoDialog(
        controller: ctrl,
        item: item,
      ),
    );
  }

  void _abrirConfigurar(EstoqueController ctrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (_) => _ConfigurarDialog(
        controller: ctrl,
        item: item,
      ),
    );
  }
}


// ─── Dialog: Registrar Produção ───────────────────────────────────────────────

class _RegistrarProducaoDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem? produtoPreSelecionado;

  const _RegistrarProducaoDialog({
    required this.controller,
    this.produtoPreSelecionado,
  });

  @override
  State<_RegistrarProducaoDialog> createState() =>
      _RegistrarProducaoDialogState();
}

class _RegistrarProducaoDialogState extends State<_RegistrarProducaoDialog> {
  EstoqueItem? _produtoSelecionado;
  final _qtdCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  DateTime _dataProducao = DateTime.now();
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _produtoSelecionado = widget.produtoPreSelecionado;
    if (_produtoSelecionado != null) {
      // Pré-preenche com a sugestão de produção real para atingir o estoque mínimo, ou o tamanho do lote
      _qtdCtrl.text = (_produtoSelecionado!.sugestaoProducao > 0 
          ? _produtoSelecionado!.sugestaoProducao 
          : _produtoSelecionado!.quantidadeProducaoLote).toString();
    }
    _motivoCtrl.text = 'Produção turno — ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.controller.itens;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: FincoreColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, color: FincoreColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Registrar Produção',
              style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seleção do produto
            const Text('Produto',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<EstoqueItem>(
              value: _produtoSelecionado,
              decoration: InputDecoration(
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Selecionar produto',
                  style: TextStyle(color: FincoreColors.textMuted)),
              dropdownColor: FincoreColors.surfaceElevated,
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              items: itens
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Row(
                          children: [
                            Text(item.nomeProduto),
                            const SizedBox(width: 8),
                            Text(
                              '(${item.quantidadeDisponivel} disponível)',
                              style: const TextStyle(
                                  color: FincoreColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _produtoSelecionado = v;
                if (v != null && _qtdCtrl.text.isEmpty) {
                  _qtdCtrl.text = (v.sugestaoProducao > 0 
                      ? v.sugestaoProducao 
                      : v.quantidadeProducaoLote).toString();
                }
              }),
            ),

            const SizedBox(height: 16),

            // Quantidade produzida
            const Text('Quantidade Produzida',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _qtdCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                suffixText: _produtoSelecionado?.unidade ?? 'un',
                suffixStyle: const TextStyle(color: FincoreColors.textMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (_produtoSelecionado != null) ...[
              const SizedBox(height: 4),
              Text(
                'Lote sugerido: ${_produtoSelecionado!.quantidadeProducaoLote} ${_produtoSelecionado!.unidade}',
                style: const TextStyle(
                    color: FincoreColors.textMuted, fontSize: 11),
              ),
            ],

            const SizedBox(height: 16),

            // Data de produção
            const Text('Data de Produção',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataProducao,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dataProducao = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: FincoreColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy — EEEE', 'pt_BR')
                          .format(_dataProducao),
                      style: const TextStyle(
                          color: FincoreColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Motivo / Observações (obrigatório)
            const Text('Observações',
                style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _motivoCtrl,
              style: const TextStyle(
                  color: FincoreColors.textPrimary, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Produção turno manhã — responsável: papai',
                hintStyle:
                    const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: FincoreColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FincoreColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!,
                  style: const TextStyle(
                      color: Color(0xFFE05C5C), fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: FincoreColors.primary,
          ),
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded, size: 16),
          label: const Text('Confirmar Produção'),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    setState(() => _erro = null);

    final produto = _produtoSelecionado;
    if (produto == null) {
      setState(() => _erro = 'Selecione um produto.');
      return;
    }
    final qty = int.tryParse(_qtdCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() => _erro = 'Informe uma quantidade válida.');
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Informe uma observação (obrigatório).');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.controller.registrarProducao(
        produtoId: produto.estoque.produtoId,
        quantidade: qty,
        motivo: _motivoCtrl.text.trim(),
        dataProducao: _dataProducao,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Dialog: Histórico de Movimentações ────────────────────────────────────────

class _HistoricoDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem item;

  const _HistoricoDialog({required this.controller, required this.item});

  @override
  State<_HistoricoDialog> createState() => _HistoricoDialogState();
}

class _HistoricoDialogState extends State<_HistoricoDialog> {
  List<MovimentacaoEstoqueData>? _historico;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await widget.controller.carregarHistorico(
      produtoId: widget.item.estoque.produtoId,
    );
    if (mounted) setState(() => _historico = h);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text('Histórico — ${widget.item.nomeProduto}',
          style: const TextStyle(
              color: FincoreColors.textPrimary, fontSize: 15)),
      content: SizedBox(
        width: 480,
        height: 400,
        child: _historico == null
            ? const Center(child: CircularProgressIndicator())
            : _historico!.isEmpty
                ? const Center(
                    child: Text('Nenhuma movimentação registrada',
                        style: TextStyle(color: FincoreColors.textMuted)))
                : ListView.separated(
                    itemCount: _historico!.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: FincoreColors.border, height: 1),
                    itemBuilder: (context, i) {
                      final m = _historico![i];
                      return _MovimentacaoRow(mov: m);
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
      ],
    );
  }
}

class _MovimentacaoRow extends StatelessWidget {
  final MovimentacaoEstoqueData mov;
  const _MovimentacaoRow({required this.mov});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _tipoInfo(mov.tipo);
    final delta = _deltaText(mov);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                if (mov.motivo.isNotEmpty)
                  Text(mov.motivo,
                      style: const TextStyle(
                          color: FincoreColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(delta,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text(
                DateFormat('dd/MM HH:mm').format(mov.dataHora.toLocal()),
                style: const TextStyle(
                    color: FincoreColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _tipoInfo(String tipo) {
    return switch (tipo) {
      'producao' => (Icons.factory_rounded, FincoreColors.success, 'Produção'),
      'reserva' => (Icons.bookmark_added_rounded, const Color(0xFFE89F2A), 'Reserva'),
      'liberacao_reserva' => (Icons.bookmark_remove_rounded, FincoreColors.textMuted, 'Reserva Liberada'),
      'expedicao' => (Icons.local_shipping_rounded, FincoreColors.primary, 'Expedição'),
      'ajuste_positivo' => (Icons.add_circle_rounded, FincoreColors.success, 'Ajuste +'),
      'ajuste_negativo' => (Icons.remove_circle_rounded, const Color(0xFFE05C5C), 'Ajuste −'),
      'inventario' => (Icons.assignment_rounded, FincoreColors.info, 'Inventário'),
      'saida' || 'cancelamento' => (Icons.remove_shopping_cart_rounded, const Color(0xFFE05C5C), 'Saída'),
      _ => (Icons.swap_horiz_rounded, FincoreColors.textMuted, tipo),
    };
  }

  String _deltaText(MovimentacaoEstoqueData mov) {
    final delta = mov.quantidadeDepois - mov.quantidadeAntes;
    final sign = delta >= 0 ? '+' : '';
    return '$sign$delta un';
  }
}

// ─── Dialog: Configurar Parâmetros ───────────────────────────────────────────────

class _ConfigurarDialog extends StatefulWidget {
  final EstoqueController controller;
  final EstoqueItem item;

  const _ConfigurarDialog({required this.controller, required this.item});

  @override
  State<_ConfigurarDialog> createState() => _ConfigurarDialogState();
}

class _ConfigurarDialogState extends State<_ConfigurarDialog> {
  late TextEditingController _segurancaCtrl;
  late TextEditingController _minimoCtrl;
  late TextEditingController _criticoCtrl;
  late TextEditingController _loteCtrl;
  late TextEditingController _coberCtrl;
  late TextEditingController _capacidadeCtrl;
  late TextEditingController _preparoCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _segurancaCtrl =
        TextEditingController(text: widget.item.quantidadeSeguranca.toString());
    _minimoCtrl =
        TextEditingController(text: widget.item.quantidadeMinima.toString());
    _criticoCtrl =
        TextEditingController(text: widget.item.quantidadeCritica.toString());
    _loteCtrl = TextEditingController(
        text: widget.item.quantidadeProducaoLote.toString());
    _coberCtrl =
        TextEditingController(text: widget.item.diasCoberturaAlvo.toString());
    _capacidadeCtrl =
        TextEditingController(text: widget.item.capacidadeCampanha.toString());
    _preparoCtrl =
        TextEditingController(text: widget.item.tempoPreparacao.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text(
        'Configurar — ${widget.item.nomeProduto}',
        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 15),
      ),
      content: SizedBox(
        width: 380,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Campo(
                label: 'Estoque de Segurança (un)',
                hint: 'ex: 100',
                controller: _segurancaCtrl,
                subtitle: 'Margem para proteção operacional/imprevistos',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Estoque Mínimo Disponível (alerta)',
                hint: 'ex: 300',
                controller: _minimoCtrl,
                subtitle: 'Alerta de ATENÇÃO quando Disponível ≤ este valor',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Estoque Crítico (alerta)',
                hint: 'ex: 50',
                controller: _criticoCtrl,
                subtitle: 'Alerta CRÍTICO quando Disponível ≤ este valor',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Tamanho Sugerido de Lote (un)',
                hint: 'ex: 200',
                controller: _loteCtrl,
                subtitle: 'Pré-preenchido ao registrar produção',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Cobertura Alvo (dias)',
                hint: 'ex: 3',
                controller: _coberCtrl,
                subtitle: 'Dias de operação que o estoque deve cobrir',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Capacidade de Produção (un/dia)',
                hint: 'ex: 1000',
                controller: _capacidadeCtrl,
                subtitle: 'Capacidade máxima de fabricação em uma campanha',
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Tempo de Preparação (minutos)',
                hint: 'ex: 30',
                controller: _preparoCtrl,
                subtitle: 'Tempo de preparação antes de iniciar a produção',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _salvar,
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    setState(() => _loading = true);
    await widget.controller.configurarParametros(
      estoqueId: widget.item.estoque.id,
      quantidadeMinima: int.tryParse(_minimoCtrl.text),
      quantidadeProducaoLote: int.tryParse(_loteCtrl.text),
      diasCoberturaAlvo: int.tryParse(_coberCtrl.text),
      quantidadeSeguranca: int.tryParse(_segurancaCtrl.text),
      quantidadeCritica: int.tryParse(_criticoCtrl.text),
      capacidadeCampanha: int.tryParse(_capacidadeCtrl.text),
      tempoPreparacao: int.tryParse(_preparoCtrl.text),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String hint;
  final String subtitle;
  final TextEditingController controller;

  const _Campo({
    required this.label,
    required this.hint,
    required this.subtitle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              color: FincoreColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: FincoreColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FincoreColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                color: FincoreColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painel C: Planejamento de Produção
// ─────────────────────────────────────────────────────────────────────────────

extension _PlanejamentoPainel on _ProducaoPageState {
  Widget _buildPainelPlanejamento(PlanoProducaoController planeCtrl) {
    final filtrados = planeCtrl.planos.where((plano) {
      if (ProducaoPage.filtroProdutoId != null &&
          plano.produtoId != ProducaoPage.filtroProdutoId) {
        return false;
      }
      if (_filtroPlanos == 'ativos') {
        return plano.status == 'planejada' ||
            plano.status == 'em_preparacao' ||
            plano.status == 'em_producao' ||
            plano.status == 'parcial';
      } else if (_filtroPlanos == 'concluidos') {
        return plano.status == 'concluida';
      } else if (_filtroPlanos == 'cancelados') {
        return plano.status == 'cancelada';
      }
      return true; // 'todos'
    }).toList();

    final String nomeProdutoFiltrado = _controller.itens
        .where((i) => i.estoque.produtoId == ProducaoPage.filtroProdutoId)
        .firstOrNull
        ?.nomeProduto ?? 'Produto';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ProducaoPage.filtroProdutoId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FincoreColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: FincoreColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtrado por: $nomeProdutoFiltrado',
                    style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: FincoreColors.primary, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    updateState(() {
                      ProducaoPage.filtroProdutoId = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildSugestoesHeader(planeCtrl),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Campanhas Planejadas',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _abrirCriarPlano(planeCtrl),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Novo Plano'),
              style: FilledButton.styleFrom(
                backgroundColor: FincoreColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFiltroChip('Ativos', 'ativos', planeCtrl),
            const SizedBox(width: 8),
            _buildFiltroChip('Concluídos', 'concluidos', planeCtrl),
            const SizedBox(width: 8),
            _buildFiltroChip('Cancelados', 'cancelados', planeCtrl),
            const SizedBox(width: 8),
            _buildFiltroChip('Todos', 'todos', planeCtrl),
          ],
        ),
        const SizedBox(height: 12),
        if (filtrados.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Nenhum plano de produção nesta categoria.',
                style: TextStyle(color: FincoreColors.textMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plano = filtrados[index];
                return _buildPlanoCard(planeCtrl, plano);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String value, PlanoProducaoController planeCtrl) {
    final selected = _filtroPlanos == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      onSelected: (val) {
        if (val) {
          updateState(() {
            _filtroPlanos = value;
          });
        }
      },
      selectedColor: FincoreColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(color: selected ? FincoreColors.primary : FincoreColors.textMuted),
      checkmarkColor: FincoreColors.primary,
      backgroundColor: FincoreColors.surface,
    );
  }

  Widget _buildSugestoesHeader(PlanoProducaoController planeCtrl) {
    if (planeCtrl.sugestoes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assistant_rounded, color: FincoreColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Sugestões Preditivas de Produção',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: planeCtrl.sugestoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final sug = planeCtrl.sugestoes[index];
                return Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sug.nomeProduto,
                            style: const TextStyle(
                              color: FincoreColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sug.motivo,
                            style: const TextStyle(
                              color: FincoreColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sugerido: ${sug.quantidadeSugerida} un',
                            style: TextStyle(
                              color: FincoreColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _abrirCriarPlanoComSugestao(planeCtrl, sug),
                            child: Text(
                              'Planejar',
                              style: TextStyle(
                                color: FincoreColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildPlanoCard(PlanoProducaoController planeCtrl, PlanoProducaoData plano) {
    final estoqueItem = _controller.itens.firstWhere(
      (item) => item.estoque.produtoId == plano.produtoId,
      orElse: () => EstoqueItem(
        estoque: EstoqueProdutoData(
          id: '',
          tenantId: '',
          produtoId: plano.produtoId,
          quantidadeAtual: 0,
          quantidadeReservada: 0,
          quantidadeMinima: 0,
          quantidadeMaxima: 0,
          quantidadeProducaoLote: 0,
          diasCoberturaAlvo: 0,
          capacidadeCampanha: 0,
          estrategiaProducao: 'concentrada',
          tempoPreparacao: 0,
          quantidadeSeguranca: 0,
          quantidadeCritica: 0,
          unidade: 'un',
          syncStatus: SyncStatus.pending,
          syncVersion: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: '',
          updatedBy: '',
        ),
        nomeProduto: 'Produto Desconhecido',
        status: EstoqueStatus.critico,
        producaoPlanejada: 0,
      ),
    );

    final status = _parseStatus(plano.status);
    final statusColor = _statusColor(plano.status);
    final dataPlanoLocal = plano.dataPlano.toLocal();

    final isDiscreet = plano.status == 'concluida' || plano.status == 'cancelada';
    if (isDiscreet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: FincoreColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              plano.status == 'concluida' ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              color: plano.status == 'concluida' ? FincoreColors.success : const Color(0xFFE05C5C),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estoqueItem.nomeProduto,
                    style: const TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plano.status == 'concluida' ? 'Concluído' : 'Cancelado'} · ${plano.quantidadeProduzida} / ${plano.quantidadePlanejada} ${estoqueItem.unidade} · ${DateFormat('dd/MM/yyyy').format(dataPlanoLocal)}',
                    style: const TextStyle(
                      color: FincoreColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _mostrarDetalhesPlanoModal(context, planeCtrl, plano, estoqueItem),
              child: const Text('Ver Detalhes', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estoqueItem.nomeProduto,
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Campanha: ${DateFormat('dd/MM/yyyy').format(dataPlanoLocal)}',
                      style: const TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _mostrarDetalhesPlanoModal(context, planeCtrl, plano, estoqueItem),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Indicador de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso da Produção: ${plano.quantidadeProduzida} / ${plano.quantidadePlanejada} ${estoqueItem.unidade}',
                style: const TextStyle(
                  color: FincoreColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${((plano.quantidadeProduzida / plano.quantidadePlanejada) * 100).round()}%',
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (plano.quantidadeProduzida / plano.quantidadePlanejada).clamp(0.0, 1.0),
              backgroundColor: FincoreColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          if (plano.observacoes != null && plano.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Obs: ${plano.observacoes}',
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (plano.status == 'cancelada' && plano.motivoCancelamento != null) ...[
            const SizedBox(height: 8),
            Text(
              'Motivo do Cancelamento: ${plano.motivoCancelamento}',
              style: const TextStyle(
                color: Color(0xFFE05C5C),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Ações dinâmicas
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _mostrarDetalhesPlanoModal(context, planeCtrl, plano, estoqueItem),
                child: const Text('Ver Detalhes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              ..._buildAcoesPlano(planeCtrl, plano),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhesPlanoModal(
      BuildContext context,
      PlanoProducaoController planeCtrl,
      PlanoProducaoData plano,
      EstoqueItem estoqueItem) {
    final statusColor = _statusColor(plano.status);
    final dataPlanoLocal = plano.dataPlano.toLocal();

    final pedidosRelacionados = _controller.reservasAgendadas
        .where((r) => r.movimentacao.produtoId == plano.produtoId)
        .toList();

    final restante = (plano.quantidadePlanejada - plano.quantidadeProduzida).clamp(0, 999999);
    final esperadoApos = estoqueItem.quantidadeDisponivel + restante;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                estoqueItem.nomeProduto,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _parseStatus(plano.status).toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PLANEJAMENTO DA CAMPANHA', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 8,
                    children: [
                      _buildPopupMetric('Data do Plano', DateFormat('dd/MM/yyyy').format(dataPlanoLocal)),
                      _buildPopupMetric('Capacidade Ref.', '${plano.capacidadeCampanha} ${estoqueItem.unidade}'),
                      _buildPopupMetric('Planejado', '${plano.quantidadePlanejada} ${estoqueItem.unidade}', isBold: true),
                      _buildPopupMetric('Produzido', '${plano.quantidadeProduzida} ${estoqueItem.unidade}'),
                      _buildPopupMetric('Restante', '$restante ${estoqueItem.unidade}'),
                      _buildPopupMetric('Estoque Atual', '${estoqueItem.quantidadeDisponivel} ${estoqueItem.unidade}'),
                      _buildPopupMetric('Estoque Esperado', '$esperadoApos ${estoqueItem.unidade}', isBold: true),
                    ],
                  ),
                ),
                if (plano.observacoes != null && plano.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('OBSERVAÇÕES', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(
                    plano.observacoes!,
                    style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                  ),
                ],
                if (plano.status == 'cancelada' && plano.motivoCancelamento != null) ...[
                  const SizedBox(height: 16),
                  const Text('MOTIVO DO CANCELAMENTO', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(
                    plano.motivoCancelamento!,
                    style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                if (pedidosRelacionados.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('PEDIDOS DE CLIENTES AFETADOS (${pedidosRelacionados.length})', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pedidosRelacionados.length,
                      separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                      itemBuilder: (context, idx) {
                        final r = pedidosRelacionados[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Entrega: ${DateFormat('dd/MM — HH:mm').format(r.dataEntrega.toLocal())}',
                                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '${r.quantidade} ${estoqueItem.unidade}',
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (TenantContext().hasContext && PermissaoService.podeAcessarFinanceiro(TenantContext().usuario.role)) ...[
                  const SizedBox(height: 16),
                  const Text('HISTÓRICO DE AUDITORIA', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  FutureBuilder<List<AuditLogEntry>>(
                    future: () async {
                      final db = DependencyInjection().get<FincoreDatabase>();
                      return await (db.select(db.auditLogsTable)
                            ..where((t) =>
                                t.targetEntity.equals('planejamento_producao') &
                                t.entityId.equals(plano.id))
                            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
                          .get();
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                      }
                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) {
                        return const Text('Nenhum registro de auditoria.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11));
                      }
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                          itemBuilder: (context, idx) {
                            final log = logs[idx];
                            final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp.toLocal());
                            final userStr = log.userName ?? log.userId.substring(0, 8).toUpperCase();
                            
                            String explanation = '';
                            try {
                              if (log.diff != null && log.diff!.isNotEmpty) {
                                final Map<String, dynamic> diffMap = jsonDecode(log.diff!) as Map<String, dynamic>;
                                if (log.action == 'CREATE') {
                                  explanation = 'Criou planejamento de ${diffMap['quantidadePlanejada']} un. Origem: ${diffMap['necessidadeOrigem'] ?? 'Manual'}';
                                } else if (log.action == 'UPDATE') {
                                  if (diffMap.containsKey('quantidadePlanejadaAntes')) {
                                    explanation = 'Ajustou planejamento: ${diffMap['quantidadePlanejadaAntes']} → ${diffMap['quantidadePlanejadaDepois']} un. (+${diffMap['acrescimo']})';
                                  } else if (diffMap.containsKey('quantidadeAdicionada')) {
                                    explanation = 'Lançamento parcial: +${diffMap['quantidadeAdicionada']} un (Total: ${diffMap['quantidadeAcumulada']})';
                                  } else if (diffMap.containsKey('quantidadeIncremental')) {
                                    explanation = 'Concluído com ${diffMap['quantidadeFinalProduzida']} un (+${diffMap['quantidadeIncremental']})';
                                  } else if (diffMap.containsKey('status')) {
                                    explanation = 'Status alterado para: ${diffMap['status']}';
                                  }
                                } else if (log.action == 'BLOCK') {
                                  explanation = 'Bloqueio de Duplicidade: tentou planejar na mesma data.';
                                }
                              }
                            } catch (_) {}
                            if (explanation.isEmpty) {
                              explanation = '${log.action} - ${log.reason ?? ''}';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$userStr (${log.userRole ?? 'Operador'})',
                                        style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        dataStr,
                                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    explanation,
                                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 11),
                                  ),
                                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Motivo: ${log.reason}',
                                      style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Fechar'),
          ),
          ..._buildAcoesPlano(planeCtrl, plano, insideModal: true, dialogContext: dialogCtx),
        ],
      ),
    );
  }

  String _parseStatus(String status) {
    return switch (status) {
      'planejada' => 'Planejada',
      'em_preparacao' => 'Preparação',
      'em_producao' => 'Em Produção',
      'parcial' => 'Produção Parcial',
      'concluida' => 'Concluída',
      'cancelada' => 'Cancelada',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'planejada' => FincoreColors.textMuted,
      'em_preparacao' => FincoreColors.info,
      'em_producao' => const Color(0xFFE89F2A),
      'parcial' => const Color(0xFFDCA900),
      'concluida' => FincoreColors.success,
      'cancelada' => const Color(0xFFE05C5C),
      _ => FincoreColors.textMuted,
    };
  }

  List<Widget> _buildAcoesPlano(PlanoProducaoController planeCtrl, PlanoProducaoData plano, {bool insideModal = false, BuildContext? dialogContext}) {
    final List<Widget> list = [];

    final activeStatus = {'planejada', 'em_preparacao', 'em_producao', 'parcial'};
    if (!activeStatus.contains(plano.status)) return list;

    // Botão de Cancelar sempre aparece para planos ativos
    list.add(
      OutlinedButton(
        onPressed: () {
          if (insideModal && dialogContext != null) {
            Navigator.pop(dialogContext);
          }
          _abrirCancelarPlano(planeCtrl, plano);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE05C5C)),
          foregroundColor: const Color(0xFFE05C5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
      ),
    );

    list.add(const SizedBox(width: 8));

    if (plano.status == 'planejada') {
      list.add(
        OutlinedButton(
          onPressed: () {
            if (insideModal && dialogContext != null) {
              Navigator.pop(dialogContext);
            }
            _abrirEditarPlano(planeCtrl, plano);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: FincoreColors.primary),
            foregroundColor: FincoreColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Editar', style: TextStyle(fontSize: 12)),
        ),
      );
      list.add(const SizedBox(width: 8));

      list.add(
        FilledButton(
          onPressed: () async {
            if (insideModal && dialogContext != null) {
              Navigator.pop(dialogContext);
            }
            await planeCtrl.iniciarPreparacao(plano.id);
          },
          style: FilledButton.styleFrom(
            backgroundColor: FincoreColors.info,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Iniciar Preparação', style: TextStyle(fontSize: 12)),
        ),
      );
    } else if (plano.status == 'em_preparacao') {
      list.add(
        FilledButton(
          onPressed: () async {
            if (insideModal && dialogContext != null) {
              Navigator.pop(dialogContext);
            }
            await planeCtrl.iniciarProducao(plano.id);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE89F2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Iniciar Produção', style: TextStyle(fontSize: 12)),
        ),
      );
    } else if (plano.status == 'em_producao' || plano.status == 'parcial') {
      list.add(
        OutlinedButton(
          onPressed: () {
            if (insideModal && dialogContext != null) {
              Navigator.pop(dialogContext);
            }
            _abrirRegistrarParcial(planeCtrl, plano);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: FincoreColors.primary),
            foregroundColor: FincoreColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Registrar Parcial', style: TextStyle(fontSize: 12)),
        ),
      );
      list.add(const SizedBox(width: 8));
      list.add(
        FilledButton(
          onPressed: () {
            if (insideModal && dialogContext != null) {
              Navigator.pop(dialogContext);
            }
            _abrirConcluirPlano(planeCtrl, plano);
          },
          style: FilledButton.styleFrom(
            backgroundColor: FincoreColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Concluir Produção', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return list;
  }

  void _abrirCriarPlano(PlanoProducaoController planeCtrl) {
    showDialog(
      context: context,
      builder: (context) => CriarPlanoDialog(
        planeCtrl: planeCtrl,
        estoqueCtrl: _controller,
        onVerPlanejamento: () => _tabs.animateTo(2),
      ),
    );
  }

  void _abrirCriarPlanoParaProduto(PlanoProducaoController planeCtrl, EstoqueItem item) {
    showDialog(
      context: context,
      builder: (context) => CriarPlanoDialog(
        planeCtrl: planeCtrl,
        estoqueCtrl: _controller,
        produtoIdPreSelecionado: item.estoque.produtoId,
        quantidadePreSelecionada: item.sugestaoProducao > 0 ? item.sugestaoProducao : null,
        onVerPlanejamento: () => _tabs.animateTo(2),
      ),
    );
  }

  void _abrirCriarPlanoComSugestao(PlanoProducaoController planeCtrl, SugestaoPlano sug) {
    showDialog(
      context: context,
      builder: (context) => CriarPlanoDialog(
        planeCtrl: planeCtrl,
        estoqueCtrl: _controller,
        sugestao: sug,
        onVerPlanejamento: () => _tabs.animateTo(2),
      ),
    );
  }

  void _abrirCancelarPlano(PlanoProducaoController planeCtrl, PlanoProducaoData plano) {
    showDialog(
      context: context,
      builder: (context) => _CancelarPlanoDialog(planeCtrl: planeCtrl, plano: plano),
    );
  }

  void _abrirRegistrarParcial(PlanoProducaoController planeCtrl, PlanoProducaoData plano) {
    showDialog(
      context: context,
      builder: (context) => _RegistrarParcialDialog(planeCtrl: planeCtrl, plano: plano),
    );
  }

  void _abrirConcluirPlano(PlanoProducaoController planeCtrl, PlanoProducaoData plano) {
    showDialog(
      context: context,
      builder: (context) => _ConcluirPlanoDialog(planeCtrl: planeCtrl, plano: plano),
    );
  }

  void _abrirEditarPlano(PlanoProducaoController planeCtrl, PlanoProducaoData plano) {
    showDialog(
      context: context,
      builder: (context) => CriarPlanoDialog(
        planeCtrl: planeCtrl,
        estoqueCtrl: _controller,
        planoParaEditar: plano,
        onVerPlanejamento: () => _tabs.animateTo(2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs de Planejamento
// ─────────────────────────────────────────────────────────────────────────────

class CriarPlanoDialog extends StatefulWidget {
  final PlanoProducaoController planeCtrl;
  final EstoqueController estoqueCtrl;
  final SugestaoPlano? sugestao;
  final String? produtoIdPreSelecionado;
  final int? quantidadePreSelecionada;
  final VoidCallback? onVerPlanejamento;
  final PlanoProducaoData? planoParaEditar;

  const CriarPlanoDialog({
    super.key,
    required this.planeCtrl,
    required this.estoqueCtrl,
    this.sugestao,
    this.produtoIdPreSelecionado,
    this.quantidadePreSelecionada,
    this.onVerPlanejamento,
    this.planoParaEditar,
  });

  @override
  State<CriarPlanoDialog> createState() => _CriarPlanoDialogState();
}

class _CriarPlanoDialogState extends State<CriarPlanoDialog> {
  String? _produtoId;
  DateTime _dataPlano = DateTime.now().add(const Duration(days: 1));
  final _qtdCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.planoParaEditar != null) {
      _produtoId = widget.planoParaEditar!.produtoId;
      _qtdCtrl.text = widget.planoParaEditar!.quantidadePlanejada.toString();
      _dataPlano = widget.planoParaEditar!.dataPlano.toLocal();
      _obsCtrl.text = widget.planoParaEditar!.observacoes ?? '';
    } else if (widget.sugestao != null) {
      _produtoId = widget.sugestao!.produtoId;
      _qtdCtrl.text = widget.sugestao!.quantidadeSugerida.toString();
    } else if (widget.produtoIdPreSelecionado != null) {
      _produtoId = widget.produtoIdPreSelecionado;
      final preSelectedEstoque = widget.estoqueCtrl.itens.firstWhere(
        (e) => e.estoque.produtoId == _produtoId,
        orElse: () => widget.estoqueCtrl.itens.first,
      );
      _qtdCtrl.text = widget.quantidadePreSelecionada?.toString() ??
          preSelectedEstoque.quantidadeProducaoLote.toString();
    } else if (widget.estoqueCtrl.itens.isNotEmpty) {
      _produtoId = widget.estoqueCtrl.itens.first.estoque.produtoId;
      _qtdCtrl.text = widget.estoqueCtrl.itens.first.quantidadeProducaoLote.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.estoqueCtrl.itens;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: Text(widget.planoParaEditar != null ? 'Editar Plano de Produção' : 'Novo Plano de Produção', style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_erro != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE05C5C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE05C5C), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Produto
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Produto', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    dropdownColor: FincoreColors.surface,
                    value: _produtoId,
                    items: itens.map((i) => DropdownMenuItem(
                      value: i.estoque.produtoId,
                      child: Text(i.nomeProduto, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
                    )).toList(),
                    onChanged: widget.planoParaEditar != null ? null : (val) {
                      setState(() {
                        _produtoId = val;
                        final matched = itens.firstWhere((i) => i.estoque.produtoId == val);
                        _qtdCtrl.text = matched.quantidadeProducaoLote.toString();
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FincoreColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Quantidade
              _Campo(
                label: 'Quantidade Planejada (un)',
                hint: 'ex: 200',
                controller: _qtdCtrl,
                subtitle: 'Quantidade alvo para esta campanha de produção.',
              ),
              const SizedBox(height: 14),
              // Data
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data da Produção / Campanha', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: FincoreColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_dataPlano),
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
                          ),
                          Icon(Icons.calendar_today_rounded, size: 16, color: FincoreColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Observações
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Observações', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Detalhes da campanha...',
                      filled: true,
                      fillColor: FincoreColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _criar,
          style: FilledButton.styleFrom(backgroundColor: FincoreColors.primary),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.planoParaEditar != null ? 'Salvar Alterações' : 'Criar Plano'),
        ),
      ],
    );
  }

  Future<void> _selecionarData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataPlano,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) {
      setState(() => _dataPlano = d);
    }
  }

  Future<void> _criar() async {
    if (_produtoId == null) return;
    final qty = int.tryParse(_qtdCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() => _erro = 'Informe uma quantidade válida.');
      return;
    }

    if (widget.planoParaEditar != null) {
      setState(() => _loading = true);
      try {
        await widget.planeCtrl.editarPlano(
          planoId: widget.planoParaEditar!.id,
          dataPlano: _dataPlano,
          quantidadePlanejada: qty,
          observacoes: _obsCtrl.text.trim(),
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => _erro = 'Erro: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final activePlans = widget.planeCtrl.planos.where((p) {
      final pLocal = p.dataPlano.toLocal();
      final selLocal = _dataPlano.toLocal();
      return p.produtoId == _produtoId &&
          pLocal.year == selLocal.year &&
          pLocal.month == selLocal.month &&
          pLocal.day == selLocal.day &&
          ['planejada', 'em_preparacao', 'em_producao', 'parcial'].contains(p.status);
    }).toList();

    if (activePlans.isNotEmpty) {
      final existing = activePlans.first;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: FincoreColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE89F2A)),
              SizedBox(width: 8),
              Text('Produção Planejada Ativa', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Já existe uma produção planejada para este produto nesta data.',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Campanha Existente', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Quantidade: ${existing.quantidadePlanejada} un',
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE89F2A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('PLANEJADA', style: TextStyle(color: Color(0xFFE89F2A), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Deseja ajustar a quantidade da campanha existente ou prefere ver o planejamento?',
                  style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx, false);
              },
              child: Text('Ver Planejamento', style: TextStyle(color: FincoreColors.primary)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogCtx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: FincoreColors.primary),
              child: const Text('Ajustar Existente'),
            ),
          ],
        ),
      );

      if (confirm == null) return;

      if (!confirm) {
        if (mounted) Navigator.pop(context);
        widget.onVerPlanejamento?.call();
        return;
      } else {
        final novaQtd = existing.quantidadePlanejada + qty;
        setState(() => _loading = true);
        try {
          await widget.planeCtrl.ajustarQuantidade(
            planoId: existing.id,
            novaQuantidadePlanejada: novaQtd,
            motivo: 'Necessidade adicional de estoque/pedidos.',
          );
          if (mounted) Navigator.pop(context);
        } catch (e) {
          setState(() => _erro = 'Erro: $e');
        } finally {
          if (mounted) setState(() => _loading = false);
        }
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await widget.planeCtrl.criarPlano(
        produtoId: _produtoId!,
        dataPlano: _dataPlano,
        quantidadePlanejada: qty,
        observacoes: _obsCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CancelarPlanoDialog extends StatefulWidget {
  final PlanoProducaoController planeCtrl;
  final PlanoProducaoData plano;

  const _CancelarPlanoDialog({required this.planeCtrl, required this.plano});

  @override
  State<_CancelarPlanoDialog> createState() => _CancelarPlanoDialogState();
}

class _CancelarPlanoDialogState extends State<_CancelarPlanoDialog> {
  final _motivoCtrl = TextEditingController();
  bool _estornarProduzido = false;
  bool _loading = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    final hasProduzido = widget.plano.quantidadeProduzida > 0;
    final int saldoRestante = (widget.plano.quantidadePlanejada - widget.plano.quantidadeProduzida).clamp(0, 999999);

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Cancelar Plano de Produção', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11)),
                const SizedBox(height: 8),
              ],
              const Text(
                'Esta ação cancela o plano de produção e não pode ser desfeita.',
                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
              if (hasProduzido) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: FincoreColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Produção Parcial (${widget.plano.quantidadeProduzida} un já produzidas)',
                              style: const TextStyle(
                                color: FincoreColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha o procedimento para as unidades lançadas no estoque físico:',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: FincoreColors.primary,
                        title: const Text(
                          'Manter unidades produzidas no estoque',
                          style: TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'As ${widget.plano.quantidadeProduzida} un continuam no freezer. Cancela apenas o saldo restante de $saldoRestante un.',
                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                        ),
                        value: false,
                        groupValue: _estornarProduzido,
                        onChanged: (val) {
                          if (val != null) setState(() => _estornarProduzido = val);
                        },
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFFE05C5C),
                        title: const Text(
                          'Estornar unidades do estoque e cancelar tudo',
                          style: TextStyle(color: Color(0xFFE05C5C), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Dá baixa (estorno) de ${widget.plano.quantidadeProduzida} un do estoque físico. Usar caso a produção/produto informado esteja incorreto.',
                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                        ),
                        value: true,
                        groupValue: _estornarProduzido,
                        onChanged: (val) {
                          if (val != null) setState(() => _estornarProduzido = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _Campo(
                label: 'Motivo do Cancelamento (obrigatório)',
                hint: 'ex: Quebra de máquina / Falta de insumos / Produto errado',
                controller: _motivoCtrl,
                subtitle: 'Justificativa do cancelamento do plano.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirmar,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE05C5C)),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_estornarProduzido ? 'Estornar & Cancelar' : 'Cancelar Plano'),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    if (_motivoCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o motivo do cancelamento.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.planeCtrl.cancelarPlano(
        planoId: widget.plano.id,
        motivo: _motivoCtrl.text.trim(),
        estornarProduzido: _estornarProduzido,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _RegistrarParcialDialog extends StatefulWidget {
  final PlanoProducaoController planeCtrl;
  final PlanoProducaoData plano;

  const _RegistrarParcialDialog({required this.planeCtrl, required this.plano});

  @override
  State<_RegistrarParcialDialog> createState() => _RegistrarParcialDialogState();
}

class _RegistrarParcialDialogState extends State<_RegistrarParcialDialog> {
  final _qtdCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    final restante = widget.plano.quantidadePlanejada - widget.plano.quantidadeProduzida;

    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Registrar Produção Parcial', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11)),
              const SizedBox(height: 8),
            ],
            Text(
              'Restam produzir $restante unidades para atingir a meta do plano.',
              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _Campo(
              label: 'Quantidade Efetivamente Produzida (un)',
              hint: 'ex: 50',
              controller: _qtdCtrl,
              subtitle: 'Este saldo será somado ao progresso da campanha.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirmar,
          style: FilledButton.styleFrom(backgroundColor: FincoreColors.primary),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    final qty = int.tryParse(_qtdCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() => _erro = 'Informe uma quantidade válida.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.planeCtrl.registrarParcial(
        planoId: widget.plano.id,
        quantidadeProduzida: qty,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ConcluirPlanoDialog extends StatefulWidget {
  final PlanoProducaoController planeCtrl;
  final PlanoProducaoData plano;

  const _ConcluirPlanoDialog({required this.planeCtrl, required this.plano});

  @override
  State<_ConcluirPlanoDialog> createState() => _ConcluirPlanoDialogState();
}

class _ConcluirPlanoDialogState extends State<_ConcluirPlanoDialog> {
  final _qtdCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Sugere a quantidade restante para conclusão
    final restante = widget.plano.quantidadePlanejada - widget.plano.quantidadeProduzida;
    _qtdCtrl.text = restante.clamp(0, 999999).toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Concluir Plano de Produção', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11)),
              const SizedBox(height: 8),
            ],
            const Text(
              'A conclusão lançará automaticamente a entrada definitiva desta quantidade no estoque físico.',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _Campo(
              label: 'Quantidade Final Produzida (un)',
              hint: 'ex: 150',
              controller: _qtdCtrl,
              subtitle: 'Este saldo gerará a movimentação de estoque física.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirmar,
          style: FilledButton.styleFrom(backgroundColor: FincoreColors.success),
          child: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Concluir e Adicionar'),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    final qty = int.tryParse(_qtdCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() => _erro = 'Informe uma quantidade válida.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.planeCtrl.concluirPlano(
        planoId: widget.plano.id,
        quantidadeFinalProduzida: qty,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
