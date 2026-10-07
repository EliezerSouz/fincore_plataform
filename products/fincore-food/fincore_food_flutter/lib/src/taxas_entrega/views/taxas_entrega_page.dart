import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:uuid/uuid.dart';

class _FaixaKmItem {
  final String id;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final TextEditingController valorCtrl;

  _FaixaKmItem({
    String? id,
    required double minKm,
    required double maxKm,
    required int valorCentavos,
  })  : id = id ?? const Uuid().v4(),
        minCtrl = TextEditingController(text: minKm % 1 == 0 ? minKm.toInt().toString() : minKm.toStringAsFixed(1)),
        maxCtrl = TextEditingController(text: maxKm % 1 == 0 ? maxKm.toInt().toString() : maxKm.toStringAsFixed(1)),
        valorCtrl = TextEditingController(text: (valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ','));

  double get minKm => double.tryParse(minCtrl.text.replaceAll(',', '.')) ?? 0.0;
  double get maxKm => double.tryParse(maxCtrl.text.replaceAll(',', '.')) ?? 0.0;

  int get valorCentavos {
    final clean = valorCtrl.text.trim().replaceAll(',', '.');
    final val = double.tryParse(clean) ?? 0.0;
    return (val * 100).round();
  }

  void dispose() {
    minCtrl.dispose();
    maxCtrl.dispose();
    valorCtrl.dispose();
  }
}

/// Tela de Gerenciamento da Tabela Única de Frete por Faixas de KM
/// Inspirada na mesma ergonomia da Política de Preços por Quantidade de Produtos.
class TaxasEntregaPage extends StatefulWidget {
  const TaxasEntregaPage({super.key});

  @override
  State<TaxasEntregaPage> createState() => _TaxasEntregaPageState();
}

class _TaxasEntregaPageState extends State<TaxasEntregaPage> {
  late final TaxaEntregaRepository _taxaRepo;
  late final TenantContext _tenantContext;

  bool _isLoading = true;
  bool _isSaving = false;

  final List<_FaixaKmItem> _faixas = [];
  final Set<String> _deletedIds = {};

  final _fallbackCtrl = TextEditingController(text: '0,00');
  String? _fallbackId;

  @override
  void initState() {
    super.initState();
    _taxaRepo = DependencyInjection().get<TaxaEntregaRepository>();
    _tenantContext = DependencyInjection().get<TenantContext>();
    _carregarDados();
  }

