import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../domain/ports/pedido_repository_port.dart';
import '../../models/domain_models.dart';

class PedidoRepository implements IPedidoRepository {
  final AppDatabase db;
  PedidoRepository(this.db);

  @override
  Stream<List<Pedido>> observar({String busca = ''}) {
    final q = db.select(db.pedidos)
      ..orderBy([(p) => OrderingTerm.desc(p.criadoEm)]);
    if (busca.trim().isNotEmpty) {
      q.where((p) =>
          p.clienteNome.contains(busca) |
          p.clienteTelefone.contains(busca) |
          p.numero.cast<String>().contains(busca));
    }
    return q.watch();
  }

  @override
  Future<int> criar({
    required Cliente cliente,
    required DateTime entrega,
    required String tipo,
    required String pagamento,
    required int? troco,
    required String observacoes,
    required int taxa,
    required List<ItemCarrinho> itens,
    String prioridade = 'Normal',
    int? origemId,
    int? prioridadeId,
    DateTime? dataProducao,
    String statusFinanceiro = 'Pendente',
  }) =>
      db.transaction(() async {
        final numero = await db.proximoNumero();
        final subtotal = itens.fold<int>(0, (v, i) => v + i.totalCentavos);
        final id = await db.into(db.pedidos).insert(PedidosCompanion.insert(
            numero: numero,
            clienteId: cliente.id,
            clienteNome: cliente.nome,
            clienteTelefone: Value(cliente.telefone),
            dataEntrega: entrega,
            tipoEntrega: tipo,
            formaPagamento: pagamento,
            trocoParaCentavos: Value(troco),
            observacoes: Value(observacoes),
            subtotalCentavos: subtotal,
            taxaEntregaCentavos: Value(taxa),
            totalCentavos: subtotal + taxa,
            prioridade: Value(prioridade),
            versao: const Value(1),
            status: const Value('Pendente'),
            origemId: Value(origemId),
            prioridadeId: Value(prioridadeId),
            dataProducao: Value(dataProducao),
            statusFinanceiro: Value(statusFinanceiro)));

        // Registrar Evento CRIADO
        final itensDesc = itens.map((i) => '${i.quantidade}x ${i.produto.nome}').join(', ');
        await registrarEvento(
          pedidoId: id,
          tipoEvento: 'CRIADO',
          titulo: 'Pedido criado',
          descricao: 'Itens: $itensDesc',
          versao: 1,
        );

        if (pagamento.toLowerCase().contains('pix')) {
          await registrarEvento(
            pedidoId: id,
            tipoEvento: 'PIX_GERADO',
            titulo: 'PIX Copia e Cola gerado',
            descricao: 'Aguardando confirmação de pagamento do PIX.',
            versao: 1,
          );
        }

        for (final i in itens) {
          await db.into(db.itensPedido).insert(ItensPedidoCompanion.insert(
              pedidoId: id,
              produtoId: i.produto.id,
              produtoNome: i.produto.nome,
              quantidade: i.quantidade,
              valorUnitarioCentavos: i.valorUnitarioCentavos,
              valorTotalCentavos: i.totalCentavos));

          // RESERVA DE ESTOQUE (apenas se o produto controlar estoque)
          if (i.produto.controlaEstoque) {
            final est = await (db.select(db.estoqueAtual)
                  ..where((e) => e.produtoId.equals(i.produto.id)))
                .getSingleOrNull();

            final reservadoAnterior = est?.reservado ?? 0;
            final reservadoNovo = reservadoAnterior + i.quantidade;
            final comercialAnterior = est?.reservadoComercial ?? 0;
            final comercialNovo = comercialAnterior + i.quantidade;

            await db.into(db.estoqueAtual).insertOnConflictUpdate(
                  EstoqueAtualCompanion(
                    produtoId: Value(i.produto.id),
                    reservado: Value(reservadoNovo),
                    reservadoComercial: Value(comercialNovo),
                    atualizadoEm: Value(DateTime.now()),
                  ),
                );

            await db.into(db.movimentacoesEstoque).insert(
                  MovimentacoesEstoqueCompanion(
                    produtoId: Value(i.produto.id),
                    tipoMovimentacao: const Value('RESERVA'),
                    quantidade: Value(i.quantidade),
                    saldoAnterior: Value(reservadoAnterior),
                    saldoNovo: Value(reservadoNovo),
                    motivo: Value('Reserva para Pedido #$numero'),
                    pedidoId: Value(id),
                    criadoEm: Value(DateTime.now()),
                  ),
                );
          }
        }
        return id;
      });

