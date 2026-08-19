import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

/// Componente de Monitoramento de Saúde da Sincronização (Sync Health Center)
/// Unifica os indicadores de Nuvem, Banco SQLite Local, Fila Outbox e Retries sem contradições.
class SyncHealthCard extends StatelessWidget {
  final bool isCloudConnected;
  final bool isSqliteHealthy;
  final int pendingOutboxCount;
  final int retryQueueCount;
  final DateTime? lastSyncTime;
  final VoidCallback? onForceSync;

  const SyncHealthCard({
    super.key,
    this.isCloudConnected = true,
    this.isSqliteHealthy = true,
    this.pendingOutboxCount = 0,
    this.retryQueueCount = 0,
    this.lastSyncTime,
    this.onForceSync,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingOutboxCount > 0 || retryQueueCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sync, color: FincoreColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SYNC HEALTH CENTER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: FincoreColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (onForceSync != null)
                OutlinedButton.icon(
                  onPressed: onForceSync,
                  icon: const Icon(Icons.refresh, size: 13),
                  label: const Text('Sincronizar Agora', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    side: BorderSide(color: FincoreColors.border),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPillar(
                label: 'NUVEM (CLOUD)',
                value: isCloudConnected ? 'Conectado' : 'Offline',
                icon: Icons.cloud_done_outlined,
                color: isCloudConnected ? FincoreColors.success : FincoreColors.danger,
              ),
              _buildDivider(),
              _buildPillar(
                label: 'SQLITE LOCAL',
                value: isSqliteHealthy ? 'Saudável' : 'Erro DB',
                icon: Icons.storage_outlined,
                color: isSqliteHealthy ? FincoreColors.success : FincoreColors.danger,
              ),
              _buildDivider(),
              _buildPillar(
                label: 'FILA OUTBOX',
                value: pendingOutboxCount == 0 ? 'Zerada' : '$pendingOutboxCount Pendente(s)',
                icon: Icons.outbox_outlined,
                color: pendingOutboxCount == 0 ? FincoreColors.success : FincoreColors.warning,
              ),
              _buildDivider(),
              _buildPillar(
                label: 'RETRY QUEUE',
                value: retryQueueCount == 0 ? 'Sem falhas' : '$retryQueueCount Tentativa(s)',
                icon: Icons.replay_outlined,
                color: retryQueueCount == 0 ? FincoreColors.success : FincoreColors.danger,
              ),
              _buildDivider(),
              _buildPillar(
                label: 'ÚLTIMA SYNC',
                value: _formatTime(lastSyncTime),
                icon: Icons.access_time_outlined,
                color: hasPending ? FincoreColors.warning : FincoreColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillar({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: FincoreColors.textMuted, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: FincoreColors.border,
    );
  }
}
