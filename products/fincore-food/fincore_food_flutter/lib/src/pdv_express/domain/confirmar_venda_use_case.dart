import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/fincore_core.dart';
import '../models/pedido_draft.dart';

/// Resultado imutável da confirmação de venda.
class ConfirmarVendaResult {
  final String pedidoId;
  final int numeroPedido;
  final String ordemPreparoId;
  final String? lancamentoFinanceiroId;

  const ConfirmarVendaResult({
    required this.pedidoId,
    required this.numeroPedido,
    required this.ordemPreparoId,
    this.lancamentoFinanceiroId,
  });
}

/// Parâmetros de entrada para o use case, desacoplados do controller.
class ConfirmarVendaInput {
  final PedidoDraft pedido;
  final List<ItemPedidoDraft> itens;
  final String paymentMethod;
  final String? clienteNome;
  final String? clienteTelefone;
  final String? enderecoJson;
  final String? ordemPreparoIdExistente; // se for edição
  final bool isEdit;
  final List<ItemPedidoData> oldItems; // itens antigos (edição)
  final bool isEntregaAgendada;
  final DateTime? dataEntregaPrevista;
  final String operadorNome;
  final String? observacao;
  final bool movimentarEstoque;
  final bool isUsoInterno;
  final bool isRetroativo;

  const ConfirmarVendaInput({
    required this.pedido,
    required this.itens,
    required this.paymentMethod,
    this.clienteNome,
    this.clienteTelefone,
    this.enderecoJson,
    this.ordemPreparoIdExistente,
    required this.isEdit,
    required this.oldItems,
    required this.isEntregaAgendada,
    this.dataEntregaPrevista,
    required this.operadorNome,
    this.observacao,
    this.movimentarEstoque = true,
    this.isUsoInterno = false,
    this.isRetroativo = false,
  });
}

/// Persiste uma venda de forma completamente atômica.
///
/// Toda a operação ocorre dentro de um único [db.transaction()]. Se
/// qualquer passo falhar (estoque, lançamento financeiro, Outbox etc.),
/// o Drift realiza rollback automático e nenhum registro parcial fica
/// no banco local. O caller recebe a exceção original para tratar na UI.
class ConfirmarVendaUseCase {
  final FincoreDatabase _db;
  final TenantContext _context;
  final _uuid = const Uuid();

  ConfirmarVendaUseCase({
    required FincoreDatabase db,
    required TenantContext context,
  })  : _db = db,
        _context = context;

