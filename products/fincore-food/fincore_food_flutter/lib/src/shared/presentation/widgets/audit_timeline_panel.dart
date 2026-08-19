import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';

/// Painel de Auditoria Forense do FINCORE ERP — Estilo Datadog / Git / Azure DevOps
/// Oferece rastreabilidade por Usuário, Máquina (Host/IP), Módulo, Git-Diffs e Replay de Dados.
class AuditTimelinePanel extends StatefulWidget {
  final String? entityName;
  final String? entityId;
  final bool isGlobalExplorer;

  const AuditTimelinePanel({
    super.key,
    this.entityName,
    this.entityId,
    this.isGlobalExplorer = false,
  });

  @override
  State<AuditTimelinePanel> createState() => _AuditTimelinePanelState();
}

class _AuditTimelinePanelState extends State<AuditTimelinePanel> {
  late final AuditLogRepository _repo;
  List<AuditLogEntry> _logs = [];
  Map<String, CoreUsuario> _userMap = {};
  bool _isLoading = true;
  static String? _cachedLocalIp;

  // Filtros Avançados & Performance
  String _searchQuery = '';
  String _selectedUser = 'Todos';
  String _selectedModule = 'Todos';
  String _selectedAction = 'Todos';
  String _selectedMachine = 'Todas';
  String _selectedPeriod = '7d';
  DateTimeRange? _customDateRange;
  bool _showAdvancedFilters = false;
  int _displayLimit = 100;

  @override
  void initState() {
    super.initState();
    _repo = DependencyInjection().get<AuditLogRepository>();
    _loadLogs();
  }

  Future<void> _fetchLocalIp() async {
    if (_cachedLocalIp != null) return;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _cachedLocalIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {}
    _cachedLocalIp = '127.0.0.1';
  }

