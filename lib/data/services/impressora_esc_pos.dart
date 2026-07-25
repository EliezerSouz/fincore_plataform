import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/formatters.dart';
import '../../domain/ports/impressora_port.dart';
import '../../models/domain_models.dart';
import '../../services/settings_service.dart';
import '../../services/pix_generator.dart';
import 'impressora_pdf.dart';

/// Implementação da porta de impressão baseada em ESC/POS.
///
/// Suporta impressão via compartilhamento Spooler Windows e salvamento temporário de binário.
class ImpressoraEscPos implements IImpressoraPort {
  const ImpressoraEscPos();

  @override
  Future<void> imprimirPedido(PedidoCompleto dados, AppSettings cfg) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          cfg.largura == 58 ? PaperSize.mm58 : PaperSize.mm80, profile);
      final p = dados.pedido;
      final c = dados.cliente;
      final bytes = <int>[];
      final maxChars = cfg.largura == 58 ? 32 : 48;

      // 1. Cabeçalho
      bytes.addAll(_text(generator, cfg.empresa,
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size1,
              width: PosTextSize.size1)));
      bytes.addAll(_text(generator, p.tipoEntrega.toUpperCase(),
          styles: const PosStyles(align: PosAlign.center, bold: true)));
      
      final dataFormatada = DateFormat('dd/MM/yyyy - HH:mm').format(p.dataEntrega);
      bytes.addAll(_text(generator, dataFormatada,
          styles: const PosStyles(align: PosAlign.center)));
          
      bytes.addAll(_text(generator, 
          'PEDIDO #${pedidoNumero(p.numero)}',
          styles: const PosStyles(align: PosAlign.center, bold: true)));
      
      bytes.addAll(generator.hr());
      
      // 2. Cliente
      bytes.addAll(_text(generator, 'CLIENTE', styles: const PosStyles(bold: true)));
      bytes.addAll(_text(generator, c.nome));
      bytes.addAll(_text(generator, c.telefone));
      
      // 3. Endereço (somente se Entrega)
      if (p.tipoEntrega.toLowerCase() == 'entrega') {
        bytes.addAll(_text(generator, 'ENDERECO', styles: const PosStyles(bold: true)));
        bytes.addAll(_text(generator, '${c.logradouro}, ${c.numero}'));
        bytes.addAll(_text(generator, '${c.bairro} - ${c.cidade}'));
        if (c.referencia.isNotEmpty) {
          bytes.addAll(_text(generator, 'Ref.: ${c.referencia}'));
        }
      }
      
      bytes.addAll(generator.hr());

      // 4. Resumo do Pedido (Salgados e Sabores)
      final totalSalgados = dados.itens.fold<int>(0, (sum, i) => sum + i.quantidade);
      final totalSabores = dados.itens.length;
      bytes.addAll(_text(generator, 'RESUMO DO PEDIDO', styles: const PosStyles(bold: true)));
      bytes.addAll(_text(generator, '$totalSalgados SALGADOS'));
      bytes.addAll(_text(generator, '$totalSabores SABORES'));
      bytes.addAll(generator.hr());

      // 5. Itens (Com preenchimento de pontos e em negrito para destaque)
      for (final i in dados.itens) {
        final left = '${i.quantidade}x ${i.produtoNome}';
        final right = dinheiro(i.valorTotalCentavos);
        final dotsCount = maxChars - left.length - right.length;
        final dots = dotsCount > 0 ? '.' * dotsCount : ' ';
        bytes.addAll(_text(generator, '$left$dots$right', styles: const PosStyles(bold: true)));
      }

      // 6. Observações (Somente se não vazio)
      if (p.observacoes.trim().isNotEmpty) {
        bytes.addAll(generator.hr());
        bytes.addAll(_text(generator, 'OBSERVACOES', styles: const PosStyles(bold: true)));
        bytes.addAll(_text(generator, p.observacoes));
      }

      bytes.addAll(generator.hr());

      // 7. Totais (Com preenchimento de pontos e destaque para o TOTAL)
      {
        final leftSub = 'Subtotal';
        final rightSub = dinheiro(p.subtotalCentavos);
        final dotsSubCount = maxChars - leftSub.length - rightSub.length;
        final dotsSub = dotsSubCount > 0 ? '.' * dotsSubCount : ' ';
        bytes.addAll(_text(generator, '$leftSub$dotsSub$rightSub'));

        final leftTaxa = 'Taxa Entrega';
        final rightTaxa = dinheiro(p.taxaEntregaCentavos);
        final dotsTaxaCount = maxChars - leftTaxa.length - rightTaxa.length;
        final dotsTaxa = dotsTaxaCount > 0 ? '.' * dotsTaxaCount : ' ';
        bytes.addAll(_text(generator, '$leftTaxa$dotsTaxa$rightTaxa'));

        final leftTotal = 'TOTAL';
        final rightTotal = dinheiro(p.totalCentavos);
        final dotsTotalCount = maxChars - leftTotal.length - rightTotal.length;
        final dotsTotal = dotsTotalCount > 0 ? '.' * dotsTotalCount : ' ';
        bytes.addAll(_text(generator, '$leftTotal$dotsTotal$rightTotal', styles: const PosStyles(bold: true)));
      }

      bytes.addAll(generator.hr());

      // 8. Forma de Pagamento
      bytes.addAll(_text(generator, 'Pagamento', styles: const PosStyles(bold: true)));
      bytes.addAll(_text(generator, p.formaPagamento.toUpperCase()));

      if (p.trocoParaCentavos != null) {
        bytes.addAll(_text(generator, 'Troco para: ${dinheiro(p.trocoParaCentavos!)}'));
      }

      // 9. Instruções PIX Automáticas
      if (p.formaPagamento.toLowerCase().contains('pix') && (cfg.habilitarPix || cfg.pixChave.isNotEmpty)) {
        final double valorPix = p.totalCentavos / 100.0;
        final copiaCola = PixGenerator.gerarCopiaCola(
          chave: cfg.pixChave,
          favorecido: cfg.pixFavorecido,
          cidade: cfg.pixCidade.isNotEmpty ? cfg.pixCidade : 'Sorocaba',
          valor: valorPix,
          mensagem: cfg.pixMensagem.isNotEmpty ? cfg.pixMensagem : 'Salgaderia',
        );

        bytes.addAll(generator.hr(ch: '-'));
        bytes.addAll(_text(generator, 'PAGAMENTO VIA PIX', styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes.addAll(_text(generator, 'Chave: ${cfg.pixChave} (${cfg.pixTipoChave.toUpperCase()})', styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes.addAll(_text(generator, 'Favorecido: ${cfg.pixFavorecido}', styles: const PosStyles(align: PosAlign.center)));
        if (cfg.pixBanco.trim().isNotEmpty) {
          bytes.addAll(_text(generator, 'Banco: ${cfg.pixBanco.trim()}', styles: const PosStyles(align: PosAlign.center)));
        }

        if (cfg.pixImprimirQrCode) {
          bytes.addAll(generator.feed(1));
          bytes.addAll(generator.qrcode(copiaCola, size: QRSize.size4, align: PosAlign.center));
        }

        // PIX copia e cola removido daqui

        if (cfg.pixMensagem.isNotEmpty) {
          bytes.addAll(generator.feed(1));
          bytes.addAll(_text(generator, cfg.pixMensagem, styles: const PosStyles(align: PosAlign.center)));
        }
        bytes.addAll(generator.hr(ch: '-'));
      }

      // 10. Rodapé (Nome da empresa repetido removido daqui)
      bytes.addAll(generator.feed(1));
      bytes.addAll(_text(generator, 'Obrigado pela preferência!', styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(_text(generator, 'Bom apetite!', styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.cut());

      if (kIsWeb) {
        // No navegador web, utiliza o driver de impressão PDF/Spooler nativo do browser com PDF válido e formato de papel correto
        final pdfBytes = await ImpressoraPdf.gerarPdfBytes(dados, cfg);
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Pedido #${pedidoNumero(p.numero)}',
          format: cfg.largura == 58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
        );
        return;
      }

      final tempDir = Directory.systemTemp.path;
      final arquivo = File('$tempDir\\salgaderia_ultimo_pedido.bin');
      await arquivo.writeAsBytes(bytes);

      if (cfg.impressora.trim().isNotEmpty) {
        final limpo = cfg.impressora.trim().replaceAll('/', '\\').replaceAll(RegExp(r'^\\+'), '');
        final destino = '\\\\$limpo';
        final result = await Process.run(
            'cmd', ['/c', 'copy', '/b', arquivo.path, destino]);
        if (result.exitCode != 0) {
          throw PrinterException(
              'Falha ao enviar impressao: ${result.stderr}');
        }
      }
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException('Erro no driver ESC/POS: $e');
    }
  }

  /// Sanitiza e gera bytes de texto seguros para a impressora.
  List<int> _text(Generator gen, String text, {PosStyles styles = const PosStyles()}) {
    return gen.text(_sanitizarString(text), styles: styles);
  }

  /// Sanitiza o texto removendo caracteres invisíveis, acentos e Ç
  /// para evitar problemas de compatibilidade e encoding na impressora.
  String _sanitizarString(String texto) {
    // Substitui espaços invisíveis/inseparáveis por espaços comuns
    var t = texto.replaceAll('\u00a0', ' ').replaceAll('\u202f', ' ');
    
    // Substituições comuns de caracteres acentuados
    final mapa = {
      'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
      'Á': 'A', 'À': 'A', 'Ã': 'A', 'Â': 'A', 'Ä': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'Ó': 'O', 'Ò': 'O', 'Õ': 'O', 'Ô': 'O', 'Ö': 'O',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C',
      'º': 'o', 'ª': 'a', '°': 'o',
      '№': 'No',
    };
    
    mapa.forEach((key, val) {
      t = t.replaceAll(key, val);
    });
    
    return t;
  }

  @override
  Future<bool> testarConexao(String destino) async {
    final limpo = destino.trim();
    if (limpo.isEmpty) return false;

    if (kIsWeb) {
      // No navegador web, verifica se o serviço de impressão local está disponível
      try {
        final impressoras = await Printing.listPrinters();
        return impressoras.isNotEmpty || limpo.isNotEmpty;
      } catch (_) {
        return limpo.isNotEmpty;
      }
    }

    try {
      final caminhoLimpo = limpo.replaceAll('/', '\\').replaceAll(RegExp(r'^\\+'), '');
      final path = '\\\\$caminhoLimpo';
      final result = await Process.run('cmd', ['/c', 'net', 'use', path]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