  Future<ConfirmarVendaResult> execute(ConfirmarVendaInput input) async {
    final activeTenant = _context.tenantId;
    final activeUser = _context.usuario.id;
    final now = DateTime.now().toUtc();
    final traceId = CorrelationIdGenerator.generateCorrelationId();
    final processName = input.isEdit ? 'EDICAO_PEDIDO' : 'CRIACAO_PEDIDO';

    final ordemPreparoId = input.ordemPreparoIdExistente ?? _uuid.v4();
    final historicoId = _uuid.v4();
    final pedidoId = input.pedido.id;
    final action = input.isEdit ? 'update' : 'create';
    final histTitle = input.isEdit ? 'Pedido editado' : 'Pedido criado';
    String histDesc = input.isEdit ? 'Itens/Valores atualizados no PDV' : 'Pedido enviado para a cozinha';

    await LogService.instance.logOperational(
      process: processName,
      step: 'PREPARACAO',
      action: 'INICIO',
      message: 'Pedido ID: $pedidoId | Cliente: ${input.clienteNome ?? "Consumidor"} | Itens: ${input.itens.length} | Total: R\$ ${(input.pedido.valorTotalCentavos / 100).toStringAsFixed(2)} | Pagamento: ${input.paymentMethod}',
      traceId: traceId,
      entityType: 'pedido',
      entityId: pedidoId,
      tenantId: activeTenant,
      userId: activeUser,
    );

    final kdsItensJson = jsonEncode(input.itens.map((i) => {
      'produtoId': i.produtoId,
      'nomeProduto': i.nome,
      'quantidade': i.quantidade,
      'unidade': 'un',
    }).toList());

    late int proxNumero;
    String? lancamentoId;

    await _db.transaction(() async {
      // ── 1. numeroPedido transacional via MAX() ──────────────────────────
      if (input.isEdit) {
        final existingPedido = await (_db.select(_db.pedidosTable)
              ..where((t) => t.id.equals(pedidoId)))
            .getSingleOrNull();
        proxNumero = existingPedido?.numeroPedido ??
            await _nextNumeroPedido(activeTenant);

        // Construir descrição dinâmica de alteração do histórico
        if (existingPedido != null) {
          final alteracoes = <String>[];
          final oldDate = existingPedido.dataHoraCriacao.toLocal();
          final newDate = input.pedido.dataHoraCriacao.toLocal();

          if (oldDate.year != newDate.year ||
              oldDate.month != newDate.month ||
              oldDate.day != newDate.day ||
              oldDate.hour != newDate.hour ||
              oldDate.minute != newDate.minute) {
            final fmt = DateFormat('dd/MM HH:mm');
            alteracoes.add('Hora da entrega alterada de ${fmt.format(oldDate)} para ${fmt.format(newDate)}');
          }

          if (existingPedido.formaPagamentoNome != input.paymentMethod) {
            alteracoes.add('Pagamento alterado de ${existingPedido.formaPagamentoNome ?? "Não informado"} para ${input.paymentMethod}');
          }

          if (existingPedido.valorTotalCentavos != input.pedido.valorTotalCentavos) {
            final oldVal = (existingPedido.valorTotalCentavos / 100).toStringAsFixed(2);
            final newVal = (input.pedido.valorTotalCentavos / 100).toStringAsFixed(2);
            alteracoes.add('Valor alterado de R\$ $oldVal para R\$ $newVal');
          }

          final oldItemMap = {for (var i in input.oldItems) i.produtoId: i};
          final newItemMap = {for (var i in input.itens) i.produtoId: i};
          final itensAlteracoes = <String>[];

          // 1. Adicionados ou quantidade alterada
          for (final n in input.itens) {
            final o = oldItemMap[n.produtoId];
            if (o == null) {
              final qtdStr = n.quantidade % 1 == 0 ? n.quantidade.toInt().toString() : n.quantidade.toString();
              itensAlteracoes.add('+ $qtdStr un de ${n.nome}');
            } else if (o.quantidade != n.quantidade) {
              final oldQtd = o.quantidade % 1 == 0 ? o.quantidade.toInt().toString() : o.quantidade.toString();
              final newQtd = n.quantidade % 1 == 0 ? n.quantidade.toInt().toString() : n.quantidade.toString();
              itensAlteracoes.add('Qtde de ${n.nome} alterada de $oldQtd para $newQtd');
            }
          }

          // 2. Removidos
          for (final o in input.oldItems) {
            if (!newItemMap.containsKey(o.produtoId)) {
              final qtdStr = o.quantidade % 1 == 0 ? o.quantidade.toInt().toString() : o.quantidade.toString();
              itensAlteracoes.add('- $qtdStr un de ${o.nomeProduto}');
            }
          }

          if (itensAlteracoes.isNotEmpty) {
            alteracoes.add('Alterações de Itens:\n  ' + itensAlteracoes.join('\n  '));
          }

          if (alteracoes.isNotEmpty) {
            histDesc = alteracoes.join('\n');
          } else {
            histDesc = 'Pedido editado sem alterações de valores ou itens';
          }
        }
      } else {
        proxNumero = await _nextNumeroPedido(activeTenant);
      }

      // ── 2. Pedido principal ─────────────────────────────────────────────
      if (input.isEdit) {
        await (_db.delete(_db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(pedidoId)))
            .go();
      }

      String? cleanClienteId = input.pedido.clienteId;
      if (cleanClienteId != null) {
        final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(cleanClienteId);
        if (!isUuid) {
          cleanClienteId = null;
        }
      }

      final pedidoStatus = input.isRetroativo ? 'entregue' : 'confirmado';
      final kdsStatus = input.isRetroativo ? 'entregue' : 'pendente';
      final kdsTitulo = input.isRetroativo ? 'Pedido finalizado (Retroativo)' : histTitle;
      final kdsDescricao = input.isRetroativo ? 'Registrado retroativamente com status entregue.' : histDesc;

      await _db.into(_db.pedidosTable).insertOnConflictUpdate(
        PedidosTableCompanion.insert(
          id: pedidoId,
          tenantId: activeTenant,
          status: Value(pedidoStatus),
          tipoLogistica: input.pedido.tipoLogistica,
          clienteId: Value(cleanClienteId),
          clienteNomeAvulso: Value(input.clienteNome),
          clienteTelefoneAvulso: Value(input.clienteTelefone),
          valorSubtotalCentavos: input.pedido.valorSubtotalCentavos,
          valorTaxaEntregaCentavos: Value(input.pedido.valorTaxaEntregaCentavos),
          valorTaxaServicoCentavos: Value(input.pedido.valorTaxaServicoCentavos),
          valorTotalCentavos: input.pedido.valorTotalCentavos,
          trocoParaCentavos: Value(input.pedido.trocoParaCentavos),
          observacoes: Value(input.pedido.observacoes),
          formaPagamentoId: Value(input.pedido.formaPagamentoId),
          formaPagamentoNome: Value(input.paymentMethod),
          numeroPedido: Value(proxNumero),
          enderecoJson: Value(input.enderecoJson),
          operadorId: Value(activeUser),
          dataHoraCriacao: input.pedido.dataHoraCriacao.toUtc(),
          canalOrigem: const Value('pdv_express'),
          dataHoraEntregaPrevista: Value(input.dataEntregaPrevista?.toUtc()),
          isUsoInterno: Value(input.isUsoInterno),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: activeUser,
          updatedBy: activeUser,
        ),
      );

      // ── 3. Itens do pedido ──────────────────────────────────────────────
      for (final item in input.itens) {
        await _db.into(_db.itensPedidoTable).insertOnConflictUpdate(
          ItensPedidoTableCompanion.insert(
            id: item.id,
            tenantId: activeTenant,
            pedidoId: pedidoId,
            produtoId: item.produtoId,
            nomeProduto: item.nome,
            quantidade: item.quantidade,
            valorUnitarioCentavos: item.valorUnitarioCentavos,
            valorTotalCentavos: item.valorTotalCentavos,
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: activeUser,
            updatedBy: activeUser,
          ),
        );
      }

      // ── 4. Ordem de preparo (KDS) ────────────────────────────────────────
      final agendadoStr = input.dataEntregaPrevista != null
          ? '\nagendado: ${DateFormat('dd/MM/yyyy HH:mm').format(input.dataEntregaPrevista!.toLocal())}'
          : '';

      String enderecoStr = '';
      String bairroStr = '';
      if (input.enderecoJson != null && input.enderecoJson!.isNotEmpty) {
        try {
          final map = jsonDecode(input.enderecoJson!);
          final logradouro = map['logradouro'] as String? ?? '';
          final numero = map['numero'] as String? ?? '';
          final bairro = map['bairro'] as String? ?? '';
          final referencia = map['referencia'] as String? ?? '';
          
          if (logradouro.isNotEmpty) {
            enderecoStr = '$logradouro, $numero';
            if (referencia.isNotEmpty) {
              enderecoStr += ' (Ref: $referencia)';
            }
          }
          bairroStr = bairro;
        } catch (_) {}
      }

      final enderecoLine = enderecoStr.isNotEmpty ? '\nendereco: $enderecoStr' : '';
      final bairroLine = bairroStr.isNotEmpty ? '\nbairro: $bairroStr' : '';
      final obsLine = input.observacao != null && input.observacao!.trim().isNotEmpty 
          ? '\nobservacao: ${input.observacao!.trim()}' 
          : '';

      final observacoesKDS =
          '[DADOS_PEDIDO]\n'
          'cliente: ${input.clienteNome ?? 'Consumidor'}\n'
          'telefone: ${input.clienteTelefone ?? ''}\n'
          'tipo: ${input.pedido.tipoLogistica}\n'
          'pagamento: ${input.paymentMethod}\n'
          'total: ${input.pedido.valorTotalCentavos}'
          '$enderecoLine'
          '$bairroLine'
          '$agendadoStr'
          '$obsLine\n'
          '[/DADOS_PEDIDO]';

      await _db.into(_db.ordensPreparoTable).insertOnConflictUpdate(
        OrdensPreparoTableCompanion.insert(
          id: ordemPreparoId,
          tenantId: activeTenant,
          pedidoId: pedidoId,
          itensJson: kdsItensJson,
          status: kdsStatus,
          prioridade: input.dataEntregaPrevista != null ? 'programado' : 'normal',
          operadorId: Value(activeUser),
          criadaEm: input.pedido.dataHoraCriacao.toLocal(),
          concluidaEm: Value(input.isRetroativo ? now.toLocal() : null),
          observacoes: Value(observacoesKDS),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: activeUser,
          updatedBy: activeUser,
        ),
      );

      // ── 5. Histórico inicial de preparo ────────────────────────────────
      await _db.into(_db.historicosOrdemPreparoTable).insert(
        HistoricosOrdemPreparoTableCompanion.insert(
          id: historicoId,
          tenantId: activeTenant,
          ordemPreparoId: ordemPreparoId,
          titulo: kdsTitulo,
          descricao: kdsDescricao,
          operadorNome: Value(input.operadorNome),
          criadaEm: now.toLocal(),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: activeUser,
          updatedBy: activeUser,
        ),
      );

      // ── 6. Baixa de estoque ────────────────────────────────────────────
      if (input.isEdit) {
        // Buscar todas as movimentações anteriores deste pedido no banco local
        final movsAnteriores = await (_db.select(_db.movimentacoesEstoqueTable)
              ..where((t) => t.pedidoId.equals(pedidoId) & t.deletedAt.isNull()))
            .get();

        final saldoFisicoPorProduto = <String, int>{};
        final saldoReservaPorProduto = <String, int>{};

        for (final mov in movsAnteriores) {
          final pId = mov.produtoId;
          final tipo = mov.tipo;
          final qtd = mov.quantidade;
          final mot = mov.motivo;

          if (tipo == 'saida') {
            saldoFisicoPorProduto[pId] = (saldoFisicoPorProduto[pId] ?? 0) + qtd;
          } else if (tipo == 'reserva') {
            saldoReservaPorProduto[pId] = (saldoReservaPorProduto[pId] ?? 0) + qtd;
          } else if (tipo == 'cancelamento') {
            if (mot.contains('reserva')) {
              saldoReservaPorProduto[pId] = (saldoReservaPorProduto[pId] ?? 0) - qtd;
            } else {
              saldoFisicoPorProduto[pId] = (saldoFisicoPorProduto[pId] ?? 0) - qtd;
            }
          }
        }

        // 1. Estorno do estoque físico
        for (final entry in saldoFisicoPorProduto.entries) {
          final pId = entry.key;
          final saldoFisico = entry.value;
          if (saldoFisico > 0) {
            await _movimentarEstoque(
              activeTenant: activeTenant,
              produtoId: pId,
              pedidoId: pedidoId,
              quantidade: saldoFisico,
              tipo: 'cancelamento',
              motivo: 'Estorno de físico por edição — Pedido #${proxNumero.toString().padLeft(4, '0')}',
              operadorId: activeUser,
              now: now,
              isEntradaFisica: true,
            );
          }
        }

        // 2. Estorno do estoque reservado
        for (final entry in saldoReservaPorProduto.entries) {
          final pId = entry.key;
          final saldoReserva = entry.value;
          if (saldoReserva > 0) {
            await _movimentarEstoque(
              activeTenant: activeTenant,
              produtoId: pId,
              pedidoId: pedidoId,
              quantidade: saldoReserva,
              tipo: 'cancelamento',
              motivo: 'Estorno de reserva por edição — Pedido #${proxNumero.toString().padLeft(4, '0')}',
              operadorId: activeUser,
              now: now,
              isSaidaReserva: true,
            );
          }
        }
      }

      if (input.movimentarEstoque) {
        for (final item in input.itens) {
          final produto = await (_db.select(_db.produtosTable)
                ..where((t) => t.id.equals(item.produtoId)))
              .getSingleOrNull();

          if (produto == null || !produto.controlaEstoque) continue;

          if (input.isEntregaAgendada) {
            await _movimentarEstoque(
              activeTenant: activeTenant,
              produtoId: item.produtoId,
              pedidoId: pedidoId,
              quantidade: item.quantidade.toInt(),
              tipo: 'reserva',
              motivo: 'Reserva para entrega — Pedido #${proxNumero.toString().padLeft(4, '0')}',
              operadorId: activeUser,
              now: now,
              dataHoraMovimentacao: input.pedido.dataHoraCriacao.toLocal(),
              isEntradaReserva: true,
              dataEntregaPrevista: input.dataEntregaPrevista,
            );
          } else {
            await _movimentarEstoque(
              activeTenant: activeTenant,
              produtoId: item.produtoId,
              pedidoId: pedidoId,
              quantidade: item.quantidade.toInt(),
              tipo: 'saida',
              motivo: 'Venda PDV — Pedido #${proxNumero.toString().padLeft(4, '0')}',
              operadorId: activeUser,
              now: now,
              dataHoraMovimentacao: input.pedido.dataHoraCriacao.toLocal(),
            );
          }
        }
      } else {
        // Grava movimentações isentas como marcadores para que o reconciliador de estoque NUNCA baixe
        for (final item in input.itens) {
          await _db.into(_db.movimentacoesEstoqueTable).insert(
            MovimentacoesEstoqueTableCompanion.insert(
              id: _uuid.v4(),
              tenantId: activeTenant,
              produtoId: item.produtoId,
              pedidoId: Value(pedidoId),
              tipo: 'isento',
              quantidade: 0,
              quantidadeAntes: 0,
              quantidadeDepois: 0,
              motivo: Value('Isento de movimentação de estoque — Pedido #${proxNumero.toString().padLeft(4, '0')}'),
              operadorId: Value(activeUser),
              dataHora: input.pedido.dataHoraCriacao.toLocal(),
              syncVersion: const Value(1),
              syncStatus: SyncStatus.pending,
              createdAt: now,
              updatedAt: now,
              createdBy: activeUser,
              updatedBy: activeUser,
            ),
          );
        }
      }

      // ── 7. Lançamento financeiro (se houver sessão de caixa ativa e não for uso interno) ──────
      lancamentoId = await _criarLancamentoFinanceiro(
        activeTenant: activeTenant,
        activeUser: activeUser,
        pedidoId: pedidoId,
        proxNumero: proxNumero,
        valorTotalCentavos: input.pedido.valorTotalCentavos,
        formaPagamentoId: input.pedido.formaPagamentoId,
        paymentMethod: input.paymentMethod,
        dataHora: input.pedido.dataHoraCriacao.toLocal(),
        isUsoInterno: input.isUsoInterno,
      );

      // ── 8. Outbox — pedido ──────────────────────────────────────────────
      await _insertOutbox(
        activeTenant: activeTenant,
        entity: 'Pedido',
        entityId: pedidoId,
        action: action,
        payload: {
          'id': pedidoId,
          'tenantId': activeTenant,
          'clienteId': cleanClienteId,
          'clienteNomeAvulso': input.clienteNome,
          'clienteTelefoneAvulso': input.clienteTelefone,
          'tipoLogistica': input.pedido.tipoLogistica,
          'valorSubtotalCentavos': input.pedido.valorSubtotalCentavos,
          'valorTaxaEntregaCentavos': input.pedido.valorTaxaEntregaCentavos,
          'valorTaxaServicoCentavos': input.pedido.valorTaxaServicoCentavos,
          'valorTotalCentavos': input.pedido.valorTotalCentavos,
          'formaPagamentoId': input.pedido.formaPagamentoId,
          'formaPagamentoNome': input.paymentMethod,
          'trocoParaCentavos': input.pedido.trocoParaCentavos,
          'observacoes': input.pedido.observacoes,
          'isUsoInterno': input.isUsoInterno,
          'status': pedidoStatus,
          'canalOrigem': 'pdv_express',
          'operadorId': activeUser,
          'dataHoraCriacao': input.pedido.dataHoraCriacao.toUtc().toIso8601String(),
          if (input.dataEntregaPrevista != null)
            'dataHoraEntregaPrevista': input.dataEntregaPrevista!.toUtc().toIso8601String(),
          'numeroPedido': proxNumero,
          'enderecoJson': input.enderecoJson,
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        },
      );

      // ── 9. Outbox — itens ───────────────────────────────────────────────
      for (final item in input.itens) {
        await _insertOutbox(
          activeTenant: activeTenant,
          entity: 'itens_pedido',
          entityId: item.id,
          action: 'create',
          payload: {
            'id': item.id,
            'tenantId': activeTenant,
            'pedidoId': pedidoId,
            'produtoId': item.produtoId,
            'nomeProduto': item.nome,
            'quantidade': item.quantidade,
            'valorUnitarioCentavos': item.valorUnitarioCentavos,
            'valorTotalCentavos': item.valorTotalCentavos,
            'syncVersion': 1,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'createdBy': activeUser,
            'updatedBy': activeUser,
          },
        );
      }

      if (input.isEdit) {
        for (final oldItem in input.oldItems) {
          await _insertOutbox(
            activeTenant: activeTenant,
            entity: 'itens_pedido',
            entityId: oldItem.id,
            action: 'DELETE',
            payload: {'id': oldItem.id, 'tenantId': activeTenant},
          );
        }
      }

      // ── 10. Outbox — KDS ────────────────────────────────────────────────
      await _insertOutbox(
        activeTenant: activeTenant,
        entity: 'OrdemPreparo',
        entityId: ordemPreparoId,
        action: action,
        payload: {
          'id': ordemPreparoId,
          'tenantId': activeTenant,
          'pedidoId': pedidoId,
          'itensJson': kdsItensJson,
          'status': kdsStatus,
          'prioridade': input.isEntregaAgendada ? 'programado' : 'normal',
          'operadorId': activeUser,
          'criadaEm': input.pedido.dataHoraCriacao.toUtc().toIso8601String(),
          if (input.isRetroativo) 'concluidaEm': now.toIso8601String(),
          'tempoEstimadoSegundos': 0,
          'observacoes': observacoesKDS,
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        },
      );

      await _insertOutbox(
        activeTenant: activeTenant,
        entity: 'HistoricoOrdemPreparo',
        entityId: historicoId,
        action: 'create',
        payload: {
          'id': historicoId,
          'tenantId': activeTenant,
          'ordemPreparoId': ordemPreparoId,
          'titulo': kdsTitulo,
          'descricao': kdsDescricao,
          'operadorNome': input.operadorNome,
          'criadaEm': input.pedido.dataHoraCriacao.toUtc().toIso8601String(),
          'versao': 'v1',
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        },
      );

      // ── 11. Outbox — lançamento financeiro (se criado) ──────────────────
      if (lancamentoId != null) {
        final sessaoAtiva = await (_db.select(_db.sessoesCaixaTable)
              ..where((t) =>
                  t.tenantId.equals(activeTenant) &
                  t.status.equals('aberta') &
                  t.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();

        if (sessaoAtiva != null) {
          await _insertOutbox(
            activeTenant: activeTenant,
            entity: 'lancamento_financeiro',
            entityId: lancamentoId!,
            action: 'CREATE',
            payload: {
              'id': lancamentoId,
              'tenantId': activeTenant,
              'sessaoCaixaId': sessaoAtiva.id,
              'pedidoId': pedidoId,
              'tipo': 'receita',
              'formaPagamentoId': input.pedido.formaPagamentoId,
              'formaPagamentoNome': input.paymentMethod,
              'valorCentavos': input.pedido.valorTotalCentavos,
              'descricao': 'Venda PDV #${proxNumero.toString().padLeft(4, '0')}',
              'operadorId': activeUser,
              'dataHora': input.pedido.dataHoraCriacao.toUtc().toIso8601String(),
              'syncVersion': 1,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
              'createdBy': activeUser,
              'updatedBy': activeUser,
            },
          );
        }
      }
    });

    await LogService.instance.logOperational(
      process: processName,
      step: 'FINALIZACAO',
      action: 'RESULTADO',
      message: 'Pedido #${proxNumero.toString().padLeft(4, '0')} (ID: $pedidoId) registrado com sucesso | Ordem KDS: $ordemPreparoId',
      traceId: traceId,
      entityType: 'pedido',
      entityId: pedidoId,
      status: LogStatus.success,
      tenantId: activeTenant,
      userId: activeUser,
    );

    return ConfirmarVendaResult(
      pedidoId: pedidoId,
      numeroPedido: proxNumero,
      ordemPreparoId: ordemPreparoId,
      lancamentoFinanceiroId: lancamentoId,
    );
  }

  // ── Helpers privados ─────────────────────────────────────────────────────

  Future<int> _nextNumeroPedido(String tenantId) async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(MAX(numero_pedido), 0) + 1 AS prox '
      'FROM pedidos_table WHERE tenant_id = ?',
      variables: [Variable.withString(tenantId)],
    ).get();
    return (rows.first.data['prox'] as int?) ?? 1;
  }

