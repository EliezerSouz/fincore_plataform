import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Resultado de uma operação de impressão.
class PrinterResult {
  final bool success;
  final String message;
  final int elapsedMs;

  const PrinterResult({
    required this.success,
    required this.message,
    this.elapsedMs = 0,
  });
}

/// Driver de impressão que abstrai o envio de texto para impressoras térmicas.
///
/// Suporta:
/// - **IP/TCP (porta 9100)**: conexão direta via Socket
/// - **Windows Spooler (UNC)**: via PowerShell `Out-Printer`
/// - **COM/LPT**: via PowerShell raw device write
///
/// A UI **nunca** interage com este driver diretamente.
/// O [PrintManager] é responsável por orquestrar as chamadas.
class PrinterDriver {
  const PrinterDriver();

  /// Envia texto formatado para uma impressora específica.
  /// Não abre diálogo — usa a impressora pelo path/IP configurado.
  Future<PrinterResult> send({
    required String printerPath,
    required String text,
    bool cortarPapel = true,
    bool abrirGaveta = false,
    int larguraPapel = 80,
  }) async {
    final sw = Stopwatch()..start();
    if (kIsWeb) {
      return PrinterResult(
        success: false,
        message: 'Impressão física direta não suportada no ambiente Web',
        elapsedMs: sw.elapsedMilliseconds,
      );
    }
    final target = printerPath.trim();

    if (target.isEmpty) {
      return PrinterResult(
        success: false,
        message: 'Nenhuma impressora configurada',
        elapsedMs: sw.elapsedMilliseconds,
      );
    }

    try {
      // Sanitizar texto (ESC/POS não suporta acentos)
      final sanitized = _sanitizar(text);

      // Detectar tipo de conexão
      final ipRegex = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?::(\d+))?$');
      final match = ipRegex.firstMatch(target);

      if (match != null) {
        // ─── IP/TCP (Rede) ─────────────────────────────────────────
        return await _sendViaSocket(
          host: match.group(1)!,
          port: int.tryParse(match.group(2) ?? '9100') ?? 9100,
          text: sanitized,
          cortarPapel: cortarPapel,
          abrirGaveta: abrirGaveta,
          larguraPapel: larguraPapel,
          stopwatch: sw,
        );
      } else {
        // ─── Windows Spooler (UNC/Nome/COM/LPT) ───────────────────
        return await _sendViaSpooler(
          printerName: target,
          text: sanitized,
          cortarPapel: cortarPapel,
          abrirGaveta: abrirGaveta,
          larguraPapel: larguraPapel,
          stopwatch: sw,
        );
      }
    } catch (e) {
      sw.stop();
      return PrinterResult(
        success: false,
        message: 'Erro ao imprimir: $e',
        elapsedMs: sw.elapsedMilliseconds,
      );
    }
  }

  // ─── IP/TCP ──────────────────────────────────────────────────────

  Future<PrinterResult> _sendViaSocket({
    required String host,
    required int port,
    required String text,
    required bool cortarPapel,
    required bool abrirGaveta,
    required int larguraPapel,
    required Stopwatch stopwatch,
  }) async {
    try {
      debugPrint('[PrinterDriver] Conectando IP $host:$port...');
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 4),
      );

      final bytes = await _compileBytes(
        text,
        cortarPapel: cortarPapel,
        abrirGaveta: abrirGaveta,
        larguraPapel: larguraPapel,
      );
      socket.add(bytes);

      await socket.flush();
      await socket.close();
      stopwatch.stop();

      debugPrint('[PrinterDriver] ✅ Impresso via IP $host:$port (${stopwatch.elapsedMilliseconds}ms)');
      return PrinterResult(
        success: true,
        message: 'Impresso com sucesso via $host:$port',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('[PrinterDriver] ❌ Erro de conexão IP: $e');
      return PrinterResult(
        success: false,
        message: 'Impressora offline ($host:$port): ${e.message}',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // ─── Windows Spooler ─────────────────────────────────────────────

  Future<PrinterResult> _sendViaSpooler({
    required String printerName,
    required String text,
    required bool cortarPapel,
    required bool abrirGaveta,
    required int larguraPapel,
    required Stopwatch stopwatch,
  }) async {
    // 1. Tentar gravação direta em portas físicas ou compartilhamentos UNC (ex: COM1, LPT1, \\localhost\compartilhamento)
    if (printerName.startsWith(r'\\') ||
        printerName.toUpperCase().startsWith('COM') ||
        printerName.toUpperCase().startsWith('LPT')) {
      try {
        final rawFile = File(printerName);
        final rawBytes = await _compileBytes(
          text,
          cortarPapel: cortarPapel,
          abrirGaveta: abrirGaveta,
          larguraPapel: larguraPapel,
        );
        await rawFile.writeAsBytes(rawBytes, flush: true);
        stopwatch.stop();
        debugPrint('[PrinterDriver] ✅ Impresso diretamente via porta/caminho: $printerName (${stopwatch.elapsedMilliseconds}ms)');
        return PrinterResult(
          success: true,
          message: 'Impresso com sucesso via porta/compartilhamento: $printerName',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } catch (e) {
        debugPrint('[PrinterDriver] Falha ao escrever direto em $printerName -> caindo para PowerShell: $e');
      }
    }

    // 2. Fallback para Windows Spooler (Fila de Impressão via PowerShell)
    try {
      final tempDir = Directory.systemTemp;
      final tmpFile = File('${tempDir.path}\\fincore_print_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final cleanText = _stripTagsForSpooler(text, cortarPapel: cortarPapel, abrirGaveta: abrirGaveta);
      await tmpFile.writeAsString(cleanText, flush: true);

      final escapedPath = printerName.replaceAll("'", "''");
      
      // Se for impressora padrão/default, não passa o parâmetro -Name
      final bool isDefault = printerName.isEmpty ||
          printerName.toLowerCase() == 'padrao' ||
          printerName.toLowerCase() == 'padrão' ||
          printerName.toLowerCase() == 'default' ||
          printerName.toLowerCase().contains('usb001');

      final psCmd = isDefault
          ? "Get-Content -Path '${tmpFile.path}' | Out-Printer"
          : "Get-Content -Path '${tmpFile.path}' | Out-Printer -Name '$escapedPath'";

      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          psCmd,
        ],
        runInShell: true,
      );

      // Limpeza do temporário
      try {
        await tmpFile.delete();
      } catch (_) {}

      stopwatch.stop();

      if (result.exitCode == 0) {
        debugPrint('[PrinterDriver] ✅ Impresso via Spooler "$printerName" (${stopwatch.elapsedMilliseconds}ms)');
        return PrinterResult(
          success: true,
          message: 'Impresso com sucesso via "$printerName"',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        final err = result.stderr.toString().trim();
        debugPrint('[PrinterDriver] ❌ Erro Spooler: $err');
        return PrinterResult(
          success: false,
          message: 'Falha na impressão: $err. Verifique o nome da impressora no Windows.',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return PrinterResult(
        success: false,
        message: 'Erro ao acessar Spooler: $e',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  String _sanitizar(String text) {
    var result = text
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"').replaceAll('”', '"')
        .replaceAll('‘', "'").replaceAll('’', "'")
        .replaceAll('•', '*')
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ã', 'a').replaceAll('â', 'a').replaceAll('ä', 'a')
        .replaceAll('Á', 'A').replaceAll('À', 'A').replaceAll('Ã', 'A').replaceAll('Â', 'A').replaceAll('Ä', 'A')
        .replaceAll('é', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e')
        .replaceAll('É', 'E').replaceAll('Ê', 'E').replaceAll('Ë', 'E')
        .replaceAll('í', 'i').replaceAll('ì', 'i').replaceAll('î', 'i').replaceAll('ï', 'i')
        .replaceAll('Í', 'I').replaceAll('Ì', 'I').replaceAll('Î', 'I').replaceAll('Ï', 'I')
        .replaceAll('ó', 'o').replaceAll('ò', 'o').replaceAll('õ', 'o').replaceAll('ô', 'o').replaceAll('ö', 'o')
        .replaceAll('Ó', 'O').replaceAll('Ò', 'O').replaceAll('Õ', 'O').replaceAll('Ô', 'O').replaceAll('Ö', 'O')
        .replaceAll('ú', 'u').replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
        .replaceAll('Ú', 'U').replaceAll('Ù', 'U').replaceAll('Û', 'U').replaceAll('Ü', 'U')
        .replaceAll('ç', 'c').replaceAll('Ç', 'C');

    final sb = StringBuffer();
    for (int i = 0; i < result.length; i++) {
      final code = result.codeUnitAt(i);
      if (code < 256) {
        sb.writeCharCode(code);
      } else {
        sb.write('-');
      }
    }
    return sb.toString();
  }

  Future<List<int>> _compileBytes(
    String text, {
    required bool cortarPapel,
    required bool abrirGaveta,
    required int larguraPapel,
  }) async {
    final bytes = <int>[];
    
    // Carrega o CapabilityProfile padrão do esc_pos_utils_plus
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      larguraPapel == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    
    bytes.addAll(generator.reset());
    
    if (abrirGaveta) {
      bytes.addAll(generator.drawer());
    }
    
    final lines = text.split('\n');
    for (int idx = 0; idx < lines.length; idx++) {
      var line = lines[idx];
      
      // Detecção de tag QR Code
      if (line.startsWith('[QRCODE:') && line.endsWith(']')) {
        final payload = line.substring(8, line.length - 1);
        bytes.addAll(generator.qrcode(payload, size: QRSize.size4, align: PosAlign.center));
        continue;
      }
      
      // Traduzir tags de estilização internas para comandos do generator
      PosAlign align = PosAlign.left;
      if (line.contains('[CENTER]')) {
        align = PosAlign.center;
        line = line.replaceAll('[CENTER]', '');
      } else if (line.contains('[RIGHT]')) {
        align = PosAlign.right;
        line = line.replaceAll('[RIGHT]', '');
      } else if (line.contains('[LEFT]')) {
        align = PosAlign.left;
        line = line.replaceAll('[LEFT]', '');
      }
      
      bool bold = false;
      if (line.contains('[BOLD_ON]')) {
        bold = true;
        line = line.replaceAll('[BOLD_ON]', '').replaceAll('[BOLD_OFF]', '');
      }
      
      bytes.addAll(generator.text(
        line,
        styles: PosStyles(align: align, bold: bold),
      ));
    }
    
    if (cortarPapel) {
      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());
    } else {
      bytes.addAll(generator.feed(3));
    }
    
    return bytes;
  }

  String _stripTagsForSpooler(String text, {required bool cortarPapel, required bool abrirGaveta}) {
    final lines = text.split('\n');
    final cleanLines = <String>[];
    const w = 48; // Largura assumida para o spooler padrão
    
    for (var line in lines) {
      bool center = line.contains('[CENTER]');
      bool right = line.contains('[RIGHT]');
      
      var clean = line
          .replaceAll('[BOLD_ON]', '')
          .replaceAll('[BOLD_OFF]', '')
          .replaceAll('[CENTER]', '')
          .replaceAll('[LEFT]', '')
          .replaceAll('[RIGHT]', '');
          
      // Se for QR Code, gera uma mensagem informativa limpa
      final qrRegex = RegExp(r'\[QRCODE:(.*?)\]');
      clean = clean.replaceAllMapped(qrRegex, (match) {
        return '[QR Code Pix - Copie e cole a chave abaixo]';
      });
      
      if (center) {
        if (clean.length < w) {
          final pad = (w - clean.length) ~/ 2;
          clean = ' ' * pad + clean;
        }
      } else if (right) {
        if (clean.length < w) {
          clean = clean.padLeft(w);
        }
      }
      
      cleanLines.add(clean);
    }
    
    final sb = StringBuffer();
    sb.write(cleanLines.join('\n'));
    if (cortarPapel) {
      sb.write('\n\n\n\n'); // Espaço extra antes de cortar no papel físico (simulado)
    }
    return sb.toString();
  }
}
