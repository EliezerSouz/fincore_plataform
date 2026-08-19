import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

enum AuditViewMode { resumo, tabela, tecnico }

/// Componente de Auditoria & Diff Visual Corporativo do FINCORE ERP
/// Renderiza alterações de dados com tradução para linguagem comercial,
/// destaques visuais em verde/vermelho e 3 modos de visualização.
class AuditDiffTable extends StatefulWidget {
  final String action;
  final String? rawDiffJson;
  final Map<String, dynamic>? beforeMap;
  final Map<String, dynamic>? afterMap;
  final Map<String, String>? customFieldLabels;
  final AuditViewMode initialMode;

  const AuditDiffTable({
    super.key,
    required this.action,
    this.rawDiffJson,
    this.beforeMap,
    this.afterMap,
    this.customFieldLabels,
    this.initialMode = AuditViewMode.resumo,
  });

  @override
  State<AuditDiffTable> createState() => _AuditDiffTableState();
}

class _AuditDiffTableState extends State<AuditDiffTable> {
  late AuditViewMode _currentMode;

  static const Map<String, String> _defaultFieldLabels = {
    'nome': 'Nome',
    'name': 'Nome',
    'username': 'Usuário (Login)',
    'email': 'E-mail de Contato',
    'role': 'Perfil RBAC / Cargo',
    'ativo': 'Status (Ativo)',
    'status': 'Status',
    'precoBaseCentavos': 'Preço de Venda',
    'preco_base_centavos': 'Preço de Venda',
    'custoCentavos': 'Custo Unitário',
    'custo_centavos': 'Custo Unitário',
    'valorCentavos': 'Valor Unitário',
    'sku': 'SKU / Código',
    'ean': 'Código de Barras (EAN)',
    'codigoBarras': 'Código de Barras',
    'categoriaId': 'Categoria',
    'categoria_id': 'Categoria',
    'tempoPreparoMinutos': 'Tempo de Preparo',
    'tempo_preparo_minutos': 'Tempo de Preparo',
    'setorImpressao': 'Setor KDS / Impressão',
    'enviarKds': 'Enviar para KDS',
    'controlaEstoque': 'Controle de Estoque',
    'estoqueMinimo': 'Estoque Mínimo',
    'capacidadeMaxima': 'Capacidade Máxima',
    'cpfCnpj': 'CPF / CNPJ',
    'cpf_cnpj': 'CPF / CNPJ',
    'telefone': 'Telefone Principal',
    'razaoSocial': 'Razão Social',
    'nomeFantasia': 'Nome Fantasia',
    'inscricaoEstadual': 'Inscrição Estadual',
    'inscricaoMunicipal': 'Inscrição Municipal',
    'tipoPolitica': 'Tipo de Política',
    'prioridade': 'Prioridade',
    'ordem': 'Ordem de Exibição',
    'fusoHorario': 'Fuso Horário',
    'moeda': 'Moeda Corrente',
    'password_hash': 'Senha',
    'senha': 'Senha',
  };

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  String _getFieldLabel(String rawKey) {
    if (widget.customFieldLabels != null && widget.customFieldLabels!.containsKey(rawKey)) {
      return widget.customFieldLabels![rawKey]!;
    }
    if (_defaultFieldLabels.containsKey(rawKey)) {
      return _defaultFieldLabels[rawKey]!;
    }
    final result = rawKey
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll('_', ' ')
        .trim();
    return result.isEmpty ? rawKey : '${result[0].toUpperCase()}${result.substring(1)}';
  }

  String _formatValue(String key, dynamic val) {
    if (val == null || val == '') return '—';
    if (val is bool) return val ? 'Sim' : 'Não';

    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('centavo') || lowerKey.contains('preco') || lowerKey.contains('valor') || lowerKey.contains('custo')) {
      if (val is num) {
        final reais = val / 100.0;
        return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
      }
    }

