import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';

/// Modelo de dados contendo as métricas reais consolidadas para o dashboard.
class DashboardMetrics {
  final int totalPedidosHoje;
  final int faturamentoCentavosHoje;
  final int emPreparo;
  final int prontosOuEntrega;

  /// Faturamento dos últimos 7 dias, indexado por dia (0=hoje, 6=6 dias atrás)
  final List<int> faturamento7DiasCentavos;

  const DashboardMetrics({
    required this.totalPedidosHoje,
    required this.faturamentoCentavosHoje,
    required this.emPreparo,
    required this.prontosOuEntrega,
    required this.faturamento7DiasCentavos,
  });

  factory DashboardMetrics.zero() {
    return const DashboardMetrics(
      totalPedidosHoje: 0,
      faturamentoCentavosHoje: 0,
      emPreparo: 0,
      prontosOuEntrega: 0,
      faturamento7DiasCentavos: [0, 0, 0, 0, 0, 0, 0],
    );
  }
}

/// Repositório responsável por buscar métricas operacionais e financeiras
/// em tempo real da [pedidos_table] do banco local.
///
/// ## P2-07: Migrado do OutboxSync (dados perdidos após purge) para pedidos_table.
/// O gráfico de 7 dias agora reflete transações reais persistidas localmente.
class DashboardRepository {
  final FincoreDatabase db;
  final TenantContext tenantContext;
  final OrdemPreparoRepository kdsRepo;

  const DashboardRepository({
    required this.db,
    required this.tenantContext,
    required this.kdsRepo,
  });

  /// Calcula as métricas operacionais consolidadas de hoje e dos últimos 7 dias.
  Future<DashboardMetrics> getMetrics() async {
    final activeTenant = tenantContext.tenantId;
    if (activeTenant.isEmpty) {
      return DashboardMetrics.zero();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // ── 1. Pedidos HOJE (pedidos_table — somente confirmados/entregues) ──────
    // Exclui pedidos cancelados e rascunhos
    final pedidosHoje = await (db.select(db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.dataHoraCriacao.isBiggerOrEqualValue(startOfDay) &
              t.dataHoraCriacao.isSmallerOrEqualValue(endOfDay) &
              t.deletedAt.isNull() &
              t.status.isNotIn(['cancelado', 'rascunho'])))
        .get();

    final totalPedidos = pedidosHoje.length;
    final faturamentoHoje = pedidosHoje.fold<int>(
      0, (sum, p) => sum + p.valorTotalCentavos,
    );

    // ── 2. Faturamento dos últimos 7 dias (gráfico) ─────────────────────────
    final faturamento7Dias = <int>[0, 0, 0, 0, 0, 0, 0]; // índice 6=hoje, 0=6 dias atrás
    for (int i = 0; i < 7; i++) {
      final dia = now.subtract(Duration(days: 6 - i));
      final inicioDia = DateTime(dia.year, dia.month, dia.day);
      final fimDia = inicioDia.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

      final pedidosDia = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(activeTenant) &
                t.dataHoraCriacao.isBiggerOrEqualValue(inicioDia) &
                t.dataHoraCriacao.isSmallerOrEqualValue(fimDia) &
                t.deletedAt.isNull() &
                t.status.isNotIn(['cancelado', 'rascunho'])))
          .get();

      faturamento7Dias[i] = pedidosDia.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
    }

    // ── 3. Ordens de preparo KDS ativas ─────────────────────────────────────
    final kdsOrders = await kdsRepo.findAtivasKds();

    int emPreparo = 0;
    int prontos = 0;

    for (final order in kdsOrders) {
      if (order.status.name == 'emPreparo' || order.status.name == 'pendente') {
        emPreparo++;
      } else if (order.status.name == 'pronto') {
        prontos++;
      }
    }

    return DashboardMetrics(
      totalPedidosHoje: totalPedidos,
      faturamentoCentavosHoje: faturamentoHoje,
      emPreparo: emPreparo,
      prontosOuEntrega: prontos,
      faturamento7DiasCentavos: faturamento7Dias,
    );
  }
}
