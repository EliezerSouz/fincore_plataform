import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_order_ai_parser.dart';

/// Subview Oficial de Gestão e Configuração Dinâmica de Mensagens do WhatsApp (Fase D2)
class MensagensWhatsAppView extends StatefulWidget {
  final VoidCallback? onChanged;

  const MensagensWhatsAppView({
    super.key,
    this.onChanged,
  });

  @override
  State<MensagensWhatsAppView> createState() => MensagensWhatsAppViewState();
}

class MensagensWhatsAppViewState extends State<MensagensWhatsAppView> {
  List<WhatsAppTemplate> _templates = [];
  Map<String, WhatsAppEventPolicy> _politicas = {};
  Map<String, String> _templatesPorEvento = {};
  int _subAbaAtiva = 0; // 0: Modelos de Mensagens, 1: Políticas por Evento, 2: Frente de Caixa (PDV), 3: Conexão & API
  bool _isLoading = true;
  String _selectedTemplateId = 'saudacao';
  final _conteudoCtrl = TextEditingController();

  // ── Integração Real com Evolution API (Fase D1/D2/D3) ──
  final _numeroTesteCtrl = TextEditingController(text: '3599879093');
  final _mensagemTesteCtrl = TextEditingController(
    text: 'Olá! Mensagem de teste enviada com sucesso do FINCORE via WhatsApp. 🚀',
  );
  WhatsAppPdvConfig _pdvConfig = const WhatsAppPdvConfig();
  bool _isEnviandoTeste = false;
  WhatsAppSendResult? _ultimoResultadoTeste;
  String _filtroCategoriaVariaveis = 'todas';

  // ── Gestão Dinâmica de Sessão & QR Code (Fase D3) ──
  EvolutionInstanceInfo? _instanceInfo;
  bool _isCheckingStatus = false;
  bool _isActionInProgress = false;

  // ── Gestão de Inteligência Artificial (Gemini & NLP Local) ──
  String _aiProvider = 'local';
  final _aiApiKeyCtrl = TextEditingController();
  final _aiModelCtrl = TextEditingController(text: 'gemini-2.5-flash');
  bool _obscureAiApiKey = true;
  bool _isTestandoGemini = false;
  String? _geminiTesteResultado;
  bool? _geminiTesteSucesso;

  static const List<Map<String, dynamic>> _categoriasVariaveis = [
    {
      'id': 'identificacao',
      'label': 'Identificação & Origem',
      'icone': Icons.person_outline_rounded,
      'cor': Color(0xFF38BDF8),
      'tags': [
        {'tag': '{cliente}', 'desc': 'Nome completo do cliente'},
        {'tag': '{primeiro_nome}', 'desc': 'Primeiro nome (saudação amigável)'},
        {'tag': '{loja}', 'desc': 'Nome fantasia da sua loja'},
        {'tag': '{pedido}', 'desc': 'Número identificador do pedido (ex: #127)'},
        {
          'tag': '{canal}',
          'desc': 'Canal de atendimento (ex: Cardápio Web ou PDV Balcão)',
          'badge': 'Canal',
          'badgeColor': Color(0xFF0284C7),
        },
        {
          'tag': '{origem}',
          'desc': 'Origem do pedido (ex: Cardápio Digital Online ou Atendimento Balcão)',
          'badge': 'Origem',
          'badgeColor': Color(0xFF0284C7),
        },
      ],
    },
    {
      'id': 'itens',
      'label': 'Itens & Produtos',
      'icone': Icons.shopping_basket_outlined,
      'cor': Color(0xFFF59E0B),
      'tags': [
        {'tag': '{itens}', 'desc': 'Lista discriminada com quantidade e valores'},
        {'tag': '{itens_resumo}', 'desc': 'Resumo em 1 linha (ex: 2x Pizza, 1x Suco)'},
        {'tag': '{quantidade_itens}', 'desc': 'Total de itens somados'},
        {'tag': '{observacoes}', 'desc': 'Observações do cliente no pedido'},
      ],
    },
    {
      'id': 'financeiro',
      'label': 'Financeiro & Pagamento',
      'icone': Icons.attach_money_rounded,
      'cor': Color(0xFF10B981),
      'tags': [
        {'tag': '{total}', 'desc': 'Valor total final do pedido'},
        {'tag': '{subtotal}', 'desc': 'Soma bruta dos produtos'},
        {'tag': '{desconto}', 'desc': 'Valor do desconto concedido'},
        {'tag': '{taxa_entrega}', 'desc': 'Valor da taxa de frete/entrega'},
        {'tag': '{taxa_servico}', 'desc': 'Taxa de serviço'},
        {'tag': '{forma_pagamento}', 'desc': 'Nome da forma de pagamento'},
        {'tag': '{status_pagamento}', 'desc': 'Pendente ou Confirmado'},
        {'tag': '{troco_para}', 'desc': 'Troco solicitado em dinheiro'},
      ],
    },
    {
      'id': 'pix',
      'label': 'PIX & Cobrança',
      'icone': Icons.pix_rounded,
      'cor': Color(0xFF32BCAD),
      'tags': [
        {
          'tag': '{bloco_pix}',
          'desc': 'Inteligente: gera chave e copia-e-cola apenas se for PIX (vazio se cartão/dinheiro)',
          'badge': 'Auto Inteligente',
          'badgeColor': Color(0xFF16A34A),
        },
        {'tag': '{chave_pix}', 'desc': 'Chave PIX pura configurada na loja'},
        {'tag': '{chave_pix_copia_cola}', 'desc': 'Payload Copia e Cola EMV do pedido'},
      ],
    },
    {
      'id': 'logistica',
      'label': 'Logística & Endereço',
      'icone': Icons.moped_rounded,
      'cor': Color(0xFFA855F7),
      'tags': [
        {
          'tag': '{bloco_endereco}',
          'desc': 'Inteligente: endereço de entrega ou da loja para retirada',
          'badge': 'Auto Logística',
          'badgeColor': Color(0xFF9333EA),
        },
        {'tag': '{tipo_pedido}', 'desc': 'Entrega, Retirada ou Balcão'},
        {'tag': '{endereco}', 'desc': 'Endereço completo de entrega do cliente'},
        {'tag': '{endereco_empresa}', 'desc': 'Endereço físico da sua loja (retirada)'},
        {'tag': '{previsao_entrega}', 'desc': 'Previsão de entrega ou retirada'},
        {'tag': '{entregador}', 'desc': 'Nome do motoboy/entregador'},
        {'tag': '{mesa}', 'desc': 'Número da mesa ou comanda'},
      ],
    },
    {
      'id': 'links',
      'label': 'Links & Cardápio Digital',
      'icone': Icons.link_rounded,
      'cor': Color(0xFF06B6D4),
      'tags': [
        {
          'tag': '{link_rastreio}',
          'desc': 'Link oficial para o cliente rastrear o pedido em tempo real',
          'badge': 'Rastreio Web',
          'badgeColor': Color(0xFF0284C7),
        },
        {'tag': '{link_cardapio}', 'desc': 'Link inicial da vitrine do seu cardápio digital'},
      ],
    },
  ];

  int get _totalVariaveis => _categoriasVariaveis.fold<int>(
        0,
        (sum, cat) => sum + (cat['tags'] as List).length,
      );

  String get _tenantId {
    try {
      if (TenantContext().hasContext) {
        return TenantContext().tenantId;
      }
    } catch (_) {}
    return 'default';
  }

  String get _nomeEmpresaResolvido {
    try {
      if (TenantContext().hasContext) {
        final fant = TenantContext().empresa.nomeFantasia;
        if (fant.isNotEmpty) return fant;
        final raz = TenantContext().empresa.razaoSocial;
        if (raz.isNotEmpty) return raz;
      }
    } catch (_) {}
    return 'Nossa Loja';
  }




  @override
  void initState() {
    super.initState();
    _carregarTemplates();
    _conteudoCtrl.addListener(_onConteudoChanged);
  }

  @override
  void dispose() {
    _conteudoCtrl.dispose();
    _numeroTesteCtrl.dispose();
    _mensagemTesteCtrl.dispose();
    super.dispose();
  }

  void _onConteudoChanged() {
    final idx = _templates.indexWhere((t) => t.id == _selectedTemplateId);
    if (idx >= 0 && _templates[idx].conteudo != _conteudoCtrl.text) {
      _templates[idx] = _templates[idx].copyWith(conteudo: _conteudoCtrl.text);
      setState(() {});
      widget.onChanged?.call();
    }
  }

  Future<void> _carregarTemplates() async {
    setState(() => _isLoading = true);
    await WhatsAppService.atualizarCacheUrlCardapio(tenantId: _tenantId);
    final carregados = await WhatsAppService.getTemplates(
      tenantId: _tenantId,
      nomeEmpresa: _nomeEmpresaResolvido,
    );
    final politicasCarregadas = await WhatsAppService.getPoliticasEventos(
      tenantId: _tenantId,
    );
    final templatesEventosCarregados = await WhatsAppService.getTemplatesEventosConfigurados(
      tenantId: _tenantId,
    );
    final pdvConfigCarregada = await WhatsAppService.getPdvConfig(tenantId: _tenantId);
    final aiCfg = await WhatsAppOrderAiParser.carregarConfig();

    if (mounted) {
      setState(() {
        _templates = List.from(carregados);
        _politicas = Map.from(politicasCarregadas);
        _templatesPorEvento = Map.from(templatesEventosCarregados);
        _pdvConfig = pdvConfigCarregada;
        _aiProvider = aiCfg.provider;
        _aiApiKeyCtrl.text = aiCfg.apiKey;
        _aiModelCtrl.text = (aiCfg.model.isNotEmpty && aiCfg.model != 'gemini-1.5-flash')
            ? aiCfg.model
            : 'gemini-2.5-flash';
        if (_templates.isNotEmpty) {
          _selecionarTemplate(_templates.first.id);
        }
        _isLoading = false;
      });
      _verificarStatusInstancia(silent: true);
    }
  }