    if (val is List || val is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(val);
      } catch (_) {
        return val.toString();
      }
    }

    final strVal = val.toString();
    if (strVal == 'true') return 'Sim';
    if (strVal == 'false') return 'Não';

    return strVal;
  }

  _ParsedDiff _parseDiffData() {
    Map<String, dynamic> before = {};
    Map<String, dynamic> after = {};
    String? summary;
    int? affectedRecords;
    List<String> relatedEntities = [];

    if (widget.beforeMap != null) before.addAll(widget.beforeMap!);
    if (widget.afterMap != null) after.addAll(widget.afterMap!);

    if (widget.rawDiffJson != null && widget.rawDiffJson!.isNotEmpty) {
      try {
        final decoded = json.decode(widget.rawDiffJson!);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('_summary')) summary = decoded['_summary']?.toString();
          if (decoded.containsKey('_affectedRecords')) affectedRecords = int.tryParse(decoded['_affectedRecords'].toString());
          if (decoded.containsKey('_relatedEntities') && decoded['_relatedEntities'] is List) {
            relatedEntities = (decoded['_relatedEntities'] as List).map((e) => e.toString()).toList();
          }

          if (decoded.containsKey('before') && decoded['before'] is Map) {
            before = Map<String, dynamic>.from(decoded['before'] as Map);
          }
          if (decoded.containsKey('after') && decoded['after'] is Map) {
            after = Map<String, dynamic>.from(decoded['after'] as Map);
          }
          if (before.isEmpty && after.isEmpty) {
            after = Map<String, dynamic>.from(decoded);
            after.removeWhere((k, _) => k.startsWith('_'));
          }
        }
      } catch (_) {
        final lines = widget.rawDiffJson!.split('\n');
        for (final line in lines) {
          if (line.startsWith('FIELD:')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final field = parts[1].trim();
              after[field] = 'Alterado';
            }
          }
        }
      }
    }

    final List<_DiffRowItem> items = [];
    final allKeys = {...before.keys, ...after.keys}.toList();

    allKeys.removeWhere((k) => k == 'id' || k == 'tenantId' || k == 'tenant_id' || k == 'metadata' || k == 'password_hash' || k.startsWith('_'));

    for (final key in allKeys) {
      final oldVal = before[key];
      final newVal = after[key];

      if (widget.action.toUpperCase() == 'UPDATE' && oldVal == newVal) {
        continue;
      }

      items.add(_DiffRowItem(
        key: key,
        label: _getFieldLabel(key),
        oldValue: _formatValue(key, oldVal),
        newValue: _formatValue(key, newVal),
        isNew: oldVal == null && newVal != null,
        isRemoved: oldVal != null && newVal == null,
        isChanged: oldVal != null && newVal != null && oldVal != newVal,
      ));
    }

    return _ParsedDiff(
      before: before,
      after: after,
      items: items,
      summary: summary,
      affectedRecords: affectedRecords,
      relatedEntities: relatedEntities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseDiffData();
    final action = widget.action.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor de Modo de Visualização (Resumo | Tabela | Técnico)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DETALHAMENTO DA ALTERAÇÃO',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: FincoreColors.textMuted,
              ),
            ),
            Container(
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Row(
                children: [
                  _buildModeTab('Resumo', AuditViewMode.resumo),
                  _buildModeTab('Tabela', AuditViewMode.tabela),
                  _buildModeTab('Técnico', AuditViewMode.tecnico),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (parsed.items.isEmpty && action != 'CREATE' && action != 'DELETE') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FincoreColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Text(
              'Nenhum atributo sofreu alteração nesta operação.',
              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            ),
          ),
        ] else ...[
          switch (_currentMode) {
            AuditViewMode.resumo => _buildResumoView(parsed, action),
            AuditViewMode.tabela => _buildTabelaView(parsed, action),
            AuditViewMode.tecnico => _buildTecnicoView(parsed),
          },
        ],
      ],
    );
  }

  Widget _buildModeTab(String label, AuditViewMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // 1. MODO RESUMO (Padrão para 95% dos usuários)
  Widget _buildResumoView(_ParsedDiff parsed, String action) {
    if (action == 'CREATE') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FincoreColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.add_circle_outline, color: FincoreColors.success, size: 16),
                SizedBox(width: 6),
                Text('CREATE • Registro Inicial', style: TextStyle(color: FincoreColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: parsed.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '${item.label}: ', style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted)),
                        TextSpan(text: item.newValue, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (action == 'DELETE') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FincoreColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.remove_circle_outline, color: FincoreColors.danger, size: 16),
                SizedBox(width: 6),
                Text('DELETE • Últimos Dados Conhecidos', style: TextStyle(color: FincoreColors.danger, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: parsed.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '${item.label}: ', style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted)),
                        TextSpan(text: item.oldValue, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.danger)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (parsed.relatedEntities.isNotEmpty || (parsed.affectedRecords != null && parsed.affectedRecords! > 0)) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'IMPACTO CORPORATIVO (${parsed.affectedRecords ?? parsed.relatedEntities.length} produto(s) / entidade(s) vinculada(s))',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    if (parsed.relatedEntities.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: parsed.relatedEntities.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FincoreColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: FincoreColors.border),
                            ),
                            child: Text('• $e', style: TextStyle(fontSize: 11, color: FincoreColors.textPrimary, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // MODO UPDATE
    return Column(
      children: parsed.items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: FincoreColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      item.oldValue,
                      style: TextStyle(fontSize: 12, color: FincoreColors.danger, decoration: TextDecoration.lineThrough),
                    ),
                    Icon(Icons.arrow_right_alt, size: 14, color: FincoreColors.textMuted),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: FincoreColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🟢 ${item.newValue}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.success),
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
  }

  // 2. MODO TABELA COMPARATIVA (Antes | Depois)
  Widget _buildTabelaView(_ParsedDiff parsed, String action) {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.4),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: FincoreColors.surfaceElevated),
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text('Campo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
              Padding(padding: const EdgeInsets.all(8), child: Text('Antes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.danger))),
              Padding(padding: const EdgeInsets.all(8), child: Text('Depois', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.success))),
            ],
          ),
          ...parsed.items.map((item) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: FincoreColors.border, width: 0.5)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(item.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.oldValue,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: item.isChanged ? FincoreColors.danger : FincoreColors.textMuted,
                      decoration: item.isChanged ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.isChanged ? '🟢 ${item.newValue}' : item.newValue,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: item.isChanged ? FontWeight.bold : FontWeight.normal,
                      color: item.isChanged ? FincoreColors.success : FincoreColors.textPrimary,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 3. MODO TÉCNICO (JSON Formatado)
  Widget _buildTecnicoView(_ParsedDiff parsed) {
    final Map<String, dynamic> rawJson = {
      'before': parsed.before,
      'after': parsed.after,
    };
    final prettyString = const JsonEncoder.withIndent('  ').convert(rawJson);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: SelectableText(
        prettyString,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Color(0xFF38BDF8),
        ),
      ),
    );
  }
}

class _ParsedDiff {
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final List<_DiffRowItem> items;
  final String? summary;
  final int? affectedRecords;
  final List<String> relatedEntities;

  const _ParsedDiff({
    required this.before,
    required this.after,
    required this.items,
    this.summary,
    this.affectedRecords,
    this.relatedEntities = const [],
  });
}

class _DiffRowItem {
  final String key;
  final String label;
  final String oldValue;
  final String newValue;
  final bool isNew;
  final bool isRemoved;
  final bool isChanged;

  const _DiffRowItem({
    required this.key,
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.isNew,
    required this.isRemoved,
    required this.isChanged,
  });
}
