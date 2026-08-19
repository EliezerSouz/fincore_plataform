import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_food_flutter/src/shared/data/sync/supabase_sync_service.dart';
import 'package:fincore_food_flutter/src/configuracoes/views/configuracoes_page.dart';
import 'package:fincore_food_flutter/src/produtos/views/produtos_page.dart';
import 'package:fincore_food_flutter/src/clientes/views/clientes_page.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pedidos_page.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';
import 'package:fincore_food_flutter/src/dashboard/views/dashboard_page.dart';
import 'package:fincore_food_flutter/src/usuarios/views/usuarios_page.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/connectivity_badge.dart';
import 'package:fincore_food_flutter/src/financeiro/views/financeiro_page.dart';
import 'package:fincore_food_flutter/src/estoque/views/estoque_page.dart';
import 'package:fincore_food_flutter/src/estoque/views/producao_page.dart';
import 'package:fincore_food_flutter/src/cozinha/views/kds_screen.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';

// ─── Modelo de item da sidebar ─────────────────────────────────────────────

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData iconSelected;

  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconSelected,
  });
}

class _NavGroup {
  final String? label;
  final List<_NavItem> items;
  const _NavGroup({this.label, required this.items});
}

// ─── Shell Principal ────────────────────────────────────────────────────────

class FincoreShell extends StatefulWidget {
  final VoidCallback? onLogout;
  const FincoreShell({super.key, this.onLogout});

  @override
  State<FincoreShell> createState() => _FincoreShellState();
}

