import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import '../../controllers/pdv_express_controller.dart';
import '../../../shared/services/whatsapp_order_ai_parser.dart';

/// Modal para Importação Inteligente de Pedidos via WhatsApp com IA
class DialogImportarPedidoIa extends StatefulWidget {
  final PdvExpressController controller;

  const DialogImportarPedidoIa({
    super.key,
    required this.controller,
  });

  static Future<bool?> show(BuildContext context, {required PdvExpressController controller}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogImportarPedidoIa(controller: controller),
    );
  }

  @override
  State<DialogImportarPedidoIa> createState() => _DialogImportarPedidoIaState();
}

class _DialogImportarPedidoIaState extends State<DialogImportarPedidoIa> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final WhatsAppOrderAiParser _parser = WhatsAppOrderAiParser();

  bool _isProcessing = false;
  PedidoIaParsedResult? _parsedResult;
  bool _substituirCarrinho = true;
  AiProviderConfig _aiConfig = const AiProviderConfig();
  Cliente? _clienteLocalizado;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracaoIa();
    _substituirCarrinho = widget.controller.cart.isEmpty;
    // Tenta ler automaticamente do clipboard ao abrir
    _lerClipboardAoAbrir();
  }

  @override
  void dispose() {
    _textController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _verificarClientePorTelefone(String raw) {
    final limpo = raw.replaceAll(RegExp(r'\D'), '');
    if (limpo.length >= 8) {
      final achado = widget.controller.clientes.where((c) {
        final cTel = c.telefone.replaceAll(RegExp(r'\D'), '');
        return cTel.isNotEmpty && (cTel == limpo || limpo.endsWith(cTel) || cTel.endsWith(limpo));
      }).firstOrNull;
      setState(() => _clienteLocalizado = achado);
    } else {
      if (_clienteLocalizado != null) {
        setState(() => _clienteLocalizado = null);
      }
    }
  }

  Future<void> _carregarConfiguracaoIa() async {
    final cfg = await WhatsAppOrderAiParser.carregarConfig();
    if (mounted) setState(() => _aiConfig = cfg);
  }

  Future<void> _lerClipboardAoAbrir() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
        final text = data.text!.trim();
        // Se parecer um pedido (tem palavras comuns como 'rua', 'entrega', 'pedido', 'x', etc.)
        final lower = text.toLowerCase();
        if (lower.contains('pedido') ||
            lower.contains('rua') ||
            lower.contains('entrega') ||
            lower.contains('pix') ||
            lower.contains('nome:') ||
            lower.contains('troco') ||
            lower.contains('1x') ||
            lower.contains('2x')) {
          _textController.text = text;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _colarClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        setState(() {
          _textController.text = data.text!;
        });
      } else {
        _mostrarToast('Área de transferência vazia.');
      }
    } catch (e) {
      _mostrarToast('Não foi possível ler da área de transferência: $e');
    }
  }

  Future<void> _processarTexto() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _mostrarToast('Cole ou digite a mensagem do WhatsApp antes de processar.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final catalogo = widget.controller.products;
      final result = await _parser.parseOrder(
        text,
        catalogoProdutos: catalogo,
        customConfig: _aiConfig,
      );

      // Sincroniza cliente e telefone
      if (_telefoneController.text.trim().isNotEmpty) {
        result.clienteTelefone = _telefoneController.text.trim();
      } else if (result.clienteTelefone != null && result.clienteTelefone!.isNotEmpty) {
        _telefoneController.text = result.clienteTelefone!;
        _verificarClientePorTelefone(result.clienteTelefone!);
      }

      if (_clienteLocalizado != null) {
        result.clienteNome = _clienteLocalizado!.nome;
      }

      if (mounted) {
        setState(() {
          _parsedResult = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _mostrarToast('Erro ao processar mensagem: $e');
      }
    }
  }

  void _mostrarToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmarEImportar() async {
    if (_parsedResult == null) return;

    if (_parsedResult!.itens.isEmpty) {
      _mostrarToast('Nenhum item válido identificado para adicionar ao pedido.');
      return;
    }

    final itensSemProduto = _parsedResult!.itens.where((i) => i.produtoMatched == null).toList();
    if (itensSemProduto.isNotEmpty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FincoreColors.surface,
          title: const Text('Itens Não Vinculados', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(
            'Existem ${itensSemProduto.length} item(ns) da mensagem que não foram vinculados a produtos do seu catálogo ativo.\n\nEles serão ignorados na inclusão do carrinho. Deseja continuar?',
            style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Revisar Itens'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
              child: const Text('Continuar Mesmo Assim'),
            ),
          ],
        ),
      );

      if (continuar != true) return;
    }

    // Propaga dados finais de cliente
    if (_telefoneController.text.trim().isNotEmpty) {
      _parsedResult!.clienteTelefone = _telefoneController.text.trim();
    }
    if (_clienteLocalizado != null) {
      _parsedResult!.clienteNome = _clienteLocalizado!.nome;
    }

    await widget.controller.aplicarPedidoIa(
      _parsedResult!,
      substituirCarrinho: _substituirCarrinho,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pedido do WhatsApp importado para o PDV com sucesso! (Origem: WhatsApp / IA)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FincoreColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 720),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _parsedResult == null
                  ? _buildInputSection()
                  : _buildSplitView(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Captura Inteligente de Pedidos (WhatsApp IA)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x338B5CF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6)),
                    ),
                    child: const Text(
                      '✨ IA NLP',
                      style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _aiConfig.isCloud
                    ? 'Provedor: ${_aiConfig.provider.toUpperCase()} (${_aiConfig.model.isNotEmpty ? _aiConfig.model : "Padrão"})'
                    : 'Modo Autônomo Offline (Processamento Local Instantâneo)',
                style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: FincoreColors.textMuted, size: 22),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Campo Opcional de Identificação do Cliente / Telefone ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _clienteLocalizado != null
                    ? const Color(0xFF10B981)
                    : FincoreColors.border,
                width: _clienteLocalizado != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_iphone_rounded,
                  size: 20,
                  color: _clienteLocalizado != null ? const Color(0xFF10B981) : const Color(0xFF25D366),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clienteLocalizado != null
                            ? 'CLIENTE LOCALIZADO NO SISTEMA'
                            : 'TELEFONE / WHATSAPP DO CLIENTE (OPCIONAL)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _clienteLocalizado != null ? const Color(0xFF10B981) : FincoreColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Digite o telefone do cliente para buscar no cadastro...',
                          hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 12, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _verificarClientePorTelefone,
                      ),
                    ],
                  ),
                ),
                if (_clienteLocalizado != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          _clienteLocalizado!.nome,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ] else if (_telefoneController.text.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: FincoreColors.textMuted),
                    tooltip: 'Limpar telefone',
                    onPressed: () {
                      _telefoneController.clear();
                      _verificarClientePorTelefone('');
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Campo de Texto da Mensagem do WhatsApp ──
          Row(
            children: [
              Icon(Icons.paste_rounded, size: 16, color: FincoreColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Cole abaixo o texto ou áudio transcrito do WhatsApp recebido do cliente:',
                style: TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _colarClipboard,
                icon: const Icon(Icons.content_paste_go_rounded, size: 14),
                label: const Text('Colar da Área de Transferência', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FincoreColors.surfaceElevated,
                  foregroundColor: FincoreColors.textPrimary,
                  elevation: 0,
                  side: const BorderSide(color: FincoreColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              if (_textController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all_rounded, color: FincoreColors.textMuted, size: 18),
                  tooltip: 'Limpar texto',
                  onPressed: () => setState(() => _textController.clear()),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Exemplo:\n"Oi boa tarde, me vê 2x Pizza Calabresa sem cebola e 1 Coca-Cola 2L.\n'
                      'Entrega na Rua das Flores, 123 - Centro\n'
                      'Cliente: João Silva, tel: (11) 98765-4321\n'
                      'Vou pagar no dinheiro com troco pra 100"',
                  hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processarTexto,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                _isProcessing ? 'Interpretação Semântica em Execução...' : '✨ Interpretar Pedido com IA',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitView() {
    final parsed = _parsedResult!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Painel Esquerdo: Mensagem Original com opção de reprocessar
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.message_rounded, size: 14, color: FincoreColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('Mensagem Original do WhatsApp', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _parsedResult = null),
                      icon: const Icon(Icons.edit_rounded, size: 12),
                      label: const Text('Editar Texto', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        parsed.textoBruto,
                        style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Badge do Canal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x6610B981)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Canal atribuído: WhatsApp Chat / IA (não interfere no Cardápio Web)',
                          style: TextStyle(color: Colors.green.shade300, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Painel Direito: Resumo Estruturado dos Dados Extraídos
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardCliente(parsed),
                  const SizedBox(height: 10),
                  _buildCardItens(parsed),
                  // Logística só é exibida se houver dados reais de entrega identificados
                  if (parsed.logradouro != null || parsed.bairro != null) ...[
                    const SizedBox(height: 10),
                    _buildCardLogistica(parsed),
                  ],
                  // Pagamento só é exibido se houver forma de pagamento ou troco identificado
                  if (parsed.formaPagamento != null || parsed.trocoParaCentavos != null) ...[
                    const SizedBox(height: 10),
                    _buildCardPagamento(parsed),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCliente(PedidoIaParsedResult parsed) {
    final bool isCadastrado = _clienteLocalizado != null;
    final bool temTelefone = (parsed.clienteTelefone != null && parsed.clienteTelefone!.isNotEmpty) ||
        _telefoneController.text.trim().isNotEmpty;
    final String telExibir = _telefoneController.text.trim().isNotEmpty
        ? _telefoneController.text.trim()
        : (parsed.clienteTelefone ?? 'Não informado');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCadastrado
              ? const Color(0xFF10B981)
              : FincoreColors.border,
          width: isCadastrado ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 16,
                color: isCadastrado ? const Color(0xFF10B981) : FincoreColors.primary,
              ),
              const SizedBox(width: 6),
              const Text('Cliente do Pedido', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCadastrado
                      ? const Color(0x3310B981)
                      : (temTelefone ? const Color(0x3338BDF8) : Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCadastrado
                        ? const Color(0xFF10B981)
                        : (temTelefone ? const Color(0xFF38BDF8) : FincoreColors.border),
                  ),
                ),
                child: Text(
                  isCadastrado
                      ? '✓ Cliente Cadastrado'
                      : (temTelefone ? 'Telefone Informado' : 'Consumidor Final'),
                  style: TextStyle(
                    color: isCadastrado
                        ? FincoreColors.success
                        : (temTelefone ? const Color(0xFF38BDF8) : FincoreColors.textMuted),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nome', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
                    Text(
                      isCadastrado
                          ? _clienteLocalizado!.nome
                          : (parsed.clienteNome ?? (temTelefone ? 'Cliente WhatsApp' : 'Consumidor Final')),
                      style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Telefone / WhatsApp', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
                    Text(
                      telExibir,
                      style: TextStyle(
                        color: temTelefone ? const Color(0xFF25D366) : FincoreColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardLogistica(PedidoIaParsedResult parsed) {
    final isRetirada = parsed.tipoLogistica == 'Retirada';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRetirada ? Icons.store_rounded : Icons.delivery_dining_rounded,
                size: 16,
                color: isRetirada ? const Color(0xFFF97316) : const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Text(
                'Logística: ${parsed.tipoLogistica.toUpperCase()}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Toggle manual de Entrega vs Retirada
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Entrega', label: Text('Entrega', style: TextStyle(fontSize: 10))),
                  ButtonSegment(value: 'Retirada', label: Text('Retirada', style: TextStyle(fontSize: 10))),
                ],
                selected: {parsed.tipoLogistica},
                onSelectionChanged: (set) {
                  setState(() => parsed.tipoLogistica = set.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (!isRetirada) ...[
            const SizedBox(height: 8),
            Text(
              'Endereço: ${parsed.logradouro ?? "Logradouro não identificado"}${parsed.numero != null ? ", ${parsed.numero}" : ""}',
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (parsed.bairro != null && parsed.bairro!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Bairro: ${parsed.bairro}', style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11)),
            ],
            if (parsed.referencia != null && parsed.referencia!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Ponto de Ref: ${parsed.referencia}', style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCardItens(PedidoIaParsedResult parsed) {
    final prodsAtivos = widget.controller.products.where((p) => p.ativo).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 16, color: FincoreColors.warning),
              const SizedBox(width: 6),
              Text(
                'Itens Reconhecidos (${parsed.itens.length})',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (parsed.itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum item reconhecido na mensagem.',
                style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsed.itens.length,
              separatorBuilder: (_, __) => const Divider(color: FincoreColors.border, height: 12),
              itemBuilder: (ctx, idx) {
                final item = parsed.itens[idx];
                final matchOk = item.produtoMatched != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Quantidade com controle digitável manual e botões rápidos
                        _ItemQuantidadeInput(
                          quantidade: item.quantidade,
                          onChanged: (novaQtd) => setState(() => item.quantidade = novaQtd),
                        ),
                        const SizedBox(width: 8),

                        // Dropdown do produto correspondente do catálogo
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Produto?>(
                              isExpanded: true,
                              value: item.produtoMatched,
                              hint: Text(
                                'Vincular a: "${item.nomeIdentificado}"',
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              dropdownColor: FincoreColors.surfaceElevated,
                              items: [
                                const DropdownMenuItem<Produto?>(
                                  value: null,
                                  child: Text('Nenhum vínculo (Ignorar item)', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)),
                                ),
                                ...prodsAtivos.map((p) => DropdownMenuItem<Produto?>(
                                      value: p,
                                      child: Text(p.nome, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (newProd) {
                                setState(() {
                                  item.produtoMatched = newProd;
                                  if (newProd != null) {
                                    item.nomeIdentificado = newProd.nome;
                                    item.confianca = 1.0;
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),
                        // Badge de Confiança
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: matchOk
                                ? const Color(0x2610B981)
                                : const Color(0x26EF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            matchOk ? 'Match ${(item.confianca * 100).round()}%' : 'Sem Match',
                            style: TextStyle(
                              color: matchOk ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: FincoreColors.textMuted, size: 16),
                          tooltip: 'Remover este item',
                          onPressed: () => setState(() => parsed.itens.removeAt(idx)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCardPagamento(PedidoIaParsedResult parsed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, size: 16, color: FincoreColors.success),
              const SizedBox(width: 6),
              const Text('Forma de Pagamento & Troco', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Forma', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
                    Text(
                      parsed.formaPagamento ?? 'Não especificado (Dinheiro)',
                      style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (parsed.trocoParaCentavos != null && parsed.trocoParaCentavos! > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Troco Solicitado', style: TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
                      Text(
                        'R\$ ${(parsed.trocoParaCentavos! / 100).toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: FincoreColors.border)),
      ),
      child: Row(
        children: [
          if (_parsedResult != null) ...[
            Checkbox(
              value: _substituirCarrinho,
              activeColor: FincoreColors.primary,
              onChanged: (val) => setState(() => _substituirCarrinho = val ?? true),
            ),
            const Text(
              'Substituir carrinho atual',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
            ),
          ],
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: FincoreColors.textSecondary,
              side: const BorderSide(color: FincoreColors.border),
            ),
            child: const Text('Cancelar [ESC]'),
          ),
          const SizedBox(width: 12),
          if (_parsedResult != null)
            ElevatedButton.icon(
              onPressed: _confirmarEImportar,
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
              label: const Text('🛒 Transferir para o Carrinho do PDV', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget para controle e digitação manual da quantidade do item
class _ItemQuantidadeInput extends StatefulWidget {
  final double quantidade;
  final ValueChanged<double> onChanged;

  const _ItemQuantidadeInput({
    required this.quantidade,
    required this.onChanged,
  });

  @override
  State<_ItemQuantidadeInput> createState() => _ItemQuantidadeInputState();
}

class _ItemQuantidadeInputState extends State<_ItemQuantidadeInput> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _formatQty(widget.quantidade));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ItemQuantidadeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantidade != widget.quantidade && !_focusNode.hasFocus) {
      _ctrl.text = _formatQty(widget.quantidade);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatQty(double q) {
    return q.truncateToDouble() == q ? q.toInt().toString() : q.toString();
  }

  void _commit() {
    final text = _ctrl.text.replaceAll(',', '.').trim();
    final val = double.tryParse(text);
    if (val != null && val > 0) {
      widget.onChanged(val);
    } else {
      _ctrl.text = _formatQty(widget.quantidade);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _focusNode.hasFocus ? FincoreColors.primary : FincoreColors.border,
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (widget.quantidade > 1) {
                final nova = widget.quantidade - 1;
                widget.onChanged(nova);
                _ctrl.text = _formatQty(nova);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.remove, size: 14, color: FincoreColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 48,
            height: 26,
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _commit(),
              onChanged: (text) {
                final val = double.tryParse(text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  widget.onChanged(val);
                }
              },
            ),
          ),
          InkWell(
            onTap: () {
              final nova = widget.quantidade + 1;
              widget.onChanged(nova);
              _ctrl.text = _formatQty(nova);
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.add, size: 14, color: FincoreColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

