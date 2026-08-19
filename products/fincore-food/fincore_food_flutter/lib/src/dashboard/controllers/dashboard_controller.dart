import 'package:flutter/foundation.dart';
import '../domain/dashboard_service.dart';
import '../data/dashboard_repository.dart';

/// Controller do Dashboard — gerencia estado e lógica de negócio.
///
/// ## Padrão adotado: ChangeNotifier (Fase 3 — Refatoração Estratégica)
/// Separa a lógica de negócio da camada de UI, deixando a DashboardPage
/// responsável apenas por renderizar o estado exposto por este controller.
///
/// ## Uso:
/// ```dart
/// final controller = DependencyInjection().get<DashboardController>();
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) => MyWidget(metrics: controller.metrics),
/// )
/// ```
class DashboardController extends ChangeNotifier {
  final DashboardService _service;

  DashboardMetrics _metrics = DashboardMetrics.zero();
  bool _isLoading = true;
  String? _errorMessage;

  DashboardController({required DashboardService service})
      : _service = service;

  // ─── Getters públicos (somente leitura para a UI) ─────────────────────────
  DashboardMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Carrega as métricas do dashboard a partir do repositório local.
  /// Pode ser chamado pela UI via pull-to-refresh ou botão de atualização.
  Future<void> loadMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getMetrics();
      _metrics = data;
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Falha ao carregar métricas operacionais: $e';
      _isLoading = false;
    }

    notifyListeners();
  }
}