  bool _isUuid(String input) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(input.trim());
  }

  String _getResolvedUserName(AuditLogEntry log) {
    final rawName = log.userName;
    if (rawName != null && rawName.isNotEmpty && rawName != log.userId && !_isUuid(rawName)) {
      return rawName;
    }
    if (_userMap.containsKey(log.userId)) {
      final u = _userMap[log.userId]!;
      if (u.nome.isNotEmpty && !_isUuid(u.nome)) return u.nome;
    }
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext && (tenantCtx.usuario.id == log.userId || tenantCtx.usuario.authUserId == log.userId)) {
        if (tenantCtx.usuario.nome.isNotEmpty && !_isUuid(tenantCtx.usuario.nome)) {
          return tenantCtx.usuario.nome;
        }
      }
    } catch (_) {}
    if (log.userId == 'system') return 'Sistema';
    return 'Operador';
  }

  String _getResolvedUserRole(AuditLogEntry log) {
    if (_userMap.containsKey(log.userId)) {
      final u = _userMap[log.userId]!;
      if (u.role != null && u.role!.isNotEmpty) return u.role!;
    }
    if (log.userRole != null && log.userRole!.isNotEmpty && log.userRole != 'Operador') {
      return log.userRole!;
    }
    return 'Operador';
  }

  String _getResolvedMachineName(AuditLogEntry log) {
    final m = log.machineName;
    if (m != null && m.isNotEmpty && m != 'RECEPCAO-PC' && m != 'Terminal-Local') {
      return m;
    }
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return Platform.localHostname;
      }
    } catch (_) {}
    return 'Terminal Local';
  }

  String _getResolvedIpAddress(AuditLogEntry log) {
    final ip = log.ipAddress;
    if (ip != null && ip.isNotEmpty && ip != '192.168.1.105' && ip != '192.168.1.100') {
      return ip;
    }
    return _cachedLocalIp ?? '127.0.0.1';
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      await _fetchLocalIp();
      List<AuditLogEntry> logs;
      if (widget.entityName != null && widget.entityId != null) {
        logs = await _repo.findByEntity(widget.entityName!, widget.entityId!);
        if (logs.isEmpty) {
          final allLogs = await _repo.findAllGlobal();
          logs = allLogs.where((l) => l.entityId == widget.entityId || l.userId == widget.entityId || l.targetEntity == widget.entityName).toList();
        }
      } else {
        logs = await _repo.findAllGlobal();
      }

      Map<String, CoreUsuario> userMap = {};
      try {
        final usuarioRepo = DependencyInjection().get<UsuarioRepository>();
        final usuarios = await usuarioRepo.findAll();
        for (final u in usuarios) {
          userMap[u.id] = u;
        }
      } catch (_) {}

      setState(() {
        _logs = logs;
        _userMap = userMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar logs de auditoria: $e');
      setState(() => _isLoading = false);
    }
  }

  List<AuditLogEntry> get _allFilteredLogs {
    final now = DateTime.now();
    return _logs.where((log) {
      // 1. Período
      if (_selectedPeriod == 'hoje') {
        if (log.timestamp.day != now.day || log.timestamp.month != now.month || log.timestamp.year != now.year) {
          return false;
        }
      } else if (_selectedPeriod == 'ontem') {
        final yesterday = now.subtract(const Duration(days: 1));
        if (log.timestamp.day != yesterday.day || log.timestamp.month != yesterday.month || log.timestamp.year != yesterday.year) {
          return false;
        }
      } else if (_selectedPeriod == '7d') {
        if (log.timestamp.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_selectedPeriod == '30d') {
        if (log.timestamp.isBefore(now.subtract(const Duration(days: 30)))) return false;
      } else if (_selectedPeriod == 'custom' && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day, 0, 0, 0);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        if (log.timestamp.isBefore(start) || log.timestamp.isAfter(end)) return false;
      }

      // 2. Módulo
      final module = log.entityModule ?? _inferModule(log.targetEntity);
      if (_selectedModule != 'Todos' && module != _selectedModule) return false;

      // 3. Ação
      if (_selectedAction != 'Todos' && log.action != _selectedAction) return false;

      // 4. Usuário
      final userDisp = _getResolvedUserName(log);
      if (_selectedUser != 'Todos' && userDisp != _selectedUser && log.userId != _selectedUser) return false;

      // 5. Máquina
      final machine = _getResolvedMachineName(log);
      if (_selectedMachine != 'Todas' && machine != _selectedMachine) return false;

      // 6. Busca por texto
      if (_searchQuery.trim().isNotEmpty) {
        final queryLower = _searchQuery.trim().toLowerCase();
        final matches = _getResolvedUserName(log).toLowerCase().contains(queryLower) ||
            _getResolvedMachineName(log).toLowerCase().contains(queryLower) ||
            _getResolvedIpAddress(log).toLowerCase().contains(queryLower) ||
            log.targetEntity.toLowerCase().contains(queryLower) ||
            (log.entityDisplayName ?? '').toLowerCase().contains(queryLower) ||
            (log.diff ?? '').toLowerCase().contains(queryLower) ||
            log.action.toLowerCase().contains(queryLower);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Set<String> get _usersList {
    final set = <String>{'Todos'};
    for (final l in _logs) {
      set.add(_getResolvedUserName(l));
    }
    return set;
  }

  Set<String> get _machinesList {
    final set = <String>{'Todas'};
    for (final l in _logs) {
      set.add(_getResolvedMachineName(l));
    }
    return set;
  }

  String _inferModule(String entityName) {
    switch (entityName.toLowerCase()) {
      case 'empresa':
      case 'empresa_configuracao':
        return 'Empresa';
      case 'produto':
      case 'produtos':
      case 'categoria':
      case 'categorias':
        return 'Produtos';
      case 'cliente':
      case 'clientes':
      case 'local_entrega':
        return 'Clientes';
      case 'ordempreparo':
      case 'pedidos':
        return 'Pedidos';
      case 'membros_empresa':
      case 'usuario':
      case 'usuarios':
        return 'Usuários';
      default:
        return 'Configurações';
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$d/$mo/${local.year} às $h:$m';
  }

  void _limparFiltros() {
    setState(() {
      _searchQuery = '';
      _selectedUser = 'Todos';
      _selectedModule = 'Todos';
      _selectedAction = 'Todos';
      _selectedMachine = 'Todas';
      _selectedPeriod = '7d';
      _customDateRange = null;
      _displayLimit = 100;
    });
  }

  Future<void> _selectCustomDateRange() async {
    DateTime start = _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
    DateTime end = _customDateRange?.end ?? DateTime.now();

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startStr = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
            final endStr = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: FincoreColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FincoreColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18, color: FincoreColors.primary),
                            const SizedBox(width: 8),
                            const Text('Período Personalizado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, size: 18, color: FincoreColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Selecione o intervalo de datas para filtrar os registros:', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DATA INICIAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: start,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) {
                                    setModalState(() => start = d);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: FincoreColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(startStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                      Icon(Icons.event, size: 16, color: FincoreColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DATA FINAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: end,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 1)),
                                  );
                                  if (d != null) {
                                    setModalState(() => end = d);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: FincoreColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: FincoreColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(endStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                                      Icon(Icons.event, size: 16, color: FincoreColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(DateTimeRange(start: start, end: end)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FincoreColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('Aplicar Filtro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _customDateRange = result;
        _selectedPeriod = 'custom';
      });
    }
  }

  Widget _buildKpiDashboard() {
    final allFiltered = _allFilteredLogs;
    final totalMutations = allFiltered.length;
    final createCount = allFiltered.where((l) => l.action == 'CREATE' || l.action == 'INSERT').length;
    final updateCount = allFiltered.where((l) => l.action == 'UPDATE').length;
    final deleteCount = allFiltered.where((l) => l.action == 'DELETE').length;

    return Row(
      children: [
        _kpiBadge('MUTAÇÕES REGISTRADAS', totalMutations.toString(), Icons.history, FincoreColors.primary),
        const SizedBox(width: 12),
        _kpiBadge('CRIAÇÕES (CREATE)', createCount.toString(), Icons.add_circle_outline, FincoreColors.success),
        const SizedBox(width: 12),
        _kpiBadge('ALTERAÇÕES (UPDATE)', updateCount.toString(), Icons.edit_note, FincoreColors.warning),
        const SizedBox(width: 12),
        _kpiBadge('EXCLUSÕES (DELETE)', deleteCount.toString(), Icons.remove_circle_outline, FincoreColors.danger),
      ],
    );
  }

  Widget _kpiBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FincoreColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasActiveFilters = _searchQuery.isNotEmpty ||
        _selectedUser != 'Todos' ||
        _selectedModule != 'Todos' ||
        _selectedAction != 'Todos' ||
        _selectedMachine != 'Todas' ||
        _selectedPeriod != '7d';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: Busca + Filtro Período + Botão Avançado + Limpar Filtros
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '🔍 Buscar por usuário, entidade, IP ou valor...',
                    hintStyle: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 16, color: FincoreColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: FincoreColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                side: BorderSide(color: _showAdvancedFilters ? FincoreColors.primary : FincoreColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.filter_list, size: 15, color: _showAdvancedFilters ? FincoreColors.primary : FincoreColors.textSecondary),
              label: Text(
                _showAdvancedFilters ? 'Filtros ▲' : 'Filtros ▼',
                style: TextStyle(fontSize: 12, color: _showAdvancedFilters ? FincoreColors.primary : FincoreColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.clear_all, size: 15, color: FincoreColors.danger),
                label: const Text('Limpar Filtros', style: TextStyle(fontSize: 12, color: FincoreColors.danger, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Linha 2: Seletor de Período Rápido
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('PERÍODO: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
            _periodChip('Hoje', 'hoje'),
            _periodChip('Ontem', 'ontem'),
            _periodChip('Últimos 7 dias', '7d'),
            _periodChip('Últimos 30 dias', '30d'),
            _periodChip(
              _customDateRange == null
                  ? 'Personalizado...'
                  : 'Custom (${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month})',
              'custom',
              onTapCustom: _selectCustomDateRange,
            ),
          ],
        ),

        // Linha 3: Filtros Avançados Colapsáveis
        if (_showAdvancedFilters) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _dropdownFilter(label: 'Módulo', value: _selectedModule, items: ['Todos', 'Empresa', 'Operação', 'Impressão', 'Produtos', 'Clientes', 'Usuários', 'Configurações'], onChanged: (v) => setState(() => _selectedModule = v!)),
                _dropdownFilter(label: 'Ação', value: _selectedAction, items: ['Todos', 'UPDATE', 'CREATE', 'DELETE', 'LOGIN', 'SYNC'], onChanged: (v) => setState(() => _selectedAction = v!)),
                _dropdownFilter(label: 'Usuário', value: _selectedUser, items: _usersList.toList(), onChanged: (v) => setState(() => _selectedUser = v!)),
                _dropdownFilter(label: 'Máquina', value: _selectedMachine, items: _machinesList.toList(), onChanged: (v) => setState(() => _selectedMachine = v!)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary),
          dropdownColor: FincoreColors.surface,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text('$label: $i'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _periodChip(String label, String code, {VoidCallback? onTapCustom}) {
    final isSelected = _selectedPeriod == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: FincoreColors.primary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : FincoreColors.textSecondary,
      ),
      onSelected: (val) {
        if (code == 'custom') {
          onTapCustom?.call();
        } else {
          if (val) setState(() => _selectedPeriod = code);
        }
      },
    );
  }

  void _showReplayModal(AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_toggle_off, color: FincoreColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replay do Estado — ${log.entityDisplayName ?? log.targetEntity}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                        ),
                        Text(
                          'Instantâneo registrado em ${_formatDateTime(log.timestamp)} por ${_getResolvedUserName(log)}',
                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                  ),
                ],
              ),
              const Divider(height: 24, color: FincoreColors.border),

              AuditDiffTable(
                action: log.action,
                rawDiffJson: log.diff,
                initialMode: AuditViewMode.tabela,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IDENTIFICADOR ÚNICO DO LOG: ${log.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: FincoreColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('HOST / TERMINAL: ${_getResolvedMachineName(log)} (${_getResolvedIpAddress(log)})', style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allFiltered = _allFilteredLogs;
    final displayedLogs = allFiltered.take(_displayLimit).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FincoreColors.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SyncHealthCard(
              isCloudConnected: true,
              isSqliteHealthy: true,
              pendingOutboxCount: 0,
              retryQueueCount: 0,
            ),
            const SizedBox(height: 16),
            _buildKpiDashboard(),
            const SizedBox(height: 16),

            _buildFilterBar(),
            const SizedBox(height: 16),

            if (_isLoading)
              Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(color: FincoreColors.primary)))
            else if (displayedLogs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: const [
                      Icon(Icons.history_outlined, size: 48, color: FincoreColors.textMuted),
                      SizedBox(height: 12),
                      Text('Nenhum log de auditoria encontrado para os filtros selecionados.', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = displayedLogs[index];
                  final userName = _getResolvedUserName(log);
                  final userRole = _getResolvedUserRole(log);
                  final machine = _getResolvedMachineName(log);
                  final ip = _getResolvedIpAddress(log);
                  final actionUpper = log.action.toUpperCase();

                  final actionColor = actionUpper == 'CREATE' || actionUpper == 'INSERT'
                      ? FincoreColors.success
                      : (actionUpper == 'DELETE' ? FincoreColors.danger : FincoreColors.warning);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho de Leitura Rápida (< 5s: Quem, O que, Quando, Onde)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$actionUpper • ${log.targetEntity}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: actionColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: '👤 ', style: TextStyle(fontSize: 12)),
                                        TextSpan(text: userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: FincoreColors.textPrimary)),
                                        TextSpan(text: ' ($userRole)', style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: '🕒 ', style: TextStyle(fontSize: 12)),
                                        TextSpan(text: _formatDateTime(log.timestamp), style: const TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: '💻 ', style: TextStyle(fontSize: 12)),
                                        TextSpan(text: '$machine ($ip)', style: const TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showReplayModal(log),
                              icon: const Icon(Icons.history_toggle_off, size: 13),
                              label: const Text('Replay', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                side: const BorderSide(color: FincoreColors.border),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Renderização oficial com o AuditDiffTable (Resumo | Tabela | Técnico)
                        AuditDiffTable(
                          action: log.action,
                          rawDiffJson: log.diff,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Paginação de 100 em 100 Registros
              if (allFiltered.length > _displayLimit) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Exibindo $_displayLimit de ${allFiltered.length} registros de auditoria',
                        style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _displayLimit += 100),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: FincoreColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.expand_more, size: 16, color: FincoreColors.primary),
                        label: Text('Carregar Mais Registros', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
