import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/entity_detail_drawer.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import 'package:fincore_food_flutter/src/pedidos/controllers/central_pedidos_controller.dart';
import 'package:fincore_food_flutter/src/shared/services/permissao_service.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/whatsapp_dialog.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import 'package:fincore_food_flutter/src/financeiro/controllers/contas_receber_controller.dart';

/// Drawer de detalhes de um pedido — especialização de [EntityDetailDrawer].
///
/// Exibe: lifecycle do pedido, dados do cliente, lista de itens, resumo
/// financeiro (se role permitir), linha do tempo operacional e ações
/// contextuais filtradas por role.
class PedidoDetailDrawer extends StatefulWidget {
  final OrdemPreparo ordem;
  final DadosOrdemKanban parsed;
  final String? userRole;
  final CentralPedidosController controller;

  /// Callback após avançar/reverter status
  final VoidCallback? onStatusChanged;

  /// Callback para ação de impressão
  final VoidCallback? onImprimir;

  /// Callback para ação de editar
  final VoidCallback? onEditar;

  /// Callback para ação de cancelar
  final VoidCallback? onCancelar;

  /// Callback para solicitar motivo de reversão (legado)
  final Future<String?> Function(String deStatus, String paraStatus)?
      onSolicitarMotivoReversao;

  /// Callback avançado para reversão com escolha de status destino e motivo
  final Future<({StatusOrdemPreparo destino, String motivo})?> Function(
      OrdemPreparo ordem, List<StatusOrdemPreparo> opcoesDestino)?
      onSolicitarReversao;

  const PedidoDetailDrawer({
    super.key,
    required this.ordem,
    required this.parsed,
    required this.controller,
    this.userRole,
    this.onStatusChanged,
    this.onImprimir,
    this.onEditar,
    this.onCancelar,
    this.onSolicitarMotivoReversao,
    this.onSolicitarReversao,
  });

  @override
  State<PedidoDetailDrawer> createState() => _PedidoDetailDrawerState();
}

class _PedidoDetailDrawerState extends State<PedidoDetailDrawer> {
  bool _loadingAction = false;
  late List<HistoricoOrdemPreparo> _historico;
  bool _loadingHistorico = true;
  Map<String, int> _itemPrecosEfetivos = {};
  // WhatsApp: dados carregados assincronamente
  String? _telefonePedido;
  String? _nomeClientePedido;
  // PIX: apenas os campos necessarios da forma de pagamento
  String? _pixChave;
  String? _pixTipoChave;
  bool _formaPagamentoIsPix = false;

  // Status Financeiro (Contas a Receber)
  bool _isPago = false;
  bool _isUsoConsumo = false;
  DateTime? _dataPagamento;
  bool _loadingFinanceiro = true;
  bool _baixandoFinanceiro = false;

  @override
  void initState() {
    super.initState();
    _historico = [];
    _carregarPrecosEfetivos();
    _carregarDadosWhatsApp();
    _carregarStatusFinanceiro();
    if (PermissaoService.podeVerTimeline(widget.userRole)) {
      _carregarHistorico();
    } else {
      _loadingHistorico = false;
    }
  }

  Future<void> _carregarStatusFinanceiro() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final pedidoRow = await (db.select(db.pedidosTable)
            ..where((p) => p.id.equals(widget.ordem.pedidoId)))
          .getSingleOrNull();

      final fpNome = pedidoRow?.formaPagamentoNome?.toLowerCase() ?? '';
      final isUsoConsumo = (pedidoRow?.isUsoInterno == true) ||
          fpNome.contains('consumo') ||
          fpNome.contains('cortesia') ||
          fpNome.contains('bonifica');

      if (isUsoConsumo) {
        if (mounted) {
          setState(() {
            _isUsoConsumo = true;
            _isPago = true;
            _loadingFinanceiro = false;
          });
        }
        return;
      }

