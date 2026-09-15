import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/fincore_core.dart';
import '../auth/services/supabase_session_service.dart';

/// Widget de troca de empresa exibido dentro do Drawer/Menu do app.
///
/// Permite que o proprietário alterne entre Matriz, Filiais e quaisquer
/// outras empresas às quais possui acesso sem precisar fazer logout.
class EmpresaSwitcherWidget extends StatefulWidget {
  final VoidCallback? onEmpresaTrocada;

  const EmpresaSwitcherWidget({super.key, this.onEmpresaTrocada});

  @override
  State<EmpresaSwitcherWidget> createState() => _EmpresaSwitcherWidgetState();
}

class _EmpresaSwitcherWidgetState extends State<EmpresaSwitcherWidget> {
  List<CoreEmpresa>? _empresas;
  bool _isLoading = true;
  String? _trocandoTenantId;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final membrosRows = await Supabase.instance.client
          .from('membro_empresa')
          .select('tenantId')
          .eq('usuarioId', user.id);

      final tenantIds = (membrosRows as List<dynamic>)
          .map((m) => m['tenantId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (tenantIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final empresaRows = await Supabase.instance.client
          .from('empresa')
          .select()
          .inFilter('id', tenantIds);

      final list = (empresaRows as List<dynamic>).map((empData) {
        final statusStr = empData['status'] as String? ?? 'ATIVO';
        final status = statusStr.toUpperCase() == 'ATIVO'
            ? StatusEmpresa.ativo
            : StatusEmpresa.bloqueado;
        return CoreEmpresa(
          id: empData['id'] as String,
          razaoSocial: empData['razaoSocial'] as String? ?? '',
          nomeFantasia: empData['nomeFantasia'] as String? ?? '',
          documentoFiscal: empData['documentoFiscal'] as String? ?? empData['cnpj'] as String? ?? '',
          email: empData['email'] as String? ?? '',
          telefone: empData['telefone'] as String? ?? '',
          tipoPessoa: empData['tipoPessoa'] as String? ?? 'JURIDICA',
          status: status,
          plano: PlanoEmpresa.prata,
          timezone: empData['timezone'] as String? ?? 'America/Sao_Paulo',
          locale: empData['locale'] as String? ?? 'pt_BR',
          currency: empData['currency'] as String? ?? 'BRL',
          country: empData['country'] as String? ?? 'BR',
          createdFrom: empData['createdFrom'] as String? ?? 'PDV',
          cidade: empData['cidade'] as String?,
          estado: empData['estado'] as String?,
          version: empData['syncVersion'] as int? ?? 1,
          metadata: SyncMetadata(
            version: empData['syncVersion'] as int? ?? 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'system',
            updatedBy: 'system',
            syncStatus: SyncStatus.synced,
          ),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _empresas = list;
        _isLoading = false;
        _expanded = list.length > 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _trocarEmpresa(CoreEmpresa empresa) async {
    final tenantContext = DependencyInjection().get<TenantContext>();
    final currentTenantId = tenantContext.hasContext ? tenantContext.empresa.id : null;

    if (currentTenantId == empresa.id) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _trocandoTenantId = empresa.id);

    try {
      final tenantContext = DependencyInjection().get<TenantContext>();
      if (tenantContext.hasContext) {
        tenantContext.setContext(
          empresa: empresa,
          usuario: tenantContext.usuario,
        );
      }

      if (!mounted) return;
      setState(() {
        _trocandoTenantId = null;
        _expanded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operando: ${empresa.nomeFantasia}'),
          backgroundColor: const Color(0xFF3FB950),
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onEmpresaTrocada?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
      setState(() => _trocandoTenantId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LinearProgressIndicator(
          backgroundColor: Color(0xFF21262D),
          color: Color(0xFF6C63FF),
        ),
      );
    }

    final empresas = _empresas;
    if (empresas == null || empresas.isEmpty) return const SizedBox.shrink();

    if (empresas.length == 1) {
      return _EmpresaAtivaTile(empresa: empresas.first, isActive: true);
    }

    final tenantContext = DependencyInjection().get<TenantContext>();
    final currentTenantId = tenantContext.hasContext ? tenantContext.empresa.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF8B949E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Empresa ativa',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        tenantContext.hasContext
                            ? tenantContext.empresa.nomeFantasia
                            : 'Selecionar...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8B949E), size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const Divider(color: Color(0xFF21262D), height: 1),
              const SizedBox(height: 4),
              ...empresas.map((emp) {
                final isActive = emp.id == currentTenantId;
                final isTrocando = _trocandoTenantId == emp.id;
                return _EmpresaAtivaTile(
                  empresa: emp,
                  isActive: isActive,
                  isLoading: isTrocando,
                  onTap: isActive ? null : () => _trocarEmpresa(emp),
                );
              }),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFF21262D), height: 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmpresaAtivaTile extends StatelessWidget {
  final CoreEmpresa empresa;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;

  const _EmpresaAtivaTile({
    required this.empresa,
    required this.isActive,
    this.isLoading = false,
    this.onTap,
  });

  String get _initials {
    final nome = empresa.nomeFantasia.trim();
    final parts = nome.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF8B949E),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                empresa.nomeFantasia,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF8B949E),
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Color(0xFF6C63FF)),
              )
            else if (isActive)
              const Icon(Icons.check_rounded, color: Color(0xFF6C63FF), size: 18),
          ],
        ),
      ),
    );
  }
}
