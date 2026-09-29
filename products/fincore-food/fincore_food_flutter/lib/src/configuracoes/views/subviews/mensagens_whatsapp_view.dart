import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

/// Subview Oficial com Live Preview do WhatsApp em Tempo Real
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
  bool _isLoading = true;
  String _selectedTemplateId = 'saudacao';
  final _conteudoCtrl = TextEditingController();

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
    super.dispose();
  }

  void _onConteudoChanged() {
    final idx = _templates.indexWhere((t) => t.id == _selectedTemplateId);
    if (idx >= 0) {
      _templates[idx] = _templates[idx].copyWith(conteudo: _conteudoCtrl.text);
      setState(() {});
      widget.onChanged?.call();
    }
  }

  Future<void> _carregarTemplates() async {
    setState(() => _isLoading = true);
    final carregados = await WhatsAppService.getTemplates(
      tenantId: _tenantId,
      nomeEmpresa: _nomeEmpresaResolvido,
    );

    if (mounted) {
      setState(() {
        _templates = List.from(carregados);
        if (_templates.isNotEmpty) {
          _selecionarTemplate(_templates.first.id);
        }
        _isLoading = false;
      });
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
    final ok = await WhatsAppService.salvarTemplates(_templates, tenantId: _tenantId);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Modelos de mensagens do WhatsApp salvos com sucesso!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetarPadroes() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: FincoreColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text('Restaurar Textos Padrões?'),
          ],
        ),
        content: const Text(
          'Deseja redefinir os textos das mensagens para o modelo padrão oficial?',
          style: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
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
      '{loja}': _nomeEmpresaResolvido,
      '{pedido}': '000104',
      '{total}': '89,90',
      '{forma_pagamento}': 'PIX',
      '{endereco}': 'Rua das Flores, 120 - Apto 34',
      '{link_cardapio}': 'https://cardapio.fincore.app/minhaloja',
      '{chave_pix}': 'pix@$_nomeEmpresaResolvido.com.br',
    };

    return WhatsAppService.interpolarTemplate(textoOriginal, dadosExemplo);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Header com Título e Botão Restaurar ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Configuração de Mensagens Rápidas do WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FincoreColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Selecione o modelo, ajuste o texto e veja o resultado formatado em tempo real ao lado.',
                  style: TextStyle(fontSize: 12.5, color: FincoreColors.textMuted),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _resetarPadroes,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Restaurar Padrões', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Barra Horizontal com Lista de Templates ──
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final t = _templates[i];
              final isSel = t.id == _selectedTemplateId;
              return InkWell(
                onTap: () => _selecionarTemplate(t.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF25D366).withValues(alpha: 0.15)
                        : FincoreColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? const Color(0xFF25D366) : FincoreColors.border,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Text(
                        t.titulo,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : FincoreColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Layout Principal (Editor 55% + Live Preview 45%) ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── COLUNA ESQUERDA: EDITOR ──
              Expanded(
                flex: 55,
                child: Container(
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (templateAtual != null) ...[
                        Row(
                          children: [
                            Text(templateAtual.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    templateAtual.titulo,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: FincoreColors.textPrimary,
                                    ),
                                  ),
                                  if (templateAtual.descricao.isNotEmpty)
                                    Text(
                                      templateAtual.descricao,
                                      style: const TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tags de inserção rápida
                      const Text(
                        'CLIQUE PARA INSERIR UMA VARIÁVEL DINÂMICA:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: FincoreColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildTagChip('{cliente}'),
                          _buildTagChip('{loja}'),
                          _buildTagChip('{pedido}'),
                          _buildTagChip('{total}'),
                          _buildTagChip('{forma_pagamento}'),
                          _buildTagChip('{endereco}'),
                          _buildTagChip('{link_cardapio}'),
                          _buildTagChip('{chave_pix}'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Campo de Texto da Mensagem
                      Expanded(
                        child: TextFormField(
                          controller: _conteudoCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontSize: 13,
                            color: FincoreColors.textPrimary,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Texto da Mensagem (Suporta *negrito*, _itálico_ e emojis)',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: FincoreColors.surfaceElevated,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: FincoreColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── COLUNA DIREITA: LIVE PREVIEW FORMATADO (WHATSAPP) ──
              Expanded(
                flex: 45,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B141A), // Fundo do WhatsApp Dark
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1F2C34)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header WhatsApp
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2C34),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Mariana Souza (Cliente)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'online',
                                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_vert, color: Color(0xFFAEBAC1), size: 18),
                          ],
                        ),
                      ),

                      // Área da Mensagem Formatada
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          alignment: Alignment.topRight,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Badge Hoje
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF182229),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'HOJE',
                                      style: TextStyle(
                                        color: Color(0xFF8696A0),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Balão Verde do WhatsApp
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 340),
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005C4B),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _gerarPreviewMensagem(_conteudoCtrl.text),
                                        style: const TextStyle(
                                          color: Color(0xFFE9EDEF),
                                          fontSize: 12.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(DateTime.now()),
                                            style: const TextStyle(
                                              color: Color(0xFF8696A0),
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.done_all_rounded,
                                            size: 14,
                                            color: Color(0xFF53BDEB),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Barra Inferior WhatsApp
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2C34),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF8696A0), size: 20),
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
                                  style: TextStyle(color: Color(0xFF8696A0), fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 15),
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
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return InkWell(
      onTap: () => _inserirTag(tag),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF38BDF8),
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