      final lancamento = await (db.select(db.lancamentosFinanceirosTable)
            ..where((l) =>
                l.pedidoId.equals(widget.ordem.pedidoId) &
                l.tipo.equals('receita') &
                l.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

      if (mounted) {
        setState(() {
          _isUsoConsumo = false;
          _isPago = lancamento != null;
          _dataPagamento = lancamento?.dataHora.toLocal();
          _loadingFinanceiro = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFinanceiro = false);
    }
  }

  Future<void> _darBaixaFinanceira() async {
    setState(() => _baixandoFinanceiro = true);
    try {
      final ctrl = DependencyInjection().tryGet<ContasReceberController>() ?? ContasReceberController();
      final ok = await ctrl.darBaixaPorPedidoId(pedidoId: widget.ordem.pedidoId);
      if (ok && mounted) {
        await _carregarStatusFinanceiro();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Recebimento confirmado e registrado no Caixa!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Erro ao registrar recebimento: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _baixandoFinanceiro = false);
    }
  }

  Future<void> _estornarBaixaFinanceira() async {
    final controllerMotivo = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Estornar Pagamento?', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deseja realmente estornar a baixa do pagamento deste pedido? Esta ação removerá o lançamento financeiro e gerará um histórico.',
                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllerMotivo,
                autofocus: true,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Motivo do Estorno *',
                  labelStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                  hintText: 'Ex: Pagamento duplicado / Cliente desistiu',
                  hintStyle: TextStyle(color: FincoreColors.textMuted.withOpacity(0.5), fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: FincoreColors.background,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o motivo do estorno';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controllerMotivo.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Estornar Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.isEmpty) return;

    setState(() => _baixandoFinanceiro = true);
    try {
      final ctrl = DependencyInjection().tryGet<ContasReceberController>() ?? ContasReceberController();
      final ok = await ctrl.estornarBaixaPorPedidoId(
        pedidoId: widget.ordem.pedidoId,
        motivoEstorno: motivo,
      );
      if (ok && mounted) {
        await _carregarStatusFinanceiro();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FincoreColors.warning,
            content: Row(
              children: [
                Icon(Icons.undo_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Baixa financeira estornada com sucesso!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FincoreColors.danger,
            content: Text('Erro ao estornar pagamento: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _baixandoFinanceiro = false);
    }
  }

  /// Carrega telefone do cliente e forma de pagamento do pedido para o WhatsApp
  Future<void> _carregarDadosWhatsApp() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
      if (pedido == null) return;

      String? tel = pedido.clienteTelefoneAvulso;
      String? nome = pedido.clienteNomeAvulso ?? widget.parsed.cliente;

      // Se tiver clienteId, busca o cliente cadastrado oficial
      if (pedido.clienteId != null) {
        try {
          final clienteRow = await (db.select(db.clientesTable)
                ..where((c) => c.id.equals(pedido.clienteId!) & c.deletedAt.isNull()))
              .getSingleOrNull();
          if (clienteRow != null) {
            tel = clienteRow.telefone;
            if (clienteRow.nome.isNotEmpty) {
              nome = clienteRow.nome;
            }
          }
        } catch (_) {}
      }

      // Se ainda não encontrou ou nome genérico, tenta resolver por telefone
      if (nome == null || nome.isEmpty || nome == 'Consumidor' || nome == 'Cliente') {
        final searchTel = tel ?? pedido.clienteTelefoneAvulso;
        if (searchTel != null && searchTel.isNotEmpty) {
          final telDigits = searchTel.replaceAll(RegExp(r'\D'), '');
          if (telDigits.length >= 8) {
            try {
              final clientes = await (db.select(db.clientesTable)
                    ..where((c) => c.deletedAt.isNull()))
                  .get();
              final match = clientes.where((c) {
                final cDigits = c.telefone.replaceAll(RegExp(r'\D'), '');
                return cDigits.length >= 8 && (cDigits.endsWith(telDigits) || telDigits.endsWith(cDigits));
              }).firstOrNull;
              if (match != null) {
                nome = match.nome;
                tel = match.telefone;
              }
            } catch (_) {}
          }
        }
      }

      // Busca forma de pagamento para verificar se e PIX
      String? pixChave;
      String? pixTipoChave;
      bool isPix = false;

      if (pedido.formaPagamentoId != null) {
        try {
          final formaRow = await (db.select(db.formasPagamentoTable)
                ..where((f) => f.id.equals(pedido.formaPagamentoId!) & f.deletedAt.isNull()))
              .getSingleOrNull();
          if (formaRow != null && formaRow.tipo == 'pix') {
            isPix = true;
            pixChave = formaRow.pixChave;
            pixTipoChave = formaRow.pixTipoChave;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _telefonePedido = tel;
          _nomeClientePedido = nome;
          _formaPagamentoIsPix = isPix;
          _pixChave = pixChave;
          _pixTipoChave = pixTipoChave;
        });
      }
    } catch (_) {}
  }

  /// Abre o WhatsAppDialog com dados do pedido, incluindo card PIX se aplicavel
  Future<void> _abrirWhatsApp({bool cobrar = false}) async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();

      PedidoData? pedidoRow;
      try {
        pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(widget.ordem.pedidoId)))
            .getSingleOrNull();
      } catch (_) {}

      final pedidoMemoria = widget.controller.pedidosMap[widget.ordem.pedidoId];

      String? tel = _telefonePedido ?? pedidoRow?.clienteTelefoneAvulso ?? pedidoMemoria?.clienteTelefoneAvulso ?? widget.parsed.telefone;
      String nome = _nomeClientePedido ?? pedidoRow?.clienteNomeAvulso ?? pedidoMemoria?.clienteNomeAvulso ?? widget.parsed.cliente;
      final clienteId = pedidoRow?.clienteId ?? pedidoMemoria?.clienteId;

      if (clienteId != null && tel.isEmpty) {
        try {
          final clienteRow = await (db.select(db.clientesTable)
                ..where((c) => c.id.equals(clienteId) & c.deletedAt.isNull()))
              .getSingleOrNull();
          if (clienteRow != null) {
            tel = clienteRow.telefone;
            if (clienteRow.nome.isNotEmpty) {
              nome = clienteRow.nome;
            }
          }
        } catch (_) {}
      }

      if (tel == null || tel.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: FincoreColors.danger,
              content: Text('Nenhum telefone cadastrado para este cliente.'),
            ),
          );
        }
        return;
      }

      // ── Itens do pedido ──────────────────────────────────────────
      List<ItemPedidoData> itemRows = [];
      try {
        itemRows = await (db.select(db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(widget.ordem.pedidoId) & t.deletedAt.isNull()))
            .get();
      } catch (_) {}

      List<Map<String, dynamic>> itensWhats = [];
      if (itemRows.isNotEmpty) {
        itensWhats = itemRows.map((it) => {
          'nome': it.nomeProduto,
          'qtd': it.quantidade,
          'unit': it.valorUnitarioCentavos / 100.0,
          'total': it.valorTotalCentavos / 100.0,
          'obs': it.observacoes,
        }).toList();
      } else {
        itensWhats = widget.ordem.itens.map((it) {
          final pUnit = _itemPrecosEfetivos[it.produtoId] ??
              widget.controller.precoUnitarioCentavos(it.produtoId);
          final totalItemCentavos = (it.quantidade * pUnit).round();
          return {
            'nome': it.nomeProduto,
            'qtd': it.quantidade,
            'unit': pUnit / 100.0,
            'total': totalItemCentavos / 100.0,
            'obs': null,
          };
        }).toList();
      }

      // ── Endereço de entrega ───────────────────────────────────────
      String? enderecoStr;
      if (pedidoRow?.enderecoJson != null && pedidoRow!.enderecoJson!.isNotEmpty) {
        try {
          final map = jsonDecode(pedidoRow.enderecoJson!) as Map<String, dynamic>;
          final logradouro = (map['logradouro'] as String?)?.trim() ?? '';
          final numero = (map['numero'] as String?)?.trim() ?? '';
          final bairro = (map['bairro'] as String?)?.trim() ?? '';
          final cidade = (map['cidade'] as String?)?.trim() ?? '';
          final complemento = (map['complemento'] as String?)?.trim() ?? '';
          final ref = (map['pontoReferencia'] as String? ?? map['referencia'] as String?)?.trim() ?? '';

          final parts = <String>[];
          if (logradouro.isNotEmpty) {
            parts.add(numero.isNotEmpty ? '$logradouro, $numero' : logradouro);
          }
          if (complemento.isNotEmpty) parts.add(complemento);
          if (bairro.isNotEmpty) parts.add(bairro);
          if (cidade.isNotEmpty) parts.add(cidade);
          if (ref.isNotEmpty) parts.add('(Ref: $ref)');
          if (parts.isNotEmpty) enderecoStr = parts.join(' - ');
        } catch (_) {}
      }
      if (enderecoStr == null || enderecoStr.isEmpty) {
        final endParsed = widget.parsed.endereco;
        final bairroParsed = widget.parsed.bairro;
        if (endParsed != null && endParsed.isNotEmpty) {
          enderecoStr = endParsed + (bairroParsed != null && bairroParsed.isNotEmpty ? ' - $bairroParsed' : '');
        }
      }

      // ── Data e Hora prevista ──────────────────────────────────────
      final dt = pedidoRow?.dataHoraEntregaPrevista?.toLocal() ??
                 pedidoRow?.dataHoraCriacao.toLocal() ??
                 widget.ordem.criadaEm.toLocal();
      final dataStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      // ── Logística e Pagamento ─────────────────────────────────────
      final tipoAtendimento = pedidoRow?.tipoLogistica ?? widget.parsed.tipoLogistica;
      final formaPagtoStr = pedidoRow?.formaPagamentoNome ?? widget.parsed.pagamento;

      // ── Valores monetários ────────────────────────────────────────
      final subtotal = (pedidoRow != null && pedidoRow.valorSubtotalCentavos > 0)
          ? (pedidoRow.valorSubtotalCentavos / 100.0)
          : itensWhats.fold<double>(0.0, (acc, item) => acc + ((item['total'] as num?)?.toDouble() ?? 0.0));
      final taxaEntrega = (pedidoRow?.valorTaxaEntregaCentavos ?? 0) / 100.0;
      final taxaServico = (pedidoRow?.valorTaxaServicoCentavos ?? 0) / 100.0;
      final total = (pedidoRow != null && pedidoRow.valorTotalCentavos > 0)
          ? (pedidoRow.valorTotalCentavos / 100.0)
          : (widget.controller.totalOrdemCentavos(widget.ordem) / 100.0);

      // ── Observações ───────────────────────────────────────────────
      final obs = (pedidoRow?.observacoes != null && pedidoRow!.observacoes!.isNotEmpty)
          ? pedidoRow.observacoes
          : (widget.parsed.observacoesLimpa.isNotEmpty ? widget.parsed.observacoesLimpa : null);

      // ── Gera card PIX se a forma de pagamento for PIX e tiver chave cadastrada ──
      PixWhatsAppInfo? pixInfo;
      if (_formaPagamentoIsPix && _pixChave != null && _pixChave!.isNotEmpty) {
        try {
          final config = await (db.select(db.empresaConfiguracaoTable)..limit(1)).getSingleOrNull();
          final copiaECola = PixGenerator.gerarCopiaCola(
            chave: _pixChave!,
            favorecido: (config?.pixFavorecido != null && config!.pixFavorecido!.isNotEmpty)
                ? config.pixFavorecido!
                : nome,
            cidade: 'Sorocaba',
            valor: total,
            tipoChave: _pixTipoChave,
          );
          pixInfo = PixWhatsAppInfo(
            chaveDisplay: _pixChave!,
            tipoChave: _pixTipoChave ?? 'PIX',
            copiaECola: copiaECola,
          );
        } catch (pixErr) {
          debugPrint('[PedidoDetailDrawer] Erro ao gerar PIX para WhatsApp: $pixErr');
        }
      }

      final numPedido = (pedidoRow?.numeroPedido != null)
          ? '#${pedidoRow!.numeroPedido.toString().padLeft(6, '0')}'
          : (pedidoMemoria?.numeroPedido != null
              ? '#${pedidoMemoria!.numeroPedido.toString().padLeft(6, '0')}'
              : '#${widget.ordem.pedidoId.length > 6 ? widget.ordem.pedidoId.substring(0, 6).toUpperCase() : widget.ordem.pedidoId.toUpperCase()}');

      String? empresaNome;
      try {
        if (TenantContext().hasContext) {
          empresaNome = TenantContext().empresa.nomeFantasia.isNotEmpty
              ? TenantContext().empresa.nomeFantasia
              : TenantContext().empresa.razaoSocial;
        }
      } catch (_) {}

      if (!mounted) return;

      final resumoWhats = WhatsAppService.gerarTextoResumoPedido(
        nomeCliente: nome,
        numeroPedidoOuId: numPedido.replaceAll('#', ''),
        tipoAtendimento: tipoAtendimento,
        dataHoraPrevista: dataStr,
        itens: itensWhats,
        subtotal: subtotal,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        total: total,
        formaPagamento: formaPagtoStr,
        enderecoEntrega: tipoAtendimento.toLowerCase().contains('entrega') ? enderecoStr : null,
        observacoes: obs,
        nomeEmpresa: empresaNome,
      );

      final calcDescontoCentavos = (pedidoRow != null)
          ? ((pedidoRow.valorSubtotalCentavos + pedidoRow.valorTaxaEntregaCentavos + pedidoRow.valorTaxaServicoCentavos) - pedidoRow.valorTotalCentavos)
          : 0;
      final descontoCalculado = calcDescontoCentavos > 0 ? (calcDescontoCentavos / 100.0) : 0.0;
      final trocoStr = (pedidoRow?.trocoParaCentavos != null && pedidoRow!.trocoParaCentavos! > 0)
          ? 'R\$ ${(pedidoRow.trocoParaCentavos! / 100.0).toStringAsFixed(2).replaceAll('.', ',')}'
          : null;

      final String templateIdSugerido;
      if (cobrar) {
        templateIdSugerido = 'cobranca_pix';
      } else if (widget.ordem.status == StatusOrdemPreparo.saiuParaEntrega) {
        templateIdSugerido = 'saiu_entrega';
      } else if (widget.ordem.status == StatusOrdemPreparo.pronto) {
        templateIdSugerido = 'pedido_pronto';
      } else if (widget.ordem.status == StatusOrdemPreparo.pendente) {
        templateIdSugerido = 'comprovante';
      } else {
        templateIdSugerido = 'contato_pedido';
      }

      await WhatsAppDialog.show(
        context,
        rawPhone: tel,
        clienteNome: nome,
        initialMessage: resumoWhats,
        initialTemplateId: templateIdSugerido,
        enderecoCliente: enderecoStr,
        enderecoEmpresa: WhatsAppService.formatarEnderecoEmpresa(),
        statusPagamento: _isPago ? 'Confirmado' : 'Pendente',
        pagamentoPendente: !_isPago,
        isPix: _formaPagamentoIsPix,
        pixInfo: pixInfo,
        numeroPedido: numPedido,
        pedidoId: pedidoRow?.id ?? widget.ordem.pedidoId,
        nomeEmpresa: empresaNome,
        itens: itensWhats,
        subtotal: subtotal,
        desconto: descontoCalculado,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        total: total,
        formaPagamento: formaPagtoStr,
        trocoPara: trocoStr,
        tipoPedido: tipoAtendimento,
        observacoes: obs,
        previsaoEntrega: dataStr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir WhatsApp: $e'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _carregarPrecosEfetivos() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final itemRows = await (db.select(db.itensPedidoTable)
            ..where((t) => t.pedidoId.equals(widget.ordem.pedidoId) & t.deletedAt.isNull()))
          .get();
      if (mounted) {
        setState(() {
          _itemPrecosEfetivos = {
            for (final row in itemRows) row.produtoId: row.valorUnitarioCentavos
          };
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarHistorico() async {
    try {
      final h = await widget.controller.carregarHistorico(widget.ordem.id);
      if (mounted) {
        setState(() {
          _historico = h;
          _loadingHistorico = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistorico = false);
    }
  }

  // ── Status e labels ──────────────────────────────────────────────────

  static const _statusLabels = {
    StatusOrdemPreparo.pendente: 'Pendente',
    StatusOrdemPreparo.emPreparo: 'Em Preparo',
    StatusOrdemPreparo.pronto: 'Pronto',
    StatusOrdemPreparo.saiuParaEntrega: 'Saiu p/ Entrega',
    StatusOrdemPreparo.entregue: 'Entregue',
    StatusOrdemPreparo.cancelado: 'Cancelado',
  };

  static const _statusColors = {
    StatusOrdemPreparo.pendente: Color(0xFFF97316),
    StatusOrdemPreparo.emPreparo: Color(0xFFF59E0B),
    StatusOrdemPreparo.pronto: Color(0xFF10B981),
    StatusOrdemPreparo.saiuParaEntrega: Color(0xFF06B6D4),
    StatusOrdemPreparo.entregue: Color(0xFF10B981),
    StatusOrdemPreparo.cancelado: Color(0xFFEF4444),
  };

  Color get _statusColor =>
      _statusColors[widget.ordem.status] ?? FincoreColors.primary;

  String get _statusLabel =>
      _statusLabels[widget.ordem.status] ?? widget.ordem.status.name;

  // ── Próxima ação pelo role ────────────────────────────────────────────

  StatusOrdemPreparo? get _proximoStatus {
    final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
    final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
        widget.parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        widget.parsed.tipoLogistica.toLowerCase().contains('delivery');

    switch (widget.ordem.status) {
      case StatusOrdemPreparo.pendente:
        return PermissaoService.podeIniciarPreparo(widget.userRole)
            ? StatusOrdemPreparo.emPreparo
            : null;
      case StatusOrdemPreparo.emPreparo:
        return PermissaoService.podeConcluirPreparo(widget.userRole)
            ? StatusOrdemPreparo.pronto
            : null;
      case StatusOrdemPreparo.pronto:
        if (isDelivery) {
          return PermissaoService.podeEntregar(widget.userRole)
              ? StatusOrdemPreparo.saiuParaEntrega
              : null;
        }
        return PermissaoService.podeEntregar(widget.userRole)
            ? StatusOrdemPreparo.entregue
            : null;
      case StatusOrdemPreparo.saiuParaEntrega:
        return PermissaoService.podeEntregar(widget.userRole)
            ? StatusOrdemPreparo.entregue
            : null;
      default:
        return null;
    }
  }

  String get _proximoLabel {
    final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
    final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
        widget.parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        widget.parsed.tipoLogistica.toLowerCase().contains('delivery');

    switch (widget.ordem.status) {
      case StatusOrdemPreparo.pendente:
        return 'Iniciar Preparo';
      case StatusOrdemPreparo.emPreparo:
        return 'Marcar como Pronto';
      case StatusOrdemPreparo.pronto:
        return isDelivery ? 'Saiu para Entrega' : 'Finalizar Entrega';
      case StatusOrdemPreparo.saiuParaEntrega:
        return 'Confirmar Entrega (Finalizar)';
      default:
        return '';
    }
  }

  // ── Ação de avançar status ────────────────────────────────────────────

  Future<void> _avancarStatus() async {
    final next = _proximoStatus;
    if (next == null) return;

    setState(() => _loadingAction = true);
    try {
      await widget.controller.moverStatus(widget.ordem, next);
      widget.onStatusChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  // ── Ação de reverter status com escolha de destino ─────────────────────

  List<StatusOrdemPreparo> get _opcoesReversao {
    switch (widget.ordem.status) {
      case StatusOrdemPreparo.emPreparo:
        return [StatusOrdemPreparo.pendente];
      case StatusOrdemPreparo.pronto:
        return [StatusOrdemPreparo.emPreparo, StatusOrdemPreparo.pendente];
      case StatusOrdemPreparo.saiuParaEntrega:
        return [
          StatusOrdemPreparo.pronto,
          StatusOrdemPreparo.emPreparo,
          StatusOrdemPreparo.pendente,
        ];
      case StatusOrdemPreparo.entregue:
        final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
        final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
            widget.parsed.tipoLogistica.toLowerCase().contains('entrega');
        return [
          if (isDelivery) StatusOrdemPreparo.saiuParaEntrega,
          StatusOrdemPreparo.pronto,
          StatusOrdemPreparo.emPreparo,
          StatusOrdemPreparo.pendente,
        ];
      case StatusOrdemPreparo.cancelado:
        return [
          StatusOrdemPreparo.pendente,
          StatusOrdemPreparo.emPreparo,
          StatusOrdemPreparo.pronto,
        ];
      default:
        return [];
    }
  }

  Future<void> _reverterStatus() async {
    final opcoes = _opcoesReversao;
    if (opcoes.isEmpty) return;

    if (widget.onSolicitarReversao != null) {
      final res = await widget.onSolicitarReversao!(widget.ordem, opcoes);
      if (res == null) return;

      setState(() => _loadingAction = true);
      try {
        await widget.controller.moverStatus(
          widget.ordem,
          res.destino,
          motivo: res.motivo,
        );
        widget.onStatusChanged?.call();
        if (mounted) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _loadingAction = false);
      }
      return;
    }

    final anterior = opcoes.first;
    final deLabel = _statusLabel;
    final paraLabel = _statusLabels[anterior] ?? anterior.name;
    final motivo = await widget.onSolicitarMotivoReversao?.call(deLabel, paraLabel);
    if (motivo == null) return;

    setState(() => _loadingAction = true);
    try {
      await widget.controller.moverStatus(
        widget.ordem,
        anterior,
        motivo: motivo,
      );
      widget.onStatusChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
    final friendlyId = pedido != null && pedido.numeroPedido != null
        ? '#${pedido.numeroPedido.toString().padLeft(6, '0')}'
        : (widget.ordem.pedidoId.length > 8
            ? '#${widget.ordem.pedidoId.substring(0, 8).toUpperCase()}'
            : '#${widget.ordem.pedidoId.toUpperCase()}');

    final minutosAtras =
        DateTime.now().difference(widget.ordem.criadaEm).inMinutes;
    final subtitle = minutosAtras < 60
        ? 'há $minutosAtras min'
        : 'há ${(minutosAtras / 60).floor()}h ${minutosAtras % 60}min';

    final isCozinha = widget.userRole?.toUpperCase() == 'COZINHA';
    return EntityDetailDrawer(
      title: 'Pedido $friendlyId',
      subtitle: subtitle,
      badges: _buildBadges(),
      lifecycle: isCozinha ? null : _buildLifecycle(),
      body: _buildBody(),
      timeline: PermissaoService.podeVerTimeline(widget.userRole) ? _buildTimeline() : null,
      actions: _buildActions(),
    );
  }

  // ── Badges de status e prioridade ────────────────────────────────────

  Widget _buildBadges() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _StatusBadge(label: _statusLabel, color: _statusColor),
        if (widget.ordem.prioridade == PrioridadeOrdem.urgente)
          _StatusBadge(label: '⚡ URGENTE', color: const Color(0xFFEF4444)),
        if (widget.ordem.prioridade == PrioridadeOrdem.vip)
          _StatusBadge(label: '★ VIP', color: const Color(0xFFF59E0B)),
        if (widget.ordem.prioridade == PrioridadeOrdem.programado)
          _StatusBadge(label: '📅 Programado', color: const Color(0xFF8B5CF6)),
      ],
    );
  }

  // ── Lifecycle horizontal ───────────────────────────────────────────────

  Widget _buildLifecycle() {
    final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
    final isDelivery = (pedido?.tipoLogistica.toLowerCase().contains('entrega') ?? false) ||
        widget.parsed.tipoLogistica.toLowerCase().contains('entrega') ||
        widget.parsed.tipoLogistica.toLowerCase().contains('delivery');

    final steps = [
      _LifecycleStep(
        label: 'Criado',
        completed: true,
        isCurrent: widget.ordem.status == StatusOrdemPreparo.pendente,
      ),
      _LifecycleStep(
        label: 'Em Preparo',
        completed: widget.ordem.status != StatusOrdemPreparo.pendente &&
            widget.ordem.status != StatusOrdemPreparo.cancelado,
        isCurrent: widget.ordem.status == StatusOrdemPreparo.emPreparo,
      ),
      _LifecycleStep(
        label: 'Pronto',
        completed: widget.ordem.status == StatusOrdemPreparo.pronto ||
            widget.ordem.status == StatusOrdemPreparo.saiuParaEntrega ||
            widget.ordem.status == StatusOrdemPreparo.entregue,
        isCurrent: widget.ordem.status == StatusOrdemPreparo.pronto,
      ),
      if (isDelivery)
        _LifecycleStep(
          label: 'A Caminho',
          completed: widget.ordem.status == StatusOrdemPreparo.saiuParaEntrega ||
              widget.ordem.status == StatusOrdemPreparo.entregue,
          isCurrent: widget.ordem.status == StatusOrdemPreparo.saiuParaEntrega,
        ),
      _LifecycleStep(
        label: 'Entregue',
        completed: widget.ordem.status == StatusOrdemPreparo.entregue,
        isCurrent: widget.ordem.status == StatusOrdemPreparo.entregue,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _StepNode(step: steps[i]),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: steps[i + 1].completed
                      ? const Color(0xFF10B981)
                      : FincoreColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Corpo do drawer ──────────────────────────────────────────────────

  Widget _buildBody() {
    final pedido = widget.controller.pedidosMap[widget.ordem.pedidoId];
    final totalCentavos = widget.controller.totalOrdemCentavos(widget.ordem);
    final mostraFinanceiro =
        PermissaoService.podeVerFinanceiro(widget.userRole);

    final agendada = widget.parsed.dataAgendada ?? pedido?.dataHoraEntregaPrevista?.toLocal();
    final String dataStr;
    final String horaStr;
    if (agendada != null) {
      final local = agendada.toLocal();
      final weekdays = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
      dataStr = '${weekdays[local.weekday - 1]}, ${DateFormat('dd/MM/yyyy').format(local)}';
      horaStr = DateFormat('HH:mm').format(local);
    } else {
      dataStr = 'Imediato';
      horaStr = DateFormat('HH:mm').format(widget.ordem.criadaEm.toLocal());
    }
    final isDelivery = widget.parsed.tipoLogistica.toLowerCase().contains('entrega') ||
                       widget.parsed.tipoLogistica.toLowerCase().contains('delivery');
    final deadline = widget.controller.calculateDeadline(widget.ordem);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Cliente Card ---
        const DrawerSectionLabel(label: 'Cliente'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: FincoreColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parsed.cliente.isEmpty ? 'Consumidor Final' : widget.parsed.cliente,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    if (widget.parsed.telefone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: FincoreColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            widget.parsed.telefone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: FincoreColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Entrega Card ---
        const DrawerSectionLabel(label: 'Logística de Atendimento'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_logisticaIcon(widget.parsed.tipoLogistica), color: const Color(0xFF06B6D4), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.parsed.tipoLogistica.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Color(0xFF06B6D4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: FincoreColors.border),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: FincoreColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          dataStr,
                          style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: FincoreColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          horaStr,
                          style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (mostraFinanceiro && widget.parsed.pagamento.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payment_outlined, size: 14, color: FincoreColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      widget.parsed.pagamento,
                      style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        if (widget.parsed.observacoesLimpa.isNotEmpty) ...[
          const SizedBox(height: 16),
          const DrawerSectionLabel(label: 'Observações'),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: FincoreColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_outlined, size: 14, color: FincoreColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.parsed.observacoesLimpa,
                    style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // --- Itens ---
        const DrawerSectionLabel(label: 'Itens do Pedido'),
        Column(
          children: [
            for (final item in widget.ordem.itens)
              _LargeItemCard(
                item: item,
                precoUnitarioCentavos: _itemPrecosEfetivos[item.produtoId] ?? widget.controller
                    .precoUnitarioCentavos(item.produtoId),
                mostraPreco: mostraFinanceiro,
              ),
          ],
        ),

        const SizedBox(height: 12),
        
        // Resumo de volumes e financeiro
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FincoreColors.primary.withValues(alpha: 0.12),
                FincoreColors.primary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL DE ITENS',
                    style: TextStyle(
                      color: FincoreColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.ordem.itens.length} item(ns) / ${widget.parsed.totalUnidades.toInt()} un.',
                    style: const TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (mostraFinanceiro && totalCentavos > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'VALOR TOTAL',
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${(totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // --- Status Financeiro / Contas a Receber ---
        if (mostraFinanceiro) ...[
          const SizedBox(height: 16),
          const DrawerSectionLabel(label: 'Contas a Receber (Financeiro)'),
          _buildCardFinanceiro(),
        ],

        const SizedBox(height: 16),

        // --- Prazo Operacional ---
        const DrawerSectionLabel(label: 'Prazo Operacional'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrazoRow(
                label: 'Preparação',
                value: '${deadline.tempoPreparacaoMinutos} min',
              ),
              if (isDelivery) ...[
                const SizedBox(height: 8),
                _PrazoRow(
                  label: 'Deslocamento',
                  value: '${deadline.tempoDeslocamentoMinutos} min',
                ),
              ],
              const SizedBox(height: 8),
              _PrazoRow(
                label: 'Margem de Segurança',
                value: '${deadline.margemSegurancaMinutos} min',
              ),
              const Divider(color: FincoreColors.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Iniciar produção até',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (deadline.isImmediate || deadline.statusLabel.contains('atrasada'))
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : FincoreColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (deadline.isImmediate || deadline.statusLabel.contains('atrasada'))
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : FincoreColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      deadline.isImmediate 
                          ? 'AGORA' 
                          : DateFormat('HH:mm').format(deadline.horarioInicioRecomendado),
                      style: TextStyle(
                        color: (deadline.isImmediate || deadline.statusLabel.contains('atrasada'))
                            ? const Color(0xFFEF4444)
                            : FincoreColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFinanceiro() {
    if (_loadingFinanceiro) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final totalCentavos = widget.controller.totalOrdemCentavos(widget.ordem);
    final valorFormatado = 'R\$ ${(totalCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    if (_isUsoConsumo) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USO E CONSUMO INTERNO (ISENTO DE COBRANÇA)',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Venda registrada como Uso/Consumo Interno ou Cortesia. Não gera financeiro a receber no Caixa.',
                    style: TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isPago) {
      final dataStr = _dataPagamento != null
          ? DateFormat('dd/MM/yyyy · HH:mm').format(_dataPagamento!)
          : 'Confirmado';
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAGAMENTO CONFIRMADO / RECEBIDO',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recebido em $dataStr · $valorFormatado',
                        style: const TextStyle(
                          color: FincoreColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _baixandoFinanceiro ? null : _estornarBaixaFinanceira,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 14),
                  label: const Text('Estornar Pagamento', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Pendente / A Receber
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAGAMENTO PENDENTE (A RECEBER)',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valor em aberto: $valorFormatado',
                      style: const TextStyle(
                        color: FincoreColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _baixandoFinanceiro ? null : _darBaixaFinanceira,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _baixandoFinanceiro
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.price_check_rounded, size: 18),
                  label: Text(
                    _baixandoFinanceiro ? 'Registrando...' : 'Dar Baixa / Confirmar Recebimento',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _abrirWhatsApp(cobrar: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Cobrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _logisticaIcon(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('entrega') || t.contains('delivery')) {
      return Icons.delivery_dining_outlined;
    }
    if (t.contains('mesa')) return Icons.table_restaurant_outlined;
    return Icons.storefront_outlined;
  }

  // ── Linha do tempo ────────────────────────────────────────────────

  Widget _buildTimeline() {
    if (_loadingHistorico) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: FincoreColors.primary,
            ),
          ),
        ),
      );
    }

    if (_historico.isEmpty) {
      return const Text(
        'Nenhum evento registrado.',
        style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _historico.length; i++)
          _TimelineEntry(
            log: _historico[i],
            isLast: i == _historico.length - 1,
          ),
      ],
    );
  }

  // ── Ações contextuais ─────────────────────────────────────────────

  Widget _buildActions() {
    final isCozinha = widget.userRole?.toUpperCase() == 'COZINHA';
    final proxStatus = _proximoStatus;
    final podeReverter = !isCozinha && PermissaoService.podeRevertarStatus(widget.userRole) &&
        _opcoesReversao.isNotEmpty;
    final podeEditar = !isCozinha && PermissaoService.podeEditarPedido(widget.userRole) &&
        widget.ordem.status == StatusOrdemPreparo.pendente;
    final podeCancelar = !isCozinha && PermissaoService.podeCancelarPedido(widget.userRole) &&
        widget.ordem.status == StatusOrdemPreparo.pendente;
    final podeImprimir = !isCozinha && PermissaoService.podeImprimir(widget.userRole);
    final temTelefone = (_telefonePedido ?? widget.parsed.telefone).isNotEmpty;
    final podeWhatsApp = !isCozinha && temTelefone;

    final hasSecondaryActions = podeEditar || podeCancelar || podeReverter || podeImprimir || podeWhatsApp;

    if (proxStatus == null && !hasSecondaryActions) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ação principal: próximo status
        if (proxStatus != null)
          ElevatedButton(
            onPressed: _loadingAction ? null : _avancarStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isCozinha ? 18 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _loadingAction
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _proximoLabel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isCozinha ? 15 : 13,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),

        // Ações secundárias
        if (hasSecondaryActions) ...[
          if (proxStatus != null) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (podeReverter)
                _SecondaryButton(
                  icon: Icons.undo_rounded,
                  label: 'Reverter',
                  onTap: _loadingAction ? null : _reverterStatus,
                  color: const Color(0xFFF59E0B),
                ),
              if (podeEditar && widget.onEditar != null)
                _SecondaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  onTap: widget.onEditar,
                ),
              if (podeImprimir && widget.onImprimir != null)
                _SecondaryButton(
                  icon: Icons.print_outlined,
                  label: 'Imprimir',
                  onTap: widget.onImprimir,
                ),
              if (podeWhatsApp)
                _SecondaryButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: _loadingAction ? null : _abrirWhatsApp,
                  color: const Color(0xFF25D366),
                ),
              if (podeCancelar && widget.onCancelar != null)
                _SecondaryButton(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelar',
                  onTap: widget.onCancelar,
                  color: FincoreColors.danger,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LifecycleStep {
  final String label;
  final bool completed;
  final bool isCurrent;
  const _LifecycleStep({
    required this.label,
    required this.completed,
    this.isCurrent = false,
  });
}

class _StepNode extends StatelessWidget {
  final _LifecycleStep step;
  const _StepNode({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = step.completed
        ? (step.isCurrent ? FincoreColors.primary : const Color(0xFF10B981))
        : FincoreColors.border;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: step.completed
                ? color
                : FincoreColors.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: step.isCurrent ? 2.5 : 1.5,
            ),
          ),
          child: Icon(
            step.completed ? Icons.check_rounded : Icons.circle_outlined,
            size: 12,
            color: step.completed ? Colors.white : FincoreColors.border,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            color: step.completed
                ? (step.isCurrent
                    ? FincoreColors.textPrimary
                    : FincoreColors.textSecondary)
                : FincoreColors.textMuted,
            fontSize: 9,
            fontWeight:
                step.isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _LargeItemCard extends StatelessWidget {
  final ItemOrdemPreparo item;
  final int precoUnitarioCentavos;
  final bool mostraPreco;

  const _LargeItemCard({
    required this.item,
    required this.precoUnitarioCentavos,
    required this.mostraPreco,
  });

  @override
  Widget build(BuildContext context) {
    final total = (item.quantidade * precoUnitarioCentavos).round();
    final totalStr =
        'R\$ ${(total / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: FincoreColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${item.quantidade.toInt()} un.',
                      style: TextStyle(
                        color: FincoreColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      '  —  ',
                      style: TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.nomeProduto,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (mostraPreco && total > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        totalStr,
                        style: const TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrazoRow extends StatelessWidget {
  final String label;
  final String value;
  const _PrazoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FincoreColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: FincoreColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


class _TimelineEntry extends StatelessWidget {
  final HistoricoOrdemPreparo log;
  final bool isLast;
  const _TimelineEntry({required this.log, required this.isLast});

  Color _bulletColor() {
    final t = log.titulo.toLowerCase();
    if (t.contains('criado')) return const Color(0xFF3B82F6);
    if (t.contains('pix') || t.contains('pagamento')) return const Color(0xFF10B981);
    if (t.contains('revertido')) return const Color(0xFFF59E0B);
    if (t.contains('cancelado')) return FincoreColors.danger;
    if (t.contains('status')) return const Color(0xFF8B5CF6);
    return FincoreColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: _bulletColor(),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 44,
                color: FincoreColors.border,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.titulo,
                      style: const TextStyle(
                        color: FincoreColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM HH:mm').format(log.criadaEm.toLocal()),
                      style: const TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.descricao,
                  style: const TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Por ${log.operadorNome}',
                  style: const TextStyle(
                    color: FincoreColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? FincoreColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
