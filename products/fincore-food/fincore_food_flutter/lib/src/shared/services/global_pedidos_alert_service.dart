import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';
import '../widgets/pedidos_atencao_overlay.dart';

/// Modelo de resumo para alertas operacionais globais de pedidos
class PedidosAlertaResumo {
  final int totalAtrasados;
  final int totalUrgentes; // ≤ 15 min
  final int totalAtencao; // ≤ 30 min
  final List<PedidoData> pedidosCriticos;

  const PedidosAlertaResumo({
    required this.totalAtrasados,
    required this.totalUrgentes,
    required this.totalAtencao,
    required this.pedidosCriticos,
  });

  bool get temPendenciasCriticas => totalAtrasados > 0 || totalUrgentes > 0;
  bool get hasAny => totalAtrasados > 0 || totalUrgentes > 0 || totalAtencao > 0;
}

/// Serviço global de vigilância de pedidos atrasados e pendências operacionais.
///
/// Executa em background em todo o aplicativo (independente da tela ativa).
/// Toca alerta sonoro configurável e exibe overlay flutuante de alta prioridade.
class GlobalPedidosAlertService {
  static final GlobalPedidosAlertService _instance = GlobalPedidosAlertService._internal();
  factory GlobalPedidosAlertService() => _instance;
  GlobalPedidosAlertService._internal();

  Timer? _timer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  PedidosAlertaResumo _ultimoResumo = const PedidosAlertaResumo(
    totalAtrasados: 0,
    totalUrgentes: 0,
    totalAtencao: 0,
    pedidosCriticos: [],
  );
  PedidosAlertaResumo get ultimoResumo => _ultimoResumo;

  final ValueNotifier<PedidosAlertaResumo?> resumoNotifier = ValueNotifier<PedidosAlertaResumo?>(null);
  final ValueNotifier<PedidosAlertaResumo?> alertaOverlayNotifier = ValueNotifier<PedidosAlertaResumo?>(null);

  OverlayEntry? _overlayEntry;
  BuildContext? _shellContext;

  /// Registra o contexto do Shell para permitir apresentação do Overlay flutuante
  void registerShellContext(BuildContext context) {
    _shellContext = context;
  }

  /// Inicia o serviço global de monitoramento
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleNextCheck();
  }

  /// Para o serviço
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    dismissOverlay();
  }

  /// Reinicia imediatamente o ciclo de temporização com as configurações recém-salvas
  void restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_isRunning) {
      _scheduleNextCheck();
    }
  }

  Future<void> _scheduleNextCheck() async {
    if (!_isRunning) return;

    // Executa a verificação imediatamente
    await checkNow();

    // Lê o intervalo configurado da empresa
    int intervaloSegundos = 60;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInterval = prefs.getInt('alerta_sonoro_intervalo_segundos');
      if (savedInterval != null && savedInterval >= 5) {
        intervaloSegundos = savedInterval;
      } else {
        final di = DependencyInjection();
        final configRepo = di.get<EmpresaConfiguracaoRepository>();
        final configs = await configRepo.findAll();
        if (configs.isNotEmpty) {
          intervaloSegundos = configs.first.intervaloAlertaPendentesSegundos;
          if (intervaloSegundos < 5) intervaloSegundos = 5;
        }
      }
    } catch (_) {}

    _timer?.cancel();
    _timer = Timer(Duration(seconds: intervaloSegundos), () => _scheduleNextCheck());
  }

  /// Executa uma varredura imediata de pedidos no banco local
  Future<PedidosAlertaResumo> checkNow() async {
    try {
      final di = DependencyInjection();
      TenantContext tenantCtx;
      FincoreDatabase db;
      try {
        db = di.get<FincoreDatabase>();
        tenantCtx = di.get<TenantContext>();
      } catch (_) {
        return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
      }

      if (!tenantCtx.hasContext) {
        return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
      }

      final activeTenantId = tenantCtx.tenantId;

      // Margem de segurança padrão (em minutos)
      int margemMinutos = 10;
      try {
        final configRepo = di.get<EmpresaConfiguracaoRepository>();
        final configs = await configRepo.findAll();
        if (configs.isNotEmpty) {
          margemMinutos = configs.first.margemSegurancaMinutos;
        }
      } catch (_) {}

      // Busca pedidos em aberto (confirmado, em_preparo) que não sejam uso interno
      final pedidosPendentes = await (db.select(db.pedidosTable)
            ..where((t) =>
                t.tenantId.equals(activeTenantId) &
                t.deletedAt.isNull() &
                t.status.isIn(const ['confirmado', 'em_preparo']) &
                t.isUsoInterno.equals(false)))
          .get();

      final now = DateTime.now();
      int atrasados = 0;
      int urgentes = 0;
      int atencao = 0;
      final List<PedidoData> criticos = [];

      for (final p in pedidosPendentes) {
        DateTime deadline;
        if (p.dataHoraEntregaPrevista != null) {
          deadline = p.dataHoraEntregaPrevista!.toLocal();
        } else {
          deadline = p.dataHoraCriacao.toLocal().add(Duration(minutes: margemMinutos));
        }

        final diff = deadline.difference(now);

        if (diff.isNegative) {
          atrasados++;
          criticos.add(p);
        } else if (diff.inMinutes <= 15) {
          urgentes++;
          criticos.add(p);
        } else if (diff.inMinutes <= 30) {
          atencao++;
        }
      }

      final resumo = PedidosAlertaResumo(
        totalAtrasados: atrasados,
        totalUrgentes: urgentes,
        totalAtencao: atencao,
        pedidosCriticos: criticos,
      );

      _ultimoResumo = resumo;
      resumoNotifier.value = resumo;

      // Dispara som e overlay se houver pendências críticas
      if (resumo.temPendenciasCriticas) {
        // Toca som de urgência
        await SoundService.playUrgentSound();

        // Notifica o Shell para exibir o overlay com animação em qualquer tela
        alertaOverlayNotifier.value = null;
        alertaOverlayNotifier.value = resumo;
      } else if (resumo.totalAtencao > 0) {
        await SoundService.playAttentionSound();
        dismissOverlay();
      } else {
        dismissOverlay();
      }

      return resumo;
    } catch (e) {
      debugPrint('[GlobalPedidosAlertService] Erro ao verificar pedidos: $e');
      return const PedidosAlertaResumo(totalAtrasados: 0, totalUrgentes: 0, totalAtencao: 0, pedidosCriticos: []);
    }
  }

  /// Descarta o overlay visual
  void dismissOverlay() {
    alertaOverlayNotifier.value = null;
    hideOverlay();
  }

  /// Esconde o overlay se inserido via OverlayState
  void hideOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }
}