  @override
  Future<PedidoCompleto> completo(int id) async {
    final p = await (db.select(db.pedidos)..where((p) => p.id.equals(id)))
        .getSingle();
    final c = await (db.select(db.clientes)
          ..where((c) => c.id.equals(p.clienteId)))
        .getSingle();
    final i = await (db.select(db.itensPedido)
          ..where((i) => i.pedidoId.equals(id)))
        .get();
    return PedidoCompleto(p, c, i);
  }

  bool _isValidTransition(String atual, String novo, String tipoEntrega) {
    if (atual == novo) return true;
    if (atual == 'Cancelado' || atual == 'Finalizado') return false;
    if (novo == 'Cancelado') return true;

    switch (atual) {
      case 'Pendente':
        return novo == 'Em Preparo';
      case 'Em Preparo':
        return novo == 'Pronto';
      case 'Pronto':
        if (tipoEntrega.toLowerCase() == 'entrega') {
          return novo == 'Em Rota';
        } else {
          return novo == 'Aguardando Cliente';
        }
      case 'Em Rota':
      case 'Aguardando Cliente':
        return novo == 'Finalizado';
      default:
        return false;
    }
  }

  @override
  Future<void> alterarStatus(int id, String novoStatus) async {
    await db.transaction(() async {
      // 1. Obter pedido e verificar transição
      final p = await (db.select(db.pedidos)..where((pedido) => pedido.id.equals(id))).getSingle();
      final statusAnterior = p.status;
      if (statusAnterior == novoStatus) return;

      if (!_isValidTransition(statusAnterior, novoStatus, p.tipoEntrega)) {
        throw Exception('Transição de status inválida de "$statusAnterior" para "$novoStatus"');
      }

      // 2. Atualizar status no banco
      await (db.update(db.pedidos)..where((pedido) => pedido.id.equals(id)))
          .write(PedidosCompanion(status: Value(novoStatus)));

      // Registrar Evento STATUS
      await registrarEvento(
        pedidoId: id,
        tipoEvento: 'STATUS',
        titulo: 'Status alterado',
        descricao: 'Passou de "$statusAnterior" para "$novoStatus"',
        versao: p.versao,
      );

      // 3. Processar transição de estoque
      final itens = await (db.select(db.itensPedido)..where((item) => item.pedidoId.equals(id))).get();
      final isEntrega = p.tipoEntrega.toLowerCase() == 'entrega';

      bool eraAtivo = _isStatusAtivo(statusAnterior);
      bool eraFinalizado = _isStatusFinalizado(statusAnterior);
      bool eraCancelado = statusAnterior == 'Cancelado';

      bool ehAtivo = _isStatusAtivo(novoStatus);
      bool ehFinalizado = _isStatusFinalizado(novoStatus);
      bool ehCancelado = novoStatus == 'Cancelado';

      for (final item in itens) {
        final prod = await (db.select(db.produtos)..where((pr) => pr.id.equals(item.produtoId))).getSingleOrNull();
        if (prod == null || !prod.controlaEstoque) continue;

        final est = await (db.select(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId))).getSingleOrNull();
        int saldoAtual = est?.saldoAtual ?? 0;
        int reservado = est?.reservado ?? 0;
        int comercialAnterior = est?.reservadoComercial ?? 0;

        String tipoMov = '';
        int saldoNovo = saldoAtual;
        int reservadoNovo = reservado;
        int comercialNovo = comercialAnterior;
        String motivo = '';

        if (eraAtivo && ehFinalizado) {
          saldoNovo = (saldoAtual - item.quantidade).clamp(0, 999999);
          reservadoNovo = (reservado - item.quantidade).clamp(0, 999999);
          comercialNovo = (comercialAnterior - item.quantidade).clamp(0, 999999);
          tipoMov = isEntrega ? 'BAIXA_ENTREGA' : 'BAIXA_RETIRADA';
          motivo = 'Baixa definitiva do Pedido #${p.numero} (Status: $novoStatus)';
        } else if (eraAtivo && ehCancelado) {
          reservadoNovo = (reservado - item.quantidade).clamp(0, 999999);
          comercialNovo = (comercialAnterior - item.quantidade).clamp(0, 999999);
          tipoMov = 'LIBERACAO_RESERVA';
          motivo = 'Cancelamento do Pedido #${p.numero}';
        } else if (eraCancelado && ehAtivo) {
          reservadoNovo = reservado + item.quantidade;
          comercialNovo = comercialAnterior + item.quantidade;
          tipoMov = 'RESERVA';
          motivo = 'Reativação do Pedido #${p.numero}';
        } else if (eraCancelado && ehFinalizado) {
          saldoNovo = (saldoAtual - item.quantidade).clamp(0, 999999);
          tipoMov = isEntrega ? 'BAIXA_ENTREGA' : 'BAIXA_RETIRADA';
          motivo = 'Baixa direta do Pedido #${p.numero} (antes cancelado)';
        } else if (eraFinalizado && ehAtivo) {
          saldoNovo = saldoAtual + item.quantidade;
          reservadoNovo = reservado + item.quantidade;
          comercialNovo = comercialAnterior + item.quantidade;
          tipoMov = 'AJUSTE_POSITIVO';
          motivo = 'Estorno de baixa/Reativação do Pedido #${p.numero}';
        } else if (eraFinalizado && ehCancelado) {
          saldoNovo = saldoAtual + item.quantidade;
          tipoMov = 'AJUSTE_POSITIVO';
          motivo = 'Estorno de baixa por cancelamento do Pedido #${p.numero}';
        }

        if (tipoMov.isNotEmpty) {
          await db.into(db.estoqueAtual).insertOnConflictUpdate(
                EstoqueAtualCompanion(
                  produtoId: Value(item.produtoId),
                  saldoAtual: Value(saldoNovo),
                  reservado: Value(reservadoNovo),
                  reservadoComercial: Value(comercialNovo),
                  atualizadoEm: Value(DateTime.now()),
                ),
              );

          final int logAnterior = (tipoMov == 'RESERVA' || tipoMov == 'LIBERACAO_RESERVA') ? reservado : saldoAtual;
          final int logNovo = (tipoMov == 'RESERVA' || tipoMov == 'LIBERACAO_RESERVA') ? reservadoNovo : saldoNovo;

          await db.into(db.movimentacoesEstoque).insert(
                MovimentacoesEstoqueCompanion(
                  produtoId: Value(item.produtoId),
                  tipoMovimentacao: Value(tipoMov),
                  quantidade: Value(item.quantidade),
                  saldoAnterior: Value(logAnterior),
                  saldoNovo: Value(logNovo),
                  motivo: Value(motivo),
                  pedidoId: Value(id),
                  criadoEm: Value(DateTime.now()),
                ),
              );
        }
      }
    });
  }

  bool _isStatusAtivo(String status) =>
      status == 'Pendente' ||
      status == 'Em Preparo' ||
      status == 'Pronto' ||
      status == 'Em Rota' ||
      status == 'Aguardando Cliente';

  bool _isStatusFinalizado(String status) => status == 'Finalizado';

  @override
  Future<int> duplicar(int id) async {
    final original = await completo(id);
    final p = original.pedido;

    final itensCarrinho = <ItemCarrinho>[];
    for (final item in original.itens) {
      final produto = await (db.select(db.produtos)
            ..where((prod) => prod.id.equals(item.produtoId)))
          .getSingleOrNull();

      if (produto != null && produto.grupoPrecoId != null) {
        final grupo = await (db.select(db.gruposPreco)
              ..where((g) => g.id.equals(produto.grupoPrecoId!)))
          .getSingleOrNull();

        if (grupo != null) {
          itensCarrinho.add(
            ItemCarrinho(
              produto: produto,
              grupo: grupo,
              quantidade: item.quantidade,
              valorUnitarioCentavos: item.valorUnitarioCentavos,
            ),
          );
        }
      }
    }

    return criar(
      cliente: original.cliente,
      entrega: DateTime.now().add(const Duration(hours: 2)),
      tipo: p.tipoEntrega,
      pagamento: p.formaPagamento,
      troco: p.trocoParaCentavos,
      observacoes: p.observacoes.isNotEmpty ? '${p.observacoes} (Duplicado)' : 'Duplicado',
      taxa: p.taxaEntregaCentavos,
      itens: itensCarrinho,
      prioridade: p.prioridade,
    );
  }

  @override
  Future<void> cancelar(int id) async {
    await db.transaction(() async {
      final p = await (db.select(db.pedidos)..where((pedido) => pedido.id.equals(id))).getSingle();
      if (p.status == 'Finalizado') {
        throw Exception('Não é possível cancelar um pedido finalizado.');
      }
      await alterarStatus(id, 'Cancelado');
      await registrarEvento(
        pedidoId: id,
        tipoEvento: 'CANCELAMENTO',
        titulo: 'Pedido cancelado',
        descricao: 'Cancelamento efetuado com sucesso.',
        versao: p.versao,
      );
    });
  }

  @override
  Future<void> editar({
    required int id,
    required Cliente cliente,
    required DateTime entrega,
    required String tipo,
    required String pagamento,
    required int? troco,
    required String observacoes,
    required int taxa,
    required List<ItemCarrinho> itens,
    String prioridade = 'Normal',
    int? origemId,
    int? prioridadeId,
    DateTime? dataProducao,
    String statusFinanceiro = 'Pendente',
  }) async {
    await db.transaction(() async {
      // 1. Obter pedido e itens antigos
      final p = await (db.select(db.pedidos)..where((pedido) => pedido.id.equals(id))).getSingle();
      if (p.status == 'Finalizado' || p.status == 'Cancelado') {
        throw Exception('Não é possível editar pedidos com status "${p.status}".');
      }

      final itensAntigos = await (db.select(db.itensPedido)..where((item) => item.pedidoId.equals(id))).get();
      final status = p.status;
      final novaVersao = p.versao + 1;

      // 2. Reverter impacto de estoque dos itens antigos
      for (final item in itensAntigos) {
        final prod = await (db.select(db.produtos)..where((pr) => pr.id.equals(item.produtoId))).getSingleOrNull();
        if (prod == null || !prod.controlaEstoque) continue;

        final est = await (db.select(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId))).getSingleOrNull();
        if (est == null) continue;

        int saldoFisico = est.saldoAtual;
        int reservado = est.reservado;
        int comercial = est.reservadoComercial;

        if (_isStatusAtivo(status)) {
          final novoReservado = (reservado - item.quantidade).clamp(0, 999999);
          final novoComercial = (comercial - item.quantidade).clamp(0, 999999);
          await (db.update(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId)))
              .write(EstoqueAtualCompanion(
                reservado: Value(novoReservado),
                reservadoComercial: Value(novoComercial),
              ));
        } else if (_isStatusFinalizado(status)) {
          final novoSaldo = saldoFisico + item.quantidade;
          await (db.update(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId)))
              .write(EstoqueAtualCompanion(saldoAtual: Value(novoSaldo)));
        }
      }

      // 3. Deletar itens antigos
      await (db.delete(db.itensPedido)..where((item) => item.pedidoId.equals(id))).go();

      // 4. Atualizar metadados do pedido
      final subtotal = itens.fold<int>(0, (v, i) => v + i.totalCentavos);
      await (db.update(db.pedidos)..where((pedido) => pedido.id.equals(id)))
          .write(PedidosCompanion(
              clienteId: Value(cliente.id),
              clienteNome: Value(cliente.nome),
              clienteTelefone: Value(cliente.telefone),
              dataEntrega: Value(entrega),
              tipoEntrega: Value(tipo),
              formaPagamento: Value(pagamento),
              trocoParaCentavos: Value(troco),
              observacoes: Value(observacoes),
              subtotalCentavos: Value(subtotal),
              taxaEntregaCentavos: Value(taxa),
              totalCentavos: Value(subtotal + taxa),
              prioridade: Value(prioridade),
              versao: Value(novaVersao),
              origemId: Value(origemId),
              prioridadeId: Value(prioridadeId),
              dataProducao: Value(dataProducao),
              statusFinanceiro: Value(statusFinanceiro)));

      // Registrar Evento EDITADO
      final descAntigos = itensAntigos.map((i) => '${i.quantidade}x ${i.produtoNome}').join(', ');
      final descNovos = itens.map((i) => '${i.quantidade}x ${i.produto.nome}').join(', ');
      await registrarEvento(
        pedidoId: id,
        tipoEvento: 'EDITADO',
        titulo: 'Pedido editado (v$novaVersao)',
        descricao: 'Antes: $descAntigos\nDepois: $descNovos',
        versao: novaVersao,
      );

      // 5. Inserir novos itens e aplicar estoque
      for (final i in itens) {
        await db.into(db.itensPedido).insert(ItensPedidoCompanion.insert(
            pedidoId: id,
            produtoId: i.produto.id,
            produtoNome: i.produto.nome,
            quantidade: i.quantidade,
            valorUnitarioCentavos: i.valorUnitarioCentavos,
            valorTotalCentavos: i.totalCentavos));

        if (i.produto.controlaEstoque) {
          final est = await (db.select(db.estoqueAtual)
                ..where((e) => e.produtoId.equals(i.produto.id)))
              .getSingleOrNull();

          final saldoFisico = est?.saldoAtual ?? 0;
          final reservado = est?.reservado ?? 0;
          final comercial = est?.reservadoComercial ?? 0;

          if (_isStatusAtivo(status)) {
            final novoReservado = reservado + i.quantidade;
            final novoComercial = comercial + i.quantidade;
            await db.into(db.estoqueAtual).insertOnConflictUpdate(
                  EstoqueAtualCompanion(
                    produtoId: Value(i.produto.id),
                    reservado: Value(novoReservado),
                    reservadoComercial: Value(novoComercial),
                    atualizadoEm: Value(DateTime.now()),
                  ),
                );
          } else if (_isStatusFinalizado(status)) {
            final novoSaldo = (saldoFisico - i.quantidade).clamp(0, 999999);
            await db.into(db.estoqueAtual).insertOnConflictUpdate(
                  EstoqueAtualCompanion(
                    produtoId: Value(i.produto.id),
                    saldoAtual: Value(novoSaldo),
                    atualizadoEm: Value(DateTime.now()),
                  ),
                );
          }
        }
      }
    });
  }

  // Eventos & Auditoria
  @override
  Future<List<EventosPedidoData>> obterEventos(int pedidoId) {
    return (db.select(db.eventosPedido)
          ..where((e) => e.pedidoId.equals(pedidoId))
          ..orderBy([(e) => OrderingTerm.desc(e.criadoEm)]))
        .get();
  }

  @override
  Future<void> registrarEvento({
    required int pedidoId,
    required String tipoEvento,
    required String titulo,
    required String descricao,
    int? usuarioId,
    String? usuarioNome,
    required int versao,
  }) async {
    await db.into(db.eventosPedido).insert(EventosPedidoCompanion.insert(
          pedidoId: pedidoId,
          tipoEvento: tipoEvento,
          titulo: titulo,
          descricao: Value(descricao),
          usuarioId: Value(usuarioId),
          usuarioNome: Value(usuarioNome ?? 'Operador'),
          versao: Value(versao),
          criadoEm: Value(DateTime.now()),
        ));
  }

  @override
  Future<void> reabrirPedido({
    required int pedidoId,
    required String novoStatus,
    required String motivo,
    required String observacao,
  }) async {
    await db.transaction(() async {
      final p = await (db.select(db.pedidos)..where((ped) => ped.id.equals(pedidoId))).getSingle();
      final novaVersao = p.versao + 1;

      // Atualizar status e versão no banco
      await (db.update(db.pedidos)..where((ped) => ped.id.equals(pedidoId)))
          .write(PedidosCompanion(
            status: Value(novoStatus),
            versao: Value(novaVersao),
          ));

      // Tratar re-ativação de estoque (se estava finalizado)
      final itens = await (db.select(db.itensPedido)..where((item) => item.pedidoId.equals(pedidoId))).get();
      if (p.status == 'Finalizado') {
        for (final item in itens) {
          final prod = await (db.select(db.produtos)..where((pr) => pr.id.equals(item.produtoId))).getSingleOrNull();
          if (prod == null || !prod.controlaEstoque) continue;

          final est = await (db.select(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId))).getSingleOrNull();
          if (est == null) continue;

          final saldoNovo = est.saldoAtual + item.quantidade;
          final reservadoNovo = est.reservado + item.quantidade;

          await db.into(db.estoqueAtual).insertOnConflictUpdate(
                EstoqueAtualCompanion(
                  produtoId: Value(item.produtoId),
                  saldoAtual: Value(saldoNovo),
                  reservado: Value(reservadoNovo),
                  atualizadoEm: Value(DateTime.now()),
                ),
              );
        }
      }

      // Registrar Evento de Reabertura
      await registrarEvento(
        pedidoId: pedidoId,
        tipoEvento: 'REABERTURA',
        titulo: 'Pedido reaberto (v$novaVersao)',
        descricao: 'Motivo: $motivo\nObs: $observacao\nStatus redefinido para: $novoStatus',
        versao: novaVersao,
      );
    });
  }

  @override
  Future<void> reverterStatus({
    required int pedidoId,
    required String statusAnterior,
    required String motivo,
    required String observacao,
  }) async {
    await db.transaction(() async {
      final p = await (db.select(db.pedidos)..where((ped) => ped.id.equals(pedidoId))).getSingle();
      final novaVersao = p.versao + 1;

      // Registrar Evento
      await registrarEvento(
        pedidoId: pedidoId,
        tipoEvento: 'STATUS',
        titulo: 'Etapa revertida',
        descricao: 'Motivo: $motivo\nObs: $observacao\nVoltou de "${p.status}" para "$statusAnterior"',
        versao: novaVersao,
      );

      // Atualizar status e versão no banco
      await (db.update(db.pedidos)..where((ped) => ped.id.equals(pedidoId)))
          .write(PedidosCompanion(
            status: Value(statusAnterior),
            versao: Value(novaVersao),
          ));

      // Ajustar estoque se estava Finalizado e voltou para Ativo
      if (p.status == 'Finalizado' && _isStatusAtivo(statusAnterior)) {
        final itens = await (db.select(db.itensPedido)..where((item) => item.pedidoId.equals(pedidoId))).get();
        for (final item in itens) {
          final prod = await (db.select(db.produtos)..where((pr) => pr.id.equals(item.produtoId))).getSingleOrNull();
          if (prod == null || !prod.controlaEstoque) continue;

          final est = await (db.select(db.estoqueAtual)..where((e) => e.produtoId.equals(item.produtoId))).getSingleOrNull();
          if (est == null) continue;

          final saldoNovo = est.saldoAtual + item.quantidade;
          final reservadoNovo = est.reservado + item.quantidade;

          await db.into(db.estoqueAtual).insertOnConflictUpdate(
                EstoqueAtualCompanion(
                  produtoId: Value(item.produtoId),
                  saldoAtual: Value(saldoNovo),
                  reservado: Value(reservadoNovo),
                  atualizadoEm: Value(DateTime.now()),
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> confirmarPix({
    required int pedidoId,
    required String comprovantePix,
  }) async {
    final p = await (db.select(db.pedidos)..where((ped) => ped.id.equals(pedidoId))).getSingle();
    await (db.update(db.pedidos)..where((ped) => ped.id.equals(pedidoId)))
        .write(PedidosCompanion(
          pixConfirmado: const Value(true),
          pixConfirmadoEm: Value(DateTime.now()),
          comprovantePix: Value(comprovantePix),
        ));

    await registrarEvento(
      pedidoId: pedidoId,
      tipoEvento: 'PIX_CONFIRMADO',
      titulo: 'PIX Confirmado',
      descricao: 'Pagamento PIX confirmado com sucesso. Ref: $comprovantePix',
      versao: p.versao,
    );
  }
}
