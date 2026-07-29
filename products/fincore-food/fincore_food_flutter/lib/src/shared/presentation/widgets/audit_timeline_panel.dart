import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/di/dependency_injection.dart';

class AuditTimelinePanel extends StatefulWidget {
  final String entityName;
  final String entityId;

  const AuditTimelinePanel({
    super.key,
    required this.entityName,
    required this.entityId,
  });

  @override
  State<AuditTimelinePanel> createState() => _AuditTimelinePanelState();
}

class _AuditTimelinePanelState extends State<AuditTimelinePanel> {
  late final AuditLogRepository _repo;
  List<AuditLogEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = DependencyInjection().get<AuditLogRepository>();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _repo.findByEntity(widget.entityName, widget.entityId);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar auditoria: $e');
      setState(() => _isLoading = false);
    }
  }

  String _translateKey(String key) {
    const map = {
      'telefone_empresa': 'Telefone',
      'nome_empresa': 'Nome da Empresa',
      'cnpj_empresa': 'CNPJ',
      'endereco_empresa': 'Endereço',
      'tema_sistema': 'Tema',
      'printer_caixa': 'Impressora (Caixa)',
      'printer_cozinha': 'Impressora (Cozinha)',
      'printer_balcao': 'Impressora (Balcão)',
      'printer_expedicao': 'Impressora (Expedição)',
      'auto_print_caixa': 'Auto Print (Caixa)',
      'auto_print_cozinha': 'Auto Print (Cozinha)',
      'vias_cliente': 'Vias (Cliente)',
      'vias_cozinha': 'Vias (Cozinha)',
      'pix_chave': 'Chave PIX',
      'pix_tipo': 'Tipo PIX',
      'pix_favorecido': 'Favorecido PIX',
      'mensagem_rodape': 'Mensagem Rodapé',
    };
    return map[key] ?? key;
  }
  
  String _formatValue(dynamic val) {
    if (val == null) return 'vazio';
    if (val is bool) return val ? 'Sim' : 'Não';
    return val.toString();
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$d/$mo/${local.year} $h:$m';
  }

  Widget _buildDiff(String? diffJson) {
    if (diffJson == null || diffJson.isEmpty) {
      return const Text('Nenhuma alteração registrada.', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13));
    }

    try {
      final map = jsonDecode(diffJson) as Map<String, dynamic>;
      if (map.isEmpty) {
        return const Text('Salvo sem alterações.', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map((e) {
          final key = _translateKey(e.key);
          final vals = e.value as Map<String, dynamic>;
          final oldVal = _formatValue(vals['old']);
          final newVal = _formatValue(vals['new']);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, size: 14, color: FincoreColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          oldVal,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: FincoreColors.textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_outlined, size: 12, color: FincoreColors.textMuted),
                      ),
                      Expanded(
                        child: Text(
                          newVal,
                          style: const TextStyle(
                            color: FincoreColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Text('Diff inválido: $diffJson', style: const TextStyle(color: FincoreColors.danger, fontSize: 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Histórico de Alterações',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: FincoreColors.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: FincoreColors.primary),
            ))
          else if (_logs.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Nenhum registro de auditoria encontrado.', style: TextStyle(color: FincoreColors.textSecondary)),
            ))
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              log.action == 'CREATE' ? Icons.add_circle_outline : (log.action == 'DELETE' ? Icons.delete_outline : Icons.edit_outlined),
                              size: 16,
                              color: log.action == 'CREATE' ? FincoreColors.primary : (log.action == 'DELETE' ? FincoreColors.danger : FincoreColors.warning),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              log.action,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              _formatDateTime(log.timestamp),
                              style: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Usuário: ${log.userId}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                            if (log.syncVersion != null) ...[
                              const Spacer(),
                              Text('Versão: ${log.syncVersion}', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                            ],
                          ],
                        ),
                        if (log.origin != null)
                          Text('Origem: ${log.origin}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: FincoreColors.border),
                        ),
                        _buildDiff(log.diff),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
