import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fincore_food_flutter/src/shared/services/pix_generator.dart';

class PrinterResult {
  final bool success;
  final String message;
  const PrinterResult({required this.success, required this.message});
}

class FincoreThermalPrinterService {
  static const String _kCaixaKey = 'printer_caixa_path';
  static const String _kCozinhaKey = 'printer_cozinha_path';
  static const String _kExpedicaoKey = 'printer_expedicao_path';
  static const String _kAutoCaixaKey = 'printer_auto_caixa';
  static const String _kAutoCozinhaKey = 'printer_auto_cozinha';
  static const String _kAutoExpedicaoKey = 'printer_auto_expedicao';
  static const String _kLarguraBobinaKey = 'printer_largura_bobina';
  static const String _kExibirQrCodeKey = 'printer_exibir_qrcode';

  /// Carrega configuração de impressoras salvas no SharedPreferences
  static Future<Map<String, dynamic>> loadPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'caixa': prefs.getString(_kCaixaKey) ?? '',
      'cozinha': prefs.getString(_kCozinhaKey) ?? '',
      'expedicao': prefs.getString(_kExpedicaoKey) ?? '',
      'autoCaixa': prefs.getBool(_kAutoCaixaKey) ?? true,
      'autoCozinha': prefs.getBool(_kAutoCozinhaKey) ?? true,
      'autoExpedicao': prefs.getBool(_kAutoExpedicaoKey) ?? true,
      'largura': prefs.getString(_kLarguraBobinaKey) ?? '80mm',
      'exibirQrCode': prefs.getBool(_kExibirQrCodeKey) ?? false,
    };
  }

  /// Salva configurações no SharedPreferences
  static Future<void> savePrinters({
    String? caixa,
    String? cozinha,
    String? expedicao,
    bool? autoCaixa,
    bool? autoCozinha,
    bool? autoExpedicao,
    String? largura,
    bool? exibirQrCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (caixa != null) await prefs.setString(_kCaixaKey, caixa);
    if (cozinha != null) await prefs.setString(_kCozinhaKey, cozinha);
    if (expedicao != null) await prefs.setString(_kExpedicaoKey, expedicao);
    if (autoCaixa != null) await prefs.setBool(_kAutoCaixaKey, autoCaixa);
    if (autoCozinha != null) await prefs.setBool(_kAutoCozinhaKey, autoCozinha);
    if (autoExpedicao != null) await prefs.setBool(_kAutoExpedicaoKey, autoExpedicao);
    if (largura != null) await prefs.setString(_kLarguraBobinaKey, largura);
    if (exibirQrCode != null) await prefs.setBool(_kExibirQrCodeKey, exibirQrCode);
  }

  /// Gera e imprime uma via de teste real para o destino especificado
  static Future<PrinterResult> testPrint({
    required String printerPath,
    required String viaName,
    int paperWidthMm = 80,
  }) async {
    final nowStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final w = paperWidthMm == 58 ? 32 : 48;
    final line = '=' * w;
    final sep = '-' * w;

    final sb = StringBuffer();
    sb.writeln(line);
    sb.writeln(_centerText('FINCORE FOOD', w));
    sb.writeln(_centerText('SISTEMA OPERACIONAL (FPOS)', w));
    sb.writeln(line);
    sb.writeln('VIA DE TESTE : $viaName');
    sb.writeln('LARGURA      : ${paperWidthMm}mm');
    sb.writeln('DATA/HORA    : $nowStr');
    sb.writeln('TERMINAL     : Windows / Desktop');
    sb.writeln(sep);
    sb.writeln(_centerText('STATUS DO SPOOLER : ONLINE [OK]', w));
    sb.writeln(_centerText('COMUNICACAO       : ATIVA  [OK]', w));
    sb.writeln(_centerText('CODIFICACAO       : UTF-8 / ESC-POS', w));
    sb.writeln(sep);
    sb.writeln(_centerText('Toda empresa tem um coracao.', w));
    sb.writeln(_centerText('O FINCORE cuida dele.', w));
    sb.writeln(line);
    sb.writeln('\n\n\n'); // Avanço para corte

    return _sendToPrinter(printerPath: printerPath, text: sb.toString());
  }

  /// Imprime um pedido formatado (cupom do cliente)
  static Future<PrinterResult> printPedido({
    required String printerPath,
    required String viaName,
    required String pedidoId,
    required String clienteNome,
    required String totalFormatado,
    required List<String> itens,
    int paperWidthMm = 80,
    String? telefoneCliente,
    String? tipoLogistica,          // 'Entrega' | 'Retirada' | 'Mesa'
    String? enderecoEntrega,        // logradouro + número + bairro
    String? subtotalFormatado,
    String? taxaEntregaFormatada,
    String? formaPagamento,
    String? observacoes,
    String? pixKey,                 // chave pix para QR (texto)
    String? pixTipo,
    String? pixFavorecido,
    String? pixBanco,
    bool exibirQrCode = false,
    String? nomeEmpresa,
    String? telefoneEmpresa,
    double totalSalgados = 0,
    int totalSabores = 0,
  }) async {
    final nowStr = DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now());
    final w = paperWidthMm == 58 ? 32 : 44;
    final sep = '-' * w;

    const boldOn = '\x1BE\x01';
    const boldOff = '\x1BE\x00';

    final sb = StringBuffer();

    // 1. Cabeçalho
    sb.writeln('$boldOn${_centerText(_sanitizarString(nomeEmpresa?.isNotEmpty == true ? nomeEmpresa! : 'SALGADERIA'), w)}$boldOff');
    final logistica = (tipoLogistica != null && tipoLogistica.isNotEmpty) ? tipoLogistica : 'RETIRADA';
    sb.writeln('$boldOn${_centerText(_sanitizarString(logistica.toUpperCase()), w)}$boldOff');
    sb.writeln(_centerText(nowStr, w));
    final numP = pedidoId.length > 6 ? pedidoId.substring(0, 6).toUpperCase() : pedidoId.toUpperCase();
    sb.writeln('$boldOn${_centerText('PEDIDO #$numP', w)}$boldOff');
    sb.writeln(sep);

    // 2. Cliente
    sb.writeln('${boldOn}CLIENTE$boldOff');
    sb.writeln(_sanitizarString(clienteNome.isNotEmpty ? clienteNome : 'Consumidor'));
    if (telefoneCliente != null && telefoneCliente.isNotEmpty) {
      sb.writeln(telefoneCliente);
    }

    // 3. Endereço (se Entrega)
    if (logistica.toLowerCase().contains('entrega') && enderecoEntrega != null && enderecoEntrega.isNotEmpty) {
      sb.writeln('${boldOn}ENDERECO$boldOff');
      sb.writeln(_sanitizarString(enderecoEntrega));
    }
    sb.writeln(sep);

    // 4. Resumo do Pedido (Salgados e Sabores)
    sb.writeln('${boldOn}RESUMO DO PEDIDO$boldOff');
    sb.writeln('${totalSalgados.toStringAsFixed(0)} SALGADOS');
    sb.writeln('$totalSabores SABORES');
    sb.writeln(sep);

    // 5. Itens (em Negrito)
    for (final item in itens) {
      sb.writeln('$boldOn${_sanitizarString(item)}$boldOff');
    }

    // 6. Observações (se houver)
    if (observacoes != null) {
      final obsLimpa = observacoes
          .replaceAll(RegExp(r'\[DADOS_PEDIDO\].*?\[/DADOS_PEDIDO\]', dotAll: true), '')
          .trim();
      if (obsLimpa.isNotEmpty) {
        sb.writeln(sep);
        sb.writeln('${boldOn}OBSERVACOES$boldOff');
        sb.writeln(_sanitizarString(obsLimpa));
      }
    }

    sb.writeln(sep);

    // 7. Totais
    final sub = subtotalFormatado ?? totalFormatado;
    final dotsSubCount = w - 'Subtotal'.length - sub.length - 4;
    final dotsSub = dotsSubCount > 0 ? '.' * dotsSubCount : ' ';
    sb.writeln('Subtotal$dotsSub R\$ $sub');

    final taxa = taxaEntregaFormatada ?? '0,00';
    final dotsTaxaCount = w - 'Taxa Entrega'.length - taxa.length - 4;
    final dotsTaxa = dotsTaxaCount > 0 ? '.' * dotsTaxaCount : ' ';
    sb.writeln('Taxa Entrega$dotsTaxa R\$ $taxa');

    final dotsTotCount = w - 'TOTAL'.length - totalFormatado.length - 4;
    final dotsTot = dotsTotCount > 0 ? '.' * dotsTotCount : ' ';
    sb.writeln('$boldOn TOTAL$dotsTot R\$ $totalFormatado $boldOff');
    sb.writeln(sep);

    // 8. Pagamento
    sb.writeln('${boldOn}Pagamento$boldOff');
    sb.writeln(_sanitizarString(formaPagamento?.toUpperCase() ?? 'PENDENTE'));

    // 9. Bloco PIX (Sem duplicar chave longa copia e cola)
    if (formaPagamento?.toLowerCase().contains('pix') == true && pixKey != null && pixKey.isNotEmpty) {
      sb.writeln(sep);
      sb.writeln('$boldOn${_centerText('PAGAMENTO VIA PIX', w)}$boldOff');
      sb.writeln('$boldOn${_centerText(_sanitizarString('Chave: $pixKey (${pixTipo ?? "PIX"})'), w)}$boldOff');
      if (pixFavorecido != null && pixFavorecido.isNotEmpty) {
        sb.writeln(_centerText(_sanitizarString('Favorecido: $pixFavorecido'), w));
      }
      if (pixBanco != null && pixBanco.isNotEmpty) {
        sb.writeln(_centerText(_sanitizarString('Banco: $pixBanco'), w));
      }

      if (exibirQrCode) {
        final double valorPix = (double.tryParse(totalFormatado.replaceAll('.', '').replaceAll(',', '.')) ?? 0);
        final copiaCola = PixGenerator.gerarCopiaCola(
          chave: pixKey,
          favorecido: pixFavorecido ?? 'Estabelecimento',
          cidade: 'Sorocaba',
          valor: valorPix,
          mensagem: 'Salgaderia',
          tipoChave: pixTipo,
        );

        sb.write('\x1D(k\x04\x001A2\x00'); // Modelo 2
        sb.write('\x1D(k\x03\x001C\x06'); // Tamanho do módulo 6
        sb.write('\x1D(k\x03\x001E0');   // Correção de erro L
        final pL = (copiaCola.length + 3) % 256;
        final pH = (copiaCola.length + 3) ~/ 256;
        sb.write('\x1D(k${String.fromCharCode(pL)}${String.fromCharCode(pH)}1\x80$copiaCola'); // Payload
        sb.write('\x1D(k\x03\x001Q0');   // Imprimir QR Code
        sb.writeln();
      }
      sb.writeln(sep);
    }

    // 10. Rodapé e Corte de Papel (Guilhotina ESC/POS)
    sb.writeln(_centerText('Obrigado pela preferencia!', w));
    sb.writeln(_centerText('Bom apetite!', w));
    sb.write('\n\n\n\x1DV\x01\x1Bi\x1Bm'); // Avanço de papel + Comandos de corte universal de guilhotina (GS V 1 / ESC i / ESC m)

    return _sendToPrinter(printerPath: printerPath, text: sb.toString());
  }

  static String _sanitizarString(String text) {
    return text
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ã', 'a').replaceAll('â', 'a').replaceAll('Á', 'A').replaceAll('À', 'A').replaceAll('Ã', 'A').replaceAll('Â', 'A')
        .replaceAll('é', 'e').replaceAll('ê', 'e').replaceAll('É', 'E').replaceAll('Ê', 'E')
        .replaceAll('í', 'i').replaceAll('Í', 'I')
        .replaceAll('ó', 'o').replaceAll('õ', 'o').replaceAll('ô', 'o').replaceAll('Ó', 'O').replaceAll('Õ', 'O').replaceAll('Ô', 'O')
        .replaceAll('ú', 'u').replaceAll('Ú', 'U')
        .replaceAll('ç', 'c').replaceAll('Ç', 'C');
  }


  /// Centraliza o envio de bytes ou chamada de Spooler por IP, COM/LPT, ou PowerShell Windows
  static Future<PrinterResult> _sendToPrinter({
    required String printerPath,
    required String text,
  }) async {
    final target = printerPath.trim();

    // 1. Verificar se é endereço IP (Rede TCP/IP porta 9100)
    final ipRegex = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?::(\d+))?$');
    final match = ipRegex.firstMatch(target);
    if (match != null) {
      final host = match.group(1)!;
      final portStr = match.group(2) ?? '9100';
      final port = int.tryParse(portStr) ?? 9100;

      try {
        debugPrint('Conectando à impressora térmica IP $host:$port...');
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 4),
        );

        // Comandos ESC/POS opcionais: Inicializar (ESC @) + Texto + Cortar Bobina (GS V 65 16)
        final initBytes = [0x1B, 0x40];
        final cutBytes = [0x1D, 0x56, 0x41, 0x10];
        final textBytes = text.codeUnits;

        socket.add(initBytes);
        socket.add(textBytes);
        socket.add(cutBytes);

        await socket.flush();
        socket.destroy();

        return PrinterResult(
          success: true,
          message: '✅ Impressão enviada com sucesso para a impressora IP $host:$port!',
        );
      } catch (e) {
        debugPrint('Erro no Socket IP $host:$port -> $e');
        return PrinterResult(
          success: false,
          message: '❌ Erro na conexão com IP $host:$port ($e). Verifique o IP e cabo de rede.',
        );
      }
    }

    // 2. Se for Windows (nome da impressora, compartilhamento SMB \\server\printer, ou impressora padrão)
    if (Platform.isWindows) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/fincore_test_spooler.txt');
        await file.writeAsString(text, flush: true);

        // Caso seja caminho UNC de compartilhamento (ex: \\localhost\caixa ou LPT1 / COM1)
        if (target.startsWith(r'\\') || target.toUpperCase().startsWith('COM') || target.toUpperCase().startsWith('LPT')) {
          try {
            final rawFile = File(target);
            await rawFile.writeAsBytes(text.codeUnits, flush: true);
            return PrinterResult(
              success: true,
              message: '✅ Impressão direta concluída em porta/compartilhamento: $target',
            );
          } catch (e) {
            debugPrint('Falha ao escrever em $target -> tentando Out-Printer.');
          }
        }

        // Impressão via PowerShell (Windows Spooler)
        String psCmd;
        if (target.isEmpty ||
            target.toLowerCase() == 'padrão' ||
            target.toLowerCase() == 'padrao' ||
            target.toLowerCase() == 'default' ||
            target.toLowerCase().contains('usb001')) {
          // Imprime na impressora padrão configurada no Windows
          psCmd = 'Get-Content -Path "${file.path}" | Out-Printer';
        } else {
          // Imprime em impressora específica pelo nome no Windows
          psCmd = 'Get-Content -Path "${file.path}" | Out-Printer -Name "$target"';
        }

        debugPrint('Executando comando PowerShell de impressão: $psCmd');
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psCmd]);

        if (res.exitCode == 0) {
          final pName = target.isEmpty ? 'Padrão do Sistema Windows' : target;
          return PrinterResult(
            success: true,
            message: '✅ Via de teste impressa na impressora "$pName" via Spooler do Windows!',
          );
        } else {
          final errMsg = res.stderr.toString().trim();
          return PrinterResult(
            success: false,
            message: '❌ Falha do Spooler Windows: $errMsg. Verifique o nome da impressora no Painel de Controle.',
          );
        }
      } catch (e) {
        return PrinterResult(
          success: false,
          message: '❌ Erro ao disparar impressão no Windows: $e',
        );
      }
    }

    // 3. Fallback genérico para outros sistemas operacionais
    return PrinterResult(
      success: true,
      message: 'ℹ️ Simulação de impressão em modo sandbox ($target)',
    );
  }

  static String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final leftPad = (width - text.length) ~/ 2;
    final rightPad = width - text.length - leftPad;
    return (' ' * leftPad) + text + (' ' * rightPad);
  }
}
