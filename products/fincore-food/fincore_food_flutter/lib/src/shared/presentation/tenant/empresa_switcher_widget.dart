import 'package:flutter/material.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/main.dart';
import 'package:fincore_food_client/fincore_food_client.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/src/shared/data/mappers/bootstrap_mapper.dart';

/// Widget de troca de empresa exibido dentro do Drawer/Menu do app.
///
/// Permite que o proprietário alterne entre Matriz, Filiais e quaisquer
/// outras empresas às quais possui acesso sem precisar fazer logout.
///
/// Uso:
/// ```dart
/// EmpresaSwitcherWidget(
///   onEmpresaTrocada: () => setState(() {}),
/// )
/// ```
class EmpresaSwitcherWidget extends StatefulWidget {
  /// Callback disparado após a empresa ser trocada com sucesso.
  /// O widget pai deve usar isso para atualizar seu estado.
  final VoidCallback? onEmpresaTrocada;

  const EmpresaSwitcherWidget({super.key, this.onEmpresaTrocada});

  @override
  State<EmpresaSwitcherWidget> createState() => _EmpresaSwitcherWidgetState();
}

class _EmpresaSwitcherWidgetState extends State<EmpresaSwitcherWidget> {
  List<Empresa>? _empresas;
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
      final list = await client.onboarding.minhasEmpresas();
      if (!mounted) return;
      setState(() {
        _empresas = list;
        _isLoading = false;
        // Só expande automaticamente se houver mais de uma empresa
        _expanded = list.length > 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _trocarEmpresa(Empresa empresa) async {
    final tenantContext = DependencyInjection().get<TenantContext>();
    final currentTenantId = tenantContext.hasContext ? tenantContext.empresa.id : null;

    // Não faz nada se já é a empresa ativa
    if (currentTenantId == empresa.id.toString()) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _trocandoTenantId = empresa.id.toString());

    try {
      final payload = await client.onboarding.trocarEmpresa(empresa.id.toString());
      if (payload == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem permissão para acessar esta empresa.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _trocandoTenantId = null);
        return;
      }

      // Atualizar o contexto na memória do app
      final usuario = BootstrapMapper.toCoreUsuario(payload.usuario);
      final empresaCore = BootstrapMapper.toCoreEmpresa(payload.empresa);
      tenantContext.setContext(empresa: empresaCore, usuario: usuario);

      if (!mounted) return;
      setState(() {
        _trocandoTenantId = null;
        _expanded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operando: ${payload.empresa.nomeFantasia}'),
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

    // Se só tem 1 empresa, exibe apenas o nome da empresa ativa (sem troca)
    if (empresas.length == 1) {
      return _EmpresaAtivaTile(empresa: empresas.first, isActive: true);
    }

    final tenantContext = DependencyInjection().get<TenantContext>();
    final currentTenantId =
        tenantContext.hasContext ? tenantContext.empresa.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho expansível — empresa ativa
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    size: 18, color: Color(0xFF8B949E)),
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

        // Lista expansível com outras empresas
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
                final isActive = emp.id.toString() == currentTenantId;
                final isTrocando = _trocandoTenantId == emp.id.toString();
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
  final Empresa empresa;
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
