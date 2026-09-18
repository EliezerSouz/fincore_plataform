import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_design_system/fincore_design_system.dart';

class LogExplorerDialog extends StatefulWidget {
  const LogExplorerDialog({super.key});

  @override
  State<LogExplorerDialog> createState() => _LogExplorerDialogState();
}

class _LogExplorerDialogState extends State<LogExplorerDialog> {
  final _searchCtrl = TextEditingController();
  LogModule? _selectedModule;
  LogLevel? _selectedLevel;
  DateTimeRange? _selectedDateRange;

  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _selectedLog;
  bool _isLoading = true;
  bool _newestFirst = true;
  String? _filterTraceId;

  @override
  void initState() {
    super.initState();
    // Default: logs das últimas 24h
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 1)),
      end: now.add(const Duration(days: 1)),
    );
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final query = _filterTraceId ?? (_searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
      final results = await LogService.instance.queryLogs(
        module: _selectedModule,
        level: _selectedLevel,
        start: _selectedDateRange?.start,
        end: _selectedDateRange?.end,
        searchQuery: query,
      );
      if (!_newestFirst) {
        results.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      } else {
        results.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      }
      setState(() {
        _logs = results;
        _selectedLog = results.isNotEmpty ? results.first : null;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return FincoreColors.danger;
      case 'WARNING':
        return FincoreColors.warning;
      case 'INFO':
        return FincoreColors.success;
      case 'DEBUG':
        return FincoreColors.accent;
      default:
        return FincoreColors.textSecondary;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error_outline;
      case 'WARNING':
        return Icons.warning_amber_outlined;
      case 'INFO':
        return Icons.info_outline;
      case 'DEBUG':
        return Icons.bug_report_outlined;
      default:
        return Icons.notes;
    }
  }

  void _exportFilteredLogs() {
    if (_logs.isEmpty) return;
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln('[${log['timestamp']}] [${log['level']}] [${log['module']}]');
      if (log['traceId'] != null) buffer.writeln('Trace ID: ${log['traceId']}');
      if (log['context'] != null) buffer.writeln('Context: ${log['context']}');
      buffer.writeln('Message: ${log['message']}');
      if (log['exception'] != null) buffer.writeln('Exception: ${log['exception']}');
      if (log['stackTrace'] != null) buffer.writeln('StackTrace: ${log['stackTrace']}');
      buffer.writeln('─' * 50);
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos os logs filtrados copiados para o clipboard!')),
    );
  }

  void _exportSelectedLog() {
    if (_selectedLog == null) return;
    final log = _selectedLog!;
    final buffer = StringBuffer();
    buffer.writeln('[${log['timestamp']}] [${log['level']}] [${log['module']}]');
    if (log['traceId'] != null) buffer.writeln('Trace ID: ${log['traceId']}');
    if (log['context'] != null) buffer.writeln('Context: ${log['context']}');
    buffer.writeln('Message: ${log['message']}');
    if (log['exception'] != null) buffer.writeln('Exception: ${log['exception']}');
    if (log['stackTrace'] != null) buffer.writeln('StackTrace: ${log['stackTrace']}');
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log selecionado copiado para o clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1000,
      height: 750,
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: [
          // Header da tela
          Padding(
            padding: const EdgeInsets.all(16.0),
            // Utilizando Row para alinhar
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: FincoreColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'CENTRAL DE DIAGNÓSTICO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: FincoreColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FincoreColors.border),

          // Painel de Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Busca textual
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: FincoreColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar por mensagem, TraceID...',
                      hintStyle: const TextStyle(color: FincoreColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: FincoreColors.textSecondary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: FincoreColors.textSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadLogs();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: FincoreColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FincoreColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _loadLogs(),
                  ),
                ),
                const SizedBox(width: 12),

                // Dropdown Módulo
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<LogModule>(
                    value: _selectedModule,
                    dropdownColor: FincoreColors.surface,
                    style: const TextStyle(color: FincoreColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Módulo',
                      labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                      filled: true,
                      fillColor: FincoreColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FincoreColors.border),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<LogModule>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...LogModule.values.map(
                        (m) => DropdownMenuItem<LogModule>(
                          value: m,
                          child: Text(m.name.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedModule = val);
                      _loadLogs();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Dropdown Nível
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<LogLevel>(
                    value: _selectedLevel,
                    dropdownColor: FincoreColors.surface,
                    style: const TextStyle(color: FincoreColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nível',
                      labelStyle: const TextStyle(color: FincoreColors.textSecondary),
                      filled: true,
                      fillColor: FincoreColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FincoreColors.border),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<LogLevel>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...LogLevel.values.map(
                        (l) => DropdownMenuItem<LogLevel>(
                          value: l,
                          child: Text(l.name.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedLevel = val);
                      _loadLogs();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Filtro de Data
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _selectedDateRange,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (ctx, child) {
                        return Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: FincoreColors.primary,
                              surface: FincoreColors.surface,
                              onSurface: FincoreColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                      _loadLogs();
                    }
                  },
                  icon: const Icon(Icons.date_range, color: Colors.white, size: 20),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Período'
                        : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),

                // Toggle Ordem Cronológica
                IconButton(
                  tooltip: _newestFirst ? 'Mais recentes primeiro' : 'Mais antigos primeiro',
                  icon: Icon(
                    _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    color: FincoreColors.primary,
                  ),
                  onPressed: () {
                    setState(() => _newestFirst = !_newestFirst);
                    _loadLogs();
                  },
                ),
                const SizedBox(width: 8),

                // Botão Exportar Todos
                ElevatedButton.icon(
                  onPressed: _logs.isEmpty ? null : _exportFilteredLogs,
                  icon: const Icon(Icons.copy_all, color: Colors.white, size: 20),
                  label: const Text('Copiar Todos', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          if (_filterTraceId != null)
            Container(
              color: FincoreColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.hub_outlined, color: FincoreColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrado por Rastreio (Trace ID): $_filterTraceId',
                    style: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() => _filterTraceId = null);
                      _loadLogs();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.close, color: FincoreColors.danger, size: 16),
                        SizedBox(width: 4),
                        Text('Limpar Filtro de Rastreio', style: TextStyle(color: FincoreColors.danger, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: FincoreColors.border),

          // Área Principal Split View
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: FincoreColors.primary),
                  )
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum log encontrado para os filtros selecionados.',
                          style: TextStyle(color: FincoreColors.textSecondary, fontSize: 15),
                        ),
                      )
                    : Row(
                        children: [
                          // Lista Lateral Esquerda
                          Expanded(
                            flex: 4,
                            child: ListView.separated(
                              itemCount: _logs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
                              itemBuilder: (ctx, index) {
                                final log = _logs[index];
                                final isSelected = _selectedLog == log;
                                final timestamp = DateTime.tryParse(log['timestamp'] ?? '');
                                final timeStr = timestamp != null
                                    ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}'
                                    : '00:00:00';
                                
                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: FincoreColors.surface,
                                  leading: Icon(
                                    _getLevelIcon(log['level'] ?? ''),
                                    color: _getLevelColor(log['level'] ?? ''),
                                    size: 20,
                                  ),
                                  title: Text(
                                    log['message'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? FincoreColors.primary : FincoreColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '[$timeStr] ${log['module'].toString().toUpperCase()}',
                                    style: const TextStyle(
                                      color: FincoreColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() => _selectedLog = log);
                                  },
                                );
                              },
                            ),
                          ),
                          const VerticalDivider(width: 1, color: FincoreColors.border),

                          // Detalhes da Direita
                          Expanded(
                            flex: 6,
                            child: _selectedLog == null
                                ? const Center(
                                    child: Text('Selecione um log para visualizar detalhes'),
                                  )
                                : Container(
                                    color: FincoreColors.surface,
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Ações do detalhe
                                        Row(
                                          children: [
                                            Icon(
                                              _getLevelIcon(_selectedLog!['level'] ?? ''),
                                              color: _getLevelColor(_selectedLog!['level'] ?? ''),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedLog!['level'].toString().toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _getLevelColor(_selectedLog!['level'] ?? ''),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: FincoreColors.border,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _selectedLog!['module'].toString().toUpperCase(),
                                                style: const TextStyle(
                                                  color: FincoreColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.copy, color: FincoreColors.textSecondary),
                                              tooltip: 'Copiar Detalhes',
                                              onPressed: _exportSelectedLog,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Timestamp e Trace
                                        Text(
                                          'Registrado em: ${_selectedLog!['timestamp']}',
                                          style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                                        ),
                                         if (_selectedLog!['traceId'] != null) ...[
                                           const SizedBox(height: 4),
                                           Row(
                                             children: [
                                               SelectableText(
                                                 'Trace ID: ${_selectedLog!['traceId']}',
                                                 style: TextStyle(
                                                   color: FincoreColors.primary,
                                                   fontWeight: FontWeight.bold,
                                                   fontSize: 13,
                                                 ),
                                               ),
                                               const SizedBox(width: 8),
                                               TextButton.icon(
                                                 style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                                 icon: Icon(Icons.hub_outlined, size: 16, color: FincoreColors.primary),
                                                 label: Text('Reconstruir Fluxo (Trace ID)', style: TextStyle(fontSize: 12, color: FincoreColors.primary)),
                                                 onPressed: () {
                                                   setState(() => _filterTraceId = _selectedLog!['traceId'] as String?);
                                                   _loadLogs();
                                                 },
                                               ),
                                             ],
                                           ),
                                         ],
                                        const SizedBox(height: 12),

                                        // Contexto (se houver)
                                        if (_selectedLog!['context'] != null) ...[
                                          const Text(
                                            'Contexto:',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, fontSize: 14),
                                          ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(top: 4, bottom: 12),
                                              decoration: BoxDecoration(
                                                color: FincoreColors.background,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: SelectableText(
                                                _selectedLog!['context'].toString(),
                                                style: const TextStyle(fontFamily: 'Courier', color: FincoreColors.textPrimary, fontSize: 13),
                                              ),
                                            ),
                                        ],

                                        // Mensagem Principal
                                        const Text(
                                          'Mensagem:',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: FincoreColors.background,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: SelectableText(
                                                _selectedLog!['message'] ?? '',
                                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        // Exception e StackTrace
                                        if (_selectedLog!['exception'] != null || _selectedLog!['stackTrace'] != null) ...[
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Detalhes da Exceção:',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.danger, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2D1616),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: FincoreColors.danger.withValues(alpha: 0.3)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (_selectedLog!['exception'] != null)
                                                      SelectableText(
                                                        'Erro: ${_selectedLog!['exception']}',
                                                        style: const TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    if (_selectedLog!['stackTrace'] != null) ...[
                                                      const SizedBox(height: 8),
                                                      SelectableText(
                                                        _selectedLog!['stackTrace'] ?? '',
                                                        style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontFamily: 'Courier'),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
