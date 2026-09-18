import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:fincore_core/fincore_core.dart';

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
      final res = PrinterResult(
        success: false,
        message: 'Nenhuma impressora configurada (caminho/IP em branco)',
        elapsedMs: sw.elapsedMilliseconds,
      );
      gravarLog(destinatario: 'NENHUMA', sucesso: false, mensagem: res.message, tempoMs: res.elapsedMs);
      return res;
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
      final res = PrinterResult(
        success: false,
        message: 'Erro ao imprimir: $e',
        elapsedMs: sw.elapsedMilliseconds,
      );
      gravarLog(destinatario: target, sucesso: false, mensagem: res.message, tempoMs: res.elapsedMs);
      return res;
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
      gravarLog(
        destinatario: '$host:$port',
        sucesso: true,
        mensagem: 'Impresso com sucesso via IP $host:$port',
        tempoMs: stopwatch.elapsedMilliseconds,
      );
      return PrinterResult(
        success: true,
        message: 'Impresso com sucesso via $host:$port',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('[PrinterDriver] ❌ Erro de conexão IP: $e');
      gravarLog(
        destinatario: '$host:$port',
        sucesso: false,
        mensagem: 'Impressora offline ($host:$port): ${e.message}',
        tempoMs: stopwatch.elapsedMilliseconds,
      );
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
        gravarLog(
          destinatario: printerName,
          sucesso: true,
          mensagem: 'Impresso com sucesso via porta: $printerName',
          tempoMs: stopwatch.elapsedMilliseconds,
        );
        return PrinterResult(
          success: true,
          message: 'Impresso com sucesso via porta: $printerName',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } catch (e) {
        debugPrint('[PrinterDriver] Falha porta direta -> caindo para Spooler RAW: $e');
      }
    }

    // 2. Transmissão RAW para Spooler Windows via script .ps1 (winspool.drv)
    try {
      final tempDir = Directory.systemTemp;
      final rawBytes = await _compileBytes(
        text,
        cortarPapel: cortarPapel,
        abrirGaveta: abrirGaveta,
        larguraPapel: larguraPapel,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final binFile = File('${tempDir.path}\\fincore_print_$timestamp.bin');
      await binFile.writeAsBytes(rawBytes, flush: true);

      final ps1File = File('${tempDir.path}\\fincore_print_$timestamp.ps1');
      final escapedPath = printerName.replaceAll("'", "''");
      final tmpPathEscaped = binFile.path.replaceAll("'", "''");

      final psScriptContent = '''
\$code = @"
using System;
using System.IO;
using System.Runtime.InteropServices;

public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }
    [DllImport("winspool.Drv", EntryPoint = "OpenPrinterA", SetLastError = true, CharSet = CharSet.Ansi)]
    public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);
    [DllImport("winspool.Drv", EntryPoint = "ClosePrinter", SetLastError = true)]
    public static extern bool ClosePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "StartDocPrinterA", SetLastError = true, CharSet = CharSet.Ansi)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, int level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);
    [DllImport("winspool.Drv", EntryPoint = "EndDocPrinter", SetLastError = true)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "StartPagePrinter", SetLastError = true)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "EndPagePrinter", SetLastError = true)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "WritePrinter", SetLastError = true)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);

    public static bool PrintFile(string printerName, string filePath) {
        if (!File.Exists(filePath)) return false;
        byte[] bytes = File.ReadAllBytes(filePath);
        IntPtr hPrinter = IntPtr.Zero;
        DOCINFOA di = new DOCINFOA { pDocName = "FINCORE FOOD PRINT", pDataType = "RAW" };
        if (OpenPrinter(printerName, out hPrinter, IntPtr.Zero)) {
            if (StartDocPrinter(hPrinter, 1, di)) {
                if (StartPagePrinter(hPrinter)) {
                    IntPtr pBytes = Marshal.AllocHGlobal(bytes.Length);
                    Marshal.Copy(bytes, 0, pBytes, bytes.Length);
                    int dwWritten = 0;
                    bool res = WritePrinter(hPrinter, pBytes, bytes.Length, out dwWritten);
                    Marshal.FreeHGlobal(pBytes);
                    EndPagePrinter(hPrinter);
                }
                EndDocPrinter(hPrinter);
            }
            ClosePrinter(hPrinter);
            return true;
        }
        return false;
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'RawPrinterHelper').Type) {
    Add-Type -TypeDefinition \$code -Language CSharp
}

\$target = '$escapedPath'
\$p = \$null
if (\$target.Length -gt 0 -and \$target -ne 'padrao' -and \$target -ne 'padrão' -and \$target -ne 'default') {
    \$p = Get-Printer -Name \$target -ErrorAction SilentlyContinue
    if (-not \$p) {
        \$p = Get-Printer | Where-Object { \$_.PortName -eq \$target -or \$_.Name -like ('*' + \$target + '*') } | Select-Object -First 1
    }
}
if (-not \$p) {
    \$p = Get-Printer | Where-Object { \$_.IsDefault -eq \$true } | Select-Object -First 1
}
if (-not \$p) {
    \$p = Get-Printer | Select-Object -First 1
}

if (\$p) {
    \$res = [RawPrinterHelper]::PrintFile(\$p.Name, '$tmpPathEscaped')
    if (\$res) {
        Write-Host "SUCCESS:\$(\$p.Name)"
    } else {
        Write-Error "Falha ao enviar stream RAW para a impressora '\$(\$p.Name)'"
        exit 1
    }
} else {
    Write-Error "Nenhuma impressora encontrada no Windows."
    exit 1
}
''';
      await ps1File.writeAsString(psScriptContent, flush: true);

      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          ps1File.path,
        ],
      );

      try { await binFile.delete(); } catch (_) {}
      try { await ps1File.delete(); } catch (_) {}

      stopwatch.stop();

      gravarLog(
        destinatario: printerName,
        sucesso: result.exitCode == 0 && result.stdout.toString().contains('SUCCESS:'),
        mensagem: result.exitCode == 0 ? result.stdout.toString().trim() : result.stderr.toString().trim(),
        tempoMs: stopwatch.elapsedMilliseconds,
      );

      if (result.exitCode == 0 && result.stdout.toString().contains('SUCCESS:')) {
        final printedName = result.stdout.toString().substring(result.stdout.toString().indexOf('SUCCESS:') + 8).trim();
        debugPrint('[PrinterDriver] ✅ Impresso via RAW Spooler "$printedName" (${stopwatch.elapsedMilliseconds}ms)');
        return PrinterResult(
          success: true,
          message: 'Impresso com sucesso via RAW Spooler ("$printedName")',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        final err = result.stderr.toString().trim();
        debugPrint('[PrinterDriver] ❌ Erro Spooler RAW: $err');
        return PrinterResult(
          success: false,
          message: err.isNotEmpty ? err : 'Falha na gravação Spooler RAW. Verifique se a impressora está conectada.',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      gravarLog(
        destinatario: printerName,
        sucesso: false,
        mensagem: 'Erro no Spooler RAW: $e',
        tempoMs: stopwatch.elapsedMilliseconds,
      );
      return PrinterResult(
        success: false,
        message: 'Erro no Spooler RAW: $e',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  static void gravarLog({
    required String destinatario,
    required bool sucesso,
    required String mensagem,
    required int tempoMs,
  }) {
    final dateStr = DateTime.now().toString();
    final line = '[$dateStr] DESTINO: $destinatario | STATUS: ${sucesso ? "SUCESSO" : "FALHA"} | MSG: $mensagem | TEMPO: ${tempoMs}ms\n';

    // 1. Grava no LogService (Central de Logs da Aplicação)
    try {
      if (sucesso) {
        LogService.instance.info(
          LogModule.printer,
          'DESTINO: $destinatario | MSG: $mensagem | TEMPO: ${tempoMs}ms',
          context: {
            'destinatario': destinatario,
            'sucesso': true,
            'mensagem': mensagem,
            'tempoMs': tempoMs,
          },
        );
      } else {
        LogService.instance.error(
          LogModule.printer,
          'DESTINO: $destinatario | ERRO: $mensagem | TEMPO: ${tempoMs}ms',
          context: {
            'destinatario': destinatario,
            'sucesso': false,
            'mensagem': mensagem,
            'tempoMs': tempoMs,
          },
        );
      }
    } catch (e) {
      debugPrint('[PrinterDriver] Erro ao registrar log no LogService: $e');
    }

    // 2. Grava na pasta oficial /LOG/Impressao/
    try {
      final now = DateTime.now();
      final monthStr = now.month.toString().padLeft(2, '0');
      final dayStr = now.day.toString().padLeft(2, '0');
      final dateKey = '${now.year}-$monthStr-$dayStr';
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final impressaoDir = Directory('$exeDir\\LOG\\Impressao');
      if (!impressaoDir.existsSync()) {
        impressaoDir.createSync(recursive: true);
      }
      final logFile = File('${impressaoDir.path}\\impressao_$dateKey.log');
      logFile.writeAsStringSync(line, mode: FileMode.append);
    } catch (e) {
      debugPrint('[PrinterDriver] Erro ao gravar em LOG/Impressao: $e');
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
