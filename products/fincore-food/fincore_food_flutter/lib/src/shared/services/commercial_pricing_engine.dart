import 'package:flutter/foundation.dart';

/// Estratégias de comercialização suportadas pelo FINCORE FOOD ERP
enum EstrategiaComercializacao {
  unitario,
  porPeso,
  porQuantidade,
  porVolume,
  personalizado,
}

extension EstrategiaComercializacaoExt on EstrategiaComercializacao {
  String get label {
    switch (this) {
      case EstrategiaComercializacao.unitario:
        return 'Preço Fixo (Unitário)';
      case EstrategiaComercializacao.porPeso:
        return 'Por Peso (R\$ / Kg)';
      case EstrategiaComercializacao.porQuantidade:
        return 'Política Comercial (Faixa em Grupo)';
      case EstrategiaComercializacao.porVolume:
        return 'Por Volume (R\$ / Litro)';
      case EstrategiaComercializacao.personalizado:
        return 'Fracionado / Variável';
    }
  }
}

/// Categorias de Itens de Estoque no ERP
enum TipoItemEstoque {
  produtoAcabado,
  insumoSemiacabado,
  materiaPrima,
  embalagem,
  servico,
}

extension TipoItemEstoqueExt on TipoItemEstoque {
  String get label {
    switch (this) {
      case TipoItemEstoque.produtoAcabado:
        return 'Produto Acabado';
      case TipoItemEstoque.insumoSemiacabado:
        return 'Insumo / Semiacabado';
      case TipoItemEstoque.materiaPrima:
        return 'Matéria-Prima';
      case TipoItemEstoque.embalagem:
        return 'Embalagem';
      case TipoItemEstoque.servico:
        return 'Serviço';
    }
  }
}

/// Modos de Produção Comercial
enum ModoProducao {
  sobDemanda,
  emLote,
  congelado,
}

extension ModoProducaoExt on ModoProducao {
  String get label {
    switch (this) {
      case ModoProducao.sobDemanda:
        return 'Sob Demanda (Ao pedir)';
      case ModoProducao.emLote:
        return 'Em Lote (Antecipado em escala)';
      case ModoProducao.congelado:
        return 'Estoque Congelado';
    }
  }
}

/// Perfil de Cliente para Cotações Comerciais
enum PerfilCliente {
  pessoaFisica,
  pessoaJuridica,
  clienteVip,
  revendaAtacado,
}

extension PerfilClienteExt on PerfilCliente {
  String get label {
    switch (this) {
      case PerfilCliente.pessoaFisica:
        return 'Pessoa Física (Varejo)';
      case PerfilCliente.pessoaJuridica:
        return 'Pessoa Jurídica (Empresa)';
      case PerfilCliente.clienteVip:
        return 'Cliente VIP / Fidelidade';
      case PerfilCliente.revendaAtacado:
        return 'Revenda / Atacado';
    }
  }

  double get fatorDesconto {
    switch (this) {
      case PerfilCliente.pessoaFisica:
        return 1.0;
      case PerfilCliente.pessoaJuridica:
        return 0.97; // 3% desc
      case PerfilCliente.clienteVip:
        return 0.95; // 5% desc
      case PerfilCliente.revendaAtacado:
        return 0.90; // 10% desc
    }
  }
}

/// Canal de Venda Comercial
enum CanalVenda {
  pdvBalcao,
  deliveryApp,
  ifood,
  whatsapp,
}

extension CanalVendaExt on CanalVenda {
  String get label {
    switch (this) {
      case CanalVenda.pdvBalcao:
        return 'PDV / Balcão Presencial';
      case CanalVenda.deliveryApp:
        return 'Delivery Proprio App';
      case CanalVenda.ifood:
        return 'Marketplace iFood';
      case CanalVenda.whatsapp:
        return 'WhatsApp Bot';
    }
  }
}

/// Faixa de precificação por quantidade acumulada no grupo comercial
class FaixaPrecificacaoModel {
  final String id;
  final double quantidadeMinima;
  final double? quantidadeMaxima;
  final double precoUnitario;

  const FaixaPrecificacaoModel({
    required this.id,
    required this.quantidadeMinima,
    this.quantidadeMaxima,
    required this.precoUnitario,
  });

  String get faixaLabel {
    if (quantidadeMaxima == null || quantidadeMaxima! >= 99999) {
      return '${quantidadeMinima.toInt()}+ un';
    }
    if (quantidadeMinima == quantidadeMaxima) {
      return '${quantidadeMinima.toInt()} un';
    }
    return '${quantidadeMinima.toInt()} até ${quantidadeMaxima!.toInt()} un';
  }
}

/// Entidade da Política Comercial Versionada
class PoliticaComercialModel {
  final String id;
  final String nome;
  final String descricao;
  final int prioridade;
  final int versao;
  final String? versaoAnteriorId;
  final bool ativo;
  final EstrategiaComercializacao estrategia;
  final List<FaixaPrecificacaoModel> faixas;
  final Set<String> produtosParticipantesIds;