  @override
  void dispose() {
    for (final f in _faixas) {
      f.dispose();
    }
    _fallbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final all = await _taxaRepo.findAll();

      for (final f in _faixas) {
        f.dispose();
      }
      _faixas.clear();
      _deletedIds.clear();

      final regrasKm = all
          .where((t) => t.tipoRegra == TipoRegraTaxaEntrega.km && t.distanciaMaxKm != null)
          .toList();

      final Map<String, TaxaEntrega> deduplicatedKm = {};
      for (final r in regrasKm) {
        final key = '${(r.distanciaMinKm ?? 0.0).toStringAsFixed(1)}_${r.distanciaMaxKm!.toStringAsFixed(1)}';
        if (!deduplicatedKm.containsKey(key)) {
          deduplicatedKm[key] = r;
        } else {
          _deletedIds.add(r.id);
        }
      }

      final sortedList = deduplicatedKm.values.toList()
        ..sort((a, b) => (a.distanciaMinKm ?? 0.0).compareTo(b.distanciaMinKm ?? 0.0));

      for (final r in sortedList) {
        _faixas.add(_FaixaKmItem(
          id: r.id,
          minKm: r.distanciaMinKm ?? 0.0,
          maxKm: r.distanciaMaxKm!,
          valorCentavos: r.valorCentavos,
        ));
      }

      // Procura taxa fixa / fallback
      final fallbackTaxa = all.where((t) => t.tipoRegra == TipoRegraTaxaEntrega.fixo).firstOrNull;
      if (fallbackTaxa != null) {
        _fallbackId = fallbackTaxa.id;
        _fallbackCtrl.text = (fallbackTaxa.valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',');
      }
    } catch (e) {
      debugPrint('[TaxasEntregaPage] Erro ao carregar taxas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _carregarGradeSugerida() {
    setState(() {
      for (final f in _faixas) {
        f.dispose();
      }
      _faixas.clear();
      _faixas.addAll([
        _FaixaKmItem(minKm: 0.0, maxKm: 2.0, valorCentavos: 0),
        _FaixaKmItem(minKm: 2.0, maxKm: 8.0, valorCentavos: 800),
        _FaixaKmItem(minKm: 8.0, maxKm: 12.0, valorCentavos: 1200),
        _FaixaKmItem(minKm: 12.0, maxKm: 16.0, valorCentavos: 1600),
      ]);
    });
  }

  void _adicionarFaixa() {
    double novoMin = 0.0;
    if (_faixas.isNotEmpty) {
      novoMin = _faixas.last.maxKm;
    }
    double novoMax = novoMin + 4.0;
    int novoValor = _faixas.isNotEmpty ? (_faixas.last.valorCentavos + 400) : 500;

    setState(() {
      _faixas.add(_FaixaKmItem(
        minKm: novoMin,
        maxKm: novoMax,
        valorCentavos: novoValor,
      ));
    });
  }

  void _removerFaixa(int index) {
    setState(() {
      final item = _faixas.removeAt(index);
      _deletedIds.add(item.id);
      item.dispose();
    });
  }

  Future<void> _limparTodasFaixas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar todas as faixas de KM?'),
        content: const Text(
          'Deseja remover todas as faixas de frete por KM desta tabela?\n\n'
          'Ao salvar em seguida, o sistema passará a utilizar exclusivamente a cobrança por Regiões/Bairros cadastrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar Todas'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        for (final f in _faixas) {
          _deletedIds.add(f.id);
          f.dispose();
        }
        _faixas.clear();
      });
    }
  }

  Future<void> _salvarTabela() async {
    // 1. Validação de Faixas
    for (int i = 0; i < _faixas.length; i++) {
      final f = _faixas[i];
      final minVal = f.minKm;
      final maxVal = f.maxKm;

      if (f.maxCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Faixa ${i + 1}: informe a distância máxima em KM.'),
          ),
        );
        return;
      }

      if (minVal < 0 || maxVal <= minVal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Faixa ${i + 1} inválida: o KM final (${maxVal.toStringAsFixed(1)} km) deve ser maior que o inicial (${minVal.toStringAsFixed(1)} km).'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final activeTenant = _tenantContext.tenantId;
      final activeUser = _tenantContext.usuario.id;
      final now = DateTime.now().toUtc();

      // Deletar faixas removidas ou duplicadas
      for (final id in _deletedIds) {
        try {
          await _taxaRepo.delete(id);
        } catch (_) {}
      }
      _deletedIds.clear();

      // Salvar faixas ativas preservando IDs existentes
      for (final f in _faixas) {
        final taxa = TaxaEntrega(
          id: f.id,
          tenantId: activeTenant,
          nome: 'De ${f.minKm.toStringAsFixed(1)} a ${f.maxKm.toStringAsFixed(1)} km',
          tipoRegra: TipoRegraTaxaEntrega.km,
          distanciaMinKm: f.minKm,
          distanciaMaxKm: f.maxKm,
          valorCentavos: f.valorCentavos,
          ativo: true,
          metadata: SyncMetadata(
            createdAt: now,
            updatedAt: now,
            createdBy: activeUser,
            updatedBy: activeUser,
            version: 1,
            syncStatus: SyncStatus.pending,
          ),
        );
        await _taxaRepo.save(taxa);
      }

      // Salvar Fallback se informado
      final cleanFallback = _fallbackCtrl.text.replaceAll(',', '.');
      final valFallback = double.tryParse(cleanFallback) ?? 0.0;
      final fallbackCentavos = (valFallback * 100).round();

      final fallbackTaxa = TaxaEntrega(
        id: _fallbackId ?? const Uuid().v4(),
        tenantId: activeTenant,
        nome: 'Taxa Padrão / Fora do Raio',
        tipoRegra: TipoRegraTaxaEntrega.fixo,
        valorCentavos: fallbackCentavos,
        ativo: true,
        metadata: SyncMetadata(
          createdAt: now,
          updatedAt: now,
          createdBy: activeUser,
          updatedBy: activeUser,
          version: 1,
          syncStatus: SyncStatus.pending,
        ),
      );
      await _taxaRepo.save(fallbackTaxa);
      _fallbackId = fallbackTaxa.id;

      // Dispara sincronização com o Supabase
      try {
        DependencyInjection().get<SyncEngine>().processPendingQueue();
      } catch (_) {}

      // Recarrega os dados do repositório para manter a tela 100% alinhada
      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Tabela de Frete por KM salva e sincronizada com sucesso!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[TaxasEntregaPage] Erro ao salvar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Falha ao salvar tabela de frete: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final double maxAtendimentoKm = _faixas.isNotEmpty
        ? _faixas.map((f) => f.maxKm).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      backgroundColor: FincoreColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabeçalho Principal ─────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tabela de Frete por Faixas de KM',
                            style: TextStyle(
                              color: FincoreColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Defina os valores de entrega pela distância até a loja. O Cardápio Web e o PDV utilizam essas faixas automaticamente.',
                            style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_isSaving ? 'Salvando...' : 'Salvar Tabela de Frete', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _salvarTabela,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Cards de Status e Resumo ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FincoreColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FincoreColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.two_wheeler_outlined, color: FincoreColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Raio Total Atendido', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  'Até ${maxAtendimentoKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FincoreColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.route_outlined, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total de Faixas', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_faixas.length} faixas ativas',
                                  style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FincoreColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Taxa Fora do Raio / Fallback', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 28,
                                    child: TextField(
                                      controller: _fallbackCtrl,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                      decoration: InputDecoration(
                                        prefixText: 'R\$ ',
                                        prefixStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        filled: true,
                                        fillColor: FincoreColors.background,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Tabela de Faixas ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    children: [
                      // Cabeçalho da Tabela
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: FincoreColors.border)),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                            Expanded(flex: 3, child: Text('De (Distância Inicial)', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                            SizedBox(width: 20),
                            Expanded(flex: 3, child: Text('Até (Distância Final)', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                            SizedBox(width: 20),
                            Expanded(flex: 3, child: Text('Valor do Frete (R\$)', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                            SizedBox(width: 20),
                            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textSecondary))),
                            SizedBox(width: 50, child: Text('Ações', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textMuted))),
                          ],
                        ),
                      ),

                      // Lista de Faixas
                      if (_faixas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_outlined, size: 40, color: FincoreColors.textMuted.withValues(alpha: 0.6)),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhuma faixa de frete por KM ativa no momento.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Se você entrega apenas por Bairros/Regiões cadastradas, você pode manter esta tabela vazia.\nOu clique abaixo para iniciar com a grade recomendada.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.auto_fix_high, size: 16),
                                    label: const Text('Carregar Grade Sugerida'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: FincoreColors.primary,
                                      side: BorderSide(color: FincoreColors.primary),
                                    ),
                                    onPressed: _carregarGradeSugerida,
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Adicionar Faixa Manual'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FincoreColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _adicionarFaixa,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _faixas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: FincoreColors.border),
                          itemBuilder: (context, index) {
                            final faixa = _faixas[index];
                            final isGratis = faixa.valorCentavos == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textMuted),
                                    ),
                                  ),

                                  // Campo De
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: faixa.minCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                      decoration: InputDecoration(
                                        suffixText: 'km',
                                        suffixStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: FincoreColors.background,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // Campo Até
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: faixa.maxCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                      decoration: InputDecoration(
                                        suffixText: 'km',
                                        suffixStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: FincoreColors.background,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // Campo Valor R$
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: faixa.valorCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isGratis ? const Color(0xFF10B981) : FincoreColors.primary,
                                      ),
                                      decoration: InputDecoration(
                                        prefixText: 'R\$ ',
                                        prefixStyle: TextStyle(
                                          color: isGratis ? const Color(0xFF10B981) : FincoreColors.primary,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: FincoreColors.background,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // Badge de Status
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGratis
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : FincoreColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isGratis ? 'Grátis (Cortesia)' : 'Pago',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isGratis ? const Color(0xFF10B981) : FincoreColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Ação Excluir
                                  SizedBox(
                                    width: 50,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: FincoreColors.danger, size: 20),
                                      tooltip: 'Remover faixa',
                                      onPressed: () => _removerFaixa(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      // Rodapé da Tabela com Ações
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Adicionar Nova Faixa de KM', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FincoreColors.primary,
                                side: const BorderSide(color: FincoreColors.border),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _adicionarFaixa,
                            ),
                            if (_faixas.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: FincoreColors.danger),
                                label: const Text(
                                  'Limpar todas as faixas',
                                  style: TextStyle(color: FincoreColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: _isSaving ? null : _limparTodasFaixas,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FincoreColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: FincoreColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Dica Operacional: Qualquer cliente que esteja em uma distância inferior à primeira faixa (ou com valor R\$ 0,00) terá entrega gratuita automática. Distâncias que excedam o raio máximo usam a Taxa Padrão / Fora do Raio.',
                          style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
