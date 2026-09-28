import '../models/print_config.dart';
import '../models/print_data.dart';
import '../components/print_header.dart';
import '../components/print_footer.dart';
import '../components/print_pix.dart';
import '../components/print_address.dart';
import '../components/print_money.dart';
import '../components/print_phone.dart';
import '../components/print_date.dart';

/// Motor de templates para geração de conteúdo textual para impressoras térmicas.
/// Gera linhas de texto ESC/POS-friendly por via de impressão baseadas no layout clássico da Salgaderia.
class PrintTemplateEngine {
  const PrintTemplateEngine();

  /// Gera o conteúdo textual completo para uma via específica.
  List<String> render({
    required PrintVia via,
    required PrintData data,
    required PrintConfig config,
  }) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;

    if (data.status?.toLowerCase() == 'cancelado') {
      lines.add('=' * w);
      lines.add('[BOLD_ON]' + '*** PEDIDO CANCELADO ***'.padLeft((w + 24) ~/ 2).padRight(w) + '[BOLD_OFF]');
      lines.add('=' * w);
      lines.add('');
    }

    switch (via) {
      case PrintVia.cliente:
        lines.addAll(_renderCliente(data, config));
        break;
      case PrintVia.cozinha:
        lines.addAll(_renderCozinha(data, config));
        break;
      case PrintVia.balcao:
        lines.addAll(_renderBalcao(data, config));
        break;
      case PrintVia.expedicao:
        lines.addAll(_renderExpedicao(data, config));
        break;
    }

    if (data.status?.toLowerCase() == 'cancelado') {
      lines.add('');
      lines.add('=' * w);
      lines.add('[BOLD_ON]' + '*** PEDIDO CANCELADO ***'.padLeft((w + 24) ~/ 2).padRight(w) + '[BOLD_OFF]');
      lines.add('=' * w);
    }

