import '../common/kds_models.dart';
import '../common/domain_primitives.dart';
import '../repository/lote_insumo_repository.dart';

/// Caso de Uso: Estornar Estoque de Lotes de Insumos (LIFO)
///
/// Restaura a quantidade de estoque quando uma ordem é cancelada ou estornada.
/// Segue a política LIFO (Last-In, First-Out) no estorno para garantir que
/// a devolução dos itens seja feita priorizando o lote que foi abastecido mais
/// recentemente, preservando o consumo FIFO original das matérias-primas mais antigas.
class EstornarLoteEstoqueUseCase {
  final LoteInsumoRepository _loteRepository;

  EstornarLoteEstoqueUseCase({required LoteInsumoRepository loteRepository})
    : _loteRepository = loteRepository;

  /// Executa o estorno de estoque para um produto específico.
  ///
  /// [produtoId] - ID do produto/insumo a ser estornado.
  /// [quantidadeCenteseimosEstornar] - Quantidade inteira em centésimos a devolver (ex: 2.50 un = 250).
  ///
  /// Retorna um [ResultadoEstorno] detalhando a operação.
  Future<ResultadoEstorno> execute({
    required String produtoId,
    required int quantidadeCenteseimosEstornar,
    required String operadorId,
  }) async {
    if (quantidadeCenteseimosEstornar <= 0) {
      return const ResultadoEstorno(
        lotesAtualizados: [],
        quantidadeDevolvida: 0,
        quantidadeNaoDevolvida: 0,
        mensagem: 'Quantidade para estorno inválida ou zerada.',
      );
    }

    // Busca lotes disponíveis e ativos em ordem LIFO (mais novos primeiro)
    final lotes = await _loteRepository.findLotesParaEstornoLIFO(produtoId);

    if (lotes.isEmpty) {
      return ResultadoEstorno(
        lotesAtualizados: const [],
        quantidadeDevolvida: 0,
        quantidadeNaoDevolvida: quantidadeCenteseimosEstornar,
        mensagem:
            'Nenhum lote ativo encontrado para estornar o produto $produtoId.',
      );
    }

    int restante = quantidadeCenteseimosEstornar;
    final List<LoteInsumo> atualizados = [];

    for (final lote in lotes) {
      if (restante <= 0) break;

      // Espaço livre no lote para estorno (não podemos exceder a capacidade inicial do lote original)
      final capacidadeLivre =
          lote.quantidadeInicial - lote.quantidadeDisponivel;

      if (capacidadeLivre <= 0) {
        // Lote já está em capacidade máxima. Avança para o próximo mais recente.
        continue;
      }

      // Quantidade que efetivamente devolveremos a este lote
      final quantDevolverLote =
          restante > capacidadeLivre ? capacidadeLivre : restante;

      final novoDisponivel = lote.quantidadeDisponivel + quantDevolverLote;

      final loteAtualizado = lote.copyWith(
        quantidadeDisponivel: novoDisponivel,
        statusLote: StatusLoteInsumo.ativo, // Garante que o lote continue ativo
        metadata: SyncMetadata(
          version: lote.metadata.version + 1,
          createdAt: lote.metadata.createdAt,
          updatedAt: DateTime.now(),
          createdBy: lote.metadata.createdBy,
          updatedBy: operadorId,
          syncStatus: SyncStatus.pending,
        ),
      );

      atualizados.add(loteAtualizado);
      restante -= quantDevolverLote;
    }

    // Salva as alterações de estoque no banco de dados de forma transacional
    for (final lote in atualizados) {
      await _loteRepository.save(lote);
    }

    final devolvida = quantidadeCenteseimosEstornar - restante;
    final msg =
        restante == 0
            ? 'Estorno LIFO concluído com sucesso. R\$ ${(devolvida / 100).toStringAsFixed(2)} unidades devolvidas aos lotes ativos.'
            : 'Estorno LIFO parcial. Devolvido: ${(devolvida / 100).toStringAsFixed(2)}. Sobrou sem lote correspondente: ${(restante / 100).toStringAsFixed(2)} devido ao limite de capacidade dos lotes.';

    return ResultadoEstorno(
      lotesAtualizados: atualizados,
      quantidadeDevolvida: devolvida,
      quantidadeNaoDevolvida: restante,
      mensagem: msg,
    );
  }
}
