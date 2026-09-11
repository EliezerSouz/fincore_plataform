import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/planejamento_controller.dart';
import 'package:fincore_food_flutter/src/estoque/controllers/estoque_controller.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart'; // Para CriarPlanoDialog
import '../controllers/dashboard_controller.dart';
import 'package:intl/intl.dart';

class BlocoRecomendacoes extends StatelessWidget {
  final DashboardController controller;

  const BlocoRecomendacoes({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final recs = controller.recomendacoes;
    if (recs.isEmpty) return const SizedBox.shrink();

    final planeCtrl = DependencyInjection().get<PlanoProducaoController>();
    final estoqueCtrl = DependencyInjection().get<EstoqueController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology_outlined, color: FincoreColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'FINCORE Recomenda',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = recs[index];

            final Color color = switch (r.tipo) {
              'producao_recomendada' => const Color(0xFFE05C5C),
              'nenhuma_acao' => FincoreColors.success,
              'alerta_operacional' || _ => const Color(0xFFF59E0B),
            };

            final IconData icon = switch (r.tipo) {
              'producao_recomendada' => Icons.precision_manufacturing_rounded,
              'nenhuma_acao' => Icons.check_circle_outline_rounded,
              'alerta_operacional' || _ => Icons.warning_amber_rounded,
            };

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.titulo,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          r.descricao,
                          style: const TextStyle(
                            color: FincoreColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildAcaoButton(context, r, planeCtrl, estoqueCtrl),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAcaoButton(
    BuildContext context,
    RecomendacaoOperacional r,
    PlanoProducaoController planeCtrl,
    EstoqueController estoqueCtrl,
  ) {
    switch (r.tipo) {
      case 'producao_recomendada':
        return ElevatedButton(
          onPressed: () {
            final item = estoqueCtrl.itens.firstWhere((i) => i.estoque.produtoId == r.produtoId);
            showDialog(
              context: context,
              builder: (_) => CriarPlanoDialog(
                planeCtrl: planeCtrl,
                estoqueCtrl: estoqueCtrl,
                produtoIdPreSelecionado: item.estoque.produtoId,
                quantidadePreSelecionada: item.sugestaoProducao > 0 ? item.sugestaoProducao : null,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE05C5C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(r.acaoLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        );

      case 'nenhuma_acao':
        return OutlinedButton(
          onPressed: () {
            final item = estoqueCtrl.itens.firstWhere((i) => i.estoque.produtoId == r.produtoId);
            final planosProduto = planeCtrl.planosAtivos
                .where((p) => p.produtoId == item.estoque.produtoId)
                .toList();

            showDialog(
              context: context,
              builder: (_) => _DialogDetalhesPlanejamentoRec(
                item: item,
                planos: planosProduto,
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: FincoreColors.success,
            side: BorderSide(color: FincoreColors.success),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(r.acaoLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        );

      case 'alerta_operacional':
      default:
        return OutlinedButton(
          onPressed: () => FincoreShell.selectTab(context, 'estoque'),
          style: OutlinedButton.styleFrom(
            foregroundColor: FincoreColors.textSecondary,
            side: const BorderSide(color: FincoreColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(r.acaoLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        );
    }
  }
}

class _DialogDetalhesPlanejamentoRec extends StatelessWidget {
  final EstoqueItem item;
  final List<PlanoProducaoData> planos;

  const _DialogDetalhesPlanejamentoRec({
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
              'Planejamento — ${item.nomeProduto}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de produção prevista: ${item.producaoPlanejada} ${item.unidade}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Estoque físico atual: ${item.quantidadeAtual} ${item.unidade} • Reservado: ${item.quantidadeReservada} ${item.unidade}',
              style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
            ),
            const Divider(height: 20, color: FincoreColors.border),
            const Text(
              'Campanhas Ativas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (planos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('Nenhuma campanha de produção pendente.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: planos.length,
                  separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 1),
                  itemBuilder: (ctx, idx) {
                    final p = planos[idx];
                    final pct = p.quantidadePlanejada > 0 ? (p.quantidadeProduzida / p.quantidadePlanejada) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Data: ${formatadorData.format(p.dataPlano.toLocal())}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FincoreColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.status.toUpperCase(),
                                  style: TextStyle(color: FincoreColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Meta: ${p.quantidadePlanejada} un • Produzido: ${p.quantidadeProduzida} un',
                                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '${(pct * 100).round()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct,
                            backgroundColor: FincoreColors.border,
                            color: FincoreColors.primary,
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar', style: TextStyle(color: FincoreColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            ProducaoPage.initialTab = 2; // Abre a aba Planejamento
            ProducaoPage.filtroProdutoId = item.estoque.produtoId; // Filtra por este produto
            Navigator.of(context).pop();
            FincoreShell.selectTab(context, 'producao');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Ir para Gestão de Produção'),
        ),
      ],
    );
  }
}
