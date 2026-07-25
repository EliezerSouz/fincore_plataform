import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/ports/impressora_port.dart';
import '../../models/domain_models.dart';
import '../../services/settings_service.dart';
import '../../services/pix_generator.dart';

/// Implementação da porta de impressão baseada no gerador de PDF e biblioteca Printing.
///
/// Permite visualização previa em tela e impressão direta em qualquer impressora instalada no sistema operacional.
class ImpressoraPdf implements IImpressoraPort {
  const ImpressoraPdf();

  /// Gera os bytes do documento PDF para um pedido.
  static Future<Uint8List> gerarPdfBytes(
      PedidoCompleto dados, AppSettings cfg) async {
    final pdf = pw.Document();
    final p = dados.pedido;
    final c = dados.cliente;
    final formatData =
        '${p.dataEntrega.day.toString().padLeft(2, '0')}/${p.dataEntrega.month.toString().padLeft(2, '0')}/${p.dataEntrega.year} - ${p.dataEntrega.hour.toString().padLeft(2, '0')}:${p.dataEntrega.minute.toString().padLeft(2, '0')}';

    final is58 = cfg.largura == 58;
    final double width = is58 ? 58 : 80;

    // Calcular altura dinâmica da bobina em milímetros
    double height = 80; // Altura base (cabeçalho, dados do cliente, margens)

    if (p.tipoEntrega.toLowerCase() == 'entrega') {
      height += 25; // Altura do endereço
    }

    height += dados.itens.length * 6.5; // 6.5mm por item

    if (p.observacoes.isNotEmpty) {
      height += 15 + (p.observacoes.length / 30).ceil() * 5.0; // Altura observações
    }

    height += 35; // Seção de totais e pagamento

    if (p.formaPagamento.toLowerCase().contains('pix') && (cfg.habilitarPix || cfg.pixChave.isNotEmpty)) {
      height += 25; // Dados básicos Pix
      if (cfg.pixImprimirQrCode) height += 40;
      if (cfg.pixImprimirCopiaCola) height += 20;
    }

    height += 20; // Altura do rodapé

    final pageSize = PdfPageFormat(
      width * PdfPageFormat.mm,
      height * PdfPageFormat.mm,
      marginAll: 2 * PdfPageFormat.mm,
    );

    final defaultStyle = pw.TextStyle(fontSize: is58 ? 9 : 11);
    final boldStyle =
        pw.TextStyle(fontSize: is58 ? 9 : 11, fontWeight: pw.FontWeight.bold);
    final largeStyle =
        pw.TextStyle(fontSize: is58 ? 10 : 12, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.Page(
        pageFormat: pageSize,
        build: (pw.Context context) {
          final isEntrega = p.tipoEntrega.toLowerCase() == 'entrega';
          final totalSalgados = dados.itens.fold<int>(0, (sum, i) => sum + i.quantidade);
          final totalSabores = dados.itens.length;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  cfg.empresa.isEmpty ? 'SALGADERIA' : cfg.empresa,
                  style: largeStyle,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  isEntrega ? 'ENTREGA' : 'RETIRADA',
                  style: boldStyle,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  formatData,
                  style: defaultStyle,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'PEDIDO #${pedidoNumero(p.numero)}',
                  style: boldStyle,
                ),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Cliente
              pw.Text('CLIENTE', style: boldStyle),
              pw.Text(c.nome, style: defaultStyle),
              pw.Text(c.telefone, style: defaultStyle),

              if (isEntrega) ...[
                pw.SizedBox(height: 4),
                pw.Text('ENDEREÇO', style: boldStyle),
                pw.Text('${c.logradouro}, ${c.numero}', style: defaultStyle),
                pw.Text('${c.bairro} - ${c.cidade}', style: defaultStyle),
                if (c.referencia.isNotEmpty)
                  pw.Text('Ref.: ${c.referencia}', style: defaultStyle),
              ],
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Resumo do Pedido (Salgados e Sabores)
              pw.Text('RESUMO DO PEDIDO', style: boldStyle),
              pw.Text('$totalSalgados SALGADOS', style: defaultStyle),
              pw.Text('$totalSabores SABORES', style: defaultStyle),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Itens
              for (final i in dados.itens)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('${i.quantidade}x ${i.produtoNome}',
                          style: defaultStyle),
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                          child: pw.Text('.' * 120,
                              maxLines: 1,
                              style: pw.TextStyle(
                                  fontSize: is58 ? 7 : 9,
                                  color: PdfColors.grey400)),
                        ),
                      ),
                      pw.Text(dinheiro(i.valorTotalCentavos),
                          style: defaultStyle),
                    ],
                  ),
                ),

              // Observações
              if (p.observacoes.trim().isNotEmpty) ...[
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('OBSERVAÇÕES', style: boldStyle),
                pw.Text(p.observacoes, style: defaultStyle),
              ],

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totais
              pw.Row(
                children: [
                  pw.Text('Subtotal', style: defaultStyle),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.Text('.' * 120,
                          maxLines: 1,
                          style: pw.TextStyle(
                              fontSize: is58 ? 7 : 9,
                              color: PdfColors.grey400)),
                    ),
                  ),
                  pw.Text(dinheiro(p.subtotalCentavos), style: defaultStyle),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Taxa Entrega', style: defaultStyle),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.Text('.' * 120,
                          maxLines: 1,
                          style: pw.TextStyle(
                              fontSize: is58 ? 7 : 9,
                              color: PdfColors.grey400)),
                    ),
                  ),
                  pw.Text(dinheiro(p.taxaEntregaCentavos), style: defaultStyle),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Text('TOTAL', style: boldStyle),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.Text('.' * 120,
                          maxLines: 1,
                          style: pw.TextStyle(
                              fontSize: is58 ? 7 : 9,
                              color: PdfColors.grey400)),
                    ),
                  ),
                  pw.Text(dinheiro(p.totalCentavos), style: boldStyle),
                ],
              ),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Forma de pagamento
              pw.Text('Pagamento', style: boldStyle),
              pw.Text(p.formaPagamento.toUpperCase(), style: defaultStyle),
              if (p.trocoParaCentavos != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Troco para: ${dinheiro(p.trocoParaCentavos!)}', style: defaultStyle),
              ],

              // Bloco PIX na comanda PDF
              if (p.formaPagamento.toLowerCase().contains('pix') && (cfg.habilitarPix || cfg.pixChave.isNotEmpty)) ...[
                () {
                  final double valorPix = p.totalCentavos / 100.0;
                  final copiaCola = PixGenerator.gerarCopiaCola(
                    chave: cfg.pixChave,
                    favorecido: cfg.pixFavorecido,
                    cidade: cfg.pixCidade.isNotEmpty ? cfg.pixCidade : 'Sorocaba',
                    valor: valorPix,
                    mensagem: cfg.pixMensagem.isNotEmpty ? cfg.pixMensagem : 'Salgaderia',
                  );

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 6),
                      pw.Divider(borderStyle: pw.BorderStyle.dashed),
                      pw.Center(
                        child: pw.Text('PAGAMENTO VIA PIX', style: boldStyle),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Center(
                        child: pw.Text('Chave: ${cfg.pixChave} (${cfg.pixTipoChave.toUpperCase()})', style: boldStyle),
                      ),
                      pw.Center(
                        child: pw.Text('Favorecido: ${cfg.pixFavorecido}', style: defaultStyle),
                      ),
                      if (cfg.pixBanco.trim().isNotEmpty)
                        pw.Center(
                          child: pw.Text('Banco: ${cfg.pixBanco.trim()}', style: defaultStyle),
                        ),
                      if (cfg.pixImprimirQrCode) ...[
                        pw.SizedBox(height: 6),
                        pw.Center(
                          child: pw.Container(
                            width: is58 ? 40 : 50,
                            height: is58 ? 40 : 50,
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: copiaCola,
                              drawText: false,
                            ),
                          ),
                        ),
                      ],
                      if (cfg.pixImprimirCopiaCola) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('PIX COPIA E COLA:', style: boldStyle),
                        pw.Text(
                          copiaCola,
                          style: pw.TextStyle(fontSize: is58 ? 6 : 7.5, color: PdfColors.grey700),
                        ),
                      ],
                      if (cfg.pixMensagem.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Center(
                          child: pw.Text(cfg.pixMensagem, style: pw.TextStyle(fontSize: is58 ? 8 : 9, fontStyle: pw.FontStyle.italic)),
                        ),
                      ],
                    ],
                  );
                }(),
              ],

              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Obrigado pela preferência!',
                  style: defaultStyle,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  cfg.empresa,
                  style: boldStyle,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Bom apetite!',
                  style: defaultStyle,
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Future<void> imprimirPedido(PedidoCompleto dados, AppSettings cfg) async {
    final pdfBytes = await gerarPdfBytes(dados, cfg);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Pedido #${pedidoNumero(dados.pedido.numero)}',
      format: cfg.largura == 58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
    );
  }

  @override
  Future<bool> testarConexao(String destino) async {
    final impressoras = await Printing.listPrinters();
    return impressoras.isNotEmpty;
  }
}
