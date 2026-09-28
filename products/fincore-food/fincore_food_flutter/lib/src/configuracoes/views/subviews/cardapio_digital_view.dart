import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';

/// Hub Operacional do Cardápio Digital Web & Pedidos Online
class CardapioDigitalView extends StatefulWidget {
  final CoreEmpresa? empresa;
  final VoidCallback? onChanged;

  const CardapioDigitalView({
    super.key,
    this.empresa,
    this.onChanged,
  });

  @override
  State<CardapioDigitalView> createState() => _CardapioDigitalViewState();
}

class _CardapioDigitalViewState extends State<CardapioDigitalView> {
  final _baseUrlCtrl = TextEditingController(text: 'https://fincore-cardapio-web.vercel.app');
  bool _isCheckingStatus = false;
  bool? _isOnline;
  String _statusMessage = 'Aguardando verificação';

  // ─── Identidade Visual ───
  final _logoUrlCtrl = TextEditingController();
  String? _logoPreviewUrl;
  bool _isSavingLogo = false;
  String _logoSaveMessage = '';

  // ─── Horários de Atendimento & Prazo Mínimo ───
  String _lojaOnlineStatus = 'auto'; // 'auto', 'aberto', 'fechado'
  final _prazoMinimoCtrl = TextEditingController(text: '120');
  final _mensagemFechadoCtrl = TextEditingController(text: 'Estamos fora do horário de atendimento. Faça seu pedido agendado!');
  bool _isSavingHorarios = false;
  String _horariosSaveMessage = '';
  List<Map<String, dynamic>> _bloqueiosAgendamento = [];