  void _selecionarTemplate(String id) {
    if (_templates.isEmpty) return;
    final t = _templates.firstWhere((item) => item.id == id, orElse: () => _templates.first);
    setState(() {
      _selectedTemplateId = t.id;
      _conteudoCtrl.text = t.conteudo;
    });
  }

  Future<void> salvar() async {
    final curIdx = _templates.indexWhere((t) => t.id == _selectedTemplateId);
    if (curIdx >= 0 && _templates[curIdx].conteudo != _conteudoCtrl.text) {
      _templates[curIdx] = _templates[curIdx].copyWith(conteudo: _conteudoCtrl.text);
    }

    final okT = await WhatsAppService.salvarTemplates(_templates, tenantId: _tenantId);
    final okP = await WhatsAppService.salvarPoliticasEventos(_politicas, tenantId: _tenantId);
    final okMap = await WhatsAppService.salvarTemplatesEventosConfigurados(_templatesPorEvento, tenantId: _tenantId);
    final okPdv = await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
    await WhatsAppOrderAiParser.salvarConfig(AiProviderConfig(
      provider: _aiProvider,
      apiKey: _aiApiKeyCtrl.text.trim(),
      model: _aiModelCtrl.text.trim(),
    ));
    if (!mounted) return;

    if (okT && okP && okPdv && okMap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Configurações e mensagens dinâmicas salvas com sucesso!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmarRestaurarPadroes() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        title: const Text('Restaurar Mensagens Padrão?', style: TextStyle(color: FincoreColors.textPrimary)),
        content: const Text(
          'Esta ação restaurará todas as mensagens oficiais recomendadas do FINCORE para os textos de fábrica.',
          style: TextStyle(color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await WhatsAppService.resetarTemplatesPadrao(
        tenantId: _tenantId,
        nomeEmpresa: _nomeEmpresaResolvido,
      );
      await _carregarTemplates();
      widget.onChanged?.call();
    }
  }

  void _inserirTag(String tag) {
    final text = _conteudoCtrl.text;
    final selection = _conteudoCtrl.selection;
    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final newText = text.replaceRange(start, end, tag);
    _conteudoCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
  }

  String _gerarPreviewMensagem(String textoOriginal) {
    final dadosExemplo = {
      '{cliente}': 'Mariana Souza',
      '{primeiro_nome}': 'Mariana',
      '{loja}': _nomeEmpresaResolvido,
      '{pedido}': '000104',
      '{itens}': '▪ 2x Burger Artesanal Especial - R\$ 56,00\n   _(Obs: Sem cebola)_\n▪ 1x Batata Rústica - R\$ 18,00\n▪ 1x Coca-Cola 2L - R\$ 14,00',
      '{itens_resumo}': '2x Burger Especial, 1x Batata Rústica, 1x Coca-Cola 2L',
      '{quantidade_itens}': '3',
      '{observacoes}': 'Caprichar no molho da casa',
      '{subtotal}': '88,00',
      '{desconto}': '10,00',
      '{taxa_entrega}': '7,00',
      '{taxa_servico}': '4,90',
      '{total}': '89,90',
      '{forma_pagamento}': 'PIX',
      '{status_pagamento}': 'Pendente',
      '{pagamento_pendente}': 'true',
      '{is_pix}': 'true',
      '{is_entrega}': 'true',
      '{is_retirada}': 'false',
      '{troco_para}': 'R\$ 100,00 (Troco: R\$ 10,10)',
      '{tipo_pedido}': 'Entrega (Delivery)',
      '{endereco}': 'Rua das Flores, 120 - Apto 34',
      '{endereco_empresa}': 'Av. Central, 500 - Centro - Sorocaba/SP',
      '{endereco_loja}': 'Av. Central, 500 - Centro - Sorocaba/SP',
      '{bloco_pix}': '🔑 *Chave PIX:* pix@$_nomeEmpresaResolvido.com.br\n\n📋 *Copia e Cola:*\n00020126580014br.gov.bcb.pix011407389215640520400005303986540589.905802BR5915FINCORE FOOD6008SOROCABA62070503***6304ABCD',
      '{bloco_endereco}': '📍 *Endereço de Entrega:* Rua das Flores, 120 - Apto 34',
      '{previsao_entrega}': '40 a 50 min',
      '{entregador}': 'Carlos (Moto Honda)',
      '{mesa}': 'Mesa 04',
      '{link_cardapio}': WhatsAppService.montarUrlCardapioDigital(
        baseUrl: WhatsAppService.baseUrlCardapioPadrao,
        tenantId: _tenantId,
      ),
      '{link_rastreio}': WhatsAppService.montarUrlRastreioPedido(
        baseUrl: WhatsAppService.baseUrlCardapioPadrao,
        numeroOuIdPedido: '000104',
        tenantId: _tenantId,
      ),
      '{chave_pix}': 'pix@$_nomeEmpresaResolvido.com.br',
      '{chave_pix_copia_cola}': '00020126580014br.gov.bcb.pix011407389215640520400005303986540589.905802BR5915FINCORE FOOD6008SOROCABA62070503***6304ABCD',
    };

    return WhatsAppService.interpolarTemplate(textoOriginal, dadosExemplo);
  }

  // ── MODAL DINÂMICO DE ADICIONAR / EDITAR MENSAGEM (Requisitos 8, 9 e 10) ──
  Future<void> _abrirDialogoMensagem([WhatsAppTemplate? templateExistente]) async {
    final isEdicao = templateExistente != null;
    final id = templateExistente?.id ?? const Uuid().v4();
    final nomeCtrl = TextEditingController(text: templateExistente?.titulo ?? '');
    final emojiCtrl = TextEditingController(text: templateExistente?.emoji ?? '💬');
    final descCtrl = TextEditingController(text: templateExistente?.descricao ?? '');
    String eventoSel = templateExistente?.evento ?? 'pedido_criado';
    String formaPgtoSel = templateExistente?.condicaoFormaPagamento ?? 'QUALQUER';
    String statusPgtoSel = templateExistente?.condicaoStatusPagamento ?? 'QUALQUER';
    bool ativo = templateExistente?.ativo ?? true;

    String resolverEventoKey(String ev) {
      if (ev == 'pedido_criado') return WhatsAppService.kEventoPedidoCriadoPdv;
      if (ev == 'pedido_aprovado') return WhatsAppService.kEventoPedidoAprovadoWeb;
      if (ev == 'pedido_pronto') return WhatsAppService.kEventoPedidoPronto;
      if (ev == 'saiu_entrega') return WhatsAppService.kEventoPedidoSaiuEntrega;
      if (ev == 'pedido_cancelado') return WhatsAppService.kEventoPedidoCancelado;
      return ev;
    }

    WhatsAppEventPolicy politicaSel = _politicas[resolverEventoKey(eventoSel)] ?? WhatsAppEventPolicy.desativado;
    bool definirComoPadraoDoEvento = (_templatesPorEvento[resolverEventoKey(eventoSel)] == id);

    final emojisSugeridos = ['👋', '📦', '🍕', '🛵', '💳', '📍', '⭐', '💬', '🔔', '✨', '🚀', '🔥', '❌'];

    final salvou = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isEventoOperacional = eventoSel != 'geral';

          return AlertDialog(
            backgroundColor: FincoreColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEdicao ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: const Color(0xFF25D366),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdicao ? 'Editar Configuração da Mensagem' : 'Adicionar Nova Mensagem',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor de Ícone / Emoji
                    const Text('Ícone / Emoji da Mensagem:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FincoreColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: FincoreColors.border),
                          ),
                          child: Text(emojiCtrl.text, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: emojisSugeridos.map((e) => InkWell(
                              onTap: () {
                                setModalState(() => emojiCtrl.text = e);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: emojiCtrl.text == e ? const Color(0xFF25D366).withValues(alpha: 0.2) : FincoreColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: emojiCtrl.text == e ? const Color(0xFF25D366) : FincoreColors.border,
                                  ),
                                ),
                                child: Text(e, style: const TextStyle(fontSize: 18)),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Nome da Mensagem
                    const Text('Nome da Mensagem:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nomeCtrl,
                      style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ex: Confirmação de Pedido, Cobrança PIX...',
                        hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: FincoreColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Evento Disparador Oficial FINCORE
                    const Text('Evento Operacional Vinculado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: eventoSel,
                      dropdownColor: FincoreColors.surfaceElevated,
                      style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: FincoreColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pedido_criado', child: Text('📦 Pedido Criado (PDV / Cardápio Digital)')),
                        DropdownMenuItem(value: 'pedido_aprovado', child: Text('✅ Pedido Aprovado / Em Preparo')),
                        DropdownMenuItem(value: 'pedido_pronto', child: Text('🍕 Pedido Pronto (Balcão / Retirada)')),
                        DropdownMenuItem(value: 'saiu_entrega', child: Text('🛵 Saiu para Entrega (Delivery)')),
                        DropdownMenuItem(value: 'pedido_cancelado', child: Text('❌ Pedido Cancelado')),
                        DropdownMenuItem(value: 'geral', child: Text('💬 Geral / Contato Avulso')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            eventoSel = val;
                            politicaSel = _politicas[resolverEventoKey(val)] ?? WhatsAppEventPolicy.desativado;
                            definirComoPadraoDoEvento = (_templatesPorEvento[resolverEventoKey(val)] == id);
                          });
                        }
                      },
                    ),

                    // Se for evento operacional, permite configurar o tipo de envio e se é padrão do evento
                    if (isEventoOperacional) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tipo de Envio do Evento (${_getNomeEvento(eventoSel)}):',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<WhatsAppEventPolicy>(
                              segments: const [
                                ButtonSegment(
                                  value: WhatsAppEventPolicy.desativado,
                                  label: Text('Desativado', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.block_rounded, size: 13),
                                ),
                                ButtonSegment(
                                  value: WhatsAppEventPolicy.manual,
                                  label: Text('Manual', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.touch_app_rounded, size: 13),
                                ),
                                ButtonSegment(
                                  value: WhatsAppEventPolicy.automatico,
                                  label: Text('Automático', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.flash_on_rounded, size: 13),
                                ),
                              ],
                              selected: {politicaSel},
                              onSelectionChanged: (Set<WhatsAppEventPolicy> newSelection) {
                                setModalState(() => politicaSel = newSelection.first);
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    if (politicaSel == WhatsAppEventPolicy.automatico) return const Color(0xFF16A34A).withValues(alpha: 0.25);
                                    if (politicaSel == WhatsAppEventPolicy.manual) return const Color(0xFFF59E0B).withValues(alpha: 0.25);
                                    return const Color(0xFF6B7280).withValues(alpha: 0.25);
                                  }
                                  return FincoreColors.surface;
                                }),
                              ),
                            ),
                            const SizedBox(height: 10),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text(
                                'Definir este modelo como mensagem oficial disparada neste evento',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                              ),
                              value: definirComoPadraoDoEvento,
                              activeColor: const Color(0xFF38BDF8),
                              onChanged: (val) {
                                setModalState(() => definirComoPadraoDoEvento = val ?? false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Condições de Disparo (PIX, etc.)
                    const Text('Condições de Disparo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Forma de Pagamento:', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: formaPgtoSel,
                                dropdownColor: FincoreColors.surfaceElevated,
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: FincoreColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'QUALQUER', child: Text('Qualquer Forma')),
                                  DropdownMenuItem(value: 'PIX', child: Text('Apenas PIX')),
                                  DropdownMenuItem(value: 'DINHEIRO', child: Text('Apenas Dinheiro')),
                                  DropdownMenuItem(value: 'CARTAO', child: Text('Apenas Cartão')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => formaPgtoSel = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status do Pagamento:', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: statusPgtoSel,
                                dropdownColor: FincoreColors.surfaceElevated,
                                style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: FincoreColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'QUALQUER', child: Text('Qualquer Status')),
                                  DropdownMenuItem(value: 'PENDENTE', child: Text('Apenas Pendente (Não pago)')),
                                  DropdownMenuItem(value: 'PAGO', child: Text('Apenas Confirmado (Pago)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => statusPgtoSel = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Switch Ativo / Inativo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: FincoreColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ativo ? 'Mensagem Ativa' : 'Mensagem Inativa',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ativo ? const Color(0xFF25D366) : FincoreColors.textMuted,
                                ),
                              ),
                              const Text('Determina se essa mensagem pode ser utilizada no fluxo.', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                            ],
                          ),
                          Switch(
                            value: ativo,
                            activeColor: const Color(0xFF25D366),
                            onChanged: (val) => setModalState(() => ativo = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (nomeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.check, size: 16),
                label: Text(isEdicao ? 'Atualizar Mensagem' : 'Adicionar Mensagem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (salvou == true) {
      final novoTitulo = nomeCtrl.text.trim();
      final novoEmoji = emojiCtrl.text.trim().isNotEmpty ? emojiCtrl.text.trim() : '💬';
      final novaDescricao = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Mensagem customizada do operador.';

      final evKey = resolverEventoKey(eventoSel);
      if (eventoSel != 'geral') {
        _politicas[evKey] = politicaSel;
        if (definirComoPadraoDoEvento) {
          _templatesPorEvento[evKey] = id;
        }
      }

      setState(() {
        if (isEdicao) {
          final idx = _templates.indexWhere((t) => t.id == templateExistente.id);
          if (idx >= 0) {
            _templates[idx] = _templates[idx].copyWith(
              titulo: novoTitulo,
              emoji: novoEmoji,
              descricao: novaDescricao,
              evento: eventoSel,
              condicaoFormaPagamento: formaPgtoSel,
              condicaoStatusPagamento: statusPgtoSel,
              ativo: ativo,
            );
          }
        } else {
          final novoTemplate = WhatsAppTemplate(
            id: id,
            titulo: novoTitulo,
            emoji: novoEmoji,
            descricao: novaDescricao,
            conteudo: 'Olá {cliente}! Seu pedido #{pedido} na *$_nomeEmpresaResolvido* está sendo preparado.',
            ativo: ativo,
            isPadrao: false,
            evento: eventoSel,
            condicaoFormaPagamento: formaPgtoSel,
            condicaoStatusPagamento: statusPgtoSel,
            ordem: _templates.length,
          );
          _templates.add(novoTemplate);
          _selecionarTemplate(id);
        }
      });
      widget.onChanged?.call();
      await salvar();
    }
  }

  Future<void> _excluirTemplate(WhatsAppTemplate template) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        title: const Text('Excluir Mensagem?', style: TextStyle(color: FincoreColors.textPrimary)),
        content: Text(
          'Deseja realmente remover a mensagem "${template.titulo}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _templates.removeWhere((t) => t.id == template.id);
        if (_selectedTemplateId == template.id && _templates.isNotEmpty) {
          _selecionarTemplate(_templates.first.id);
        }
      });
      widget.onChanged?.call();
      await salvar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    WhatsAppTemplate? templateAtual;
    if (_templates.isNotEmpty) {
      templateAtual = _templates.firstWhere(
        (t) => t.id == _selectedTemplateId,
        orElse: () => _templates.first,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Principal Limpo ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: FincoreColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'WhatsApp & Mensageria Operacional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Modelos dinâmicos, políticas por evento e integração segura com a Evolution API.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
                _buildTopStatusBadge(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Barra de Navegação por Sub-Abas ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: FincoreColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Row(
              children: [
                _buildSubTabButton(
                  index: 0,
                  icon: Icons.mark_chat_read_rounded,
                  label: 'Modelos de Mensagens (${_templates.length})',
                ),
                _buildSubTabButton(
                  index: 1,
                  icon: Icons.rule_rounded,
                  label: 'Políticas por Evento',
                ),
                _buildSubTabButton(
                  index: 2,
                  icon: Icons.point_of_sale_rounded,
                  label: 'Frente de Caixa (PDV)',
                ),
                _buildSubTabButton(
                  index: 3,
                  icon: Icons.phone_android_rounded,
                  label: 'Aparelho WhatsApp',
                ),
                _buildSubTabButton(
                  index: 4,
                  icon: Icons.auto_awesome_rounded,
                  label: 'IA & Gemini',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Conteúdo da Sub-Aba Ativa ──
          if (_subAbaAtiva == 0) ...[
            _buildCardGerenciadorMensagens(templateAtual),
            const SizedBox(height: 12),
            if (templateAtual != null)
              _buildSecaoEditorEPreview(templateAtual),
          ] else if (_subAbaAtiva == 1) ...[
            _buildCardPoliticasEventos(),
          ] else if (_subAbaAtiva == 2) ...[
            _buildCardConfiguracaoPdv(),
          ] else if (_subAbaAtiva == 3) ...[
            _buildCardEvolutionApi(),
          ] else if (_subAbaAtiva == 4) ...[
            _buildCardInteligenciaArtificialIa(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool ativo = _subAbaAtiva == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _subAbaAtiva = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF25D366).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: ativo ? Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: ativo ? const Color(0xFF25D366) : FincoreColors.textMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                    color: ativo ? const Color(0xFF25D366) : FincoreColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNomeEvento(String ev) {
    switch (ev) {
      case 'pedido_criado':
        return '📦 Pedido Criado';
      case 'pedido_aprovado':
        return '✅ Pedido Aprovado';
      case 'pedido_pronto':
        return '🍕 Pedido Pronto';
      case 'saiu_entrega':
        return '🛵 Saiu para Entrega';
      case 'pedido_cancelado':
        return '❌ Pedido Cancelado';
      case 'geral':
      default:
        return '💬 Geral / Avulso';
    }
  }

  Widget _buildBadgePoliticaEvento(String ev) {
    String eventoKey = ev;
    if (ev == 'pedido_criado') {
      eventoKey = WhatsAppService.kEventoPedidoCriadoPdv;
    } else if (ev == 'pedido_aprovado') {
      eventoKey = WhatsAppService.kEventoPedidoAprovadoWeb;
    } else if (ev == 'pedido_pronto') {
      eventoKey = WhatsAppService.kEventoPedidoPronto;
    } else if (ev == 'saiu_entrega') {
      eventoKey = WhatsAppService.kEventoPedidoSaiuEntrega;
    } else if (ev == 'pedido_cancelado') {
      eventoKey = WhatsAppService.kEventoPedidoCancelado;
    }

    final pol = _politicas[eventoKey] ?? WhatsAppEventPolicy.desativado;
    final Color cor;
    final String label;
    final IconData icon;

    switch (pol) {
      case WhatsAppEventPolicy.automatico:
        cor = const Color(0xFF22C55E);
        label = 'Auto';
        icon = Icons.flash_on_rounded;
        break;
      case WhatsAppEventPolicy.manual:
        cor = const Color(0xFF38BDF8);
        label = 'Manual';
        icon = Icons.touch_app_rounded;
        break;
      case WhatsAppEventPolicy.desativado:
        cor = FincoreColors.textMuted;
        label = 'Off';
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: cor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  // ── CARD APARELHO WHATSAPP (Sub-aba 3: Aparelho WhatsApp) ──
  Widget _buildCardEvolutionApi() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android_rounded, color: Color(0xFF25D366), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Aparelho WhatsApp do Estabelecimento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Vincule o WhatsApp da sua loja para envio automático de pedidos, rastreio e notificações aos clientes.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
              ),
              _buildBadgeStatusConexao(),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: FincoreColors.border),
          const SizedBox(height: 18),

          // Painel Oficial de Pareamento & Sessão WhatsApp (Fase D3)
          _buildPainelSessaoWhatsApp(),

          const SizedBox(height: 20),

          // Seção de Teste Controlado de Disparo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Teste de Disparo (Simulação no seu Celular)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInputField('Número Destino (DDD + Número):', _numeroTesteCtrl, '35992503114'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: _buildInputField('Mensagem de Teste:', _mensagemTesteCtrl, 'Mensagem de teste...'),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: ElevatedButton.icon(
                        onPressed: _isEnviandoTeste ? null : _dispararTesteTecnicoManual,
                        icon: _isEnviandoTeste
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Disparar Teste', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_ultimoResultadoTeste != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _ultimoResultadoTeste!.sucesso ? const Color(0xFF16A34A).withValues(alpha: 0.15) : const Color(0xFFDC2626).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ultimoResultadoTeste!.sucesso ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _ultimoResultadoTeste!.sucesso ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: _ultimoResultadoTeste!.sucesso ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ultimoResultadoTeste!.sucesso
                                ? 'Disparo realizado com sucesso! ID: ${_ultimoResultadoTeste!.messageId ?? "OK"}'
                                : 'Falha no disparo: ${_ultimoResultadoTeste!.erro ?? "Erro de comunicação"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _ultimoResultadoTeste!.sucesso ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Future<void> _dispararTesteTecnicoManual() async {
    final numero = _numeroTesteCtrl.text.trim();
    final texto = _mensagemTesteCtrl.text.trim();
    if (numero.isEmpty || texto.isEmpty) return;

    setState(() => _isEnviandoTeste = true);
    final res = await WhatsAppService.enviarMensagem(
      rawPhone: numero,
      mensagem: texto,
      tenantId: _tenantId,
      eventoId: 'teste_tecnico',
      isManualIntent: true,
    );

    if (mounted) {
      setState(() {
        _isEnviandoTeste = false;
        _ultimoResultadoTeste = res;
      });
    }
  }

  // ── MÉTODOS DE GESTÃO DE SESSÃO, QR CODE & CONEXÃO (Fase D3) ──

  Future<void> _verificarStatusInstancia({bool silent = false}) async {
    if (!silent) setState(() => _isCheckingStatus = true);
    final cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);
    final info = await EvolutionApiClient.obterStatusInstancia(config: cfg);
    if (mounted) {
      setState(() {
        _instanceInfo = info;
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _conectarOuAbrirQrCode() async {
    var cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);

    // Se o cliente for novo e não tiver instância criada, gera o nome e cria sob demanda agora
    if (cfg.instanceName.trim().isEmpty) {
      final novoNome = EvolutionApiClient.gerarNomeInstanciaEstabelecimento(
        tenantId: _tenantId,
        nomeLoja: _nomeEmpresaResolvido,
      );
      cfg = cfg.copyWith(instanceName: novoNome);

      if (!mounted) return;
      setState(() => _isActionInProgress = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Criando nova conexão de WhatsApp para este estabelecimento...'),
          duration: Duration(seconds: 2),
        ),
      );

      final res = await EvolutionApiClient.criarInstancia(config: cfg);
      setState(() => _isActionInProgress = false);

      if (!mounted) return;
      if (!res.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao criar conexão na VPS: ${res.erro ?? "Verifique a conectividade de rede."}'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Salva a configuração com a instância gerada para este estabelecimento
      await EvolutionApiClient.salvarConfig(cfg, tenantId: _tenantId);
    } else {
      // Se a instância já tem nome mas no servidor deu 'not_found', inicializa
      final statusAtual = await EvolutionApiClient.obterStatusInstancia(config: cfg);
      if (statusAtual.isNotFound) {
        setState(() => _isActionInProgress = true);
        final res = await EvolutionApiClient.criarInstancia(config: cfg);
        setState(() => _isActionInProgress = false);
        if (!mounted) return;
        if (!res.sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao registrar conexão: ${res.erro ?? "Erro de rede."}'),
              backgroundColor: const Color(0xFFDC2626),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    if (mounted) {
      _abrirModalQrCode();
    }
  }

  Future<void> _confirmarRemoverInstancia() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Remover Conexão WhatsApp?'),
          ],
        ),
        content: const Text(
          'Deseja remover completamente a conexão deste estabelecimento?\n\n'
          'A sessão e a instância serão excluídas da VPS e o FINCORE deixará de enviar mensagens até que uma nova conexão seja criada.',
          style: TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover Conexão'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);
    setState(() => _isActionInProgress = true);
    if (cfg.instanceName.isNotEmpty) {
      await EvolutionApiClient.deletarInstancia(config: cfg);
    }
    // Salva configuração com instanceName vazio para voltar ao estado zerado
    await EvolutionApiClient.salvarConfig(cfg.copyWith(instanceName: ''), tenantId: _tenantId);
    setState(() => _isActionInProgress = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conexão de WhatsApp removida com sucesso.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
    await _verificarStatusInstancia();
  }

  Future<void> _confirmarDesvincularTelefone() async {
    final info = _instanceInfo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Desconectar WhatsApp?'),
          ],
        ),
        content: Text(
          'Deseja realmente desconectar o WhatsApp do número ${info?.formattedPhone ?? "deste estabelecimento"}?\n\nO FINCORE pausará os envios automáticos até uma nova reconexão.',
          style: const TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);

    setState(() => _isActionInProgress = true);
    final ok = await EvolutionApiClient.desvincularInstancia(config: cfg);
    setState(() => _isActionInProgress = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp desconectado com sucesso.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível desconectar. O aparelho já pode estar desconectado.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
    }
    await _verificarStatusInstancia();
  }

  Future<void> _recriarInstanciaLimpa() async {
    final cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);
    if (!mounted) return;

    setState(() => _isActionInProgress = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reiniciando conexão de WhatsApp...'), duration: Duration(seconds: 2)),
    );

    await EvolutionApiClient.deletarInstancia(config: cfg);
    await Future.delayed(const Duration(milliseconds: 1500));
    final res = await EvolutionApiClient.criarInstancia(config: cfg);
    setState(() => _isActionInProgress = false);

    if (!mounted) return;
    if (res.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conexão pronta com sucesso! Abrindo QR Code...'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 2),
        ),
      );
      await _verificarStatusInstancia();
      if (mounted) {
        _abrirModalQrCode();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reiniciar conexão: ${res.erro ?? "Erro inesperado."}'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _confirmarRecriarInstancia() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text('Reiniciar Conexão?'),
          ],
        ),
        content: const Text(
          'Esta ação removerá a sessão do WhatsApp e preparará uma nova conexão limpa pronta para leitura imediata do QR Code.',
          style: TextStyle(fontSize: 13, color: FincoreColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reiniciar e Conectar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _recriarInstanciaLimpa();
    }
  }

  Future<void> _abrirModalQrCode() async {
    final cfg = await EvolutionApiClient.carregarConfig(tenantId: _tenantId);
    if (!mounted) return;

    if (cfg.apiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço de WhatsApp não configurado no ambiente.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        String? base64Qr;
        String? erroQr;
        bool carregando = true;
        bool conectadoSucesso = false;
        String? telefoneConectado;
        Timer? pollingTimer;
        Timer? refreshQrTimer;
        int segundosRestantes = 18;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void buscarQrCode({bool silencioso = false}) async {
              if (!silencioso) {
                setModalState(() {
                  carregando = true;
                  erroQr = null;
                });
              }

              final res = await EvolutionApiClient.obterQrCodeConexao(config: cfg);
              if (!dialogCtx.mounted) return;

              if (res.isAlreadyConnected) {
                setModalState(() {
                  carregando = false;
                  conectadoSucesso = true;
                });
                pollingTimer?.cancel();
                refreshQrTimer?.cancel();
                Future.delayed(const Duration(milliseconds: 1400), () {
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  _verificarStatusInstancia();
                });
                return;
              }

              if (res.sucesso && res.base64Qr != null) {
                setModalState(() {
                  carregando = false;
                  base64Qr = res.base64Qr;
                  erroQr = null;
                  segundosRestantes = 18;
                });
              } else {
                setModalState(() {
                  carregando = false;
                  erroQr = res.erro ?? 'Aguardando inicialização do QR Code...';
                });
              }
            }

            // Inicia busca e polling de conexão
            if (pollingTimer == null) {
              buscarQrCode();
              pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
                if (!dialogCtx.mounted) {
                  timer.cancel();
                  return;
                }
                final check = await EvolutionApiClient.obterStatusInstancia(config: cfg);
                if (check.isConnected && dialogCtx.mounted) {
                  timer.cancel();
                  refreshQrTimer?.cancel();
                  setModalState(() {
                    conectadoSucesso = true;
                    telefoneConectado = check.formattedPhone;
                  });
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    _verificarStatusInstancia();
                  });
                } else if (base64Qr == null && !carregando) {
                  buscarQrCode();
                }
              });

              // Auto-renovação periódica do QR Code (a cada 18s) para manter 100% alinhado com o Baileys/VPS
              refreshQrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!dialogCtx.mounted) {
                  timer.cancel();
                  return;
                }
                if (conectadoSucesso) {
                  timer.cancel();
                  return;
                }
                setModalState(() {
                  if (segundosRestantes > 1) {
                    segundosRestantes--;
                  } else {
                    segundosRestantes = 18;
                    buscarQrCode(silencioso: true);
                  }
                });
              });
            }

            return Dialog(
              backgroundColor: FincoreColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF25D366), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Conectar WhatsApp',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Aponte a câmera do WhatsApp para conectar',
                                  style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              pollingTimer?.cancel();
                              refreshQrTimer?.cancel();
                              Navigator.of(dialogCtx).pop();
                              _verificarStatusInstancia();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (conectadoSucesso) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF16A34A)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 54),
                              const SizedBox(height: 12),
                              const Text(
                                'WhatsApp Conectado com Sucesso!',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                              ),
                              if (telefoneConectado != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Telefone: $telefoneConectado',
                                  style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        // Área do QR Code
                        Container(
                          width: 260,
                          height: 260,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF25D366), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: carregando
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF25D366)),
                                    SizedBox(height: 12),
                                    Text(
                                      'Gerando QR Code...',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Iniciando WhatsApp Web na nuvem',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 10.5, color: Colors.black54),
                                    ),
                                  ],
                                )
                              : base64Qr != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(base64Qr!),
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.sync_problem_rounded, color: Color(0xFFEF4444), size: 36),
                                          const SizedBox(height: 8),
                                          Text(
                                            erroQr ?? 'Aguardando QR Code...',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            onPressed: buscarQrCode,
                                            icon: const Icon(Icons.refresh_rounded, size: 14),
                                            label: const Text('Tentar Novamente', style: TextStyle(fontSize: 11.5)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF25D366),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                        if (base64Qr != null && !conectadoSucesso) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'QR Code ativo • Renova em ${segundosRestantes}s',
                                style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => buscarQrCode(),
                                child: const Tooltip(
                                  message: 'Renovar QR Code agora',
                                  child: Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF38BDF8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Instruções
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FincoreColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: FincoreColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Como escanear:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                              ),
                              SizedBox(height: 6),
                              Text('1. Abra o WhatsApp no celular do estabelecimento', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                              Text('2. Toque em Aparelhos conectados > Conectar um aparelho', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                              Text('3. Aponte a câmera para este QR Code', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Ações de Contingência caso ocorra travamento no Baileys
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                pollingTimer?.cancel();
                                refreshQrTimer?.cancel();
                                Navigator.of(dialogCtx).pop();
                                await _recriarInstanciaLimpa();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 14, color: FincoreColors.textMuted),
                              label: const Text('Reiniciar conexão limpa', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _verificarStatusInstancia();
    });
  }

  Widget _buildTopStatusBadge() {
    Color bgCor = const Color(0xFF6B7280).withValues(alpha: 0.15);
    Color dotCor = const Color(0xFF9CA3AF);
    Color textCor = const Color(0xFF9CA3AF);
    String label = 'Verificando WhatsApp...';

    if (_isCheckingStatus) {
      label = 'Consultando Conexão...';
      dotCor = const Color(0xFF38BDF8);
      textCor = const Color(0xFF38BDF8);
      bgCor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
    } else if (_instanceInfo != null) {
      if (_instanceInfo!.isConnected) {
        dotCor = const Color(0xFF22C55E);
        textCor = const Color(0xFF22C55E);
        bgCor = const Color(0xFF16A34A).withValues(alpha: 0.15);
        label = _instanceInfo!.formattedPhone != null
            ? 'WhatsApp Conectado (${_instanceInfo!.formattedPhone})'
            : 'WhatsApp Conectado';
      } else if (_instanceInfo!.isNotConfigured) {
        dotCor = const Color(0xFF9CA3AF);
        textCor = const Color(0xFF9CA3AF);
        bgCor = const Color(0xFF6B7280).withValues(alpha: 0.15);
        label = 'WhatsApp Não Conectado';
      } else if (_instanceInfo!.isDisconnected) {
        dotCor = const Color(0xFFF59E0B);
        textCor = const Color(0xFFF59E0B);
        bgCor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        label = 'WhatsApp Desconectado (Requer QR Code)';
      } else if (_instanceInfo!.isNotFound) {
        dotCor = const Color(0xFFF59E0B);
        textCor = const Color(0xFFF59E0B);
        bgCor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        label = 'Aguardando Inicialização';
      } else if (_instanceInfo!.isConnecting) {
        dotCor = const Color(0xFF38BDF8);
        textCor = const Color(0xFF38BDF8);
        bgCor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
        label = 'Aguardando Leitura do QR Code';
      } else {
        dotCor = const Color(0xFFEF4444);
        textCor = const Color(0xFFEF4444);
        bgCor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        label = 'Falha na Conexão';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgCor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotCor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotCor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCor),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatusConexao() {
    if (_isCheckingStatus) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38BDF8)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
            ),
            SizedBox(width: 6),
            Text('Verificando...', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_instanceInfo != null) {
      if (_instanceInfo!.isConnected) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF16A34A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
              SizedBox(width: 6),
              Text('Conectado', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      } else if (_instanceInfo!.isNotConfigured) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.white60, size: 8),
              SizedBox(width: 6),
              Text('Não Vinculado', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      } else if (_instanceInfo!.isDisconnected) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFFF59E0B), size: 8),
              SizedBox(width: 6),
              Text('Desconectado', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      } else if (_instanceInfo!.isNotFound) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFFF59E0B), size: 8),
              SizedBox(width: 6),
              Text('Pendente', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white60, size: 8),
          SizedBox(width: 6),
          Text('Não verificado', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPainelSessaoWhatsApp() {
    final info = _instanceInfo;
    final isConnected = info?.isConnected ?? false;
    final isDisconnected = info?.isDisconnected ?? false;
    final isNotConfigured = info?.isNotConfigured ?? (info == null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF16A34A).withValues(alpha: 0.6)
              : isDisconnected
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                  : FincoreColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConnected
                    ? Icons.phone_android_rounded
                    : (isNotConfigured ? Icons.phonelink_erase_rounded : Icons.qr_code_2_rounded),
                color: isConnected
                    ? const Color(0xFF22C55E)
                    : (isNotConfigured ? const Color(0xFF9CA3AF) : const Color(0xFF38BDF8)),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'Aparelho WhatsApp Pareado e Ativo'
                          : (isNotConfigured
                              ? 'Aparelho WhatsApp Não Vinculado'
                              : 'WhatsApp Desconectado — Requer Conexão'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'Sessão ativa e apta a disparar mensagens automáticas e manuais do FINCORE.'
                          : (isNotConfigured
                              ? 'Este estabelecimento ainda não possui WhatsApp vinculado. Caso queira enviar mensagens e notificações aos clientes, clique em Conectar WhatsApp abaixo.'
                              : 'Conecte o WhatsApp do seu estabelecimento via QR Code para habilitar o envio automático de pedidos.'),
                      style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_isCheckingStatus) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Se estiver conectado, mostra detalhes do telefone e perfil
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Telefone Vinculado: ${info?.formattedPhone ?? "Identificado"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        if (info?.profileName != null && info!.profileName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Perfil: ${info.profileName} • Pronto para Envios',
                            style: const TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Barra de Ações Operacionais
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Botão Verificar Conexão
              OutlinedButton.icon(
                onPressed: _isCheckingStatus ? null : () => _verificarStatusInstancia(),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Verificar Conexão', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FincoreColors.textPrimary,
                  side: const BorderSide(color: FincoreColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),

              // Se Desconectado ou Não Configurado: Botão Conectar (QR Code)
              if (!isConnected) ...[
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _conectarOuAbrirQrCode,
                  icon: _isActionInProgress
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Conectar WhatsApp (Ler QR Code)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],

              // Se Conectado: Botão Desconectar
              if (isConnected) ...[
                OutlinedButton.icon(
                  onPressed: _isActionInProgress ? null : _confirmarDesvincularTelefone,
                  icon: const Icon(Icons.link_off_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: const Text('Desconectar Aparelho', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],

              // Opção de Reiniciar Conexão (caso tenha sessão configurada e precise de nova tentativa limpa)
              if (!isConnected && !isNotConfigured) ...[
                TextButton.icon(
                  onPressed: _isActionInProgress ? null : _confirmarRecriarInstancia,
                  icon: const Icon(Icons.restart_alt_rounded, size: 14, color: FincoreColors.textMuted),
                  label: const Text('Reiniciar Conexão', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                ),
              ],

              // Opção de Excluir / Remover Conexão (caso o cliente não queira mais utilizar WhatsApp)
              if (!isNotConfigured) ...[
                TextButton.icon(
                  onPressed: _isActionInProgress ? null : _confirmarRemoverInstancia,
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                  label: const Text('Remover Conexão', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── CARD POLÍTICAS OPERACIONAIS POR EVENTO (Sub-aba 1) ──
  Widget _buildCardPoliticasEventos() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rule_rounded, color: Color(0xFF38BDF8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Políticas Operacionais por Evento & Modelos Vinculados',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Defina o modo de envio (Desativado, Manual ou Automático) e escolha qual modelo de mensagem dispara em cada etapa do pedido.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: FincoreColors.border),
          const SizedBox(height: 16),

          _buildLinhaPolitica(
            eventoId: WhatsAppService.kEventoPedidoCriadoPdv,
            eventoChaveTemplate: 'pedido_criado',
            titulo: '1. Pedido Criado no PDV / Balcão',
            descricao: 'Disparado ao confirmar o pedido no Caixa ou importar venda.',
          ),
          const Divider(height: 24, color: FincoreColors.border),
          _buildLinhaPolitica(
            eventoId: WhatsAppService.kEventoPedidoAprovadoWeb,
            eventoChaveTemplate: 'pedido_aprovado',
            titulo: '2. Pedido Web Aprovado pelo Operador',
            descricao: 'Disparado no momento da aprovação do pedido vindo do Cardápio Digital.',
          ),
          const Divider(height: 24, color: FincoreColors.border),
          _buildLinhaPolitica(
            eventoId: WhatsAppService.kEventoPedidoPronto,
            eventoChaveTemplate: 'pedido_pronto',
            titulo: '3. Pedido Pronto (Balcão / Retirada)',
            descricao: 'Avisa o cliente de balcão que o pedido já está pronto para retirada.',
          ),
          const Divider(height: 24, color: FincoreColors.border),
          _buildLinhaPolitica(
            eventoId: WhatsAppService.kEventoPedidoSaiuEntrega,
            eventoChaveTemplate: 'saiu_entrega',
            titulo: '4. Pedido Saiu para Entrega (Delivery)',
            descricao: 'Avisa o cliente que o motoboy despachou o pedido para entrega.',
          ),
          const Divider(height: 24, color: FincoreColors.border),
          _buildLinhaPolitica(
            eventoId: WhatsAppService.kEventoPedidoCancelado,
            eventoChaveTemplate: 'pedido_cancelado',
            titulo: '5. Pedido Cancelado (Estorno / Não Concretizado)',
            descricao: 'Avisa o cliente formalmente sobre o cancelamento do pedido e detalhes do estorno.',
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaPolitica({
    required String eventoId,
    required String eventoChaveTemplate,
    required String titulo,
    required String descricao,
  }) {
    final politicaAtual = _politicas[eventoId] ?? WhatsAppEventPolicy.desativado;
    final templatesAtivos = _templates.where((t) => t.ativo).toList();

    // Determinar o template associado a este evento
    String? templateIdAtual = _templatesPorEvento[eventoId];
    if (templateIdAtual == null || !templatesAtivos.any((t) => t.id == templateIdAtual)) {
      final templateDoEvento = templatesAtivos.firstWhere(
        (t) => t.evento == eventoChaveTemplate,
        orElse: () => templatesAtivos.first,
      );
      templateIdAtual = templateDoEvento.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(descricao, style: const TextStyle(fontSize: 11.5, color: FincoreColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SegmentedButton<WhatsAppEventPolicy>(
              segments: const [
                ButtonSegment(
                  value: WhatsAppEventPolicy.desativado,
                  label: Text('Desativado', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.block_rounded, size: 14),
                ),
                ButtonSegment(
                  value: WhatsAppEventPolicy.manual,
                  label: Text('Manual', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.touch_app_rounded, size: 14),
                ),
                ButtonSegment(
                  value: WhatsAppEventPolicy.automatico,
                  label: Text('Automático', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.flash_on_rounded, size: 14),
                ),
              ],
              selected: {politicaAtual},
              onSelectionChanged: (Set<WhatsAppEventPolicy> newSelection) async {
                setState(() {
                  _politicas[eventoId] = newSelection.first;
                });
                await WhatsAppService.salvarPoliticasEventos(_politicas, tenantId: _tenantId);
                widget.onChanged?.call();
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    if (politicaAtual == WhatsAppEventPolicy.automatico) return const Color(0xFF16A34A).withValues(alpha: 0.25);
                    if (politicaAtual == WhatsAppEventPolicy.manual) return const Color(0xFFF59E0B).withValues(alpha: 0.25);
                    return const Color(0xFF6B7280).withValues(alpha: 0.25);
                  }
                  return FincoreColors.surface;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_chat_read_rounded, size: 16, color: Color(0xFF25D366)),
              const SizedBox(width: 8),
              const Text(
                'Modelo Disparado:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: templateIdAtual,
                    isExpanded: true,
                    dropdownColor: FincoreColors.surfaceElevated,
                    items: templatesAtivos.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Row(
                          children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${t.titulo} (${_getNomeEvento(t.evento)})',
                                style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (novoId) async {
                      if (novoId != null) {
                        setState(() {
                          _templatesPorEvento[eventoId] = novoId;
                          if (eventoId == WhatsAppService.kEventoPedidoCriadoPdv) {
                            _pdvConfig = _pdvConfig.copyWith(templateId: novoId);
                          }
                        });
                        await WhatsAppService.salvarTemplatesEventosConfigurados(_templatesPorEvento, tenantId: _tenantId);
                        if (eventoId == WhatsAppService.kEventoPedidoCriadoPdv) {
                          await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
                        }
                        widget.onChanged?.call();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _subAbaAtiva = 0;
                    _selecionarTemplate(templateIdAtual!);
                  });
                },
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text('Editar Texto', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CARD CONFIGURAÇÃO DO FRENTE DE CAIXA (Sub-aba 2: PDV & PIX) ──
  Widget _buildCardConfiguracaoPdv() {
    final templatesAtivos = _templates.where((t) => t.ativo).toList();

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Frente de Caixa (PDV) — Disparo ao Finalizar Venda',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: FincoreColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Configure o modelo padrão de comprovante e o comportamento de PIX (chave ou copia e cola) ao finalizar no PDV.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: FincoreColors.border),
          const SizedBox(height: 16),

          // 1. Seletor de Modelo Padrão do PDV
          const Text(
            'Modelo de Mensagem Padrão ao Finalizar Pedido:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FincoreColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FincoreColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: templatesAtivos.any((t) => t.id == _pdvConfig.templateId)
                    ? _pdvConfig.templateId
                    : (templatesAtivos.isNotEmpty ? templatesAtivos.first.id : null),
                isExpanded: true,
                dropdownColor: FincoreColors.surfaceElevated,
                items: templatesAtivos.map((t) {
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Row(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${t.titulo} (${t.categoria})',
                            style: const TextStyle(fontSize: 12.5, color: FincoreColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (novoId) async {
                  if (novoId != null) {
                    setState(() {
                      _pdvConfig = _pdvConfig.copyWith(templateId: novoId);
                    });
                    await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
                    widget.onChanged?.call();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Seção de Configuração PIX
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF32BCAD).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF32BCAD).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.pix, color: Color(0xFF32BCAD), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Regras para Pagamento PIX no Frente de Caixa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF32BCAD),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Como enviar as informações de PIX na mensagem principal:',
                  style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'bloco_completo',
                      label: Text('Chave + Copia e Cola', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.all_inclusive_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: 'chave',
                      label: Text('Apenas Chave', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.key_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: 'copia_cola',
                      label: Text('Apenas Copia e Cola', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.content_copy_rounded, size: 14),
                    ),
                  ],
                  selected: {_pdvConfig.formatoPixPadrao},
                  onSelectionChanged: (val) async {
                    setState(() {
                      _pdvConfig = _pdvConfig.copyWith(formatoPixPadrao: val.first);
                    });
                    await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
                    widget.onChanged?.call();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF32BCAD).withValues(alpha: 0.25);
                      }
                      return FincoreColors.surface;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enviar PIX Copia e Cola em 2ª mensagem separada por padrão',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Facilita para o cliente copiar o código instantaneamente com 1 toque no app do banco.',
                    style: TextStyle(fontSize: 10.5, color: FincoreColors.textMuted),
                  ),
                  value: _pdvConfig.enviarPix2MsgPadrao,
                  activeColor: const Color(0xFF32BCAD),
                  onChanged: (val) async {
                    setState(() {
                      _pdvConfig = _pdvConfig.copyWith(enviarPix2MsgPadrao: val);
                    });
                    await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
                    widget.onChanged?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Switch de Envio por Padrão
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Habilitar envio de WhatsApp por padrão ao confirmar venda no caixa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FincoreColors.textPrimary),
            ),
            subtitle: const Text(
              'O interruptor de envio no fechamento do pedido já começará ativado se o cliente possuir telefone.',
              style: TextStyle(fontSize: 10.5, color: FincoreColors.textMuted),
            ),
            value: _pdvConfig.enviarWhatsAppPadrao,
            activeColor: const Color(0xFF25D366),
            onChanged: (val) async {
              setState(() {
                _pdvConfig = _pdvConfig.copyWith(enviarWhatsAppPadrao: val);
              });
              await WhatsAppService.salvarPdvConfig(_pdvConfig, tenantId: _tenantId);
              widget.onChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  // ── CARD GERENCIADOR DE MENSAGENS (Sub-aba 0: Modelos de Mensagens) ──
  Widget _buildCardGerenciadorMensagens(WhatsAppTemplate? templateAtual) {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF25D366), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mensagens Cadastradas (${_templates.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _confirmarRestaurarPadroes,
                    icon: const Icon(Icons.restore_rounded, size: 14),
                    label: const Text('Restaurar Padrões', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _abrirDialogoMensagem(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Adicionar Mensagem', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid / Wrap Responsivo de Cards de Mensagens
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _templates.map((t) {
              final isSel = t.id == _selectedTemplateId;
              final condicaoDesc = t.condicaoFormaPagamento != 'QUALQUER' || t.condicaoStatusPagamento != 'QUALQUER'
                  ? '${t.condicaoFormaPagamento} • ${t.condicaoStatusPagamento}'
                  : 'Qualquer pagamento';

              String evKey = t.evento;
              if (t.evento == 'pedido_criado') {
                evKey = WhatsAppService.kEventoPedidoCriadoPdv;
              } else if (t.evento == 'pedido_aprovado') {
                evKey = WhatsAppService.kEventoPedidoAprovadoWeb;
              } else if (t.evento == 'pedido_pronto') {
                evKey = WhatsAppService.kEventoPedidoPronto;
              } else if (t.evento == 'saiu_entrega') {
                evKey = WhatsAppService.kEventoPedidoSaiuEntrega;
              } else if (t.evento == 'pedido_cancelado') {
                evKey = WhatsAppService.kEventoPedidoCancelado;
              }

              final bool isPadraoDoEvento = _templatesPorEvento[evKey] == t.id;

              return InkWell(
                onTap: () => _selecionarTemplate(t.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 285,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF25D366).withValues(alpha: 0.12) : FincoreColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? const Color(0xFF25D366) : FincoreColors.border,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                color: isSel ? Colors.white : FincoreColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Badge Ativo / Inativo
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.ativo ? const Color(0xFF16A34A).withValues(alpha: 0.2) : const Color(0xFF6B7280).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.ativo ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: t.ativo ? const Color(0xFF22C55E) : FincoreColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_getNomeEvento(t.evento)} | $condicaoDesc',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, color: FincoreColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildBadgePoliticaEvento(t.evento),
                        ],
                      ),
                      if (isPadraoDoEvento) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                              SizedBox(width: 3),
                              Text('Oficial do Evento', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            tooltip: 'Editar Regras / Evento',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: FincoreColors.textSecondary,
                            onPressed: () => _abrirDialogoMensagem(t),
                          ),
                          const SizedBox(width: 12),
                          if (!t.isPadrao)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              tooltip: 'Excluir Mensagem',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: const Color(0xFFEF4444),
                              onPressed: () => _excluirTemplate(t),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── SEÇÃO EDITOR & LIVE PREVIEW RESPONSIVO (Requisito 7: Layout Robusto sem Overflow) ──
  Widget _buildSecaoEditorEPreview(WhatsAppTemplate templateAtual) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final editorWidget = Container(
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(templateAtual.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateAtual.titulo,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Evento: ${templateAtual.evento} • ${templateAtual.condicaoFormaPagamento != "QUALQUER" ? templateAtual.condicaoFormaPagamento : "Todas formas"}',
                          style: const TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _abrirDialogoMensagem(templateAtual),
                    icon: const Icon(Icons.settings_outlined, size: 14),
                    label: const Text('Configurar Regras', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FincoreColors.textSecondary,
                      side: const BorderSide(color: FincoreColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Seletor Categorizado de Variáveis Dinâmicas ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: FincoreColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'VARIÁVEIS DINÂMICAS DISPONÍVEIS:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: FincoreColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Caixa de Seleção / Dropdown de Categorias
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: FincoreColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtroCategoriaVariaveis,
                            dropdownColor: FincoreColors.surfaceElevated,
                            icon: const Icon(Icons.arrow_drop_down, size: 16, color: FincoreColors.textSecondary),
                            style: const TextStyle(fontSize: 11, color: FincoreColors.textPrimary),
                            items: [
                              DropdownMenuItem(
                                value: 'todas',
                                child: Text('📂 Todas as Categorias ($_totalVariaveis)', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              ..._categoriasVariaveis.map((cat) {
                                return DropdownMenuItem(
                                  value: cat['id'] as String,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat['icone'] as IconData, size: 13, color: cat['cor'] as Color),
                                      const SizedBox(width: 6),
                                      Text('${cat['label']} (${(cat['tags'] as List).length})'),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _filtroCategoriaVariaveis = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Clique para inserir no cursor',
                        style: TextStyle(fontSize: 10, color: FincoreColors.textMuted.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Chips de filtro em Wrap responsivo (não corta na lateral e quebra linhas suavemente)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text('Todas ($_totalVariaveis)', style: const TextStyle(fontSize: 11)),
                    selected: _filtroCategoriaVariaveis == 'todas',
                    selectedColor: const Color(0xFF25D366).withValues(alpha: 0.2),
                    backgroundColor: FincoreColors.surface,
                    labelStyle: TextStyle(
                      color: _filtroCategoriaVariaveis == 'todas' ? const Color(0xFF22C55E) : FincoreColors.textSecondary,
                      fontWeight: _filtroCategoriaVariaveis == 'todas' ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: _filtroCategoriaVariaveis == 'todas' ? const Color(0xFF22C55E) : FincoreColors.border,
                    ),
                    onSelected: (sel) => setState(() => _filtroCategoriaVariaveis = 'todas'),
                  ),
                  ..._categoriasVariaveis.map((cat) {
                    final isSel = _filtroCategoriaVariaveis == cat['id'];
                    final cor = cat['cor'] as Color;
                    final count = (cat['tags'] as List).length;

                    return ChoiceChip(
                      avatar: Icon(cat['icone'] as IconData, size: 13, color: isSel ? cor : FincoreColors.textMuted),
                      label: Text('${cat['label']} ($count)', style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: cor.withValues(alpha: 0.18),
                      backgroundColor: FincoreColors.surface,
                      labelStyle: TextStyle(
                        color: isSel ? cor : FincoreColors.textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSel ? cor : FincoreColors.border,
                      ),
                      onSelected: (sel) => setState(() => _filtroCategoriaVariaveis = sel ? cat['id'] as String : 'todas'),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),

              // Exibição dos blocos de variáveis agrupadas por categoria
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FincoreColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _categoriasVariaveis
                      .where((cat) => _filtroCategoriaVariaveis == 'todas' || _filtroCategoriaVariaveis == cat['id'])
                      .map((cat) {
                    final cor = cat['cor'] as Color;
                    final tags = cat['tags'] as List<Map<String, dynamic>>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_filtroCategoriaVariaveis == 'todas')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(cat['icone'] as IconData, size: 12, color: cor),
                                  const SizedBox(width: 5),
                                  Text(
                                    (cat['label'] as String).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: tags.map((t) {
                              return _buildTagChip(
                                t['tag'] as String,
                                color: cor,
                                tooltip: t['desc'] as String,
                                badge: t['badge'] as String?,
                                badgeColor: t['badgeColor'] as Color?,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // ── Seção de Blocos Condicionais Inteligentes ──
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFFEAB308)),
                  const SizedBox(width: 5),
                  const Text(
                    'BLOCOS CONDICIONAIS INTELIGENTES ({se ...}):',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEAB308),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBlocoCondicionalButton(
                    label: '+ Bloco Condicional PIX',
                    tooltip: 'Exibe a chave PIX somente quando a forma de pagamento for PIX',
                    conteudo: '\n{se forma_pagamento == PIX}\n🔑 *Chave PIX:* {chave_pix}\n{/se}\n',
                  ),
                  _buildBlocoCondicionalButton(
                    label: '+ PIX Pendente & Copia e Cola',
                    tooltip: 'Exibe a chave e Copia e Cola somente se forma for PIX e estiver pendente',
                    conteudo: '\n{se forma_pagamento == PIX && status_pagamento == Pendente}\n💳 *Pagamento pendente*\n🔑 *Chave PIX:* {chave_pix}\n\n📋 *Copia e Cola:*\n{chave_pix_copia_cola}\n{/se}\n',
                  ),
                  _buildBlocoCondicionalButton(
                    label: '+ Entrega vs Retirada',
                    tooltip: 'Exibe endereço de entrega se Delivery, ou endereço da loja se Retirada no balcão',
                    conteudo: '\n{se tipo_pedido == Entrega}\n📍 *Endereço de Entrega:* {endereco}\n{senao}\n🏢 *Retirada na Loja:* {endereco_empresa}\n{/se}\n',
                  ),
                  _buildBlocoCondicionalButton(
                    label: '+ Nome do Entregador',
                    tooltip: 'Exibe o entregador apenas quando já estiver definido',
                    conteudo: '\n{se entregador != "A definir"}\n🛵 *Entregador:* {entregador}\n{/se}\n',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'Texto da Mensagem (Suporta *negrito*, _itálico_ e emojis):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _conteudoCtrl,
                maxLines: 10,
                style: const TextStyle(
                  fontSize: 13,
                  color: FincoreColors.textPrimary,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FincoreColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FincoreColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF25D366)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        );

        final previewWidget = Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111B21), // Cor de fundo do WhatsApp Dark
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior do simulador WhatsApp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF202C33),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF00A884),
                      child: const Text('MS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Mariana Souza (Cliente)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('online', style: TextStyle(color: Color(0xFF00A884), fontSize: 10.5)),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Color(0xFFAEBAC1), size: 18),
                  ],
                ),
              ),

              // Área de mensagens simuladas
              Container(
                height: 340,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B141A),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Badge de data
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF182229),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('HOJE', style: TextStyle(color: Color(0xFF8696A0), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Balão verde de mensagem do WhatsApp
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF005C4B), // Verde clássico do balão enviado WhatsApp
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(0),
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _gerarPreviewMensagem(_conteudoCtrl.text),
                                style: const TextStyle(
                                  color: Color(0xFFE9EDEF),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(DateTime.now()),
                                    style: const TextStyle(color: Color(0xFF8696A0), fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.done_all, color: Color(0xFF53BDEB), size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Barra inferior do simulador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF202C33),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_outlined, color: Color(0xFF8696A0), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A3942),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Mensagem...',
                          style: TextStyle(color: Color(0xFF8696A0), fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A884),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 55, child: editorWidget),
              const SizedBox(width: 14),
              Expanded(flex: 45, child: previewWidget),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              editorWidget,
              const SizedBox(height: 14),
              previewWidget,
            ],
          );
        }
      },
    );
  }

  Widget _buildTagChip(
    String tag, {
    Color? color,
    String? tooltip,
    String? badge,
    Color? badgeColor,
  }) {
    final chipColor = color ?? const Color(0xFF38BDF8);
    return Tooltip(
      message: tooltip ?? 'Inserir variável $tag',
      child: InkWell(
        onTap: () => _inserirTag(tag),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: chipColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: chipColor,
                  fontFamily: 'monospace',
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? chipColor).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? chipColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlocoCondicionalButton({
    required String label,
    required String tooltip,
    required String conteudo,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: () => _inserirTag(conteudo),
        icon: const Icon(Icons.alt_route_rounded, size: 12, color: Color(0xFFEAB308)),
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFEAB308))),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFFEAB308).withValues(alpha: 0.4)),
          backgroundColor: const Color(0xFFEAB308).withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _testarChaveGemini() async {
    final key = _aiApiKeyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() {
        _geminiTesteSucesso = false;
        _geminiTesteResultado = 'Informe a Chave de API antes de testar a conexão.';
      });
      return;
    }

    setState(() {
      _isTestandoGemini = true;
      _geminiTesteResultado = null;
      _geminiTesteSucesso = null;
    });

    final res = await WhatsAppOrderAiParser.testarConexaoGemini(
      key,
      model: _aiModelCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isTestandoGemini = false;
        _geminiTesteSucesso = res['sucesso'] as bool? ?? false;
        _geminiTesteResultado = res['mensagem'] as String? ?? '';
        if (res['modeloRecomendado'] != null) {
          final rec = res['modeloRecomendado'] as String;
          if (rec.isNotEmpty && rec != _aiModelCtrl.text.trim()) {
            _aiModelCtrl.text = rec;
          }
        }
      });
    }
  }

  Widget _buildCardInteligenciaArtificialIa() {
    final bool isGemini = _aiProvider == 'gemini';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Card Superior: Status e Introdução ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isGemini
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                  : const Color(0xFF10B981).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isGemini ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: isGemini ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Inteligência Artificial & Captura de Pedidos WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGemini
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isGemini
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                                  : const Color(0xFF10B981).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isGemini ? 'Google Gemini 1.5 Flash' : 'Motor Local Offline (0ms)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isGemini ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'O FINCORE Food conta com interpretação semântica inteligente capaz de ler mensagens copiadas do WhatsApp ou recebidas via Evolution API, identificando itens, quantidades (inclusive no padrão de buffet/salgados), cliente, formas de pagamento e endereço.',
                      style: TextStyle(fontSize: 12, color: FincoreColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Card 1: Seleção do Provedor de IA ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: FincoreColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Modo Operacional da IA',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Opção 1: Motor Local Offline
              InkWell(
                onTap: () => setState(() => _aiProvider = 'local'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _aiProvider == 'local'
                        ? const Color(0xFF10B981).withValues(alpha: 0.10)
                        : FincoreColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _aiProvider == 'local'
                          ? const Color(0xFF10B981)
                          : FincoreColors.border,
                      width: _aiProvider == 'local' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'local',
                        groupValue: _aiProvider,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _aiProvider = val!),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Motor Local Offline Nativo (Recomendado)',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '• Grátis • Sem Cota • 0ms Latência',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Executa regex sintático e distância Levenshtein (Fuzzy Matching) diretamente na memória contra seu cadastro local do SQLite. Não requer conexão com internet e não gasta nenhuma cota de API.',
                              style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Opção 2: Google Gemini (Nuvem)
              InkWell(
                onTap: () => setState(() => _aiProvider = 'gemini'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _aiProvider == 'gemini'
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.10)
                        : FincoreColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _aiProvider == 'gemini'
                          ? const Color(0xFF38BDF8)
                          : FincoreColors.border,
                      width: _aiProvider == 'gemini' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'gemini',
                        groupValue: _aiProvider,
                        activeColor: const Color(0xFF38BDF8),
                        onChanged: (val) => setState(() => _aiProvider = val!),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Google Gemini (Nuvem / Multimodal - Flash 2.5 / 2.0)',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '• Requer API Key • Suporta Áudios e Mensagens Complexas',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Envia a transcrição para os servidores de IA generativa do Google. Capaz de compreender linguagem coloquial, gírias, áudios e pedidos desestruturados com alta precisão contextual.',
                              style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Card 2: Chave de API do Gemini e Teste de Conexão ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_rounded, size: 16, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text(
                    'Credenciais da API do Google Gemini',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure sua chave de API para habilitar os recursos em nuvem e a integração com áudios.',
                style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
              ),
              const SizedBox(height: 14),

              // Campo API Key
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chave de API do Gemini (API Key)', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _aiApiKeyCtrl,
                    obscureText: _obscureAiApiKey,
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Cole sua chave de API (ex: AIzaSyD...)',
                      hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: FincoreColors.surface,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureAiApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 16,
                              color: FincoreColors.textSecondary,
                            ),
                            tooltip: _obscureAiApiKey ? 'Mostrar Chave' : 'Ocultar Chave',
                            onPressed: () => setState(() => _obscureAiApiKey = !_obscureAiApiKey),
                          ),
                          IconButton(
                            icon: const Icon(Icons.paste_rounded, size: 16, color: FincoreColors.textSecondary),
                            tooltip: 'Colar da Área de Transferência',
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null && data!.text!.trim().isNotEmpty) {
                                setState(() => _aiApiKeyCtrl.text = data.text!.trim());
                              }
                            },
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Campo Modelo do Gemini
              _buildInputField(
                'Modelo Google Gemini',
                _aiModelCtrl,
                'gemini-2.5-flash',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildModelChip('gemini-2.5-flash', label: 'gemini-2.5-flash (Mais Recente)', isRecommended: true),
                  _buildModelChip('gemini-2.0-flash', label: 'gemini-2.0-flash'),
                  _buildModelChip('gemini-1.5-flash', label: 'gemini-1.5-flash (Legado)'),
                ],
              ),

              const SizedBox(height: 14),

              // Barra de Ações: Testar Conexão e Salvar
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isTestandoGemini ? null : _testarChaveGemini,
                    icon: _isTestandoGemini
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.network_check_rounded, size: 16),
                    label: Text(
                      _isTestandoGemini ? 'Testando Conexão...' : 'Testar Chave do Gemini',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: salvar,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text(
                      'Salvar Configuração',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              // Mensagem de Feedback do Teste
              if (_geminiTesteResultado != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _geminiTesteSucesso == true
                        ? const Color(0x1A10B981)
                        : const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _geminiTesteSucesso == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _geminiTesteSucesso == true ? Icons.verified_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: _geminiTesteSucesso == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _geminiTesteResultado!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _geminiTesteSucesso == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

        const SizedBox(height: 14),

        // ── Card 3: Como Obter a Chave Gratuita no Google ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Text(
                    'Como Obter sua Chave Gratuita do Gemini (Passo a Passo)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '1. Acesse o portal oficial do Google: https://aistudio.google.com\n'
                '2. Faça login com sua conta Google (Gmail).\n'
                '3. No menu lateral ou no botão superior, clique em "Get API key".\n'
                '4. Clique no botão azul "Create API key" (Crie uma nova chave gratuita).\n'
                '5. Copie a chave gerada (iniciada por AIzaSy...) e cole no campo acima.\n'
                '6. Clique em "Testar Chave do Gemini" e depois em "Salvar Configuração".',
                style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Card 4: Automação de Áudios via Evolution API ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mic_rounded, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suporte a Áudios de WhatsApp',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• No WhatsApp Web: basta usar o recurso nativo de transcrever áudio do WhatsApp, copiar o texto e clicar em "WhatsApp IA" no caixa.\n'
                      '• Via Evolution API: com o webhook ativo e a chave do Gemini configurada, áudios recebidos de clientes podem ser convertidos automaticamente em Pré-Pedidos pendentes de aprovação no Frente de Caixa!',
                      style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelChip(String modelCode, {required String label, bool isRecommended = false}) {
    final bool isSelected = _aiModelCtrl.text.trim() == modelCode;
    return InkWell(
      onTap: () => setState(() => _aiModelCtrl.text = modelCode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isRecommended ? const Color(0xFF10B981).withValues(alpha: 0.20) : const Color(0xFF38BDF8).withValues(alpha: 0.20))
              : FincoreColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isRecommended ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                : FincoreColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: isRecommended ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: FincoreColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: FincoreColors.surface,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: FincoreColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}
