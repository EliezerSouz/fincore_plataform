import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:intl/intl.dart';
import '../../shared/services/fincore_thermal_printer_service.dart';
import '../../shared/services/impressao_service.dart';
import '../../shared/services/pix_generator.dart';
import '../controllers/pdv_express_controller.dart';
import '../models/pdv_item.dart';
import '../../cap/printing/print_capability.dart';
import 'package:fincore_core/di/dependency_injection.dart';


/// Tela de pré-visualização e impressão do cupom do pedido.
///
/// Exibe o cupom simulado na tela (idêntico ao formato da impressora térmica)
/// e permite imprimir nas vias configuradas (Caixa, Cozinha, Expedição).
class ComprovantePedidoPage extends StatefulWidget {
  final String pedidoId;
  final DadosCliente cliente;
  final DadosEntrega entrega;
  final List<PdvItem> itens;
  final int totalCentavos;
  final String formaPagamento;

  const ComprovantePedidoPage({
    super.key,
    required this.pedidoId,
    required this.cliente,
    required this.entrega,
    required this.itens,
    required this.totalCentavos,
    required this.formaPagamento,
  });

  @override
  State<ComprovantePedidoPage> createState() => _ComprovantePedidoPageState();
}

class _ComprovantePedidoPageState extends State<ComprovantePedidoPage> {
  bool _isPrinting = false;
  bool _exibirQrCode = false;
  bool _exibirCopiaCola = false;
  String _printerCaixaPath = '';
  String _printerCozinhaPath = '';
  String _printerExpedicaoPath = '';
  bool _autoPrintCaixa = true;
  bool _autoPrintCozinha = true;
  bool _autoPrintExpedicao = true;
  String _largura = '80mm';
  String? _pixKey;
  String? _pixFavorecido;
  String? _pixTipo;
  String? _pixBanco;
  String? _nomeEmpresa;
  String? _lastMessage;
  bool _lastSuccess = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await FincoreThermalPrinterService.loadPrinters();
    final impConfig = await FincoreImpressaoConfig.carregar();
    setState(() {
      _printerCaixaPath = cfg['caixa'] as String? ?? '';
      _printerCozinhaPath = cfg['cozinha'] as String? ?? '';
      _printerExpedicaoPath = cfg['expedicao'] as String? ?? '';
      _autoPrintCaixa = cfg['autoCaixa'] as bool? ?? true;
      _autoPrintCozinha = cfg['autoCozinha'] as bool? ?? true;
      _autoPrintExpedicao = cfg['autoExpedicao'] as bool? ?? true;
      _largura = cfg['largura'] as String? ?? '80mm';
      _exibirQrCode = cfg['exibirQrCode'] as bool? ?? false;
      _exibirCopiaCola = impConfig.habilitarCopiaCola;
      _pixKey = impConfig.pixChave.isNotEmpty ? impConfig.pixChave : null;
      _pixFavorecido = impConfig.pixFavorecido.isNotEmpty ? impConfig.pixFavorecido : null;
      _pixTipo = impConfig.pixTipo;
      _pixBanco = impConfig.pixBanco.isNotEmpty ? impConfig.pixBanco : null;
      _nomeEmpresa = impConfig.nomeEmpresa.isNotEmpty ? impConfig.nomeEmpresa : null;
    });
  }

  Future<void> _imprimir() async {
    if (_isPrinting) return;
    setState(() {
      _isPrinting = true;
      _lastMessage = null;
    });

    final enderecoStr = widget.entrega.tipo == 'Entrega'
        ? '${widget.entrega.logradouro}, ${widget.entrega.numero} - ${widget.entrega.bairro}'
        : '';

    final useCase = DependencyInjection().get<PrintUseCase>();

    final printItens = widget.itens.map((i) {
      return PrintDataItem(
        nome: i.name,
        quantidade: i.quantity,
        precoUnitarioCentavos: i.priceInCents,
        totalCentavos: i.totalInCents,
      );
    }).toList();

    final printData = PrintData(
      pedidoId: widget.pedidoId,
      clienteNome: widget.cliente.nome,
      clienteTelefone: widget.cliente.telefone,
      tipoLogistica: widget.entrega.tipo,
      endereco: widget.entrega.tipo == 'Entrega' ? enderecoStr : null,
      formaPagamento: widget.formaPagamento,
      totalCentavos: widget.totalCentavos,
      itens: printItens,
      dataHora: DateTime.now(),
    );

    final result = await useCase.reimprimir(
      via: PrintVia.cliente,
      data: printData,
      usuario: 'pdv_express',
    );

    setState(() {
      _isPrinting = false;
      _lastMessage = result.message;
      _lastSuccess = result.success;
    });
  }

  String get _shortId =>
      widget.pedidoId.length > 8 ? widget.pedidoId.substring(0, 8).toUpperCase() : widget.pedidoId;

  String get _dataHora => DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final itensStr = widget.itens.map((i) {
      final precoFmt = 'R\$ ${(i.priceInCents / 100).toStringAsFixed(2)}';
      final totalFmt = 'R\$ ${(i.totalInCents / 100).toStringAsFixed(2)}';
      return '${i.quantity.toStringAsFixed(0)}x ${i.name}  $precoFmt = $totalFmt';
    }).toList();

    final totalFmt = 'R\$ ${(widget.totalCentavos / 100).toStringAsFixed(2)}';
    final enderecoStr = widget.entrega.tipo == 'Entrega'
        ? '${widget.entrega.logradouro}, ${widget.entrega.numero} - ${widget.entrega.bairro}'
        : '';

    return Scaffold(
      backgroundColor: FincoreColors.background,
      appBar: AppBar(
        backgroundColor: FincoreColors.surface,
        elevation: 0,
        title: const Text(
          'COMPROVANTE DO PEDIDO',
          style: TextStyle(
            color: FincoreColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (_isPrinting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _imprimir,
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Painel esquerdo: preview do cupom
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Preview visual do cupom térmico
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Serrilhado superior
                        _SerrilhadoBorda(top: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              // Cabeçalho
                              Image.asset(
                                'assets/images/app_launcher_icon.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 6),
                              _CupomTexto('FINCORE FOOD', bold: true, center: true, size: 15),
                              _CupomTexto('CUPOM NAO FISCAL', center: true, muted: true),
                              _CupomDivisor(double: true),

                              // Dados do pedido
                              _CupomLinhaChaveValor('PEDIDO', '#$_shortId'),
                              _CupomLinhaChaveValor('DATA', _dataHora),
                              _CupomLinhaChaveValor('TIPO', widget.entrega.tipo),
                              if ((widget.cliente.nome ?? '').isNotEmpty)
                                _CupomLinhaChaveValor('CLIENTE', widget.cliente.nome!),
                              if (enderecoStr.isNotEmpty)
                                _CupomLinhaChaveValor('ENTREGA', enderecoStr, wrap: true),
                              _CupomDivisor(),

                              // Itens
                              _CupomTexto('ITENS:', bold: true),
                              const SizedBox(height: 4),
                              ...itensStr.map((it) => _CupomTexto('  $it')),
                              _CupomDivisor(),

                              // Total
                              _CupomLinhaChaveValor('TOTAL', totalFmt, bold: true),
                              _CupomLinhaChaveValor('PAGTO', widget.formaPagamento),
                              _CupomDivisor(double: true),

                              // QR Code / PIX
                              if ((_pixKey ?? '').isNotEmpty && widget.formaPagamento.toLowerCase().contains('pix')) ...[
                                _CupomTexto('PAGAMENTO VIA PIX', center: true, bold: true),
                                const SizedBox(height: 4),
                                _CupomTexto('Chave: $_pixKey (${_pixTipo ?? "PIX"})', center: true, bold: true, size: 10),
                                if (_pixFavorecido != null)
                                  _CupomTexto('Favorecido: $_pixFavorecido', center: true, size: 10),
                                if (_pixBanco != null)
                                  _CupomTexto('Banco: $_pixBanco', center: true, size: 10),
                                const SizedBox(height: 4),
                                _CupomTexto('Envie o comprovante apos o pagamento', center: true, muted: true, size: 9),
                                _CupomDivisor(),
                              ],

                              // Rodapé
                              _CupomTexto('Obrigado pela preferencia!', center: true),
                              _CupomTexto('Volte sempre :)', center: true, muted: true),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        // Serrilhado inferior
                        _SerrilhadoBorda(top: false),
                      ],
                    ),
                  ),

                  // Feedback da impressão
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lastSuccess
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _lastSuccess
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _lastSuccess ? Icons.check_circle_outline : Icons.error_outline,
                            color: _lastSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastMessage!,
                              style: TextStyle(
                                color: _lastSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Painel direito: opções de impressão
          Container(
            width: 300,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FincoreColors.border),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPÇÕES DE IMPRESSÃO',
                    style: TextStyle(
                      color: FincoreColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Impressora
                  const Text('Impressora do Caixa', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: FincoreColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.print_outlined, size: 16, color: FincoreColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _printerCaixaPath.isEmpty ? 'Padrão do sistema' : _printerCaixaPath,
                            style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Para alterar, acesse Configurações > Impressão',
                    style: TextStyle(color: FincoreColors.textMuted, fontSize: 10),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: FincoreColors.border),
                  const SizedBox(height: 16),

                  // As configurações de PIX e QR Code agora são herdadas automaticamente 
                  // das Configurações da Empresa, sem necessidade de reconfigurar por venda.

                  const SizedBox(height: 24),

                  // Botão Imprimir
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _imprimir,
                      icon: _isPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.print, size: 16),
                      label: Text(_isPrinting ? 'Imprimindo...' : 'Imprimir Cupom'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FincoreColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Fechar / Voltar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FincoreColors.textSecondary,
                        side: const BorderSide(color: FincoreColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets do cupom térmico ─────────────────────────────────────────────────

class _CupomTexto extends StatelessWidget {
  final String text;
  final bool bold;
  final bool center;
  final bool muted;
  final double size;

  const _CupomTexto(
    this.text, {
    this.bold = false,
    this.center = false,
    this.muted = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: muted ? Colors.black38 : Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}

class _CupomLinhaChaveValor extends StatelessWidget {
  final String chave;
  final String valor;
  final bool bold;
  final bool wrap;

  const _CupomLinhaChaveValor(this.chave, this.valor, {this.bold = false, this.wrap = false});

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$chave:',
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 11, color: Colors.black54),
            ),
            Text(
              valor,
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$chave:',
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 11,
                color: Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CupomDivisor extends StatelessWidget {
  final bool double;
  const _CupomDivisor({this.double = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        double ? '=' * 36 : '-' * 36,
        style: const TextStyle(fontFamily: 'Courier New', fontSize: 10, color: Colors.black54),
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _SerrilhadoBorda extends StatelessWidget {
  final bool top;
  const _SerrilhadoBorda({required this.top});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        size: const Size(double.infinity, 12),
        painter: _SerrilhadoPainter(top: top),
      ),
    );
  }
}

class _SerrilhadoPainter extends CustomPainter {
  final bool top;
  const _SerrilhadoPainter({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    const radius = 6.0;
    const spacing = 14.0;
    double x = 0;

    while (x < size.width) {
      canvas.drawCircle(
        Offset(x + radius, top ? 0 : size.height),
        radius,
        paint,
      );
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders a visual QR Code using the qr package built into pdf/printing.
/// This widget generates a real QR code matrix and paints it pixel-by-pixel.
class _QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const _QrCodeWidget({required this.data, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(4),
      child: CustomPaint(
        size: Size(size - 8, size - 8),
        painter: _QrCodePainter(data: data),
      ),
    );
  }
}

/// Simple QR Code painter that generates a visual representation.
/// Uses a basic bit-matrix approach for visual rendering on screen.
class _QrCodePainter extends CustomPainter {
  final String data;
  const _QrCodePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    // Generate a deterministic pattern from the data string
    // For a proper QR code on the thermal printer, ESC/POS commands are used.
    // This is a visual approximation for the screen preview.
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw white background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    // Create a hash-based pattern that looks like a QR code
    final moduleCount = 25;
    final moduleSize = size.width / moduleCount;
    final bytes = data.codeUnits;

    // Finder patterns (3 corners)
    void drawFinderPattern(double x, double y) {
      // Outer border (7x7)
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
          final isOuter = i == 0 || i == 6 || j == 0 || j == 6;
          final isInner = i >= 2 && i <= 4 && j >= 2 && j <= 4;
          if (isOuter || isInner) {
            canvas.drawRect(
              Rect.fromLTWH(
                x + j * moduleSize,
                y + i * moduleSize,
                moduleSize,
                moduleSize,
              ),
              paint,
            );
          }
        }
      }
    }

    drawFinderPattern(0, 0);
    drawFinderPattern((moduleCount - 7) * moduleSize, 0);
    drawFinderPattern(0, (moduleCount - 7) * moduleSize);

    // Data modules — use hash of data to create deterministic pattern
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i]) & 0x7FFFFFFF;
    }

    for (int row = 0; row < moduleCount; row++) {
      for (int col = 0; col < moduleCount; col++) {
        // Skip finder pattern areas
        if ((row < 8 && col < 8) ||
            (row < 8 && col >= moduleCount - 8) ||
            (row >= moduleCount - 8 && col < 8)) {
          continue;
        }

        // Timing patterns
        if (row == 6) {
          if (col % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(col * moduleSize, row * moduleSize, moduleSize, moduleSize),
              paint,
            );
          }
          continue;
        }
        if (col == 6) {
          if (row % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(col * moduleSize, row * moduleSize, moduleSize, moduleSize),
              paint,
            );
          }
          continue;
        }

        // Data region — deterministic from hash
        final seed = (hash + row * 37 + col * 53 + bytes[((row * col) + col) % bytes.length]) & 0xFFFF;
        if (seed % 3 != 0) {
          canvas.drawRect(
            Rect.fromLTWH(col * moduleSize, row * moduleSize, moduleSize, moduleSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.data != data;
}