  final Map<String, ({bool ativo, String abertura, String fechamento, String nome})> _diasSemana = {
    'dom': (ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Domingo'),
    'seg': (ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Segunda-feira'),
    'ter': (ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Terça-feira'),
    'qua': (ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Quarta-feira'),
    'qui': (ativo: true, abertura: '08:00', fechamento: '22:00', nome: 'Quinta-feira'),
    'sex': (ativo: true, abertura: '08:00', fechamento: '23:00', nome: 'Sexta-feira'),
    'sab': (ativo: true, abertura: '08:00', fechamento: '23:00', nome: 'Sábado'),
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadLogoUrl();
    _loadHorarios();
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _logoUrlCtrl.dispose();
    _prazoMinimoCtrl.dispose();
    _mensagemFechadoCtrl.dispose();
    super.dispose();
  }

  String get _tenantId {
    if (widget.empresa?.id != null && widget.empresa!.id.isNotEmpty) {
      return widget.empresa!.id;
    }
    final tenantCtx = DependencyInjection().get<TenantContext>();
    return tenantCtx.hasContext ? tenantCtx.empresa.id : '';
  }

  String get _nomeEmpresa {
    return widget.empresa?.nomeFantasia ?? widget.empresa?.razaoSocial ?? 'Sua Empresa';
  }

  String get _fullUrl {
    final raw = _baseUrlCtrl.text.trim();
    final base = raw.isEmpty ? 'https://fincore-cardapio-web.vercel.app' : raw;
    final tId = _tenantId;
    if (tId.isEmpty) return base;

    return base.contains('?') ? '$base&tenant_id=$tId' : '$base/?tenant_id=$tId';
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final tId = _tenantId;
    final saved = (tId.isNotEmpty ? prefs.getString('cardapio_base_url_$tId') : null) ??
        prefs.getString('cardapio_base_url');

    if (saved != null && saved.isNotEmpty) {
      if (mounted) {
        setState(() {
          _baseUrlCtrl.text = saved;
        });
      }
    }

    _checkConnectivity();
  }

  Future<void> _saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final tId = _tenantId;
    if (tId.isNotEmpty) {
      await prefs.setString('cardapio_base_url_$tId', url.trim());
    }
    await prefs.setString('cardapio_base_url', url.trim());
    widget.onChanged?.call();
    _checkConnectivity();
  }

  // ─── Logo: leitura e gravação via empresa_configuracao.logoUrl ───
  Future<void> _loadLogoUrl() async {
    final tId = _tenantId;
    final prefs = await SharedPreferences.getInstance();
    final cachedLogo = (tId.isNotEmpty ? prefs.getString('empresa_logo_url_$tId') : null) ?? prefs.getString('empresa_logo_url');
    if (cachedLogo != null && cachedLogo.isNotEmpty && mounted) {
      setState(() {
        _logoUrlCtrl.text = cachedLogo;
        _logoPreviewUrl = cachedLogo;
      });
    }

    if (tId.isEmpty) return;
    try {
      final sb = Supabase.instance.client;
      final row = await sb
          .from('empresa_configuracao')
          .select('logoUrl')
          .eq('tenantId', tId)
          .maybeSingle();
      final url = row?['logoUrl'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() {
          _logoUrlCtrl.text = url;
          _logoPreviewUrl = url;
        });
        await prefs.setString('empresa_logo_url_$tId', url);
        await prefs.setString('empresa_logo_url', url);
      } else if (mounted && (url == null || url.isEmpty)) {
        final empRow = await sb.from('empresa').select('logoUrl').eq('id', tId).maybeSingle();
        final empLogo = empRow?['logoUrl'] as String?;
        if (empLogo != null && empLogo.isNotEmpty && mounted) {
          setState(() {
            _logoUrlCtrl.text = empLogo;
            _logoPreviewUrl = empLogo;
          });
          await prefs.setString('empresa_logo_url_$tId', empLogo);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickLocalLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'svg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() => _logoSaveMessage = 'Não foi possível ler o arquivo selecionado.');
        }
        return;
      }

      setState(() {
        _isSavingLogo = true;
        _logoSaveMessage = 'Processando imagem...';
      });

      final tId = _tenantId;
      final ext = (file.extension ?? 'png').toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp'
              ? 'image/webp'
              : (ext == 'svg' ? 'image/svg+xml' : 'image/jpeg'));

      String? finalUrl;

      // 1. Tentar upload para Supabase Storage
      try {
        final sb = Supabase.instance.client;
        final fileName = 'logo_${tId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await sb.storage.from('empresa-logos').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
        finalUrl = sb.storage.from('empresa-logos').getPublicUrl(fileName);
      } catch (_) {
        // Fallback: Armazenar Data URI Base64 direto
        final b64 = base64Encode(bytes);
        finalUrl = 'data:$mimeType;base64,$b64';
      }

      if (finalUrl.isNotEmpty) {
        _logoUrlCtrl.text = finalUrl;
        setState(() {
          _logoPreviewUrl = finalUrl;
        });
        await _saveLogoUrl();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingLogo = false;
          _logoSaveMessage = 'Erro ao selecionar imagem: $e';
        });
      }
    }
  }

  Widget _buildLogoPreview() {
    if (_logoPreviewUrl == null || _logoPreviewUrl!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 40, color: FincoreColors.textMuted),
            SizedBox(height: 8),
            Text('Nenhuma logo configurada', style: TextStyle(fontSize: 13, color: FincoreColors.textMuted)),
            SizedBox(height: 3),
            Text('Importe uma foto local ou insira uma URL pública', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
          ],
        ),
      );
    }

    if (_logoPreviewUrl!.startsWith('data:image')) {
      try {
        final commaIdx = _logoPreviewUrl!.indexOf(',');
        if (commaIdx != -1) {
          final b64Str = _logoPreviewUrl!.substring(commaIdx + 1);
          final bytes = base64Decode(b64Str);
          return Image.memory(bytes, fit: BoxFit.contain);
        }
      } catch (_) {}
    }

    return Image.network(
      _logoPreviewUrl!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 36, color: FincoreColors.textMuted),
            SizedBox(height: 6),
            Text('Não foi possível carregar a imagem', style: TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLogoUrl() async {
    final tId = _tenantId;
    if (tId.isEmpty) return;
    final url = _logoUrlCtrl.text.trim();
    setState(() {
      _isSavingLogo = true;
      _logoSaveMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('empresa_logo_url_$tId', url);
      await prefs.setString('empresa_logo_url', url);

      final sb = Supabase.instance.client;
      try {
        await sb.from('empresa_configuracao').upsert({
          'tenantId': tId,
          'logoUrl': url.isEmpty ? null : url,
          'updatedAt': DateTime.now().toIso8601String(),
        }, onConflict: 'tenantId');
      } catch (_) {
        await sb.from('empresa_configuracao')
            .update({'logoUrl': url.isEmpty ? null : url, 'updatedAt': DateTime.now().toIso8601String()})
            .eq('tenantId', tId);
      }

      try {
        await sb.from('empresa')
            .update({'logoUrl': url.isEmpty ? null : url, 'updatedAt': DateTime.now().toIso8601String()})
            .eq('id', tId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _logoPreviewUrl = url.isEmpty ? null : url;
          _logoSaveMessage = url.isEmpty ? 'Logo removida.' : 'Logo salva com sucesso!';
        });
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _logoSaveMessage = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSavingLogo = false);
    }
  }

  // ─── Horários de Atendimento & Regras de Pedidos Web ───
  Future<void> _loadHorarios() async {
    final tId = _tenantId;
    final prefs = await SharedPreferences.getInstance();
    final cached = (tId.isNotEmpty ? prefs.getString('cardapio_horarios_$tId') : null) ?? prefs.getString('cardapio_horarios');
    if (cached != null && cached.isNotEmpty) {
      _parseHorariosJson(cached);
    }

    if (tId.isEmpty) return;
    try {
      final sb = Supabase.instance.client;
      final row = await sb
          .from('empresa_configuracao')
          .select('*')
          .eq('tenantId', tId)
          .maybeSingle();

      if (row != null && row['horariosAtendimento'] != null) {
        final jsonStr = row['horariosAtendimento'] is String
            ? row['horariosAtendimento'] as String
            : jsonEncode(row['horariosAtendimento']);
        _parseHorariosJson(jsonStr);
        await prefs.setString('cardapio_horarios_$tId', jsonStr);
        await prefs.setString('cardapio_horarios', jsonStr);
      }
    } catch (_) {}
  }

  void _parseHorariosJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data.containsKey('status')) {
        _lojaOnlineStatus = data['status'] as String? ?? 'auto';
      }
      if (data.containsKey('prazoMinimoMinutos')) {
        _prazoMinimoCtrl.text = (data['prazoMinimoMinutos'] ?? 120).toString();
      }
      if (data.containsKey('mensagemFechado')) {
        _mensagemFechadoCtrl.text = data['mensagemFechado'] as String? ?? '';
      }
      if (data.containsKey('bloqueios') && data['bloqueios'] is List) {
        _bloqueiosAgendamento = (data['bloqueios'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _bloqueiosAgendamento = [];
      }
      if (data.containsKey('dias') && data['dias'] is Map) {
        final diasMap = data['dias'] as Map<String, dynamic>;
        for (final k in _diasSemana.keys) {
          if (diasMap.containsKey(k) && diasMap[k] is Map) {
            final d = diasMap[k] as Map<String, dynamic>;
            _diasSemana[k] = (
              ativo: d['ativo'] as bool? ?? true,
              abertura: d['abertura'] as String? ?? '08:00',
              fechamento: d['fechamento'] as String? ?? '22:00',
              nome: _diasSemana[k]!.nome,
            );
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveHorarios() async {
    final tId = _tenantId;
    if (tId.isEmpty) return;
    setState(() {
      _isSavingHorarios = true;
      _horariosSaveMessage = '';
    });

    try {
      final prazoMin = int.tryParse(_prazoMinimoCtrl.text.trim()) ?? 120;
      final diasJson = <String, dynamic>{};
      for (final e in _diasSemana.entries) {
        diasJson[e.key] = {
          'ativo': e.value.ativo,
          'abertura': e.value.abertura,
          'fechamento': e.value.fechamento,
        };
      }

      final payload = {
        'status': _lojaOnlineStatus,
        'prazoMinimoMinutos': prazoMin,
        'mensagemFechado': _mensagemFechadoCtrl.text.trim(),
        'dias': diasJson,
        'bloqueios': _bloqueiosAgendamento,
      };
      final jsonStr = jsonEncode(payload);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cardapio_horarios_$tId', jsonStr);
      await prefs.setString('cardapio_horarios', jsonStr);

      final sb = Supabase.instance.client;
      try {
        await sb.from('empresa_configuracao').upsert({
          'tenantId': tId,
          'horariosAtendimento': jsonStr,
          'updatedAt': DateTime.now().toIso8601String(),
        }, onConflict: 'tenantId');
      } catch (_) {
        await sb.from('empresa_configuracao').update({
          'horariosAtendimento': jsonStr,
          'updatedAt': DateTime.now().toIso8601String(),
        }).eq('tenantId', tId);
      }

      if (mounted) {
        setState(() {
          _horariosSaveMessage = '✅ Horários e regras de pedidos web salvos com sucesso!';
        });
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _horariosSaveMessage = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSavingHorarios = false);
    }
  }

  void _replicarHorario(String origemKey, bool apenasUteis) {
    final origem = _diasSemana[origemKey];
    if (origem == null) return;

    setState(() {
      for (final k in _diasSemana.keys) {
        if (apenasUteis && (k == 'dom' || k == 'sab')) continue;
        _diasSemana[k] = (
          ativo: origem.ativo,
          abertura: origem.abertura,
          fechamento: origem.fechamento,
          nome: _diasSemana[k]!.nome,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horário de ${origem.nome} replicado ${apenasUteis ? "para dias úteis (Seg-Sex)" : "para toda a semana"}!'),
        backgroundColor: FincoreColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    if (_isCheckingStatus) return;
    setState(() {
      _isCheckingStatus = true;
      _statusMessage = 'Verificando conexão...';
    });

    try {
      final uri = Uri.parse(_fullUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'FinCore-Food-Hub/2.0');
      final res = await req.close();
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _isOnline = res.statusCode >= 200 && res.statusCode < 400;
          if (_isOnline == true) {
            _statusMessage = 'Cardápio Online & Operacional (${res.statusCode} OK)';
          } else if (res.statusCode == 401 || res.statusCode == 403) {
            _statusMessage = 'Servidor requer login/senha (Status ${res.statusCode}). Troque para o preset Vercel.';
          } else {
            _statusMessage = 'Servidor respondeu com status ${res.statusCode}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _isOnline = false;
          _statusMessage = 'Não foi possível alcançar a URL do cardápio';
        });
      }
    }
  }

  Future<void> _openBrowser() async {
    final uri = Uri.parse(_fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link no navegador.'),
            backgroundColor: FincoreColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _shareWhatsApp() async {
    final msg = Uri.encodeComponent(
      'Olá! 👋 Conheça o cardápio online de *$_nomeEmpresa* e faça seu pedido direto pelo seu celular:\n\n🔗 $_fullUrl\n\nAproveite nossas novidades e ofertas!',
    );
    final uri = Uri.parse('https://api.whatsapp.com/send?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _printDisplayMesa(bool isA4) async {
    final doc = pw.Document();
    final fullUrl = _fullUrl;
    final nome = _nomeEmpresa;

    doc.addPage(
      pw.Page(
        pageFormat: isA4 ? PdfPageFormat.a4 : const PdfPageFormat(80 * PdfPageFormat.mm, 150 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  nome.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: isA4 ? 26 : 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'CARDÁPIO DIGITAL & PEDIDOS ONLINE',
                  style: pw.TextStyle(
                    fontSize: isA4 ? 14 : 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: fullUrl,
                    width: isA4 ? 200 : 120,
                    height: isA4 ? 200 : 120,
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  '📱 Aponte a câmera do seu celular',
                  style: pw.TextStyle(
                    fontSize: isA4 ? 16 : 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Consulte preços, promoções e faça seu pedido sem filas!',
                  style: pw.TextStyle(
                    fontSize: isA4 ? 12 : 8,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  fullUrl,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Display_Mesa_Cardapio_${_nomeEmpresa.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 1. CARD: STATUS OPERACIONAL DO CARDÁPIO DIGITAL ─────────────────────
        FincoreSectionCard(
          title: 'Hub de Pedidos Online & Cardápio Digital',
          subtitle: 'Visão geral do canal de vendas digital integrado ao FinCore Food',
          icon: Icons.storefront_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_menu_rounded, color: FincoreColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nomeEmpresa,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tenant ID: ${_tenantId.isNotEmpty ? _tenantId : "Empresa não autenticada"}',
                          style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: FincoreColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Badge de status de conexão
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOnline == true
                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                          : (_isOnline == false
                              ? FincoreColors.danger.withValues(alpha: 0.12)
                              : FincoreColors.surfaceElevated),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isOnline == true
                            ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                            : (_isOnline == false
                                ? FincoreColors.danger.withValues(alpha: 0.4)
                                : FincoreColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCheckingStatus)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: FincoreColors.primary),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnline == true
                                  ? const Color(0xFF16A34A)
                                  : (_isOnline == false ? FincoreColors.danger : Colors.grey),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isOnline == true
                                ? const Color(0xFF16A34A)
                                : (_isOnline == false ? FincoreColors.danger : FincoreColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Recarregar Teste de Conectividade',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _checkConnectivity,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: FincoreColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Automação de Cozinha & KDS: Os pedidos realizados pelos clientes chegam instantaneamente na Central de Pedidos e entram na fila de preparo da Cozinha.',
                        style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── CARD: IDENTIDADE VISUAL DO CARDÁPIO DIGITAL ─────────────────────
        FincoreSectionCard(
          title: 'Identidade Visual do Cardápio',
          subtitle: 'Logo exibida no portal de pedidos online desta empresa',
          icon: Icons.image_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview da logo
              Container(
                width: double.infinity,
                height: 140,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FincoreColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildLogoPreview(),
              ),
              const FincoreFieldLabel(label: 'URL da Logo (ou importe uma foto local):'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: FincoreTextField(
                      controller: _logoUrlCtrl,
                      hintText: 'https://seu-cdn.com/logo.png ou importe abaixo',
                      onChanged: (v) {
                        setState(() => _logoPreviewUrl = v.trim());
                      },
                    ),
                  ),
                  if (_logoUrlCtrl.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Limpar logo',
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _logoUrlCtrl.clear();
                        setState(() => _logoPreviewUrl = null);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Você pode importar uma imagem direto do computador ou inserir uma URL pública da logo.',
                style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSavingLogo ? null : _pickLocalLogo,
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('📁 Importar Foto do Computador'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isSavingLogo ? null : _saveLogoUrl,
                    icon: _isSavingLogo
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSavingLogo ? 'Salvando...' : 'Salvar Logo'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  if (_logoSaveMessage.isNotEmpty) ...[
                    Text(
                      _logoSaveMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: _logoSaveMessage.contains('Erro') ? FincoreColors.danger : FincoreColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── CARD: HORÁRIOS DE ATENDIMENTO & REGRAS DE PEDIDOS WEB ───────
        _buildHorariosCard(),

        const SizedBox(height: 16),

        // ─── 2. CARD: LINK OFICIAL E DOMÍNIO DE ACESSO ─────────────────────
        FincoreSectionCard(
          title: 'Link Oficial e Domínio de Acesso',
          subtitle: 'Link público oficial hospedado na Vercel e integrado em tempo real',
          icon: Icons.link_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 22, color: FincoreColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hospedagem Oficial Vercel (Produção)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                          ),
                          Text(
                            'https://fincore-cardapio-web.vercel.app',
                            style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: FincoreColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (_baseUrlCtrl.text.trim() != 'https://fincore-cardapio-web.vercel.app')
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _baseUrlCtrl.text = 'https://fincore-cardapio-web.vercel.app';
                          });
                          _saveBaseUrl(_baseUrlCtrl.text);
                        },
                        icon: const Icon(Icons.restore_rounded, size: 14),
                        label: const Text('Restaurar Vercel', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const FincoreFieldLabel(label: 'URL Base do Cardápio (ou Domínio Próprio):'),
              FincoreTextField(
                controller: _baseUrlCtrl,
                hintText: 'https://fincore-cardapio-web.vercel.app ou https://cardapio.minhaloja.com.br',
                onChanged: (val) {
                  _saveBaseUrl(val);
                },
              ),
              const SizedBox(height: 14),
              const FincoreFieldLabel(label: 'Link Público Completo da Empresa:'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: FincoreColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        _fullUrl,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: FincoreColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fullUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Link copiado para a área de transferência!'),
                          backgroundColor: Color(0xFF16A34A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar Link'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: FincoreColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openBrowser,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: Colors.white),
                    label: const Text('Abrir no Navegador', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _shareWhatsApp,
                    icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                    label: const Text('Divulgar no WhatsApp', style: TextStyle(color: FincoreColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── 3. CARD: DISPLAY DE MESA & GERADOR DE QR CODE ───────────────────────
        FincoreSectionCard(
          title: 'Display de Mesa, Balcão & QR Code',
          subtitle: 'Gere materiais impressos para os clientes pedirem diretamente da mesa ou embalagem de delivery',
          icon: Icons.qr_code_2_rounded,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return isNarrow
                  ? Column(
                      children: [
                        _buildQrCodePreview(),
                        const SizedBox(height: 16),
                        _buildPrintActions(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQrCodePreview(),
                        const SizedBox(width: 24),
                        Expanded(child: _buildPrintActions()),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodePreview() {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _nomeEmpresa,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'PEÇA ONLINE',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFFF97316), letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          // QR Code renderizado
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(_fullUrl)}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aponte a câmera',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materiais Prontos para Impressão',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Imprima displays de acrílico para as mesas, adesivos para balcão ou cartões de agradecimento para enviar dentro das sacolas de delivery.',
          style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => _printDisplayMesa(true),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Imprimir Display A4 / Mesa (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.surfaceElevated,
                foregroundColor: FincoreColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: FincoreColors.border),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _printDisplayMesa(false),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Imprimir Cupom QR Bobina (80mm)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FincoreColors.surfaceElevated,
                foregroundColor: FincoreColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: FincoreColors.border),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHorariosCard() {
    return FincoreSectionCard(
      title: 'Dias, Horários & Regras de Atendimento Web',
      subtitle: 'Controle o status da loja online, horários de funcionamento e prazo mínimo de antecedência',
      icon: Icons.access_time_filled_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. Status da Loja Online ───
          const FincoreFieldLabel(label: 'Status da Loja para Pedidos Online:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildStatusOption(
                value: 'auto',
                icon: Icons.schedule_rounded,
                label: 'Automático (Conforme Grade)',
                color: FincoreColors.primary,
              ),
              _buildStatusOption(
                value: 'aberto',
                icon: Icons.check_circle_rounded,
                label: 'Aberto Agora (Forçar)',
                color: const Color(0xFF16A34A),
              ),
              _buildStatusOption(
                value: 'fechado',
                icon: Icons.pause_circle_filled_rounded,
                label: 'Fechado (Pausar Pedidos)',
                color: const Color(0xFFEF4444),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── 2. Prazo Mínimo de Antecedência ───
          const FincoreFieldLabel(label: 'Prazo Mínimo de Antecedência para Fazer Pedidos:'),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: FincoreTextField(
                  controller: _prazoMinimoCtrl,
                  keyboardType: TextInputType.number,
                  hintText: '120',
                ),
              ),
              const SizedBox(width: 10),
              const Text('minutos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FincoreColors.textSecondary)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '💡 Ex: 120 min = 2 horas de antecedência. Pedidos feitos às 08:00 só poderão ser agendados para a partir das 10:00.',
                  style: const TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── 3. Grade Semanal de Horários de Atendimento ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FincoreFieldLabel(label: 'Grade Semanal de Abertura e Fechamento:'),
              PopupMenuButton<String>(
                tooltip: 'Ações Rápidas de Horário',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: FincoreColors.surfaceElevated,
                onSelected: (val) {
                  if (val == 'uteis') _replicarHorario('seg', true);
                  if (val == 'todos') _replicarHorario('seg', false);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'uteis',
                    child: Text('Replicar Seg para Dias Úteis (Seg-Sex)', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
                  ),
                  const PopupMenuItem(
                    value: 'todos',
                    child: Text('Replicar Seg para Todos os Dias (Dom-Sáb)', style: TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FincoreColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_all_rounded, size: 14, color: FincoreColors.primary),
                      const SizedBox(width: 6),
                      Text('Ações Rápidas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.primary)),
                      Icon(Icons.arrow_drop_down, size: 16, color: FincoreColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: FincoreColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FincoreColors.border),
            ),
            child: Column(
              children: _diasSemana.entries.map((entry) {
                final key = entry.key;
                final dia = entry.value;
                final isLast = key == _diasSemana.keys.last;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(bottom: BorderSide(color: FincoreColors.border)),
                  ),
                  child: Row(
                    children: [
                      // Switch dia ativo
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            Switch.adaptive(
                              value: dia.ativo,
                              activeColor: FincoreColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _diasSemana[key] = (
                                    ativo: val,
                                    abertura: dia.abertura,
                                    fechamento: dia.fechamento,
                                    nome: dia.nome,
                                  );
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dia.nome,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: dia.ativo ? FontWeight.bold : FontWeight.normal,
                                  color: dia.ativo ? FincoreColors.textPrimary : FincoreColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      if (dia.ativo) ...[
                        const Text('Das', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 85,
                          child: _buildTimeDropdown(
                            currentVal: dia.abertura,
                            onChanged: (newVal) {
                              setState(() {
                                _diasSemana[key] = (
                                  ativo: dia.ativo,
                                  abertura: newVal,
                                  fechamento: dia.fechamento,
                                  nome: dia.nome,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('às', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 85,
                          child: _buildTimeDropdown(
                            currentVal: dia.fechamento,
                            onChanged: (newVal) {
                              setState(() {
                                _diasSemana[key] = (
                                  ativo: dia.ativo,
                                  abertura: dia.abertura,
                                  fechamento: newVal,
                                  nome: dia.nome,
                                );
                              });
                            },
                          ),
                        ),
                      ] else ...[
                        const Expanded(
                          child: Text(
                            'Fechado para pedidos',
                            style: TextStyle(fontSize: 12, color: FincoreColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ─── 4. Bloqueio de Datas e Horários Específicos (Compromissos / Feriados) ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FincoreFieldLabel(label: 'Bloqueio de Datas e Horários Específicos:'),
              OutlinedButton.icon(
                onPressed: _abrirModalAdicionarBloqueio,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Bloquear Data / Horário', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FincoreColors.primary,
                  side: const BorderSide(color: FincoreColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Bloqueie datas ou horários específicos em que você terá compromissos ou folgas e não aceitará pedidos agendados.',
            style: TextStyle(fontSize: 11.5, color: FincoreColors.textMuted),
          ),
          const SizedBox(height: 10),

          _buildBloqueiosList(),

          const SizedBox(height: 18),

          // ─── 5. Mensagem Quando Fechado ───
          const FincoreFieldLabel(label: 'Mensagem exibida ao cliente quando a loja estiver fechada:'),
          const SizedBox(height: 6),
          FincoreTextField(
            controller: _mensagemFechadoCtrl,
            hintText: 'Estamos fora do horário de atendimento. Faça seu pedido para o próximo turno!',
          ),

          const SizedBox(height: 16),

          // Botão Salvar
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _isSavingHorarios ? null : _saveHorarios,
                icon: _isSavingHorarios
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSavingHorarios ? 'Salvando...' : 'Salvar Horários & Regras'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              if (_horariosSaveMessage.isNotEmpty) ...[
                Text(
                  _horariosSaveMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _horariosSaveMessage.contains('Erro') ? FincoreColors.danger : FincoreColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _lojaOnlineStatus == value;
    return InkWell(
      onTap: () => setState(() => _lojaOnlineStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : FincoreColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : FincoreColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String currentVal,
    required ValueChanged<String> onChanged,
  }) {
    // Horários de 30 em 30 min (00:00 até 23:30)
    final options = List.generate(48, (i) {
      final h = (i ~/ 2).toString().padLeft(2, '0');
      final m = (i % 2 == 0) ? '00' : '30';
      return '$h:$m';
    });

    final val = options.contains(currentVal) ? currentVal : options.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
          dropdownColor: FincoreColors.surfaceElevated,
          items: options.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  String _formatDataBr(String dataIso) {
    if (dataIso.isEmpty) return '';
    try {
      final parts = dataIso.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dataIso;
  }

  Widget _buildBloqueiosList() {
    if (_bloqueiosAgendamento.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: Color(0xFF16A34A), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Nenhum dia ou horário bloqueado. Agendamentos permitidos normalmente conforme a grade semanal.',
                style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        children: _bloqueiosAgendamento.asMap().entries.map((entry) {
          final idx = entry.key;
          final b = entry.value;
          final isLast = idx == _bloqueiosAgendamento.length - 1;
          final dataBr = _formatDataBr(b['data']?.toString() ?? '');
          final diaTodo = b['diaTodo'] as bool? ?? true;
          final inicio = b['inicio']?.toString() ?? '08:00';
          final fim = b['fim']?.toString() ?? '18:00';
          final motivo = b['motivo']?.toString() ?? 'Bloqueio de agendamento';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: FincoreColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FincoreColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: FincoreColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dataBr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: diaTodo ? FincoreColors.danger.withValues(alpha: 0.15) : FincoreColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              diaTodo ? 'O Dia Inteiro' : 'Das $inicio às $fim',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: diaTodo ? FincoreColors.danger : FincoreColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (motivo.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          motivo,
                          style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover este bloqueio',
                  icon: const Icon(Icons.delete_outline_rounded, color: FincoreColors.danger, size: 18),
                  onPressed: () {
                    setState(() {
                      _bloqueiosAgendamento.removeAt(idx);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _abrirModalAdicionarBloqueio() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool diaTodo = true;
    String horaInicio = '08:00';
    String horaFim = '18:00';
    final motivoCtrl = TextEditingController(text: 'Compromisso pessoal');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final dataFormatada = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
          return AlertDialog(
            backgroundColor: FincoreColors.surfaceElevated,
            title: const Row(
              children: [
                Icon(Icons.event_busy_rounded, color: FincoreColors.danger, size: 22),
                SizedBox(width: 10),
                Text('Bloquear Data / Horário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FincoreFieldLabel(label: 'Data do Bloqueio:'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: FincoreColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: FincoreColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              dataFormatada,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FincoreColors.textPrimary),
                            ),
                            const Spacer(),
                            const Text('Alterar data', style: TextStyle(fontSize: 11.5, color: FincoreColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch.adaptive(
                          value: diaTodo,
                          activeColor: FincoreColors.danger,
                          onChanged: (v) => setDialogState(() => diaTodo = v),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bloquear o dia inteiro',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: diaTodo ? FontWeight.bold : FontWeight.normal,
                            color: FincoreColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!diaTodo) ...[
                      const SizedBox(height: 12),
                      const FincoreFieldLabel(label: 'Faixa de Horário Bloqueada:'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Das', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                          const SizedBox(width: 8),
                          _buildTimeDropdown(
                            currentVal: horaInicio,
                            onChanged: (v) => setDialogState(() => horaInicio = v),
                          ),
                          const SizedBox(width: 12),
                          const Text('às', style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
                          const SizedBox(width: 8),
                          _buildTimeDropdown(
                            currentVal: horaFim,
                            onChanged: (v) => setDialogState(() => horaFim = v),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const FincoreFieldLabel(label: 'Motivo / Observação (Exibido se o cliente tentar agendar):'),
                    const SizedBox(height: 6),
                    FincoreTextField(
                      controller: motivoCtrl,
                      hintText: 'Ex: Compromisso particular, Evento externo, Feriado',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: FincoreColors.primary),
                onPressed: () {
                  final isoDate = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  setState(() {
                    _bloqueiosAgendamento.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'data': isoDate,
                      'diaTodo': diaTodo,
                      'inicio': horaInicio,
                      'fim': horaFim,
                      'motivo': motivoCtrl.text.trim(),
                    });
                  });
                  Navigator.of(ctx).pop();
                },
                child: const Text('Adicionar Bloqueio'),
              ),
            ],
          );
        },
      ),
    );
  }
}
