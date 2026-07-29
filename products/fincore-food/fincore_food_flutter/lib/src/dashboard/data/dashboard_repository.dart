import 'dart:convert';
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

  const DashboardMetrics({
    required this.totalPedidosHoje,
    required this.faturamentoCentavosHoje,
    required this.emPreparo,
    required this.prontosOuEntrega,
  });

  factory DashboardMetrics.zero() {
    return const DashboardMetrics(
      totalPedidosHoje: 0,
      faturamentoCentavosHoje: 0,
      emPreparo: 0,
      prontosOuEntrega: 0,
    );
  }
}

/// Repositório responsável por buscar métricas operacionais e financeiras em tempo real do banco de dados local.
class DashboardRepository {
  final FincoreDatabase db;
  final TenantContext tenantContext;
  final OrdemPreparoRepository KdsRepo;

  const DashboardRepository({
    required this.db,
    required this.tenantContext,
    required this.KdsRepo,
  });

  /// Calcula as métricas operacionais consolidadas de hoje.
  Future<DashboardMetrics> getMetrics() async {
    final activeTenant = tenantContext.tenantId;
    if (activeTenant.isEmpty) {
      return DashboardMetrics.zero();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // 1. Buscar transações de pedidos do dia na OutboxSync
    final orderRows = await (db.select(db.outboxSync)
          ..where((t) =>
              t.entity.equals('Pedido') &
              t.tenantId.equals(activeTenant) &
              t.createdAt.isBiggerOrEqualValue(startOfDay) &
              t.createdAt.isSmallerOrEqualValue(endOfDay)))
        .get();

    int totalPedidos = orderRows.length;
    int faturamentoCentavos = 0;

    for (final row in orderRows) {
      try {
        final payload = jsonDecode(row.payload) as Map<String, dynamic>;
        final total = payload['valorTotalCentavos'] as int? ?? 0;
        faturamentoCentavos += total;
      } catch (e) {
        // Ignora erros de parsing de payloads individuais
      }
    }

    // 2. Buscar ordens de preparo KDS ativas
    final kdsOrders = await KdsRepo.findAtivasKds();
    
    int emPreparo = 0;
    int prontos = 0;

    for (final order in kdsOrders) {
      // Status: pendente | em_preparo | pronto
      if (order.status.name == 'emPreparo' || order.status.name == 'pendente') {
        emPreparo++;
      } else if (order.status.name == 'pronto') {
        prontos++;
      }
    }

    return DashboardMetrics(
      totalPedidosHoje: totalPedidos,
      faturamentoCentavosHoje: faturamentoCentavos,
      emPreparo: emPreparo,
      prontosOuEntrega: prontos,
    );
  }
}
