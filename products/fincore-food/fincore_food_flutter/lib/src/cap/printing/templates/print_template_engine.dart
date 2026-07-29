import 'package:intl/intl.dart';
import '../models/print_config.dart';
import '../models/print_data.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';
import '../components/print_header.dart';
import '../components/print_footer.dart';
import '../components/print_pix.dart';
import '../components/print_address.dart';
import '../components/print_money.dart';
import '../components/print_phone.dart';
import '../components/print_date.dart';
import '../components/print_qrcode.dart';

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
    switch (via) {
      case PrintVia.cliente:
        return _renderCliente(data, config);
      case PrintVia.cozinha:
        return _renderCozinha(data, config);
      case PrintVia.balcao:
        return _renderBalcao(data, config);
      case PrintVia.expedicao:
        return _renderExpedicao(data, config);
    }
  }

  // ─── Via do Cliente ───────────────────────────────────────────────

  List<String> _renderCliente(PrintData data, PrintConfig config) {
    final lines = <String>[];
    final w = config.larguraPapel == 58 ? 32 : 48;
    final divSingle = '-' * w;

    // 1. Cabeçalho
    lines.addAll(
      PrintHeader.render(
        nomeEmpresaCupom: config.nomeEmpresaCupom ?? "FINCORE FOOD - DELIVERY",
        cnpj: config.cnpjEmpresa,
        telefone: config.telefoneEmpresa,
        endereco: config.enderecoEmpresa,
        tipoLogistica: data.tipoLogistica,
        dataHora: data.dataHora,
        shortId: data.shortId,
        width: w,
      ),
    );

    // 2. Cliente
    lines.add('[BOLD_ON]CLIENTE[BOLD_OFF]');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add(data.clienteNome!);
    }
    final formattedPhone = PrintPhone.format(data.clienteTelefone ?? '');
    if (formattedPhone.isNotEmpty) {
      lines.add(formattedPhone);
    }

    // 3. Endereço (somente se Entrega/Delivery)
    if (data.tipoLogistica.toLowerCase().contains('entrega') || 
        data.tipoLogistica.toLowerCase().contains('delivery')) {
      lines.add('[BOLD_ON]ENDERECO[BOLD_OFF]');
      lines.addAll(
        PrintAddress.format(
          logradouro: data.endereco ?? '',
          bairro: data.bairro ?? '',
          referencia: data.referencia,
        ),
      );
    }
    lines.add(divSingle);

    // 4. Resumo do Pedido (Salgados e Sabores)
    final totalSalgados = data.itens.fold<double>(0, (sum, i) => sum + i.quantidade);
    final totalSabores = data.itens.length;
    lines.add('[BOLD_ON]RESUMO DO PEDIDO[BOLD_OFF]');
    lines.add('${totalSalgados.toStringAsFixed(0)} Unidades');
    lines.add('$totalSabores Sabores');
    lines.add(divSingle);

    // 5. Itens (Com preenchimento de pontos e em negrito para destaque)
    for (final i in data.itens) {
      final qtyStr = i.quantidade % 1 == 0 
          ? i.quantidade.toStringAsFixed(0) 
          : i.quantidade.toStringAsFixed(1);
      final left = '${qtyStr}x ${i.nome}';
      final right = PrintMoney.format(i.totalCentavos);
      final dotsCount = w - left.length - right.length;
      final dots = dotsCount > 0 ? '.' * dotsCount : ' ';
      lines.add('[BOLD_ON]$left$dots$right[BOLD_OFF]');
      
      if ((i.observacao ?? '').isNotEmpty) {
        lines.add('   OBS: ${i.observacao}');
      }
    }

    // 6. Observações Gerais (Somente se não vazio e diferente do endereço)
    final obs = (data.observacao ?? '').trim();
    final end = (data.endereco ?? '').trim();
    if (obs.isNotEmpty && obs != end) {
      lines.add(divSingle);
      lines.add('[BOLD_ON]OBSERVACOES[BOLD_OFF]');
      lines.add(obs);
    }
    lines.add(divSingle);

    // 7. Totais (Com preenchimento de pontos e destaque para o TOTAL)
    final subtotal = data.totalCentavos - (data.taxaEntregaCentavos ?? 0) + (data.descontoCentavos ?? 0);
    
    final leftSub = 'Subtotal';
    final rightSub = PrintMoney.format(subtotal);
    final dotsSubCount = w - leftSub.length - rightSub.length;
    final dotsSub = dotsSubCount > 0 ? '.' * dotsSubCount : ' ';
    lines.add('$leftSub$dotsSub$rightSub');

    if (data.taxaEntregaCentavos != null && data.taxaEntregaCentavos! > 0) {
      final leftTaxa = 'Taxa Entrega';
      final rightTaxa = PrintMoney.format(data.taxaEntregaCentavos!);
      final dotsTaxaCount = w - leftTaxa.length - rightTaxa.length;
      final dotsTaxa = dotsTaxaCount > 0 ? '.' * dotsTaxaCount : ' ';
      lines.add('$leftTaxa$dotsTaxa$rightTaxa');
    }

    if (data.descontoCentavos != null && data.descontoCentavos! > 0) {
      final leftDesc = 'Desconto';
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

    // 8. Forma de Pagamento
    lines.add('[BOLD_ON]Pagamento[BOLD_OFF]');
    lines.add(data.formaPagamento.toUpperCase());
    lines.add(divSingle);

    // 9. Instruções PIX Automáticas
    if (data.formaPagamento.toLowerCase().contains('pix') && 
        (config.pixKey ?? '').isNotEmpty) {
      lines.addAll(
        PrintPix.render(
          totalCentavos: data.totalCentavos,
          chave: config.pixKey!,
          tipoChave: config.pixTipo,
          favorecido: config.pixFavorecido ?? 'Estabelecimento',
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
    lines.add('[BOLD_ON]PEDIDO: #${data.shortId}[BOLD_OFF]');
    lines.add('HORA: ${PrintDate.formatTimeOnly(data.dataHora)}');
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

    // Observação geral
    if ((data.observacao ?? '').isNotEmpty) {
      lines.add('OBS GERAL: ${data.observacao}');
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

    lines.add('PEDIDO: #${data.shortId}');
    lines.add('HORA: ${PrintDate.formatTimeOnly(data.dataHora)}');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add('CLIENTE: ${data.clienteNome!}');
    }
    lines.add('TIPO: ${data.tipoLogistica}');
    lines.add('PAGTO: ${data.formaPagamento}');
    lines.add('[BOLD_ON]TOTAL: ${PrintMoney.format(data.totalCentavos)}[BOLD_OFF]');
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

    lines.add('PEDIDO: #${data.shortId}');
    lines.add('DATA: ${PrintDate.format(data.dataHora)}');
    if ((data.clienteNome ?? '').isNotEmpty) {
      lines.add('CLIENTE: ${data.clienteNome!}');
    }
    final formattedPhone = PrintPhone.format(data.clienteTelefone ?? '');
    if (formattedPhone.isNotEmpty) {
      lines.add('FONE: $formattedPhone');
    }
    lines.add(divSingle);

    // Endereço destacado
    if ((data.endereco ?? '').isNotEmpty) {
      lines.add('[BOLD_ON]ENDERECO:[BOLD_OFF]');
      lines.addAll(
        PrintAddress.format(
          logradouro: data.endereco ?? '',
          bairro: data.bairro ?? '',
          referencia: data.referencia,
        ),
      );
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
}