    return lines;
  }

  // ─── Via do Cliente ───────────────────────────────────────────────

  List<String> _renderCliente(PrintData data, PrintConfig config) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;
    final divSingle = '-' * w;

    final idExibicao = data.numeroPedido?.toString() ?? data.shortId;
    // 1. Cabeçalho
    lines.addAll(
      PrintHeader.render(
        nomeEmpresaCupom: config.nomeEmpresaCupom ?? "FINCORE FOOD - DELIVERY",
        cnpj: config.cnpjEmpresa,
        telefone: config.telefoneEmpresa,
        endereco: config.enderecoEmpresa,
        tipoLogistica: data.tipoLogistica,
        dataHora: data.dataHora,
        idExibicao: idExibicao,
        width: w,
      ),
    );

    // 2. Cliente
    lines.add('[BOLD_ON]CLIENTE:[BOLD_OFF] ${data.clienteNome ?? "Consumidor"}');
    final formattedPhone = PrintPhone.format(data.clienteTelefone ?? '');
    if (formattedPhone.isNotEmpty) {
      lines.add('[BOLD_ON]TELEFONE:[BOLD_OFF] $formattedPhone');
    }

    // 3. Endereço (somente se Entrega/Delivery)
    if (data.tipoLogistica.toLowerCase().contains('entrega') || 
        data.tipoLogistica.toLowerCase().contains('delivery')) {
      final addressLines = PrintAddress.format(
        logradouro: data.endereco ?? '',
        bairro: data.bairro ?? '',
        cidade: data.cidade ?? '',
        uf: data.uf ?? '',
        referencia: data.referencia,
      );
      if (addressLines.isNotEmpty) {
        final fullAddressText = 'ENDERECO: ' + addressLines.map((l) => l.trim()).join(' - ');
        final wrappedLines = _wrapText(fullAddressText, w);
        for (final line in wrappedLines) {
          lines.add('[BOLD_ON]$line[BOLD_OFF]');
        }
      }
    }
    lines.add(divSingle);

    // 4. (Removido: resumo de unidades/sabores — mantém cupom enxuto)

    // 5. Itens (Com preenchimento de pontos e em negrito para destaque)
    lines.add('[BOLD_ON]ITENS:[BOLD_OFF]');
    for (final i in data.itens) {
      final qtyStr = i.quantidade % 1 == 0 
          ? i.quantidade.toStringAsFixed(0) 
          : i.quantidade.toStringAsFixed(1);
      final left = '  ${qtyStr}x ${i.nome}';
      final right = PrintMoney.format(i.totalCentavos);
      final dotsCount = w - left.length - right.length;
      final dots = dotsCount > 0 ? ' ' * dotsCount : ' ';
      lines.add('$left$dots$right');
      
      if ((i.observacao ?? '').isNotEmpty) {
        lines.add('   OBS: ${i.observacao}');
      }
    }
    lines.add(divSingle);

    final totalQtdCaixa = data.itens.fold<double>(0, (sum, item) => sum + item.quantidade);
    final totalQtdCaixaStr = totalQtdCaixa % 1 == 0 ? totalQtdCaixa.toStringAsFixed(0) : totalQtdCaixa.toStringAsFixed(1);
    lines.add('[BOLD_ON]TOTAL DE ITENS: $totalQtdCaixaStr un[BOLD_OFF]');
    lines.add(divSingle);

    // 7. Totais + Forma de Pagamento (agrupados — igual ao layout da tela)
    final subtotal = data.totalCentavos - (data.taxaEntregaCentavos ?? 0) - (data.taxaServicoCentavos ?? 0) + (data.descontoCentavos ?? 0);
    
    final leftSub = 'SUBTOTAL';
    final rightSub = PrintMoney.format(subtotal);
    final dotsSubCount = w - leftSub.length - rightSub.length;
    final dotsSub = dotsSubCount > 0 ? '.' * dotsSubCount : ' ';
    lines.add('$leftSub$dotsSub$rightSub');

    if (data.taxaEntregaCentavos != null && data.taxaEntregaCentavos! > 0) {
      final leftTaxa = 'TAXA ENTREGA';
      final rightTaxa = PrintMoney.format(data.taxaEntregaCentavos!);
      final dotsTaxaCount = w - leftTaxa.length - rightTaxa.length;
      final dotsTaxa = dotsTaxaCount > 0 ? '.' * dotsTaxaCount : ' ';
      lines.add('$leftTaxa$dotsTaxa$rightTaxa');
    }

    if (data.taxaServicoCentavos != null && data.taxaServicoCentavos! > 0) {
      final leftServico = 'TAXA SERVICO/MAO OBRA';
      final rightServico = PrintMoney.format(data.taxaServicoCentavos!);
      final dotsServCount = w - leftServico.length - rightServico.length;
      final dotsServ = dotsServCount > 0 ? '.' * dotsServCount : ' ';
      lines.add('$leftServico$dotsServ$rightServico');
    }

    if (data.descontoCentavos != null && data.descontoCentavos! > 0) {
      final leftDesc = 'DESCONTO';
      final rightDesc = '- ${PrintMoney.format(data.descontoCentavos!)}';
      final dotsDescCount = w - leftDesc.length - rightDesc.length;
      final dotsDesc = dotsDescCount > 0 ? '.' * dotsDescCount : ' ';
      lines.add('$leftDesc$dotsDesc$rightDesc');
    }

    final leftTotal = 'TOTAL';
    final rightTotal = PrintMoney.format(data.totalCentavos);
    final dotsTotalCount = w - leftTotal.length - rightTotal.length;
    final dotsTotal = dotsTotalCount > 0 ? '.' * dotsTotalCount : ' ';
    lines.add('[BOLD_ON]$leftTotal$dotsTotal$rightTotal[BOLD_OFF]');
    lines.add(divSingle);

    // 8. Forma de Pagamento (junto ao bloco de totais)
    String formaPg = data.formaPagamento.toUpperCase();
    if (formaPg.contains('CONTINGENTE')) {
      formaPg = formaPg.replaceAll('CONTINGENTE', '').trim();
    }
    final leftPag = 'PAGTO';
    final dotsCountPag = w - leftPag.length - 1 - formaPg.length;
    final dotsPag = dotsCountPag > 0 ? ' ' * dotsCountPag : ' ';
    lines.add('[BOLD_ON]$leftPag$dotsPag$formaPg[BOLD_OFF]');

    if (formaPg.contains('DINHEIRO') && data.trocoParaCentavos != null && data.trocoParaCentavos! > 0) {
      final trocoCentavos = data.trocoParaCentavos! - data.totalCentavos;
      if (trocoCentavos > 0) {
        lines.add('Troco para: ${PrintMoney.format(data.trocoParaCentavos!)}');
        lines.add('[BOLD_ON]Troco: ${PrintMoney.format(trocoCentavos)}[BOLD_OFF]');
      }
    }

    // Divisor duplo após o pagamento
    lines.add('=' * w);

    // 6. Observações Gerais — no final, após o divisor duplo (como no layout da tela)
    final obs = (data.observacao ?? '').trim();
    final end = (data.endereco ?? '').trim();
    if (obs.isNotEmpty && obs != end) {
      lines.add('[BOLD_ON]OBSERVACOES:[BOLD_OFF]');
      lines.add(obs);
      lines.add(divSingle);
    }

    // 9. Instruções PIX Automáticas
    final effectivePixKey = (data.pixChave != null && data.pixChave!.isNotEmpty) ? data.pixChave! : (config.pixKey ?? '');
    final effectivePixTipo = (data.pixTipo != null && data.pixTipo!.isNotEmpty) ? data.pixTipo! : config.pixTipo;
    final effectiveFavorecido = (data.pixBanco != null && data.pixBanco!.isNotEmpty)
        ? data.pixBanco!
        : (config.pixFavorecido ?? 'Estabelecimento');

    if (data.formaPagamento.toLowerCase().contains('pix') && 
        effectivePixKey.isNotEmpty) {
      lines.addAll(
        PrintPix.render(
          totalCentavos: data.totalCentavos,
          chave: effectivePixKey,
          tipoChave: effectivePixTipo,
          favorecido: effectiveFavorecido,
          cidade: config.pixCidade,
          mensagemRodape: config.mensagemRodape,
          imprimirQRCode: config.imprimirQRCode,
          imprimirCopiaCola: config.imprimirCopiaCola,
          width: w,
        ),
      );
    }

    // 10. Rodapé
    lines.addAll(
      PrintFooter.render(
        imprimirRodape: config.imprimirRodape,
        mensagemRodape: config.mensagemRodape,
      ),
    );

    return lines;
  }

  // ─── Via da Cozinha ───────────────────────────────────────────────

  List<String> _renderCozinha(PrintData data, PrintConfig config) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;
    final divSingle = '-' * w;
    final divDouble = '=' * w;

    lines.add('[CENTER][BOLD_ON]*** COZINHA ***[BOLD_OFF]');
    lines.add(divDouble);

    // Info do pedido
    final idExibicao = data.numeroPedido?.toString() ?? data.shortId;
    lines.add('[BOLD_ON]PEDIDO: #$idExibicao[BOLD_OFF]');
    lines.add('[BOLD_ON]AGENDADO: ${PrintDate.format(data.dataHora.toLocal()).toUpperCase()}[BOLD_OFF]');
    lines.add('TIPO: ${data.tipoLogistica}');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add('CLIENTE: ${data.clienteNome!}');
    }
    if (data.tipoLogistica == 'Mesa' && (data.mesa ?? '').isNotEmpty) {
      lines.add('MESA: ${data.mesa!}');
    }
    lines.add(divSingle);

    // Itens SEM preços (foco na produção)
    for (final item in data.itens) {
      final qtyStr = item.quantidade % 1 == 0 
          ? item.quantidade.toStringAsFixed(0) 
          : item.quantidade.toStringAsFixed(1);
      lines.add('[BOLD_ON]>>> ${qtyStr}x ${item.nome}[BOLD_OFF]');
      if ((item.observacao ?? '').isNotEmpty) {
        lines.add('    *** ${item.observacao} ***');
      }
    }
    lines.add(divSingle);
    final totalQtdCozinha = data.itens.fold<double>(0, (sum, item) => sum + item.quantidade);
    final totalQtdCozinhaStr = totalQtdCozinha % 1 == 0 ? totalQtdCozinha.toStringAsFixed(0) : totalQtdCozinha.toStringAsFixed(1);
    lines.add('[BOLD_ON]TOTAL DE ITENS: $totalQtdCozinhaStr un[BOLD_OFF]');
    lines.add(divSingle);

    // Observação geral
    if ((data.observacao ?? '').isNotEmpty) {
      lines.add('OBS GERAL: ${data.observacao}');
    }

    if (data.taxaServicoCentavos != null && data.taxaServicoCentavos! > 0) {
      lines.add(divSingle);
      lines.add('[BOLD_ON]*** SERVICO/MAO DE OBRA NO LOCAL ***[BOLD_OFF]');
      lines.add('TAXA SERVICO: ${PrintMoney.format(data.taxaServicoCentavos!)}');
    }

    lines.add('');
    return lines;
  }

  // ─── Via do Balcão ────────────────────────────────────────────────

  List<String> _renderBalcao(PrintData data, PrintConfig config) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;
    final divSingle = '-' * w;
    final divDouble = '=' * w;

    lines.add('[CENTER][BOLD_ON]*** BALCAO ***[BOLD_OFF]');
    lines.add(divDouble);

    final idExibicao = data.numeroPedido?.toString() ?? data.shortId;
    lines.add('PEDIDO: #$idExibicao');
    lines.add('[BOLD_ON]AGENDADO: ${PrintDate.format(data.dataHora.toLocal()).toUpperCase()}[BOLD_OFF]');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add('CLIENTE: ${data.clienteNome!}');
    }
    lines.add('TIPO: ${data.tipoLogistica}');
    lines.add('PAGTO: ${data.formaPagamento}');
    lines.add('[BOLD_ON]TOTAL: ${PrintMoney.format(data.totalCentavos)}[BOLD_OFF]');
    if (data.taxaServicoCentavos != null && data.taxaServicoCentavos! > 0) {
      lines.add('SERVICO/MAO OBRA: ${PrintMoney.format(data.taxaServicoCentavos!)}');
    }
    lines.add(divSingle);

    // Itens resumidos
    for (final item in data.itens) {
      final qtyStr = item.quantidade % 1 == 0 
          ? item.quantidade.toStringAsFixed(0) 
          : item.quantidade.toStringAsFixed(1);
      lines.add('${qtyStr}x ${item.nome}');
    }

    lines.add('');
    return lines;
  }

  // ─── Via da Expedição ─────────────────────────────────────────────

  List<String> _renderExpedicao(PrintData data, PrintConfig config) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;
    final divSingle = '-' * w;
    final divDouble = '=' * w;

    lines.add('[CENTER][BOLD_ON]*** EXPEDICAO / ENTREGA ***[BOLD_OFF]');
    lines.add(divDouble);

    final idExibicao = data.numeroPedido?.toString() ?? data.shortId;
    lines.add('PEDIDO: #$idExibicao');
    lines.add('[BOLD_ON]AGENDADO: ${PrintDate.format(data.dataHora.toLocal()).toUpperCase()}[BOLD_OFF]');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add('CLIENTE: ${data.clienteNome!}');
    }
    final formattedPhone = PrintPhone.format(data.clienteTelefone ?? '');
    if (formattedPhone.isNotEmpty) {
      lines.add('FONE: $formattedPhone');
    }
    if (data.taxaServicoCentavos != null && data.taxaServicoCentavos! > 0) {
      lines.add('[BOLD_ON]SERVICO/MAO OBRA: ${PrintMoney.format(data.taxaServicoCentavos!)}[BOLD_OFF]');
    }
    lines.add(divSingle);

    // Endereço destacado
    if ((data.endereco ?? '').isNotEmpty) {
      final addressLines = PrintAddress.format(
        logradouro: data.endereco ?? '',
        bairro: data.bairro ?? '',
        cidade: data.cidade ?? '',
        uf: data.uf ?? '',
        referencia: data.referencia,
      );
      if (addressLines.isNotEmpty) {
        final fullAddressText = 'ENDERECO: ' + addressLines.map((l) => l.trim()).join(' - ');
        final wrappedLines = _wrapText(fullAddressText, w);
        for (final line in wrappedLines) {
          lines.add('[BOLD_ON]$line[BOLD_OFF]');
        }
      }
      lines.add(divSingle);
    }

    // Itens (quantidade apenas)
    lines.add('ITENS:');
    for (final item in data.itens) {
      final qtyStr = item.quantidade % 1 == 0 
          ? item.quantidade.toStringAsFixed(0) 
          : item.quantidade.toStringAsFixed(1);
      lines.add('  ${qtyStr}x ${item.nome}');
    }
    lines.add(divSingle);
    final totalQtdExp = data.itens.fold<double>(0, (sum, item) => sum + item.quantidade);
    final totalQtdExpStr = totalQtdExp % 1 == 0 ? totalQtdExp.toStringAsFixed(0) : totalQtdExp.toStringAsFixed(1);
    lines.add('[BOLD_ON]TOTAL DE ITENS: $totalQtdExpStr un[BOLD_OFF]');
    lines.add(divSingle);

    // Total e forma de pagamento
    lines.add('[BOLD_ON]TOTAL: ${PrintMoney.format(data.totalCentavos)}[BOLD_OFF]');
    lines.add('PAGTO: ${data.formaPagamento}');

    // Observação
    final obs = (data.observacao ?? '').trim();
    final end = (data.endereco ?? '').trim();
    if (obs.isNotEmpty && obs != end) {
      lines.add(divSingle);
      lines.add('OBS: $obs');
    }

    lines.add('');
    return lines;
  }

  List<String> _wrapText(String text, int width) {
    if (text.length <= width) return [text];
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';
    
    for (final word in words) {
      if (word.isEmpty) continue;
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }
}