class _FincoreShellState extends State<FincoreShell>
    with TickerProviderStateMixin {
  String _selectedTabId = 'dashboard';
  bool _sidebarExpanded = true;
  late final TenantContext _tenantContext;
  late String _activeTenantName;
  late String _userName;
  late String _userInitials;
  late String _userRole;

  // PDV padrão (delivery = pdv_express, balcao = pdv_balcao)
  String _pdvPadrao = 'pdv_express';
  static const _kPdvPadrao = 'pdv_padrao_tab';

  int _pendingCount = 0;
  int _failedCount = 0;
  bool _isOnline = true;
  String _lastSyncStr = 'Nunca';
  Timer? _syncStatusTimer;

  // Grupos de navegação — organizados por contexto funcional.
  // Visibilidade por role é aplicada em _buildNavItem via PermissaoService.
  static const List<_NavGroup> _allNavGroups = [
    _NavGroup(
      label: 'OPERAÇÃO',
      items: [
        _NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          iconSelected: Icons.dashboard_rounded,
        ),
        _NavItem(
          id: 'pdv',
          label: 'Frente de Caixa',
          icon: Icons.point_of_sale_outlined,
          iconSelected: Icons.point_of_sale_rounded,
        ),
        _NavItem(
          id: 'pedidos',
          label: 'Central de Pedidos',
          icon: Icons.receipt_long_outlined,
          iconSelected: Icons.receipt_long_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'CADASTROS',
      items: [
        _NavItem(
          id: 'produtos',
          label: 'Produtos',
          icon: Icons.restaurant_menu_outlined,
          iconSelected: Icons.restaurant_menu_rounded,
        ),
        _NavItem(
          id: 'clientes',
          label: 'Clientes',
          icon: Icons.people_outline,
          iconSelected: Icons.people_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'FINANCEIRO',
      items: [
        _NavItem(
          id: 'financeiro',
          label: 'Financeiro',
          icon: Icons.account_balance_wallet_outlined,
          iconSelected: Icons.account_balance_wallet_rounded,
        ),
        _NavItem(
          id: 'estoque',
          label: 'Estoque',
          icon: Icons.inventory_2_outlined,
          iconSelected: Icons.inventory_2_rounded,
        ),
        _NavItem(
          id: 'producao',
          label: 'Produção',
          icon: Icons.factory_outlined,
          iconSelected: Icons.factory_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'SISTEMA',
      items: [
        _NavItem(
          id: 'usuarios',
          label: 'Usuários & Permissões',
          icon: Icons.people_alt_outlined,
          iconSelected: Icons.people_alt_rounded,
        ),
        _NavItem(
          id: 'configuracoes',
          label: 'Configurações',
          icon: Icons.settings_outlined,
          iconSelected: Icons.settings_rounded,
        ),
      ],
    ),
  ];

  List<_NavGroup> get _navGroups {
    final role = _tenantContext.hasContext ? _tenantContext.usuario.role : null;
    return _allNavGroups
        .map((group) {
          final visibleItems = group.items.where((item) {
            switch (item.id) {
              case 'dashboard':
                return PermissaoService.podeVerDashboard(role);
              case 'pdv':
                return PermissaoService.podeAcessarPdv(role);
              case 'pedidos':
                return true; // todos os perfis
              case 'kds':
                return PermissaoService.podeVerKds(role);
              case 'produtos':
              case 'clientes':
                return PermissaoService.podeAcessarCadastros(role);
              case 'financeiro':
                return PermissaoService.podeAcessarFinanceiro(role);
              case 'estoque':
              case 'producao':
                return PermissaoService.podeAcessarFinanceiro(role);
              case 'usuarios':
              case 'configuracoes':
                return PermissaoService.podeAcessarSistema(role);
              default:
                return true;
            }
          }).toList();
          return _NavGroup(label: group.label, items: visibleItems);
        })
        .where((g) => g.items.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tenantContext = DependencyInjection().get<TenantContext>();
    _activeTenantName = _tenantContext.hasContext
        ? _tenantContext.empresa.nomeFantasia
        : 'Matriz';
    final nome = _tenantContext.hasContext
        ? _tenantContext.usuario.nome
        : 'Usuário';
    _userName = nome;
    _userInitials = nome
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    // ⚠️  SEGURANÇA: A role do usuário é lida do campo `role` do model CoreUsuario,
    // populado pelo servidor via MembroEmpresa.role (ADMIN, OPERADOR, COZINHA, etc.).
    // Nunca comparar e-mail para determinar privilégios — isso é um vetor de
    // escalada de privilégio. Ver [SEC-002] do relatório de auditoria.
    _userRole = _mapRoleToLabel(
      _tenantContext.hasContext ? _tenantContext.usuario.role : null,
    );
    _loadPrefs();
    _startSyncStatusMonitoring();
  }

  /// Converte a role técnica do banco (ex: 'ADMIN', 'SUPERADMIN') em um
  /// label amigável para exibição na interface.
  String _mapRoleToLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPERADMIN':
        return 'Superadmin';
      case 'ADMIN':
        return 'Administrador';
      case 'OPERADOR':
      case 'OPERADOR_CAIXA':
        return 'Operador de Caixa';
      case 'COZINHA':
        return 'Cozinha';
      case 'ENTREGADOR':
        return 'Entregador';
      default:
        return 'Operador';
    }
  }


  void _startSyncStatusMonitoring() {
    _updateSyncStatus();
    // P3-05: Aumentado de 4s para 15s — 15 queries/min → 4 queries/min sem impacto de UX.
    // O SupabaseSyncService notifica via onConnectivityChanged em tempo real quando necessário.
    _syncStatusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _updateSyncStatus();
      }
    });
  }

  Future<void> _updateSyncStatus() async {
    try {
      final di = DependencyInjection();
      
      OutboxService outbox;
      FincoreDatabase db;
      try {
        outbox = di.get<OutboxService>();
        db = di.get<FincoreDatabase>();
      } catch (_) {
        return;
      }

      final pendingList = await outbox.getPendingEntries();
      final failedList = await (db.select(db.outboxSync)
            ..where((t) => t.status.equals('failed')))
          .get();

      bool online = false;
      try {
        final syncService = di.get<SupabaseSyncService>();
        online = await syncService.isOnline();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _pendingCount = pendingList.length;
          _failedCount = failedList.length;
          _isOnline = online;
          if (pendingList.isEmpty && failedList.isEmpty && online) {
            final now = DateTime.now();
            _lastSyncStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _showSyncFailuresDialog(BuildContext context) async {
    final di = DependencyInjection();
    final db = di.get<FincoreDatabase>();
    final outbox = di.get<OutboxService>();

    List<OutboxEntry> pendingList = await outbox.getPendingEntries();
    List<OutboxEntry> failedList = await (db.select(db.outboxSync)
          ..where((t) => t.status.equals('failed')))
        .get();

    if (!context.mounted) return;

    int initialTab = (failedList.isNotEmpty && pendingList.isEmpty) ? 1 : 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> refreshData() async {
            final newPending = await outbox.getPendingEntries();
            final newFailed = await (db.select(db.outboxSync)
                  ..where((t) => t.status.equals('failed')))
                .get();
            setDialogState(() {
              pendingList = newPending;
              failedList = newFailed;
            });
            _updateSyncStatus();
          }

          return Dialog(
            backgroundColor: FincoreColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 720,
              height: 540,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FincoreColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.sync, color: FincoreColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Central de Diagnóstico de Sincronização',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: FincoreColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Gerenciador de Fila de Transmissão (Outbox Engine)',
                                style: TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Abas de Seleção (Pendentes / Falhas / Visão Geral)
                  Container(
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => initialTab = 0),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: initialTab == 0 ? FincoreColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_top_rounded,
                                      size: 14,
                                      color: initialTab == 0 ? FincoreColors.warning : FincoreColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pendentes (${pendingList.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: initialTab == 0 ? FincoreColors.textPrimary : FincoreColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => initialTab = 1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: initialTab == 1 ? FincoreColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      size: 14,
                                      color: initialTab == 1 ? FincoreColors.danger : FincoreColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Falhas (${failedList.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: initialTab == 1 ? FincoreColors.textPrimary : FincoreColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => initialTab = 2),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: initialTab == 2 ? FincoreColors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 14,
                                      color: initialTab == 2 ? FincoreColors.primary : FincoreColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Visão Geral',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: initialTab == 2 ? FincoreColors.textPrimary : FincoreColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conteúdo da Aba Selecionada
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        if (initialTab == 0) {
                          // ABA 0: PENDENTES
                          if (pendingList.isEmpty) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: FincoreColors.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FincoreColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, color: FincoreColors.success, size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      'Nenhuma alteração pendente de envio!',
                                      style: TextStyle(color: FincoreColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: pendingList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = pendingList[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FincoreColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: FincoreColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ENTIDADE: [${item.entity.toUpperCase()}] • ${item.action}',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: FincoreColors.warning),
                                          ),
                                        ),
                                        Text(
                                          'ID: ${item.entityId}',
                                          style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: FincoreColors.border),
                                      ),
                                      child: SelectableText(
                                        item.payload,
                                        maxLines: 3,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: FincoreColors.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Criado em: ${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')} às ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}:${item.createdAt.second.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 10.5, color: FincoreColors.textMuted),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FincoreColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final syncEngine = di.get<SyncEngine>();
                                              await syncEngine.processPendingQueue();
                                            } catch (_) {}
                                            await refreshData();
                                          },
                                          icon: const Icon(Icons.send_rounded, size: 13, color: Colors.white),
                                          label: const Text('Forçar Envio Agora', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else if (initialTab == 1) {
                          // ABA 1: FALHAS
                          if (failedList.isEmpty) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: FincoreColors.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FincoreColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, color: FincoreColors.success, size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      'Nenhuma falha de sincronização pendente!',
                                      style: TextStyle(color: FincoreColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: failedList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = failedList[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FincoreColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: FincoreColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: FincoreColors.danger.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ENTIDADE: ${item.entity.toUpperCase()} • ${item.action}',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: FincoreColors.danger),
                                          ),
                                        ),
                                        Text(
                                          'ID: ${item.entityId} • ${item.attemptsCount} tentativa(s)',
                                          style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: FincoreColors.danger.withValues(alpha: 0.3)),
                                      ),
                                      child: SelectableText(
                                        'ERRO EXATO: ${item.errorMessage ?? "Falha de conexão / Timeout / Restrição no servidor"}',
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFFFCA5A5)),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: FincoreColors.danger),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          onPressed: () async {
                                            await (db.delete(db.outboxSync)..where((t) => t.id.equals(item.id))).go();
                                            await refreshData();
                                          },
                                          icon: const Icon(Icons.delete_outline, size: 14, color: FincoreColors.danger),
                                          label: const Text('Descartar / Resetar', style: TextStyle(fontSize: 11, color: FincoreColors.danger)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FincoreColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          ),
                                          onPressed: () async {
                                            await outbox.updateStatus(item.id, SyncStatus.pending);
                                            try {
                                              final syncEngine = di.get<SyncEngine>();
                                              await syncEngine.processPendingQueue();
                                            } catch (_) {}
                                            await refreshData();
                                          },
                                          icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                                          label: const Text('Tentar Sincronizar Novamente', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          // ABA 2: VISÃO GERAL
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: FincoreColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                            color: _isOnline ? FincoreColors.success : FincoreColors.danger,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Status da Conexão Nuvem: ${_isOnline ? "CONECTADO (ONLINE)" : "OFFLINE"}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _isOnline ? FincoreColors.success : FincoreColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        pendingList.isNotEmpty || failedList.isNotEmpty
                                            ? '• Status do Engine: Há ${pendingList.length + failedList.length} registro(s) no Outbox. O recebimento remoto (PULL) fica suspenso até o envio da fila local.'
                                            : '• Status do Engine: Fila Outbox 100% limpa. Sistema sincronizado com a nuvem.',
                                        style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: FincoreColors.border),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('PENDENTES DE ENVIO', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('${pendingList.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FincoreColors.warning)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: FincoreColors.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: FincoreColors.border),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('FALHAS DE ENVIO', style: TextStyle(fontSize: 10, color: FincoreColors.textMuted, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('${failedList.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FincoreColors.danger)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FincoreColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final syncEngine = di.get<SyncEngine>();
                                        await syncEngine.processPendingQueue();
                                      } catch (_) {}
                                      await refreshData();
                                    },
                                    icon: const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                                    label: const Text('Forçar Processamento da Fila de Sincronização', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    _updateSyncStatus();
  }

  @override
  void dispose() {
    _syncStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pdvPadrao = prefs.getString(_kPdvPadrao) ?? 'pdv_express';
      _selectedTabId = 'dashboard'; // Sempre inicia no Dashboard
    });
  }

  Future<void> _setPdvPadrao(String modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPdvPadrao, modo);
    setState(() {
      _pdvPadrao = modo;
    });
  }

  void _selectTab(String id) {
    setState(() => _selectedTabId = id);
  }

  Future<void> _logout() async {
    final ok = await _confirmarAcao(
      context,
      titulo: 'Sair da Conta',
      mensagem:
          'Tem certeza que deseja sair? Você precisará fazer login novamente.',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fincore_offline_usuario_id');
      await Supabase.instance.client.auth.signOut();
      if (widget.onLogout != null) {
        widget.onLogout!();
      }
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _shellBg => _isDark ? FincoreColors.background : Theme.of(context).scaffoldBackgroundColor;
  Color get _sidebarBg => _isDark ? FincoreColors.sidebarBackground : Colors.white;
  Color get _sidebarBorder => _isDark ? FincoreColors.sidebarBorder : const Color(0xFFE5E7EB);
  Color get _surfaceBg => _isDark ? FincoreColors.surface : Colors.white;
  Color get _textPrimary => _isDark ? FincoreColors.textPrimary : const Color(0xFF111827);
  Color get _textSecondary => _isDark ? FincoreColors.textSecondary : const Color(0xFF4B5563);
  Color get _textMuted => _isDark ? FincoreColors.textMuted : const Color(0xFF6B7280);

  Widget _buildStatusBar() {
    Color syncColor = FincoreColors.success;
    IconData syncIcon = Icons.cloud_done_outlined;
    String syncLabel = 'Sincronizado';

    if (_failedCount > 0) {
      syncColor = FincoreColors.danger;
      syncIcon = Icons.cloud_off_outlined;
      syncLabel = '$_failedCount falha(s) de sincronização';
    } else if (_pendingCount > 0) {
      syncColor = FincoreColors.warning;
      syncIcon = Icons.sync_rounded;
      syncLabel = '$_pendingCount alteração(ões) pendente(s)';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(
          top: BorderSide(color: _sidebarBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lado Esquerdo: Status do Sincronismo
          InkWell(
            onTap: () => _showSyncFailuresDialog(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(syncIcon, size: 14, color: syncColor),
                  const SizedBox(width: 6),
                  Text(
                    syncLabel,
                    style: TextStyle(
                      color: syncColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_pendingCount == 0 && _failedCount == 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•  Último sincronismo: $_lastSyncStr',
                      style: const TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Lado Direito: Conexão Supabase
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? FincoreColors.success : FincoreColors.danger,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'Conectado à Nuvem' : 'Modo Offline',
                style: TextStyle(
                  color: _isOnline ? _textSecondary : FincoreColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _shellBg,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? 220 : 64,
            child: _buildSidebar(),
          ),

          // ── Conteúdo ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopbar(),
                const SizedBox(height: 1),
                Expanded(
                  child: Container(
                    color: _shellBg,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(_selectedTabId),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ),
                _buildStatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(
          right: BorderSide(color: _sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          _buildSidebarHeader(),

          const SizedBox(height: 8),

          // Grupos de navegação
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _navGroups.map(_buildNavGroup).toList(),
              ),
            ),
          ),

          // Rodapé: usuário + sair
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
      child: Row(
        children: [
          // Logo 3D Oficial
          Image.asset(
            'assets/images/app_launcher_icon.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),

          if (_sidebarExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINCORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'FOOD',
                    style: TextStyle(
                      color: FincoreColors.primary.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botão colapsar
          InkWell(
            onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _sidebarExpanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: FincoreColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup(_NavGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.label != null && _sidebarExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 0, 6),
            child: Text(
              group.label!,
              style: const TextStyle(
                color: FincoreColors.textDisabled,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ] else if (group.label != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: FincoreColors.sidebarBorder,
          ),
          const SizedBox(height: 8),
        ],
        ...group.items.map(_buildNavItem),
      ],
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isSelected = _selectedTabId == item.id ||
        (_selectedTabId == 'pdv_express' && item.id == 'pdv') ||
        (_selectedTabId == 'pdv_balcao' && item.id == 'pdv');

    return Tooltip(
      message: _sidebarExpanded ? '' : item.label,
      child: InkWell(
        onTap: () {
          if (item.id == 'pdv') {
            _selectTab(_pdvPadrao);
          } else {
            _selectTab(item.id);
          }
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: FincoreColors.hoverSurface,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded ? 10 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? FincoreColors.hoverPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: FincoreColors.primary.withValues(alpha: 0.25),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Indicador lateral ativo
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: isSelected ? 18 : 0,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isSelected ? FincoreColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                isSelected ? item.iconSelected : item.icon,
                color: isSelected
                    ? FincoreColors.primary
                    : FincoreColors.textMuted,
                size: 18,
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? _textPrimary
                          : _textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    final tenantCtx = DependencyInjection().get<TenantContext>();
    final currentUserName = tenantCtx.hasContext ? tenantCtx.usuario.nome : 'Usuário';
    final currentUserRole = tenantCtx.hasContext
        ? _mapRoleToLabel(tenantCtx.usuario.role)
        : 'Operador';
    final userInitials = currentUserName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    final activeTenantName = tenantCtx.hasContext
        ? tenantCtx.empresa.nomeFantasia
        : 'Matriz';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _sidebarBorder),
        ),
      ),
      child: Column(
        children: [
          // Usuário
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: FincoreColors.purpleGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUserName.split(' ').first,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentUserRole,
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: _textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Tenant chip
          if (_sidebarExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 12, color: _textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activeTenantName,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Topbar ────────────────────────────────────────────────────────────────

  Widget _buildTopbar() {
    final (title, subtitle) = _getTabInfo(_selectedTabId);
    // Breadcrumb: descobre o grupo do item ativo
    final group = _navGroups.where((g) =>
        g.items.any((i) => i.id == _selectedTabId ||
            (_selectedTabId.startsWith('pdv') && i.id == 'pdv'))).firstOrNull;
    final breadcrumb = group?.label != null ? '${group!.label} › $title' : title;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(bottom: BorderSide(color: _sidebarBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),



          // Relógio em tempo real
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 30)),
            builder: (context, _) {
              final now = DateTime.now();
              final hour = now.hour.toString().padLeft(2, '0');
              final minute = now.minute.toString().padLeft(2, '0');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: FincoreColors.borderSubtle),
                ),
                child: Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),


          // Badge dinâmico de conectividade (Online/Offline em tempo real)
          const ConnectivityBadge(),
        ],
      ),
    );
  }



  // ── Conteúdo ──────────────────────────────────────────────────────────────

  Widget _buildContent() {
    switch (_selectedTabId) {
      case 'dashboard':
        return const DashboardPage();
      case 'pdv_express':
        return const PdvExpressScreen();
      case 'pdv_balcao':
        return const PdvPage();
      case 'pedidos':
        return const PedidosPage();
      case 'kds':
        return const KdsScreen();
      case 'clientes':
        return const ClientesPage();
      case 'produtos':
        return const ProdutosPage();
      case 'financeiro':
        return const FinanceiroPage();
      case 'estoque':
        return const EstoquePage();
      case 'producao':
        return const ProducaoPage();
      case 'usuarios':
        return const UsuariosPage();
      case 'configuracoes':
        return const ConfiguracoesPage();
      default:
        return _buildPlaceholder(_selectedTabId);
    }
  }

  Widget _buildPlaceholder(String tabId) {
    return Center(
      child: FincoreAnimatedEntry(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: FincoreColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: FincoreShadows.glow(FincoreColors.primary, intensity: 0.15),
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tabId.toUpperCase().replaceAll('_', ' '),
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Em desenvolvimento',
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Este módulo estará disponível em breve.',
              style: TextStyle(
                color: FincoreColors.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _getTabInfo(String id) {
    return switch (id) {
      'dashboard' => ('Dashboard', 'Visão geral do negócio'),
      'pdv_express' => ('Frente de Caixa', 'Modo Express — Delivery e Retirada'),
      'pdv_balcao' => ('Frente de Caixa', 'Modo Mesa / Balcão'),
      'pedidos' => ('Central de Pedidos', 'Acompanhamento de pedidos em tempo real'),
      'kds' => ('KDS — Cozinha', 'Fila de preparo em tempo real'),
      'clientes' => ('Clientes', 'Cadastro e histórico de clientes'),
      'produtos' => ('Produtos', 'Cardápio e política de preços'),
      'financeiro' => ('Financeiro', 'Caixa, receitas e relatórios'),
      'estoque' => ('Estoque', 'Controle de produtos acabados'),
      'producao' => ('Produção', 'Registro de lotes e planejamento preditivo'),
      'usuarios' => ('Usuários & Permissões', 'Gestão de equipe e controle de acesso'),
      'configuracoes' => ('Configurações', 'Parametrização do sistema'),
      _ => (id, ''),
    };
  }
}

// ─── Helper: Dialog de Confirmação Global ──────────────────────────────────

Future<bool> _confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        titulo,
        style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Text(
        mensagem,
        style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: FincoreColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDestructive ? FincoreColors.danger : FincoreColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Função global para reutilizar em qualquer tela do app
Future<bool> confirmarAcaoFincore(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) {
  return _confirmarAcao(
    context,
    titulo: titulo,
    mensagem: mensagem,
    confirmLabel: confirmLabel,
    isDestructive: isDestructive,
  );
}
