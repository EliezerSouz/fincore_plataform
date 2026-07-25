import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../database/app_database.dart';
import '../../providers/app_view_model.dart';
import '../../core/widgets/status_badge.dart';
import '../../design_system/components/operational_fields.dart';
import '../pedidos/novo_pedido_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> with SingleTickerProviderStateMixin {
  final _buscaController = TextEditingController();
  String _busca = '';
  int? _clienteSelecionadoId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String dinheiro(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final repo = vm.clientes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clientes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestão centralizada de clientes, histórico de vendas e inteligência operacional.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () async {
                  final novo = await abrirCliente(context);
                  if (novo != null && mounted) {
                    setState(() {
                      _clienteSelecionadoId = novo.id;
                    });
                  }
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Novo cliente'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // StreamBuilder Principal de Clientes + Pedidos para Dados Master-Detail
          Expanded(
            child: StreamBuilder<List<Cliente>>(
              stream: repo.observar(),
              builder: (context, snapshotClientes) {
                final todosClientes = snapshotClientes.data ?? [];
                final dadosClientes = _busca.isEmpty
                    ? todosClientes
                    : todosClientes
                        .where((c) =>
                            c.nome.toLowerCase().contains(_busca) ||
                            c.telefone.contains(_busca))
                        .toList();

                // Selecionar o primeiro por padrão se nenhum estiver selecionado ou se o atual não estiver no filtro
                if (dadosClientes.isNotEmpty) {
                  if (_clienteSelecionadoId == null ||
                      !dadosClientes.any((c) => c.id == _clienteSelecionadoId)) {
                    _clienteSelecionadoId = dadosClientes.first.id;
                  }
                } else {
                  _clienteSelecionadoId = null;
                }

                // StreamBuilder de Todos os Pedidos para Métricas em Tempo Real
                return StreamBuilder<List<Pedido>>(
                  stream: vm.db.select(vm.db.pedidos).watch(),
                  builder: (context, snapshotPedidos) {
                    final todosPedidos = snapshotPedidos.data ?? [];

                    // Mapeamento de métricas por cliente
                    final Map<int, List<Pedido>> pedidosPorCliente = {};
                    for (final p in todosPedidos) {
                      if (p.status != 'Cancelado') {
                        pedidosPorCliente.putIfAbsent(p.clienteId, () => []).add(p);
                      }
                    }

                    // Métricas Globais
                    final totalClientes = todosClientes.length;
                    final totalAtivos = todosClientes.where((c) => c.ativo).length;
                    final totalVips = todosClientes.where((c) => c.observacoes.toLowerCase().contains('vip')).length;
                    final faturamentoTotalBase = todosPedidos
                        .where((p) => p.status != 'Cancelado')
                        .fold<int>(0, (sum, p) => sum + p.totalCentavos);

                    return Column(
                      children: [
                        // Cards de Métricas do Topo
                        Row(
                          children: [
                            _metricChip('Total de Clientes', '$totalClientes', Colors.blue),
                            const SizedBox(width: 12),
                            _metricChip('Ativos', '$totalAtivos', Colors.green),
                            const SizedBox(width: 12),
                            _metricChip('VIPs', '$totalVips', Colors.amber),
                            const SizedBox(width: 12),
                            _metricChip('Faturamento Base', dinheiro(faturamentoTotalBase), Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Layout Split Screen: Tabela Master (60%) + Painel Detalhe (40%)
                        Expanded(
                          child: dadosClientes.isEmpty
                              ? Card(
                                  child: EmptyState(
                                    icone: Icons.people_outline,
                                    titulo: _busca.isEmpty
                                        ? 'Nenhum cliente cadastrado'
                                        : 'Nenhum cliente encontrado',
                                    mensagem: _busca.isEmpty
                                        ? 'Clique em "Novo cliente" para realizar o primeiro cadastro.'
                                        : 'Tente buscar por outro nome ou número de telefone.',
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. TABELA MASTER (Esquerda - 60%)
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        children: [
                                          // Campo de busca
                                          TextField(
                                            controller: _buscaController,
                                            onChanged: (v) => setState(() => _busca = v.trim().toLowerCase()),
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(Icons.search, size: 20),
                                              suffixIcon: _busca.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.clear, size: 18),
                                                      onPressed: () {
                                                        _buscaController.clear();
                                                        setState(() => _busca = '');
                                                      },
                                                    )
                                                  : null,
                                              hintText: 'Pesquisar cliente por nome ou telefone...',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Tabela Estilo Linear / Gmail
                                          Expanded(
                                            child: Card(
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Column(
                                                children: [
                                                  // Cabeçalho da Tabela
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    color: Colors.grey.shade100,
                                                    child: Row(
                                                      children: [
                                                        const Expanded(flex: 3, child: Text('CLIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                        const Expanded(flex: 2, child: Text('TELEFONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                        const Expanded(flex: 2, child: Text('ÚLT. PEDIDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                        const Expanded(flex: 1, child: Text('PEDIDOS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                        const Expanded(flex: 2, child: Text('TKT MÉDIO', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                        const Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                                      ],
                                                    ),
                                                  ),
                                                  const Divider(height: 1),

                                                  // Corpos das Linhas da Tabela
                                                  Expanded(
                                                    child: ListView.separated(
                                                      itemCount: dadosClientes.length,
                                                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                                                      itemBuilder: (context, index) {
                                                        final c = dadosClientes[index];
                                                        final isSelected = c.id == _clienteSelecionadoId;
                                                        final listPedidos = pedidosPorCliente[c.id] ?? [];
                                                        
                                                        // Cálculos da linha
                                                        final countPedidos = listPedidos.length;
                                                        final totalCentavos = listPedidos.fold<int>(0, (sum, p) => sum + p.totalCentavos);
                                                        final tktMedioCentavos = countPedidos == 0 ? 0 : (totalCentavos / countPedidos).round();

                                                        // Data do último pedido
                                                        String ultPedidoStr = 'Sem pedidos';
                                                        Color ultPedidoColor = Colors.grey.shade600;
                                                        if (listPedidos.isNotEmpty) {
                                                          final sorted = List<Pedido>.from(listPedidos)..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
                                                          final diff = DateTime.now().difference(sorted.first.criadoEm);
                                                          if (diff.inMinutes < 60) {
                                                            ultPedidoStr = 'há ${diff.inMinutes}m';
                                                            ultPedidoColor = Colors.green.shade700;
                                                          } else if (diff.inHours < 24) {
                                                            ultPedidoStr = 'há ${diff.inHours}h';
                                                            ultPedidoColor = Colors.green.shade700;
                                                          } else if (diff.inDays == 1) {
                                                            ultPedidoStr = 'ontem';
                                                            ultPedidoColor = Colors.green.shade700;
                                                          } else {
                                                            ultPedidoStr = 'há ${diff.inDays}d';
                                                            ultPedidoColor = diff.inDays > 30 ? Colors.red.shade700 : Colors.blue.shade700;
                                                          }
                                                        }

                                                        final isVip = c.observacoes.toLowerCase().contains('vip');

                                                        return InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _clienteSelecionadoId = c.id;
                                                            });
                                                          },
                                                          child: AnimatedContainer(
                                                            duration: const Duration(milliseconds: 150),
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                            decoration: BoxDecoration(
                                                              color: isSelected
                                                                  ? AppColors.primary.withValues(alpha: 0.08)
                                                                  : Colors.white,
                                                              border: isSelected
                                                                  ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
                                                                  : null,
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                // Nome + VIP
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Row(
                                                                    children: [
                                                                      Flexible(
                                                                        child: Text(
                                                                          c.nome,
                                                                          style: TextStyle(
                                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                                            fontSize: 13,
                                                                            color: isSelected ? AppColors.primary : Colors.black87,
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      if (isVip) ...[
                                                                        const SizedBox(width: 4),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.amber.shade100,
                                                                            borderRadius: BorderRadius.circular(4),
                                                                          ),
                                                                          child: const Text('⭐ VIP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                ),
                                                                // Telefone
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    c.telefone.isEmpty ? '-' : c.telefone,
                                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                                  ),
                                                                ),
                                                                // Último Pedido
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    ultPedidoStr,
                                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ultPedidoColor),
                                                                  ),
                                                                ),
                                                                // Pedidos
                                                                Expanded(
                                                                  flex: 1,
                                                                  child: Center(
                                                                    child: Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.grey.shade100,
                                                                        borderRadius: BorderRadius.circular(10),
                                                                      ),
                                                                      child: Text(
                                                                        '$countPedidos',
                                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Ticket Médio
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    dinheiro(tktMedioCentavos),
                                                                    textAlign: TextAlign.right,
                                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                                  ),
                                                                ),
                                                                // Total
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    dinheiro(totalCentavos),
                                                                    textAlign: TextAlign.right,
                                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // 2. PAINEL LATERAL DE DETALHES (Direita - 40%)
                                    Expanded(
                                      flex: 4,
                                      child: _buildPainelDetalheCliente(
                                        context,
                                        vm,
                                        todosClientes.firstWhere(
                                          (cl) => cl.id == _clienteSelecionadoId,
                                          orElse: () => dadosClientes.first,
                                        ),
                                        pedidosPorCliente[_clienteSelecionadoId] ?? [],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500, color: color, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelDetalheCliente(
    BuildContext context,
    AppViewModel vm,
    Cliente c,
    List<Pedido> pedidosCliente,
  ) {
    final countPedidos = pedidosCliente.length;
    final totalCentavos = pedidosCliente.fold<int>(0, (sum, p) => sum + p.totalCentavos);
    final tktMedioCentavos = countPedidos == 0 ? 0 : (totalCentavos / countPedidos).round();
    final sortedPedidos = List<Pedido>.from(pedidosCliente)..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Painel Lateral
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.ativo ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.ativo ? Colors.green : Colors.grey),
                          ),
                          child: Text(
                            c.ativo ? '🟢 ATIVO' : '🔴 INATIVO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.ativo ? Colors.green.shade800 : Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  c.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(c.telefone.isEmpty ? 'Sem telefone' : c.telefone, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 16),

                // Botões de Ação Rápida no Painel
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('Novo Pedido')),
                                body: NovoPedidoPage(clientePreSelecionado: c),
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Novo Pedido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => abrirCliente(context, c),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // TabBar ([Resumo], [Pedidos], [Endereços])
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              const Tab(text: 'Resumo'),
              Tab(text: 'Pedidos ($countPedidos)'),
              const Tab(text: 'Endereço'),
            ],
          ),
          const Divider(height: 1),

          // Conteúdo das Abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Aba 1: Resumo
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(child: _panelStatCard('Ticket Médio', dinheiro(tktMedioCentavos), Icons.shopping_bag_outlined, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _panelStatCard('Total Gasto', dinheiro(totalCentavos), Icons.monetization_on_outlined, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _panelStatCard('Recorrência de Vendas', '$countPedidos pedidos realizados', Icons.repeat, Colors.blue),
                    const SizedBox(height: 16),

                    const Text('Endereço Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        c.logradouro.isEmpty
                            ? 'Sem endereço cadastrado'
                            : '${c.logradouro}, ${c.numero} - ${c.bairro} (${c.cidade})',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),

                    if (c.observacoes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Observações / Preferências', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          c.observacoes,
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ],
                ),

                // Aba 2: Histórico de Pedidos
                sortedPedidos.isEmpty
                    ? const Center(
                        child: Text('Nenhum pedido realizado.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedPedidos.length,
                        itemBuilder: (context, index) {
                          final p = sortedPedidos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pedido #${p.numero}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(dinheiro(p.totalCentavos), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                              subtitle: Text(
                                '${DateFormat("dd/MM/yyyy 'às' HH:mm").format(p.criadoEm)} • ${p.status}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              trailing: StatusBadge(status: p.status),
                              onTap: () {
                                vm.navegarKanbanComDestaque(pedidoId: p.id, status: p.status);
                              },
                            ),
                          );
                        },
                      ),

                // Aba 3: Endereço Principal & Locais de Entrega Secundários
                StreamBuilder<List<LocaisEntregaData>>(
                  stream: (vm.db.select(vm.db.locaisEntrega)..where((l) => l.clienteId.equals(c.id))).watch(),
                  builder: (context, snapshotLocais) {
                    final locaisSecundarios = snapshotLocais.data ?? [];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Endereço Principal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Endereço Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text('🏠 PRINCIPAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoDetailRow(Icons.location_on_outlined, 'Logradouro', c.logradouro.isEmpty ? '-' : '${c.logradouro}, ${c.numero}'),
                        _infoDetailRow(Icons.map_outlined, 'Bairro / Cidade', c.bairro.isEmpty ? '-' : '${c.bairro} - ${c.cidade}'),
                        _infoDetailRow(Icons.markunread_mailbox_outlined, 'CEP', c.cep.isEmpty ? '-' : c.cep),
                        if (c.referencia.isNotEmpty)
                          _infoDetailRow(Icons.info_outline, 'Referência', c.referencia),
                        const Divider(height: 24),

                        // Endereços Secundários / Locais de Entrega
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Locais de Entrega (${locaisSecundarios.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            TextButton.icon(
                              onPressed: () => abrirLocalEntregaDialog(context, c.id),
                              icon: const Icon(Icons.add_location_alt_outlined, size: 14),
                              label: const Text('Novo Local', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (locaisSecundarios.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Text(
                              'Nenhum endereço secundário cadastrado. Clique em "+ Novo Local" para adicionar (ex: Trabalho, Sítio, Casa da mãe).',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          )
                        else
                          ...locaisSecundarios.map((loc) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.place_outlined, size: 14, color: AppColors.primary),
                                ),
                                title: Text(loc.nomeIdentificador, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text(
                                  '${loc.logradouro}, ${loc.numero} - ${loc.bairro} (${loc.cidade})',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  onPressed: () async {
                                    await (vm.db.delete(vm.db.locaisEntrega)..where((l) => l.id.equals(loc.id))).go();
                                    if (context.mounted) {
                                      AppSnackbar.sucesso(context, 'Local de entrega removido.');
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Cliente?> abrirCliente(BuildContext context, [Cliente? cliente]) async {
  final nomeCtrl = TextEditingController(text: cliente?.nome ?? '');
  final telefoneCtrl = TextEditingController(text: cliente?.telefone ?? '');
  final logradouroCtrl = TextEditingController(text: cliente?.logradouro ?? '');
  final numeroCtrl = TextEditingController(text: cliente?.numero ?? '');
  final bairroCtrl = TextEditingController(text: cliente?.bairro ?? '');
  final cidadeCtrl = TextEditingController(text: cliente?.cidade ?? 'Sorocaba');
  final cepCtrl = TextEditingController(text: cliente?.cep ?? '');
  final referenciaCtrl = TextEditingController(text: cliente?.referencia ?? '');
  final observacoesCtrl = TextEditingController(text: cliente?.observacoes ?? '');

  return showDialog<Cliente>(
    context: context,
    builder: (dialog) {
      return AlertDialog(
        title: Text(cliente == null ? 'Novo cliente' : 'Editar cliente'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Nome',
                  isRequired: true,
                  controller: nomeCtrl,
                  hint: 'Nome completo do cliente',
                ),
                const SizedBox(height: 12),
                AppPhoneField(
                  label: 'Telefone',
                  isRequired: true,
                  controller: telefoneCtrl,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Logradouro',
                        controller: logradouroCtrl,
                        hint: 'Rua, Avenida, etc.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Número',
                        controller: numeroCtrl,
                        hint: 'Ex.: 123',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Bairro',
                        controller: bairroCtrl,
                        hint: 'Nome do bairro',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Cidade',
                        controller: cidadeCtrl,
                        hint: 'Nome da cidade',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppCepField(
                        label: 'CEP',
                        controller: cepCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Ponto de referência',
                        controller: referenciaCtrl,
                        hint: 'Ex.: Próximo ao mercado',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Observações',
                  controller: observacoesCtrl,
                  hint: 'Ex.: Cliente VIP, casa de portão verde',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar cliente'),
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) {
                AppSnackbar.erro(dialog, 'Informe o nome do cliente.');
                return;
              }
              final vm = context.read<AppViewModel>();
              final id = await vm.clientes.salvar(
                ClientesCompanion(
                  nome: Value(nomeCtrl.text.trim()),
                  telefone: Value(telefoneCtrl.text.trim()),
                  logradouro: Value(logradouroCtrl.text.trim()),
                  numero: Value(numeroCtrl.text.trim()),
                  bairro: Value(bairroCtrl.text.trim()),
                  cidade: Value(cidadeCtrl.text.trim()),
                  cep: Value(cepCtrl.text.trim()),
                  referencia: Value(referenciaCtrl.text.trim()),
                  observacoes: Value(observacoesCtrl.text.trim()),
                ),
                id: cliente?.id,
              );
              final salvo = await (vm.db.select(vm.db.clientes)
                    ..where((t) => t.id.equals(id)))
                  .getSingle();
              if (dialog.mounted) Navigator.pop(dialog, salvo);
            },
          ),
        ],
      );
    },
  );
}

Future<void> abrirLocalEntregaDialog(BuildContext context, int clienteId) async {
  final nomeIdentificadorCtrl = TextEditingController(text: 'Trabalho');
  final logradouroCtrl = TextEditingController();
  final numeroCtrl = TextEditingController();
  final bairroCtrl = TextEditingController();
  final cidadeCtrl = TextEditingController(text: 'Sorocaba');
  final cepCtrl = TextEditingController();
  final referenciaCtrl = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (dialog) {
      return AlertDialog(
        title: const Text('Novo Local de Entrega'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Identificador (Ex: Trabalho, Casa da Mãe, Sítio)',
                  isRequired: true,
                  controller: nomeIdentificadorCtrl,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Logradouro',
                        isRequired: true,
                        controller: logradouroCtrl,
                        hint: 'Rua, Avenida, etc.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Número',
                        isRequired: true,
                        controller: numeroCtrl,
                        hint: 'Ex.: 123',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Bairro',
                        isRequired: true,
                        controller: bairroCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Cidade',
                        controller: cidadeCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppCepField(
                        label: 'CEP',
                        controller: cepCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Referência',
                        controller: referenciaCtrl,
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
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar Local'),
            onPressed: () async {
              if (logradouroCtrl.text.trim().isEmpty || numeroCtrl.text.trim().isEmpty) {
                AppSnackbar.erro(dialog, 'Informe logradouro e número.');
                return;
              }
              final vm = context.read<AppViewModel>();
              await vm.db.into(vm.db.locaisEntrega).insert(
                LocaisEntregaCompanion.insert(
                  clienteId: clienteId,
                  nomeIdentificador: Value(nomeIdentificadorCtrl.text.trim().isEmpty ? 'Secundário' : nomeIdentificadorCtrl.text.trim()),
                  logradouro: logradouroCtrl.text.trim(),
                  numero: numeroCtrl.text.trim(),
                  bairro: bairroCtrl.text.trim(),
                  cidade: Value(cidadeCtrl.text.trim()),
                  cep: Value(cepCtrl.text.trim()),
                  referencia: Value(referenciaCtrl.text.trim()),
                ),
              );
              if (dialog.mounted) {
                Navigator.pop(dialog);
                AppSnackbar.sucesso(context, 'Novo local de entrega adicionado!');
              }
            },
          ),
        ],
      );
    },
  );
}
