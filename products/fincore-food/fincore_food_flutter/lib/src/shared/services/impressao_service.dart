import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';

// ─── Modelo de configurações de impressão ──────────────────────────────────

class FincoreImpressaoConfig {
  final String nomeEmpresa;
  final String telefone;
  final int larguraMm; // 58 ou 80
  final bool habilitarQrCodePix;
  final bool habilitarCopiaCola;
  final String pixChave;
  final String pixTipo;
  final String pixFavorecido;
  final String pixBanco;
  final String rodape;

  const FincoreImpressaoConfig({
    this.nomeEmpresa = 'FINCORE FOOD',
    this.telefone = '',
    this.larguraMm = 80,
    this.habilitarQrCodePix = false,
    this.habilitarCopiaCola = false,
    this.pixChave = '',
    this.pixTipo = 'PIX',
    this.pixFavorecido = '',
    this.pixBanco = '',
    this.rodape = 'Obrigado pela preferência!',
  });

  static const _kEmpresa = 'imp_empresa';
  static const _kTelefone = 'imp_telefone';
  static const _kLargura = 'imp_largura';
  static const _kQrCode = 'imp_qrcode';
  static const _kCopiaCola = 'imp_copiacola';
  static const _kPixChave = 'imp_pix_chave';
  static const _kPixTipo = 'imp_pix_tipo';
  static const _kPixFavorecido = 'imp_pix_favorecido';
  static const _kPixBanco = 'imp_pix_banco';
  static const _kRodape = 'imp_rodape';

  static Future<FincoreImpressaoConfig> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    return FincoreImpressaoConfig(
      nomeEmpresa: prefs.getString(_kEmpresa) ?? 'FINCORE FOOD',
      telefone: prefs.getString(_kTelefone) ?? '',
      larguraMm: prefs.getInt(_kLargura) ?? 80,
      habilitarQrCodePix: prefs.getBool(_kQrCode) ?? false,
      habilitarCopiaCola: prefs.getBool(_kCopiaCola) ?? false,
      pixChave: prefs.getString(_kPixChave) ?? '',
      pixTipo: prefs.getString(_kPixTipo) ?? 'PIX',
      pixFavorecido: prefs.getString(_kPixFavorecido) ?? '',
      pixBanco: prefs.getString(_kPixBanco) ?? '',
      rodape: prefs.getString(_kRodape) ?? 'Obrigado pela preferência!',
    );
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmpresa, nomeEmpresa);
    await prefs.setString(_kTelefone, telefone);
    await prefs.setInt(_kLargura, larguraMm);
    await prefs.setBool(_kQrCode, habilitarQrCodePix);
    await prefs.setBool(_kCopiaCola, habilitarCopiaCola);
    await prefs.setString(_kPixChave, pixChave);
    await prefs.setString(_kPixTipo, pixTipo);
    await prefs.setString(_kPixFavorecido, pixFavorecido);
    await prefs.setString(_kPixBanco, pixBanco);
    await prefs.setString(_kRodape, rodape);
  }

  FincoreImpressaoConfig copyWith({
    String? nomeEmpresa,
    String? telefone,
    int? larguraMm,
    bool? habilitarQrCodePix,
    bool? habilitarCopiaCola,
    String? pixChave,
    String? pixTipo,
    String? pixFavorecido,
    String? pixBanco,
    String? rodape,
  }) {
    return FincoreImpressaoConfig(
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      telefone: telefone ?? this.telefone,
      larguraMm: larguraMm ?? this.larguraMm,
      habilitarQrCodePix: habilitarQrCodePix ?? this.habilitarQrCodePix,
      habilitarCopiaCola: habilitarCopiaCola ?? this.habilitarCopiaCola,
      pixChave: pixChave ?? this.pixChave,
      pixTipo: pixTipo ?? this.pixTipo,
      pixFavorecido: pixFavorecido ?? this.pixFavorecido,
      pixBanco: pixBanco ?? this.pixBanco,
      rodape: rodape ?? this.rodape,
    );
  }
}

// ─── Dados do Pedido para Impressão ────────────────────────────────────────

class DadosImpressaoPedido {
  final String numeroPedido;
  final String nomeCliente;
  final String? telefoneCliente;
  final String? enderecoCliente;
  final String tipoEntrega; // 'Entrega' | 'Retirada' | 'Balcão' | 'Mesa X'
  final DateTime dataHora;
  final List<ItemImpressao> itens;
  final int subtotalCentavos;
  final int taxaEntregaCentavos;
  final int totalCentavos;
  final String formaPagamento;
  final String? observacoes;

  const DadosImpressaoPedido({
    required this.numeroPedido,
    required this.nomeCliente,
    this.telefoneCliente,
    this.enderecoCliente,
    required this.tipoEntrega,
    required this.dataHora,
    required this.itens,
    required this.subtotalCentavos,
    this.taxaEntregaCentavos = 0,
    required this.totalCentavos,
    required this.formaPagamento,
    this.observacoes,
  });
}