  Future<String?> _criarLancamentoFinanceiro({
    required String activeTenant,
    required String activeUser,
    required String pedidoId,
    required int proxNumero,
    required int valorTotalCentavos,
    required String? formaPagamentoId,
    required String paymentMethod,
    required DateTime dataHora,
    required bool isUsoInterno,
  }) async {
    // Se for uso interno, consumo próprio ou cortesia, não gera movimentação financeira
    if (isUsoInterno) return null;

    final lowerMethod = paymentMethod.toLowerCase();
    if (lowerMethod.contains('consumo') || lowerMethod.contains('cortesia') || lowerMethod.contains('bonifica') || lowerMethod.contains('interno')) {
      return null;
    }

    String? bandeiraPadrao;
    if (formaPagamentoId != null) {
      final formaRow = await (_db.select(_db.formasPagamentoTable)
            ..where((t) => t.id.equals(formaPagamentoId) & t.tenantId.equals(activeTenant)))
          .getSingleOrNull();
      if (formaRow != null) {
        final rowNomeLower = formaRow.nome.toLowerCase();
        if (!formaRow.movimentaFinanceiro ||
            formaRow.isUsoInterno ||
            formaRow.tipo == 'consumo_interno' ||
            formaRow.tipo == 'consumo' ||
            rowNomeLower.contains('consumo') ||
            rowNomeLower.contains('cortesia') ||
            rowNomeLower.contains('bonifica')) {
          return null;
        }

        // Venda a Prazo / Faturado / Cartão (Débito e Crédito): não entram no caixa imediato;
        // serão liquidados/quitados via Contas a Receber da Adquirente / Cliente
        final isCartaoOuPrazo = formaRow.tipo == 'notaPrazo' ||
            formaRow.tipo == 'cartaoCredito' ||
            formaRow.tipo == 'cartaoDebito' ||
            formaRow.tipo == 'cartao' ||
            rowNomeLower.contains('prazo') ||
            rowNomeLower.contains('faturad') ||
            rowNomeLower.contains('cart') ||
            rowNomeLower.contains('créd') ||
            rowNomeLower.contains('cred') ||
            rowNomeLower.contains('déb') ||
            rowNomeLower.contains('deb');

        if (isCartaoOuPrazo) {
          return null;
        }

        bandeiraPadrao = formaRow.bandeiraPadrao;
      }
    }

    // Se o método de pagamento textual indicar a prazo ou cartão
    if (lowerMethod.contains('prazo') ||
        lowerMethod.contains('faturad') ||
        lowerMethod.contains('cart') ||
        lowerMethod.contains('créd') ||
        lowerMethod.contains('cred') ||
        lowerMethod.contains('déb') ||
        lowerMethod.contains('deb')) {
      return null;
    }

    final sessao = await (_db.select(_db.sessoesCaixaTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.status.equals('aberta') &
              t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();

    if (sessao == null) return null;

    final id = _uuid.v4();
    await _db.into(_db.lancamentosFinanceirosTable).insert(
      LancamentosFinanceirosTableCompanion.insert(
        id: id,
        tenantId: activeTenant,
        sessaoCaixaId: sessao.id,
        pedidoId: Value(pedidoId),
        tipo: 'receita',
        formaPagamentoId: Value(formaPagamentoId),
        formaPagamentoNome: Value(paymentMethod),
        valorCentavos: valorTotalCentavos,
        descricao: Value('Venda PDV #${proxNumero.toString().padLeft(4, '0')}'),
        operadorId: Value(activeUser),
        dataHora: dataHora,
        bandeira: Value(bandeiraPadrao),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        createdBy: activeUser,
        updatedBy: activeUser,
      ),
    );
    return id;
  }

  Future<void> _movimentarEstoque({
    required String activeTenant,
    required String produtoId,
    required String pedidoId,
    required int quantidade,
    required String tipo,
    required String motivo,
    required String operadorId,
    required DateTime now,
    DateTime? dataHoraMovimentacao,
    bool isEntradaFisica = false,
    bool isEntradaReserva = false,
    bool isSaidaFisica = false,
    bool isSaidaReserva = false,
    DateTime? dataEntregaPrevista,
  }) async {
    final dtMov = dataHoraMovimentacao ?? now;
    var estoque = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.produtoId.equals(produtoId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();

    final estoqueId = estoque?.id ?? _uuid.v4();

    if (estoque == null) {
      await _db.into(_db.estoqueProdutosTable).insertOnConflictUpdate(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: activeTenant,
          produtoId: produtoId,
          quantidadeAtual: const Value(0),
          quantidadeReservada: const Value(0),
          quantidadeMinima: const Value(0),
          quantidadeMaxima: const Value(9999),
          quantidadeProducaoLote: const Value(100),
          diasCoberturaAlvo: const Value(3),
          unidade: const Value('un'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );
      estoque = await (_db.select(_db.estoqueProdutosTable)
            ..where((t) => t.id.equals(estoqueId)))
          .getSingleOrNull();
    }

    final qFisicoAntes = estoque?.quantidadeAtual ?? 0;
    final qReservadaAntes = estoque?.quantidadeReservada ?? 0;
    int qFisicoDepois = qFisicoAntes;
    int qReservadaDepois = qReservadaAntes;

    if (isEntradaFisica) {
      qFisicoDepois += quantidade;
    } else if (isEntradaReserva) {
      qReservadaDepois += quantidade;
    } else if (isSaidaFisica && isSaidaReserva) {
      qFisicoDepois = (qFisicoDepois - quantidade).clamp(-999999, 999999);
      qReservadaDepois = (qReservadaDepois - quantidade).clamp(0, 999999);
    } else if (isSaidaReserva) {
      qReservadaDepois = (qReservadaDepois - quantidade).clamp(0, 999999);
    } else {
      qFisicoDepois = (qFisicoDepois - quantidade).clamp(-999999, 999999);
    }

    await (_db.update(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId)))
        .write(EstoqueProdutosTableCompanion(
      quantidadeAtual: Value(qFisicoDepois),
      quantidadeReservada: Value(qReservadaDepois),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncVersion: const Value(1),
      syncStatus: const Value(SyncStatus.pending),
    ));

    final movId = _uuid.v4();
    await _db.into(_db.movimentacoesEstoqueTable).insert(
      MovimentacoesEstoqueTableCompanion.insert(
        id: movId,
        tenantId: activeTenant,
        produtoId: produtoId,
        pedidoId: Value(pedidoId),
        tipo: tipo,
        quantidade: quantidade,
        quantidadeAntes: qFisicoAntes,
        quantidadeDepois: qFisicoDepois,
        quantidadeReservadaAntes: Value(qReservadaAntes),
        quantidadeReservadaDepois: Value(qReservadaDepois),
        motivo: Value(motivo),
        operadorId: Value(operadorId),
        dataHora: dtMov,
        dataEntregaPrevista: Value(dataEntregaPrevista),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );

    await _insertOutbox(
      activeTenant: activeTenant,
      entity: 'movimentacao_estoque',
      entityId: movId,
      action: 'create',
      payload: {
        'id': movId,
        'tenantId': activeTenant,
        'produtoId': produtoId,
        'pedidoId': pedidoId,
        'tipo': tipo,
        'quantidade': quantidade,
        'quantidadeAntes': qFisicoAntes,
        'quantidadeDepois': qFisicoDepois,
        'quantidadeReservadaAntes': qReservadaAntes,
        'quantidadeReservadaDepois': qReservadaDepois,
        'motivo': motivo,
        'operadorId': operadorId,
        'dataHora': dtMov.toUtc().toIso8601String(),
        if (dataEntregaPrevista != null)
          'dataEntregaPrevista': dataEntregaPrevista.toUtc().toIso8601String(),
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      },
    );

    await _insertOutbox(
      activeTenant: activeTenant,
      entity: 'estoque_produto',
      entityId: estoqueId,
      action: 'upsert',
      payload: {
        'id': estoqueId,
        'tenantId': activeTenant,
        'produtoId': produtoId,
        'quantidadeAtual': qFisicoDepois,
        'quantidadeReservada': qReservadaDepois,
        'quantidadeMinima': estoque?.quantidadeMinima ?? 0,
        'quantidadeMaxima': estoque?.quantidadeMaxima ?? 9999,
        'quantidadeProducaoLote': estoque?.quantidadeProducaoLote ?? 100,
        'diasCoberturaAlvo': estoque?.diasCoberturaAlvo ?? 3,
        'unidade': estoque?.unidade ?? 'un',
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      },
    );
  }

  Future<void> _insertOutbox({
    required String activeTenant,
    required String entity,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final outboxService = DependencyInjection().get<OutboxService>();
      await outboxService.enqueue(
        entity: entity,
        entityId: entityId,
        action: action.toUpperCase(),
        payload: payload,
        version: (payload['syncVersion'] as num?)?.toInt() ?? 1,
      );

      final syncEngine = DependencyInjection().get<SyncEngine>();
      syncEngine.processPendingQueue();
    } catch (_) {
      await _db.into(_db.outboxSync).insert(OutboxSyncCompanion.insert(
        tenantId: activeTenant,
        entity: entity,
        entityId: entityId,
        action: action,
        payload: jsonEncode(payload),
        status: 'pending',
        version: 1,
        createdAt: DateTime.now().toUtc(),
      ));
    }
  }
}
