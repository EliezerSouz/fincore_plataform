import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/status_badge.dart';
import '../../database/app_database.dart';
import '../../providers/app_view_model.dart';

class AgendaOperacionalPage extends StatefulWidget {
  const AgendaOperacionalPage({super.key});

  @override
  State<AgendaOperacionalPage> createState() => _AgendaOperacionalPageState();
}

class _AgendaOperacionalPageState extends State<AgendaOperacionalPage> {
  DateTime _dataSelecionada = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    final inicioDia = DateTime(_dataSelecionada.year, _dataSelecionada.month, _dataSelecionada.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    // Buscar pedidos agendados para a data selecionada (não cancelados)
    final query = db.select(db.pedidos)
      ..where((p) => p.dataEntrega.isBiggerOrEqualValue(inicioDia) & p.dataEntrega.isSmallerThanValue(fimDia))
      ..where((p) => p.status.equals('Cancelado').not())
      ..orderBy([(p) => OrderingTerm.asc(p.dataEntrega)]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda Operacional',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visualize os compromissos de entrega e retirada cronologicamente.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              // Seletor de Data
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _dataSelecionada = _dataSelecionada.subtract(const Duration(days: 1));
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dataSelecionada,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dataSelecionada = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _dataSelecionada = _dataSelecionada.add(const Duration(days: 1));
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: query.watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedidos = snapshot.data!;

                if (pedidos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Sem agendamentos para este dia.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Novos pedidos agendados para este dia aparecerão aqui.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final p = pedidos[index];
                    final formatHora = DateFormat('HH:mm').format(p.dataEntrega);
                    final isEntrega = p.tipoEntrega.toLowerCase() == 'entrega';

                    return FutureBuilder<List<ItensPedidoData>>(
                      future: (db.select(db.itensPedido)..where((i) => i.pedidoId.equals(p.id))).get(),
                      builder: (context, itemSnapshot) {
                        final itens = itemSnapshot.data ?? [];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coluna Hora
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isEntrega ? Colors.blue.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        formatHora,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isEntrega ? Colors.blue.shade800 : Colors.green.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        isEntrega ? Icons.local_shipping_outlined : Icons.storefront_outlined,
                                        color: isEntrega ? Colors.blue.shade800 : Colors.green.shade800,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Coluna Detalhes do Pedido
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Pedido #${p.numero} - ${p.clienteNome}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          StatusBadge(status: p.status),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      ...itens.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            '${item.quantidade}x ${item.produtoNome}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }),
                                      if (p.observacoes.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Text(
                                            'Obs: ${p.observacoes}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}
