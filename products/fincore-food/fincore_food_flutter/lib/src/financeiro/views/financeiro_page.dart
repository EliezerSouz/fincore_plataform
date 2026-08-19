import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../controllers/financeiro_controller.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  late FinanceiroController _controller;
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _controller = FinanceiroController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(int centavos) => _moeda.format(centavos / 100);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<FinanceiroController>(
        builder: (context, ctrl, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ctrl),
              const SizedBox(height: 20),
              if (ctrl.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else ...[
                _buildCaixaStatus(ctrl),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(ctrl)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(FinanceiroController ctrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financeiro',
                style: TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Caixa do dia · ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        // Botão de refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: FincoreColors.textMuted),
          tooltip: 'Atualizar',
          onPressed: () => ctrl.refresh(),
        ),
        const SizedBox(width: 8),
        // Abrir/Fechar Caixa
        if (!ctrl.resumo.caixaAberto)
          _ActionButton(
            icon: Icons.lock_open_rounded,
            label: 'Abrir Caixa',
            color: FincoreColors.success,
            onTap: () => _mostrarDialogAbrirCaixa(ctrl),
          )
        else
          _ActionButton(
            icon: Icons.lock_rounded,
            label: 'Fechar Caixa',
            color: const Color(0xFFE05C5C),
            onTap: () => _mostrarDialogFecharCaixa(ctrl),
          ),
      ],
    );
  }

  // ─── Status do Caixa ───────────────────────────────────────────────────────

  Widget _buildCaixaStatus(FinanceiroController ctrl) {
    final aberto = ctrl.resumo.caixaAberto;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: aberto
            ? FincoreColors.success.withOpacity(0.08)
            : const Color(0xFFE05C5C).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: aberto
              ? FincoreColors.success.withOpacity(0.3)
              : const Color(0xFFE05C5C).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            aberto ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: aberto ? FincoreColors.success : const Color(0xFFE05C5C),
          ),
          const SizedBox(width: 8),
          Text(
            aberto
                ? 'Caixa aberto · Operador: ${ctrl.resumo.sessaoAtiva?.operadorNome ?? ''}'
                : 'Caixa fechado · Abra o caixa para registrar movimentações',
            style: TextStyle(
              color: aberto ? FincoreColors.success : const Color(0xFFE05C5C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (aberto) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => _mostrarDialogMovimento(ctrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 13, color: FincoreColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Lançamento', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(FinanceiroController ctrl) {
    final resumo = ctrl.resumo;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de totais
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Faturamento Bruto',
                  value: _fmt(resumo.totalVendasCentavos),
                  color: FincoreColors.success,
                  sub: '${resumo.qtdPedidos} pedido${resumo.qtdPedidos != 1 ? 's' : ''}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.trending_down_rounded,
                  label: 'Saídas / Sangrias',
                  value: _fmt(resumo.totalDespesasCentavos),
                  color: const Color(0xFFE05C5C),
                  sub: 'do turno',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Saldo em Caixa',
                  value: _fmt(resumo.saldoCentavos),
                  color: FincoreColors.primary,
                  sub: 'estimado',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vendas por forma de pagamento
          const Text(
            'RECEITAS POR FORMA DE PAGAMENTO',
            style: TextStyle(
              color: FincoreColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          if (resumo.vendasPorFormaPagamento.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: const Center(
                child: Text(
                  'Nenhuma venda registrada hoje',
                  style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                children: [
                  ...resumo.vendasPorFormaPagamento.entries.map((e) {
                    final pct = resumo.totalVendasCentavos > 0
                        ? e.value / resumo.totalVendasCentavos
                        : 0.0;
                    return _FormaPagamentoRow(
                      nome: e.key,
                      valor: _fmt(e.value),
                      percentual: pct,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: FincoreColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _fmt(resumo.totalVendasCentavos),
                          style: const TextStyle(
                            color: FincoreColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Diálogos ──────────────────────────────────────────────────────────────

  void _mostrarDialogAbrirCaixa(FinanceiroController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _DialogAbrirCaixa(onConfirm: (valor) async {
        await ctrl.abrirCaixa(valorAberturaCentavos: valor);
      }),
    );
  }

  void _mostrarDialogFecharCaixa(FinanceiroController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _DialogFecharCaixa(
        resumo: ctrl.resumo,
        formatarValor: _fmt,
        onConfirm: (valorContado, obs) async {
          await ctrl.fecharCaixa(
            valorContadoCentavos: valorContado,
            observacoes: obs,
          );
        },
      ),
    );
  }

  void _mostrarDialogMovimento(FinanceiroController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _DialogMovimento(onConfirm: (tipo, valor, desc) async {
        await ctrl.lancarMovimento(tipo: tipo, valorCentavos: valor, descricao: desc);
      }),
    );
  }
}

// ─── Widgets Internos ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final bool highlighted;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.sub,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.08) : FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? color.withOpacity(0.35) : FincoreColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FormaPagamentoRow extends StatelessWidget {
  final String nome;
  final String valor;
  final double percentual;

  const _FormaPagamentoRow({
    required this.nome,
    required this.valor,
    required this.percentual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nome, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
              Text(valor, style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentual.clamp(0.0, 1.0),
              backgroundColor: FincoreColors.border,
              color: FincoreColors.primary,
              minHeight: 4,
            ),
          ),
          const Divider(color: FincoreColors.border, height: 20),
        ],
      ),
    );
  }
}

// ─── Diálogos ────────────────────────────────────────────────────────────────

class _DialogAbrirCaixa extends StatefulWidget {
  final Future<void> Function(int valorCentavos) onConfirm;
  const _DialogAbrirCaixa({required this.onConfirm});

  @override
  State<_DialogAbrirCaixa> createState() => _DialogAbrirCaixaState();
}

class _DialogAbrirCaixaState extends State<_DialogAbrirCaixa> {
  final _ctrl = TextEditingController(text: '0');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Abrir Caixa', style: TextStyle(color: FincoreColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Informe o valor do fundo de troco inicial:',
            style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: FincoreColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Fundo de troco (R\$)',
              labelStyle: const TextStyle(color: FincoreColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FincoreColors.border),
              ),
              prefixText: 'R\$ ',
              prefixStyle: const TextStyle(color: FincoreColors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final valor = (double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0) * 100;
                  await widget.onConfirm(valor.toInt());
                  if (context.mounted) Navigator.pop(context);
                },
          style: FilledButton.styleFrom(backgroundColor: FincoreColors.success),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Abrir Caixa'),
        ),
      ],
    );
  }
}

class _DialogFecharCaixa extends StatefulWidget {
  final ResumoCaixa resumo;
  final String Function(int) formatarValor;
  final Future<void> Function(int? valorContado, String? obs) onConfirm;

  const _DialogFecharCaixa({
    required this.resumo,
    required this.formatarValor,
    required this.onConfirm,
  });

  @override
  State<_DialogFecharCaixa> createState() => _DialogFecharCaixaState();
}

class _DialogFecharCaixaState extends State<_DialogFecharCaixa> {
  final _valorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Fechar Caixa', style: TextStyle(color: FincoreColors.textPrimary)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow('Total de Vendas', widget.formatarValor(widget.resumo.totalVendasCentavos), FincoreColors.success),
            _SummaryRow('Saídas', widget.formatarValor(widget.resumo.totalDespesasCentavos), const Color(0xFFE05C5C)),
            _SummaryRow('Saldo Estimado', widget.formatarValor(widget.resumo.saldoCentavos), FincoreColors.primary),
            const Divider(color: FincoreColors.border, height: 24),
            TextField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: FincoreColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Valor Contado Fisicamente (opcional)',
                labelStyle: const TextStyle(color: FincoreColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsCtrl,
              style: const TextStyle(color: FincoreColors.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observações',
                labelStyle: const TextStyle(color: FincoreColors.textMuted),
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
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  int? valorContado;
                  if (_valorCtrl.text.isNotEmpty) {
                    valorContado = ((double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0) * 100).toInt();
                  }
                  await widget.onConfirm(valorContado, _obsCtrl.text.isEmpty ? null : _obsCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE05C5C)),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Fechar Caixa'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DialogMovimento extends StatefulWidget {
  final Future<void> Function(String tipo, int valor, String desc) onConfirm;
  const _DialogMovimento({required this.onConfirm});

  @override
  State<_DialogMovimento> createState() => _DialogMovimentoState();
}

class _DialogMovimentoState extends State<_DialogMovimento> {
  String _tipo = 'sangria';
  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      title: const Text('Lançamento Avulso', style: TextStyle(color: FincoreColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _tipo,
            isExpanded: true,
            dropdownColor: FincoreColors.surface,
            style: const TextStyle(color: FincoreColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'sangria', child: Text('Sangria (retirada de dinheiro)')),
              DropdownMenuItem(value: 'suprimento', child: Text('Suprimento (reforço de troco)')),
              DropdownMenuItem(value: 'despesa', child: Text('Despesa Operacional')),
            ],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valorCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: FincoreColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Valor (R\$)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: FincoreColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final valor = ((double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0) * 100).toInt();
                  if (valor <= 0) {
                    setState(() => _loading = false);
                    return;
                  }
                  await widget.onConfirm(_tipo, valor, _descCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
