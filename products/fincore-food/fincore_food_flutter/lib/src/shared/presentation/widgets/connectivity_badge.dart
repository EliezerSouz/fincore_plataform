import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';

/// Badge compacto que exibe o status de conectividade com a nuvem em tempo real.
///
/// Usa o [CloudConnectivity] enum do [SupabaseSyncService] e polling periódico
/// para refletir o estado atual. Quando offline, exibe em laranja com ícone
/// de aviso. Quando online, exibe em verde discreto.
///
/// ## Uso (na AppBar da Shell):
/// ```dart
/// AppBar(
///   actions: const [ConnectivityBadge(), SizedBox(width: 8)],
/// )
/// ```
class ConnectivityBadge extends StatefulWidget {
  final VoidCallback? onTap;
  const ConnectivityBadge({super.key, this.onTap});

  @override
  State<ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<ConnectivityBadge> {
  CloudConnectivity _status = CloudConnectivity.unknown;
  Timer? _pollingTimer;
  SupabaseSyncService? _syncService;
  ({int pending, int retrying, int failed, int total}) _stats = (pending: 0, retrying: 0, failed: 0, total: 0);

  @override
  void initState() {
    super.initState();
    try {
      _syncService = DependencyInjection().get<SupabaseSyncService>();
      _updateStatus();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _updateStatus());
    } catch (_) {}
  }

  Future<void> _updateStatus() async {
    if (!mounted) return;
    final status = _syncService?.connectivity ?? CloudConnectivity.unknown;
    final stats = await _syncService?.getOutboxStats() ?? (pending: 0, retrying: 0, failed: 0, total: 0);

    if (status != _status || stats != _stats) {
      setState(() {
        _status = status;
        _stats = stats;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_stats.failed > 0 || _stats.pending > 0 || _stats.retrying > 0) {
      final count = await _syncService?.retryFailedEntries() ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Solicitada a re-sincronização de $count item(ns) da fila.'
                : 'Fila de sincronização ativa.'),
            duration: const Duration(seconds: 3),
          ),
        );
        _updateStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(_status, _stats);

    return InkWell(
      onTap: widget.onTap ?? _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: config.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: config.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_status == CloudConnectivity.online && _stats.failed == 0)
                _PulsingDot(color: config.color)
              else
                Icon(config.icon, color: config.color, size: 12),
              const SizedBox(width: 5),
              Text(
                config.label,
                style: TextStyle(
                  color: config.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _BadgeConfig _badgeConfig(CloudConnectivity status, ({int pending, int retrying, int failed, int total}) stats) {
    if (status == CloudConnectivity.offline) {
      return const _BadgeConfig(
        color: FincoreColors.warning,
        icon: Icons.cloud_off_outlined,
        label: 'Offline',
        tooltip: 'Sem conexão — alterações salvas localmente no SQLite.',
      );
    }

    if (status == CloudConnectivity.unknown) {
      return const _BadgeConfig(
        color: FincoreColors.textMuted,
        icon: Icons.sync_outlined,
        label: 'Verificando',
        tooltip: 'Verificando conexão...',
      );
    }

    // Online
    if (stats.failed > 0) {
      return _BadgeConfig(
        color: FincoreColors.danger,
        icon: Icons.warning_amber_rounded,
        label: 'Online (${stats.failed} falha${stats.failed > 1 ? "s" : ""})',
        tooltip: '${stats.failed} item(ns) com falha de schema/banco no envio. Clique para reprocessar.',
      );
    }

    final pendingTotal = stats.pending + stats.retrying;
    if (pendingTotal > 0) {
      return _BadgeConfig(
        color: FincoreColors.info,
        icon: Icons.sync_outlined,
        label: 'Online ($pendingTotal pendente${pendingTotal > 1 ? "s" : ""})',
        tooltip: 'Transmitindo $pendingTotal alteração(ões) em segundo plano...',
      );
    }

    return const _BadgeConfig(
      color: FincoreColors.success,
      icon: Icons.check_circle_outline,
      label: 'Online · Sincronizado',
      tooltip: 'Conectado ao Supabase — tudo sincronizado em tempo real.',
    );
  }
}

/// Ponto pulsante animado para indicar conectividade ativa.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Icon(Icons.circle, color: widget.color, size: 8),
    );
  }
}

class _BadgeConfig {
  final Color color;
  final IconData icon;
  final String label;
  final String tooltip;

  const _BadgeConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}