  const PoliticaComercialModel({
    required this.id,
    required this.nome,
    required this.descricao,
    this.prioridade = 1,
    this.versao = 1,
    this.versaoAnteriorId,
    this.ativo = true,
    this.estrategia = EstrategiaComercializacao.porQuantidade,
    required this.faixas,
    required this.produtosParticipantesIds,
  });
}

/// Item simulado ou de pedido enviado ao motor de precificação
class ItemCotacao {
  final String produtoId;
  final String nomeProduto;
  final double quantidade;
  final double? precoUnitarioBase;

  const ItemCotacao({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    this.precoUnitarioBase,
  });
}

/// Passo da Trilha de Raciocínio de Explicabilidade
class ExplicacaoCalculoPasso {
  final String titulo;
  final String detalhe;
  final bool foiAplicado;

  const ExplicacaoCalculoPasso({
    required this.titulo,
    required this.detalhe,
    this.foiAplicado = true,
  });
}

/// Trilha de Explicabilidade da Regra Aplicada pelo Pricing Engine
class ExplicacaoCalculo {
  final String resumoRegra;
  final List<ExplicacaoCalculoPasso> passos;

  const ExplicacaoCalculo({
    required this.resumoRegra,
    required this.passos,
  });
}

/// Alerta de Validação de Faixas Comerciais (Brechas / Sobreposições)
class ValidacaoFaixaAlerta {
  final bool isErro; // true = erro de sobreposição; false = aviso de lacuna sem cobertura
  final String mensagem;

  const ValidacaoFaixaAlerta({
    required this.isErro,
    required this.mensagem,
  });
}

/// Resultado detalhado do cálculo de um item
class ResultadoCotacaoItem {
  final ItemCotacao item;
  final double precoUnitarioCalculado;
  final double subtotal;

  const ResultadoCotacaoItem({
    required this.item,
    required this.precoUnitarioCalculado,
    required this.subtotal,
  });
}

/// Resultado consolidado do grupo comercial com Explicabilidade
class ResultadoCotacaoGrupo {
  final PoliticaComercialModel? politica;
  final double quantidadeTotalGrupo;
  final FaixaPrecificacaoModel? faixaAplicada;
  final double precoUnitarioAplicado;
  final double valorTotalGrupo;
  final double descontoAplicado;
  final ExplicacaoCalculo explicacao;
  final List<ResultadoCotacaoItem> itens;

  const ResultadoCotacaoGrupo({
    this.politica,
    required this.quantidadeTotalGrupo,
    this.faixaAplicada,
    required this.precoUnitarioAplicado,
    required this.valorTotalGrupo,
    this.descontoAplicado = 0.0,
    required this.explicacao,
    required this.itens,
  });
}

/// Motor de Precificação Comercial Centralizado (CommercialPricingEngine)
/// Responsável exclusivo por efetuar todos os cálculos comerciais do FINCORE FOOD ERP.
class CommercialPricingEngine {
  CommercialPricingEngine._();
  static final CommercialPricingEngine instance = CommercialPricingEngine._();