class ItemImpressao {
  final String nome;
  final double quantidade;
  final int precoUnitarioCentavos;
  final int totalCentavos;

  const ItemImpressao({
    required this.nome,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.totalCentavos,
  });
}

// ─── Gerador de PDF ────────────────────────────────────────────────────────

class FincorePdfGerador {
  static String _dinheiro(int centavos) {
    return 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static Future<Uint8List> gerarBytes(
    DadosImpressaoPedido dados,
    FincoreImpressaoConfig cfg,
  ) async {
    final pdf = pw.Document();
    final is58 = cfg.larguraMm == 58;
    final double width = is58 ? 58 : 80;

    final isEntrega = dados.tipoEntrega.toLowerCase().contains('entrega');

    // Calcular altura dinâmica da bobina em milímetros
    double height = 80; // Altura base (cabeçalho, cliente, margens)

    if (isEntrega) {
      height += 25; // Altura do endereço
    }

    height += dados.itens.length * 6.5; // 6.5mm por item

    if (dados.observacoes != null && dados.observacoes!.isNotEmpty) {
      height += 15 + (dados.observacoes!.length / 30).ceil() * 5.0; // Altura observações
    }

    height += 35; // Seção de totais e pagamento

    if (dados.formaPagamento.toLowerCase().contains('pix') && (cfg.habilitarQrCodePix || cfg.pixChave.isNotEmpty)) {
      height += 25;
      if (cfg.habilitarQrCodePix) height += 40;
      if (cfg.habilitarCopiaCola) height += 20;
    }

    height += 20; // Altura do rodapé

    final pageSize = PdfPageFormat(
      width * PdfPageFormat.mm,
      height * PdfPageFormat.mm,
      marginAll: 2 * PdfPageFormat.mm,
    );

    final defaultStyle = pw.TextStyle(fontSize: is58 ? 9 : 11);
    final boldStyle = pw.TextStyle(fontSize: is58 ? 9 : 11, fontWeight: pw.FontWeight.bold);
    final largeStyle = pw.TextStyle(fontSize: is58 ? 10 : 12, fontWeight: pw.FontWeight.bold);

    final formatData = DateFormat('dd/MM/yyyy - HH:mm').format(dados.dataHora);
    final totalSalgados = dados.itens.fold<double>(0, (sum, i) => sum + i.quantidade);
    final totalSabores = dados.itens.length;

    pdf.addPage(
      pw.Page(
        pageFormat: pageSize,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  cfg.nomeEmpresa.isEmpty ? 'SALGADERIA' : cfg.nomeEmpresa,
                  style: largeStyle,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  isEntrega ? 'ENTREGA' : dados.tipoEntrega.toUpperCase(),
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
                  'PEDIDO #${dados.numeroPedido}',
                  style: boldStyle,
                ),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Cliente
              pw.Text('CLIENTE', style: boldStyle),
              pw.Text(dados.nomeCliente, style: defaultStyle),
              if (dados.telefoneCliente != null && dados.telefoneCliente!.isNotEmpty)
                pw.Text(dados.telefoneCliente!, style: defaultStyle),

              if (dados.enderecoCliente != null && dados.enderecoCliente!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('ENDEREÇO', style: boldStyle),
                pw.Text(dados.enderecoCliente!, style: defaultStyle),
              ],
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Resumo do Pedido (Salgados e Sabores)
              pw.Text('RESUMO DO PEDIDO', style: boldStyle),
              pw.Text('${totalSalgados.toStringAsFixed(0)} SALGADOS', style: defaultStyle),
              pw.Text('$totalSabores SABORES', style: defaultStyle),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Itens com linha pontilhada idêntica à Salgaderia
              for (final i in dados.itens)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('${i.quantidade.toStringAsFixed(0)}x ${i.nome}', style: defaultStyle),
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                          child: pw.Text(
                            '.' * 120,
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: is58 ? 7 : 9,
                              color: PdfColors.grey400,
                            ),
                          ),
                        ),
                      ),
                      pw.Text(_dinheiro(i.totalCentavos), style: defaultStyle),
                    ],
                  ),
                ),

              // Observações
              () {
                final rawObs = dados.observacoes ?? '';
                final obsLimpa = rawObs
                    .replaceAll(RegExp(r'\[DADOS_PEDIDO\].*?\[/DADOS_PEDIDO\]', dotAll: true), '')
                    .trim();

                if (obsLimpa.isEmpty) return pw.SizedBox();

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Divider(borderStyle: pw.BorderStyle.dashed),
                    pw.Text('OBSERVAÇÕES', style: boldStyle),
                    pw.Text(obsLimpa, style: defaultStyle),
                  ],
                );
              }(),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totais com linha pontilhada idêntica à Salgaderia
              pw.Row(
                children: [
                  pw.Text('Subtotal', style: defaultStyle),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.Text('.' * 120, maxLines: 1, style: pw.TextStyle(fontSize: is58 ? 7 : 9, color: PdfColors.grey400)),
                    ),
                  ),
                  pw.Text(_dinheiro(dados.subtotalCentavos), style: defaultStyle),
                ],
              ),
              if (dados.taxaEntregaCentavos > 0)
                pw.Row(
                  children: [
                    pw.Text('Taxa Entrega', style: defaultStyle),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                        child: pw.Text('.' * 120, maxLines: 1, style: pw.TextStyle(fontSize: is58 ? 7 : 9, color: PdfColors.grey400)),
                      ),
                    ),
                    pw.Text(_dinheiro(dados.taxaEntregaCentavos), style: defaultStyle),
                  ],
                ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Text('TOTAL', style: boldStyle),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.Text('.' * 120, maxLines: 1, style: pw.TextStyle(fontSize: is58 ? 7 : 9, color: PdfColors.grey400)),
                    ),
                  ),
                  pw.Text(_dinheiro(dados.totalCentavos), style: boldStyle),
                ],
              ),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Forma de pagamento
              pw.Text('Pagamento', style: boldStyle),
              pw.Text(dados.formaPagamento.toUpperCase(), style: defaultStyle),

              // Bloco PIX com QR Code e Copia e Cola idêntico ao Salgaderia
              if (dados.formaPagamento.toLowerCase().contains('pix') && cfg.pixChave.isNotEmpty) ...[
                () {
                  final copiaCola = PixGenerator.gerarCopiaCola(
                    chave: cfg.pixChave,
                    favorecido: cfg.pixFavorecido.isNotEmpty ? cfg.pixFavorecido : 'Estabelecimento',
                    cidade: 'Sorocaba',
                    valor: dados.totalCentavos / 100.0,
                    mensagem: 'Salgaderia',
                  );

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 6),
                      pw.Divider(borderStyle: pw.BorderStyle.dashed),
                      pw.Center(child: pw.Text('PAGAMENTO VIA PIX', style: boldStyle)),
                      pw.SizedBox(height: 2),
                      pw.Center(child: pw.Text('Chave: ${cfg.pixChave} (${cfg.pixTipo.toUpperCase()})', style: boldStyle)),
                      if (cfg.pixFavorecido.isNotEmpty)
                        pw.Center(child: pw.Text('Favorecido: ${cfg.pixFavorecido}', style: defaultStyle)),
                      if (cfg.pixBanco.isNotEmpty)
                        pw.Center(child: pw.Text('Banco: ${cfg.pixBanco}', style: defaultStyle)),
                      pw.SizedBox(height: 6),
                      pw.Center(
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: copiaCola,
                          width: 80,
                          height: 80,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('PIX COPIA E COLA:', style: boldStyle),
                      pw.Text(copiaCola, style: pw.TextStyle(fontSize: is58 ? 6 : 7)),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: pw.Text('Envie o comprovante após o pagamento', style: pw.TextStyle(fontSize: is58 ? 7 : 8, fontStyle: pw.FontStyle.italic)),
                      ),
                    ],
                  );
                }(),
              ],

              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Center(child: pw.Text(cfg.rodape, style: defaultStyle)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

// ─── Diálogo de Ação Pós-Pedido ────────────────────────────────────────────

/// Exibe um dialog perguntando se deseja imprimir, visualizar ou não imprimir.
/// Retorna true se o fluxo de impressão foi concluído, false caso contrário.
class DialogImpressao {
  static Future<void> mostrar(
    BuildContext context, {
    required DadosImpressaoPedido dados,
    required FincoreImpressaoConfig config,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogImpressaoWidget(
        dados: dados,
        config: config,
      ),
    );
  }
}

class _DialogImpressaoWidget extends StatelessWidget {
  final DadosImpressaoPedido dados;
  final FincoreImpressaoConfig config;

  const _DialogImpressaoWidget({
    required this.dados,
    required this.config,
  });

  Future<void> _imprimir(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    try {
      final bytes = await FincorePdfGerador.gerarBytes(dados, config);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Pedido #${dados.numeroPedido}',
        format: config.larguraMm == 58
            ? PdfPageFormat.roll57
            : PdfPageFormat.roll80,
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Erro ao imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _visualizar(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    await showDialog<void>(
      context: ctx,
      builder: (dlgCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 520,
          height: 680,
          child: Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xFF1A1A2E),
                title: Text('Cupom — Pedido #${dados.numeroPedido}',
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dlgCtx).pop(),
                  ),
                ],
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) => FincorePdfGerador.gerarBytes(dados, config),
                  allowPrinting: true,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B2B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFFF6B2B),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pedido Finalizado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'O que deseja fazer com o cupom do Pedido #${dados.numeroPedido}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Imprimir
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _imprimir(context),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text(
                  'Imprimir Agora',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B2B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Visualizar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _visualizar(context),
                icon: const Icon(Icons.preview_rounded, size: 18),
                label: const Text(
                  'Visualizar Cupom',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF374151)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Não imprimir
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Não imprimir agora',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
