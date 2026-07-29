import '../data/dashboard_repository.dart';

/// Serviço de domínio para gerenciar e expor dados do dashboard consolidado.
class DashboardService {
  final DashboardRepository repository;

  const DashboardService({required this.repository});

  /// Busca as métricas de hoje em tempo real.
  Future<DashboardMetrics> getMetrics() async {
    return repository.getMetrics();
  }
}
