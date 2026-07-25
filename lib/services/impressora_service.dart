import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/domain_models.dart';
import 'settings_service.dart';

class ImpressoraService {
  Future<void> imprimir(PedidoCompleto dados, AppSettings cfg) async {
    final profile = await CapabilityProfile.load();
    final generator =
        Generator(cfg.largura == 58 ? PaperSize.mm58 : PaperSize.mm80, profile);
    final p = dados.pedido, c = dados.cliente;
    final bytes = <int>[];
    bytes.addAll(generator.text(cfg.empresa,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2)));
    bytes.addAll(generator.text(p.tipoEntrega.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Pedido Nº ${pedidoNumero(p.numero)}',
        styles: const PosStyles(bold: true)));
    bytes.addAll(generator.text('${c.nome}\n${c.telefone}'));
    bytes.addAll(generator.text(
        'Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(p.dataEntrega)}'));
    if (p.tipoEntrega == 'Entrega')
      bytes.addAll(generator.text(
          '${c.logradouro}, ${c.numero}\n${c.bairro} - ${c.cidade}\nRef.: ${c.referencia}'));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('ITENS', styles: const PosStyles(bold: true)));
    for (final i in dados.itens)
      bytes.addAll(generator.row([
        PosColumn(text: '${i.quantidade}x ${i.produtoNome}', width: 8),
        PosColumn(
            text: dinheiro(i.valorTotalCentavos),
            width: 4,
            styles: const PosStyles(align: PosAlign.right))
      ]));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal', width: 7),
      PosColumn(
          text: dinheiro(p.subtotalCentavos),
          width: 5,
          styles: const PosStyles(align: PosAlign.right))
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'Entrega', width: 7),
      PosColumn(
          text: dinheiro(p.taxaEntregaCentavos),
          width: 5,
          styles: const PosStyles(align: PosAlign.right))
    ]));
    bytes.addAll(generator.text('TOTAL ${dinheiro(p.totalCentavos)}',
        styles: const PosStyles(
            align: PosAlign.right, bold: true, height: PosTextSize.size2)));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Pagamento: ${p.formaPagamento}'));
    if (p.trocoParaCentavos != null)
      bytes.addAll(
          generator.text('Troco para: ${dinheiro(p.trocoParaCentavos!)}'));
    if (p.observacoes.isNotEmpty)
      bytes.addAll(generator.text('Observações: ${p.observacoes}'));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(cfg.rodape,
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.cut());
    final arquivo =
        File('${Directory.systemTemp.path}\\salgaderia_ultimo_pedido.bin');
    await arquivo.writeAsBytes(bytes);
    if (cfg.impressora.trim().isNotEmpty) {
      final destino = '\\\\${cfg.impressora.replaceAll('/', '\\')}';
      final result =
          await Process.run('cmd', ['/c', 'copy', '/b', arquivo.path, destino]);
      if (result.exitCode != 0)
        throw Exception('Falha ao imprimir: ${result.stderr}');
    }
  }
}
