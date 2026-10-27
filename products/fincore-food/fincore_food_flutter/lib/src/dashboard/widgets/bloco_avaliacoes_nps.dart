import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/dashboard_controller.dart';

/// Bloco do Dashboard para Monitoramento de Satisfação do Cliente, NPS e Feedbacks
class BlocoAvaliacoesNps extends StatefulWidget {
  final DashboardController controller;
  const BlocoAvaliacoesNps({super.key, required this.controller});

  @override
  State<BlocoAvaliacoesNps> createState() => _BlocoAvaliacoesNpsState();
}

class _BlocoAvaliacoesNpsState extends State<BlocoAvaliacoesNps> {
  List<Map<String, dynamic>> _avaliacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAvaliacoes();
  }

  Future<void> _carregarAvaliacoes() async {
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final tenantId = tenantCtx.hasContext ? tenantCtx.empresa.id : null;
      if (tenantId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await Supabase.instance.client
          .from('avaliacoes_pedidos')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _avaliacoes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[BlocoAvaliacoesNps] Erro ao carregar avaliacoes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FincoreColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_avaliacoes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satisfação do Cliente & NPS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FincoreColors.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Nenhuma avaliação pós-venda registrada ainda. Envie o link de avaliação via WhatsApp aos clientes para medir o NPS da sua loja.',
                    style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final total = _avaliacoes.length;
    final somaNotas = _avaliacoes.fold<num>(0, (acc, item) => acc + ((item['nota'] as num?) ?? 5));
    final media = (somaNotas / total).toStringAsFixed(1);
    final promotores = _avaliacoes.where((a) => ((a['nota'] as num?) ?? 0) >= 4).length;
    final pctAprovacao = ((promotores / total) * 100).round();

    // Contagem de tags mais frequentes
    final Map<String, int> tagCounts = {};
    for (final a in _avaliacoes) {
      final tags = (a['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
      for (final t in tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Bloco
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satisfação do Cliente & NPS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: FincoreColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Feedback real dos clientes via WhatsApp pós-venda',
                    style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _carregarAvaliacoes,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                color: FincoreColors.textMuted,
                tooltip: 'Atualizar avaliações',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPIs em Grid Compacto
          Row(
            children: [
              // Média de Estrelas
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOTA MÉDIA',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            media,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                          const SizedBox(width: 4),
                          const Text('/ 5.0', style: TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(5, (i) {
                          final mVal = double.tryParse(media) ?? 5.0;
                          return Icon(
                            i < mVal.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 14,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Taxa de Aprovação / NPS
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APROVAÇÃO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pctAprovacao%',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$promotores de $total promotores',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Total de Feedbacks
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVALIAÇÕES',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FincoreColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FincoreColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'clientes avaliaram',
                        style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Principais Elogios & Tags
          if (topTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'O que os clientes mais elogiam:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: FincoreColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in topTags.take(5))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${entry.key} (${entry.value})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                    ),
                  ),
              ],
            ),
          ],

          // Comentários Recentes
          const SizedBox(height: 14),
          const Divider(height: 1, color: FincoreColors.border),
          const SizedBox(height: 10),
          const Text(
            'Comentários Recentes:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: FincoreColors.textPrimary),
          ),
          const SizedBox(height: 8),

          for (final rev in _avaliacoes.take(3)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
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
                      Text(
                        rev['cliente_nome']?.toString() ?? 'Cliente',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FincoreColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(((rev['nota'] as num?)?.toInt() ?? 5), (_) {
                          return const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B));
                        }),
                      ),
                      const Spacer(),
                      if (rev['created_at'] != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.tryParse(rev['created_at'].toString())?.toLocal() ?? DateTime.now()),
                          style: const TextStyle(fontSize: 10, color: FincoreColors.textMuted),
                        ),
                    ],
                  ),
                  if (rev['comentario'] != null && rev['comentario'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${rev['comentario']}”',
                      style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: FincoreColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