  /// Valida faixas comerciais detectando sobreposições e brechas sem cobertura
  List<ValidacaoFaixaAlerta> validateFaixas(List<FaixaPrecificacaoModel> faixas) {
    final List<ValidacaoFaixaAlerta> alertas = [];
    if (faixas.isEmpty) return alertas;

    final sorted = List<FaixaPrecificacaoModel>.from(faixas)
      ..sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));

    for (int i = 0; i < sorted.length - 1; i++) {
      final atual = sorted[i];
      final proxima = sorted[i + 1];

      if (atual.quantidadeMaxima != null && atual.quantidadeMaxima! >= proxima.quantidadeMinima) {
        alertas.add(ValidacaoFaixaAlerta(
          isErro: true,
          mensagem: 'Sobreposição detectada: Faixa ${atual.faixaLabel} colide com a Faixa ${proxima.faixaLabel}.',
        ));
      } else if (atual.quantidadeMaxima != null && (proxima.quantidadeMinima - atual.quantidadeMaxima!) > 1) {
        final brechaMin = (atual.quantidadeMaxima! + 1).toInt();
        final brechaMax = (proxima.quantidadeMinima - 1).toInt();
        alertas.add(ValidacaoFaixaAlerta(
          isErro: false,
          mensagem: 'Intervalo sem cobertura: De $brechaMin até $brechaMax unidades não possui regra de preço cadastrada.',
        ));
      }
    }

    return alertas;
  }

  /// Efetua a cotação comercial com Trilha de Explicabilidade completa
  ResultadoCotacaoGrupo calculatePolicyQuote({
    required PoliticaComercialModel policy,
    required List<ItemCotacao> items,
    PerfilCliente perfilCliente = PerfilCliente.pessoaFisica,
    CanalVenda canalVenda = CanalVenda.pdvBalcao,
    double cupomDescontoPercentual = 0.0,
  }) {
    final List<ExplicacaoCalculoPasso> passos = [];

    passos.add(ExplicacaoCalculoPasso(
      titulo: '1. Política Comercial Selecionada',
      detalhe: '${policy.nome} (Versão v${policy.versao})',
    ));

    final matchingItems = items.where((i) => policy.produtosParticipantesIds.contains(i.produtoId)).toList();
    if (matchingItems.isEmpty) {
      passos.add(const ExplicacaoCalculoPasso(
        titulo: '2. Verificação de Produtos Participantes',
        detalhe: 'Nenhum item do pedido pertence a esta Política Comercial.',
        foiAplicado: false,
      ));

      return ResultadoCotacaoGrupo(
        politica: policy,
        quantidadeTotalGrupo: 0.0,
        precoUnitarioAplicado: 0.0,
        valorTotalGrupo: 0.0,
        explicacao: ExplicacaoCalculo(resumoRegra: 'Nenhum item participante', passos: passos),
        itens: const [],
      );
    }

    final double totalQuantity = matchingItems.fold(0.0, (sum, item) => sum + item.quantidade);
    passos.add(ExplicacaoCalculoPasso(
      titulo: '2. Acumulado do Grupo Comercial',
      detalhe: 'Total acumulado: ${totalQuantity.toInt()} unidades mistas no grupo.',
    ));

    FaixaPrecificacaoModel? selectedFaixa;
    final sortedFaixas = List<FaixaPrecificacaoModel>.from(policy.faixas)
      ..sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));

    for (final faixa in sortedFaixas) {
      final bool satisfiesMin = totalQuantity >= faixa.quantidadeMinima;
      final bool satisfiesMax = faixa.quantidadeMaxima == null || totalQuantity <= faixa.quantidadeMaxima!;
      if (satisfiesMin && satisfiesMax) {
        selectedFaixa = faixa;
        break;
      }
    }

    if (selectedFaixa == null && sortedFaixas.isNotEmpty && totalQuantity >= sortedFaixas.last.quantidadeMinima) {
      selectedFaixa = sortedFaixas.last;
    }

    double baseUnitPrice = selectedFaixa?.precoUnitario ?? (matchingItems.first.precoUnitarioBase ?? 0.0);
    passos.add(ExplicacaoCalculoPasso(
      titulo: '3. Faixa de Quantidade Aplicada',
      detalhe: selectedFaixa != null
          ? 'Enquadrado na Faixa "${selectedFaixa.faixaLabel}" ➔ Preço Base: R\$ ${baseUnitPrice.toStringAsFixed(2)} / un'
          : 'Nenhuma faixa específica ➔ Preço Base Padrão: R\$ ${baseUnitPrice.toStringAsFixed(2)} / un',
    ));

    double effectiveUnitPrice = baseUnitPrice * perfilCliente.fatorDesconto;
    if (perfilCliente != PerfilCliente.pessoaFisica) {
      passos.add(ExplicacaoCalculoPasso(
        titulo: '4. Ajuste por Perfil de Cliente',
        detalhe: '${perfilCliente.label} ➔ Fator ${perfilCliente.fatorDesconto} (Preço: R\$ ${effectiveUnitPrice.toStringAsFixed(2)} / un)',
      ));
    }

    passos.add(ExplicacaoCalculoPasso(
      titulo: '5. Canal de Venda',
      detalhe: canalVenda.label,
    ));

    if (cupomDescontoPercentual > 0) {
      effectiveUnitPrice = effectiveUnitPrice * (1.0 - (cupomDescontoPercentual / 100.0));
      passos.add(ExplicacaoCalculoPasso(
        titulo: '6. Cupom de Desconto Adicional',
        detalhe: 'Desconto de ${cupomDescontoPercentual.toStringAsFixed(0)}% aplicado no lote.',
      ));
    }

    passos.add(ExplicacaoCalculoPasso(
      titulo: '7. Preço Unitário Efetivo Final',
      detalhe: 'R\$ ${effectiveUnitPrice.toStringAsFixed(2)} por unidade do salgado.',
    ));

    final List<ResultadoCotacaoItem> calculatedItems = matchingItems.map((item) {
      final subtotal = item.quantidade * effectiveUnitPrice;
      return ResultadoCotacaoItem(
        item: item,
        precoUnitarioCalculado: effectiveUnitPrice,
        subtotal: subtotal,
      );
    }).toList();

    final double totalGroupValue = calculatedItems.fold(0.0, (sum, i) => sum + i.subtotal);
    final double rawTotalWithoutDiscount = totalQuantity * baseUnitPrice;
    final double totalDiscount = rawTotalWithoutDiscount - totalGroupValue;

    final resumo = 'Preço de R\$ ${effectiveUnitPrice.toStringAsFixed(2)}/un calculado pela política "${policy.nome}" na faixa ${selectedFaixa?.faixaLabel ?? 'padrão'}.';

    return ResultadoCotacaoGrupo(
      politica: policy,
      quantidadeTotalGrupo: totalQuantity,
      faixaAplicada: selectedFaixa,
      precoUnitarioAplicado: effectiveUnitPrice,
      valorTotalGrupo: totalGroupValue,
      descontoAplicado: totalDiscount > 0 ? totalDiscount : 0.0,
      explicacao: ExplicacaoCalculo(resumoRegra: resumo, passos: passos),
      itens: calculatedItems,
    );
  }
}
