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
  final WhatsAppOrderAiParser _parser = WhatsAppOrderAiParser();

  bool _isProcessing = false;
  PedidoIaParsedResult? _parsedResult;
  bool _substituirCarrinho = true;
  AiProviderConfig _aiConfig = const AiProviderConfig();

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
    super.dispose();
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

  void _abrirConfiguracoesIa() {
    showDialog(
      context: context,
      builder: (ctx) => _DialogConfigIa(
        initialConfig: _aiConfig,
        onSave: (newConfig) async {
          await WhatsAppOrderAiParser.salvarConfig(newConfig);
          setState(() => _aiConfig = newConfig);
          _mostrarToast('Configurações de IA salvas com sucesso.');
        },
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
            icon: const Icon(Icons.settings_outlined, color: FincoreColors.textSecondary, size: 20),
            tooltip: 'Configurar Provedor de IA (Gemini / OpenAI / Local)',
            onPressed: _abrirConfiguracoesIa,
          ),
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
                  _buildCardLogistica(parsed),
                  const SizedBox(height: 10),
                  _buildCardItens(parsed),
                  const SizedBox(height: 10),
                  _buildCardPagamento(parsed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCliente(PedidoIaParsedResult parsed) {
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
              Icon(Icons.person_rounded, size: 16, color: FincoreColors.primary),
              const SizedBox(width: 6),
              const Text('Cliente Identificado', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (parsed.clienteNome != null || parsed.clienteTelefone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x3310B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Identificado', style: TextStyle(color: FincoreColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      parsed.clienteNome ?? 'Consumidor WhatsApp',
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
                      parsed.clienteTelefone ?? 'Não informado',
                      style: TextStyle(
                        color: parsed.clienteTelefone != null ? const Color(0xFF25D366) : FincoreColors.textMuted,
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
                        // Quantidade com controles rápidos
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: FincoreColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: FincoreColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (item.quantidade > 1) {
                                    setState(() => item.quantidade -= 1);
                                  }
                                },
                                child: const Icon(Icons.remove, size: 14, color: FincoreColors.textSecondary),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  item.quantidade.toStringAsFixed(item.quantidade.truncateToDouble() == item.quantidade ? 0 : 1),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => item.quantidade += 1),
                                child: const Icon(Icons.add, size: 14, color: FincoreColors.textSecondary),
                              ),
                            ],
                          ),
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
                    if (item.observacoes != null && item.observacoes!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 42, top: 2),
                        child: Text(
                          'Obs: ${item.observacoes}',
                          style: const TextStyle(color: FincoreColors.warning, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
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

/// Diálogo para Configurações do Provedor de IA
class _DialogConfigIa extends StatefulWidget {
  final AiProviderConfig initialConfig;
  final ValueChanged<AiProviderConfig> onSave;

  const _DialogConfigIa({
    required this.initialConfig,
    required this.onSave,
  });

  @override
  State<_DialogConfigIa> createState() => _DialogConfigIaState();
}

class _DialogConfigIaState extends State<_DialogConfigIa> {
  late String _provider;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _modelCtrl;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialConfig.provider;
    _keyCtrl = TextEditingController(text: widget.initialConfig.apiKey);
    _modelCtrl = TextEditingController(text: widget.initialConfig.model);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: FincoreColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Configurar Provedor de IA', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolha como deseja que as mensagens do WhatsApp sejam interpretadas:',
              style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            RadioListTile<String>(
              value: 'local',
              groupValue: _provider,
              title: const Text('Modo Local Offline (Recomendado)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Instantâneo, 0ms de latência, não requer internet nem chave de API.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
              onChanged: (val) => setState(() => _provider = val!),
            ),
            RadioListTile<String>(
              value: 'gemini',
              groupValue: _provider,
              title: const Text('Google Gemini (Nuvem)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Utiliza a API do Gemini (gemini-1.5-flash) para compreensão profunda de mensagens complexas.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
              onChanged: (val) => setState(() => _provider = val!),
            ),
            RadioListTile<String>(
              value: 'openai',
              groupValue: _provider,
              title: const Text('OpenAI ChatGPT (Nuvem)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Utiliza a API da OpenAI (gpt-4o-mini).', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
              onChanged: (val) => setState(() => _provider = val!),
            ),
            if (_provider != 'local') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _keyCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Chave de API (API Key)',
                  labelStyle: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                  hintText: 'Cole aqui sua chave sk-... ou AIza...',
                  hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Modelo Customizado (Opcional)',
                  labelStyle: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
                  hintText: _provider == 'gemini' ? 'gemini-1.5-flash' : 'gpt-4o-mini',
                  hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(AiProviderConfig(
              provider: _provider,
              apiKey: _keyCtrl.text.trim(),
              model: _modelCtrl.text.trim(),
            ));
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
