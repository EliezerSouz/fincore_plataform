import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import '../controllers/kds_controller.dart';

/// Workspace de Produção (KDS — Kitchen Display System)
///
/// Ergonomia adaptada para uso industrial na cozinha:
/// - Fontes 150% ampliadas para leitura rápida a 2-3 metros de distância.
/// - Botões touch ampliados (mínimo 64x64dp) para operadores com luvas.
/// - Timer progressivo em tempo real com indicador visual de atraso (Danger).
class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  late final KdsController _controller;
  late final String _operadorId;
  Timer? _timerTick;

  @override
  void initState() {
    super.initState();
    _controller = KdsController();
    _operadorId = DependencyInjection().get<TenantContext>().usuario.id;
    _controller.carregarOrdens();

    // Atualiza timers e recarrega ordens silenciosamente a cada 2 segundos
    int count = 0;
    _timerTick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      count++;
      if (count % 2 == 0) {
        _controller.carregarOrdens(silent: true);
      }
      if (_controller.ordensEmPreparo.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timerTick?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: FincoreColors.primary),
          );
        }

        if (_controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: FincoreColors.danger),
                const SizedBox(height: 16),
                Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _controller.carregarOrdens,
                  child: const Text('TENTAR NOVAMENTE'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              // ── Coluna: PENDENTES ─────────────────────────────────
              Expanded(
                child: _buildKdsColumn(
                  title: 'PENDENTES',
                  count: _controller.ordensPendentes.length,
                  badgeColor: FincoreColors.textMuted,
                  ordens: _controller.ordensPendentes,
                ),
              ),
              const VerticalDivider(color: FincoreColors.border, width: 1.5),

              // ── Coluna: EM PREPARO ────────────────────────────────
              Expanded(
                child: _buildKdsColumn(
                  title: 'EM PREPARO',
                  count: _controller.ordensEmPreparo.length,
                  badgeColor: FincoreColors.primary,
                  ordens: _controller.ordensEmPreparo,
                ),
              ),
              const VerticalDivider(color: FincoreColors.border, width: 1.5),

              // ── Coluna: PRONTOS ───────────────────────────────────
              Expanded(
                child: _buildKdsColumn(
                  title: 'PRONTOS',
                  count: _controller.ordensProntas.length,
                  badgeColor: FincoreColors.success,
                  ordens: _controller.ordensProntas,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: FincoreColors.surface,
            mini: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: FincoreColors.border, width: 1),
            ),
            onPressed: _controller.carregarOrdens,
            child: const Icon(Icons.refresh, color: FincoreColors.textPrimary, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildKdsColumn({
    required String title,
    required int count,
    required Color badgeColor,
    required List<OrdemPreparo> ordens,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header da coluna KDS
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          color: FincoreColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FincoreColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: FincoreColors.border, height: 1),

        // Lista rolável de Cards de Produção
        Expanded(
          child: ordens.isEmpty
              ? Center(
                  child: Text(
                    'Sem pedidos nesta fila',
                    style: TextStyle(
                      color: FincoreColors.textMuted,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordens.length,
                  itemBuilder: (context, index) {
                    return _buildOrdemCard(ordens[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrdemCard(OrdemPreparo ordem) {
    final decorrido = ordem.tempoDecorrido;
    final atrasada = ordem.estaAtrasada;

    String timerStr = '00:00';
    if (decorrido != null) {
      final min = decorrido.inMinutes.toString().padLeft(2, '0');
      final seg = (decorrido.inSeconds % 60).toString().padLeft(2, '0');
      timerStr = '$min:$seg';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Borda vermelha se estiver atrasado, caso contrário borda cinza padrão
          color: atrasada ? FincoreColors.danger : FincoreColors.border,
          width: atrasada ? 3 : 1.5,
        ),
        boxShadow: atrasada
            ? [
                BoxShadow(
                  color: FincoreColors.danger.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Faixa de Prioridade no topo do Card para alto contraste
          if (ordem.prioridade == PrioridadeOrdem.urgente || ordem.prioridade == PrioridadeOrdem.vip)
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: ordem.prioridade == PrioridadeOrdem.urgente ? FincoreColors.danger : FincoreColors.warning,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
          // Top do Card (Nº Pedido, Prioridade e Timer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDEM #${ordem.id.substring(0, 4).toUpperCase()}',
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prioridade: ${ordem.prioridade.name.toUpperCase()}',
                      style: TextStyle(
                        color: ordem.prioridade == PrioridadeOrdem.urgente
                            ? FincoreColors.danger
                            : (ordem.prioridade == PrioridadeOrdem.vip
                                ? FincoreColors.warning
                                : FincoreColors.textSecondary),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Timer / Alerta de Atraso
                if (ordem.status == StatusOrdemPreparo.emPreparo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: atrasada ? FincoreColors.danger : FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: atrasada ? Colors.white : FincoreColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timerStr,
                          style: TextStyle(
                            color: atrasada ? Colors.white : FincoreColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: FincoreColors.border, height: 1),

          // Itens a serem produzidos (Ampliados para legibilidade)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ordem.itens.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: FincoreColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${item.quantidade.toInt()}x  ${item.nomeProduto}',
                          style: const TextStyle(
                            color: FincoreColors.textPrimary,
                            fontSize: 16.5, // 150% Ampliado
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Observações (se houver)
          if (ordem.observacoes != null && ordem.observacoes!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment_bank_outlined, color: FincoreColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ordem.observacoes!,
                        style: const TextStyle(
                          color: FincoreColors.textSecondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Divider(color: FincoreColors.border, height: 1),

          // Painel de Ações com Botões Gigantes (Mapeados para 64x64 dp de área de toque mínima)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ação Primária de Transição de Estado
                Expanded(
                  child: SizedBox(
                    height: 64, // Mínimo de 64 dp de altura ergonômica (PRD-008)
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionColor(ordem.status),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _handlePrimaryAction(ordem),
                      child: Text(
                        _getActionLabel(ordem.status).toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Botão de Cancelamento / Estorno LIFO
                SizedBox(
                  width: 64,
                  height: 64,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: FincoreColors.background,
                      side: const BorderSide(color: FincoreColors.danger, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: FincoreColors.danger, size: 28),
                    onPressed: () => _showCancelDialog(ordem),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(StatusOrdemPreparo status) {
    switch (status) {
      case StatusOrdemPreparo.pendente:
        return FincoreColors.primary;
      case StatusOrdemPreparo.emPreparo:
        return FincoreColors.success;
      case StatusOrdemPreparo.pronto:
        return FincoreColors.accent;
      default:
        return FincoreColors.textMuted;
    }
  }

  String _getActionLabel(StatusOrdemPreparo status) {
    switch (status) {
      case StatusOrdemPreparo.pendente:
        return 'INICIAR PREPARO';
      case StatusOrdemPreparo.emPreparo:
        return 'CONCLUIR PREPARO';
      case StatusOrdemPreparo.pronto:
        return 'ENTREGAR PEDIDO';
      default:
        return 'CONCLUÍDO';
    }
  }

  void _handlePrimaryAction(OrdemPreparo ordem) {
    if (ordem.status == StatusOrdemPreparo.pendente) {
      _controller.iniciarPreparo(ordem.id, _operadorId);
    } else if (ordem.status == StatusOrdemPreparo.emPreparo) {
      _controller.concluirPreparo(ordem.id, _operadorId);
    } else if (ordem.status == StatusOrdemPreparo.pronto) {
      _controller.entregarOrdem(ordem.id, _operadorId);
    }
  }

  void _showCancelDialog(OrdemPreparo ordem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Text('Cancelar Ordem?', style: TextStyle(color: FincoreColors.textPrimary)),
        content: Text(
          'Esta ação removerá a ordem #${ordem.id.substring(0, 4).toUpperCase()} e devolverá as quantidades de insumos ao estoque utilizando a regra LIFO.',
          style: const TextStyle(color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NÃO', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.danger),
            onPressed: () {
              _controller.cancelarOrdem(ordem.id, _operadorId);
              Navigator.pop(ctx);
            },
            child: const Text('CANCELAR E ESTORNAR LIFO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
