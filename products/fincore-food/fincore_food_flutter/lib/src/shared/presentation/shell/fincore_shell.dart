import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/configuracoes/views/configuracoes_page.dart';
import 'package:fincore_food_flutter/src/produtos/views/produtos_page.dart';
import 'package:fincore_food_flutter/src/clientes/views/clientes_page.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pedidos_page.dart';
import 'package:fincore_food_flutter/src/pedidos/views/pdv_page.dart';
import 'package:fincore_food_flutter/src/pdv_express/views/pdv_express_screen.dart';
import 'package:fincore_food_flutter/src/dashboard/views/dashboard_page.dart';

// ─── Modelo de item da sidebar ─────────────────────────────────────────────

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData iconSelected;

  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconSelected,
  });
}

class _NavGroup {
  final String? label;
  final List<_NavItem> items;
  const _NavGroup({this.label, required this.items});
}

// ─── Shell Principal ────────────────────────────────────────────────────────

class FincoreShell extends StatefulWidget {
  const FincoreShell({super.key});

  @override
  State<FincoreShell> createState() => _FincoreShellState();
}

class _FincoreShellState extends State<FincoreShell>
    with TickerProviderStateMixin {
  String _selectedTabId = 'dashboard';
  bool _sidebarExpanded = true;
  late final TenantContext _tenantContext;
  late String _activeTenantName;
  late String _userName;
  late String _userInitials;
  late String _userRole;

  // PDV padrão (delivery = pdv_express, balcao = pdv_balcao)
  String _pdvPadrao = 'pdv_express';
  static const _kPdvPadrao = 'pdv_padrao_tab';

  final List<_NavGroup> _navGroups = const [
    _NavGroup(
      items: [
        _NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          iconSelected: Icons.dashboard_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'VENDAS',
      items: [
        _NavItem(
          id: 'pdv',
          label: 'Frente de Caixa',
          icon: Icons.point_of_sale_outlined,
          iconSelected: Icons.point_of_sale_rounded,
        ),
        _NavItem(
          id: 'pedidos',
          label: 'Central de Pedidos',
          icon: Icons.receipt_long_outlined,
          iconSelected: Icons.receipt_long_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'CARDÁPIO & CLIENTES',
      items: [
        _NavItem(
          id: 'produtos',
          label: 'Produtos',
          icon: Icons.restaurant_menu_outlined,
          iconSelected: Icons.restaurant_menu_rounded,
        ),
        _NavItem(
          id: 'clientes',
          label: 'Clientes',
          icon: Icons.people_outline,
          iconSelected: Icons.people_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'OPERAÇÕES',
      items: [
        _NavItem(
          id: 'financeiro',
          label: 'Financeiro',
          icon: Icons.account_balance_wallet_outlined,
          iconSelected: Icons.account_balance_wallet_rounded,
        ),
      ],
    ),
    _NavGroup(
      label: 'SISTEMA',
      items: [
        _NavItem(
          id: 'configuracoes',
          label: 'Configurações',
          icon: Icons.settings_outlined,
          iconSelected: Icons.settings_rounded,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tenantContext = DependencyInjection().get<TenantContext>();
    _activeTenantName = _tenantContext.hasContext
        ? _tenantContext.empresa.nomeFantasia
        : 'Matriz';
    final nome = _tenantContext.hasContext
        ? _tenantContext.usuario.nome
        : 'Usuário';
    _userName = nome;
    _userInitials = nome
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    _userRole = _tenantContext.hasContext
        ? (_tenantContext.usuario.email == 'admin@fincore.com'
            ? 'Superadmin'
            : 'Operador')
        : 'Operador';
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pdvPadrao = prefs.getString(_kPdvPadrao) ?? 'pdv_express';
      _selectedTabId = 'dashboard'; // Sempre inicia no Dashboard
    });
  }

  Future<void> _setPdvPadrao(String modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPdvPadrao, modo);
    setState(() {
      _pdvPadrao = modo;
    });
  }

  void _selectTab(String id) {
    setState(() => _selectedTabId = id);
  }

  Future<void> _logout() async {
    final ok = await _confirmarAcao(
      context,
      titulo: 'Sair da Conta',
      mensagem:
          'Tem certeza que deseja sair? Você precisará fazer login novamente.',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (ok) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? 220 : 64,
            child: _buildSidebar(),
          ),

          // ── Conteúdo ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopbar(),
                const SizedBox(height: 1),
                Expanded(
                  child: Container(
                    color: FincoreColors.background,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(
          right: BorderSide(color: Color(0xFF1E1E2E), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          _buildSidebarHeader(),

          const SizedBox(height: 8),

          // Grupos de navegação
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _navGroups.map(_buildNavGroup).toList(),
              ),
            ),
          ),

          // Rodapé: usuário + sair
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B2B), Color(0xFFFF9500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          if (_sidebarExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINCORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'FOOD',
                    style: TextStyle(
                      color: const Color(0xFFFF6B2B).withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botão colapsar
          InkWell(
            onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _sidebarExpanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: const Color(0xFF6B7280),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup(_NavGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.label != null && _sidebarExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 0, 6),
            child: Text(
              group.label!,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ] else if (group.label != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFF1E1E2E),
          ),
          const SizedBox(height: 8),
        ],
        ...group.items.map(_buildNavItem),
      ],
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isSelected = _selectedTabId == item.id ||
        (_selectedTabId == 'pdv_express' && item.id == 'pdv') ||
        (_selectedTabId == 'pdv_balcao' && item.id == 'pdv');

    return Tooltip(
      message: _sidebarExpanded ? '' : item.label,
      child: InkWell(
        onTap: () {
          if (item.id == 'pdv') {
            // Vai direto pro PDV padrão configurado
            _selectTab(_pdvPadrao);
          } else {
            _selectTab(item.id);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded ? 10 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6B2B).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFFF6B2B).withValues(alpha: 0.25), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.iconSelected : item.icon,
                color: isSelected
                    ? const Color(0xFFFF6B2B)
                    : const Color(0xFF6B7280),
                size: 18,
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E2E)),
        ),
      ),
      child: Column(
        children: [
          // Usuário
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userRole,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Tenant chip
          if (_sidebarExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _activeTenantName,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Topbar ────────────────────────────────────────────────────────────────

  Widget _buildTopbar() {
    final (title, subtitle) = _getTabInfo(_selectedTabId);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const Spacer(),

          // PDV Mode Switcher (apenas quando em PDV)
          if (_selectedTabId == 'pdv_express' ||
              _selectedTabId == 'pdv_balcao') ...[
            _buildPdvSwitcher(),
            const SizedBox(width: 12),
          ],

          // Indicador online
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdvSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _pdvTab('Express / Delivery', 'pdv_express'),
          const SizedBox(width: 2),
          _pdvTab('Mesa / Balcão', 'pdv_balcao'),
        ],
      ),
    );
  }

  Widget _pdvTab(String label, String mode) {
    final isActive = _selectedTabId == mode;
    return InkWell(
      onTap: () async {
        _selectTab(mode);
        await _setPdvPadrao(mode);
      },
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6B2B) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Conteúdo ──────────────────────────────────────────────────────────────

  Widget _buildContent() {
    switch (_selectedTabId) {
      case 'dashboard':
        return const DashboardPage();
      case 'pdv_express':
        return const PdvExpressScreen();
      case 'pdv_balcao':
        return const PdvPage();
      case 'pedidos':
        return const PedidosPage();
      case 'clientes':
        return const ClientesPage();
      case 'produtos':
        return const ProdutosPage();
      case 'configuracoes':
        return const ConfiguracoesPage();
      default:
        return _buildPlaceholder(_selectedTabId);
    }
  }

  Widget _buildPlaceholder(String tabId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            tabId.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em breve',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _getTabInfo(String id) {
    return switch (id) {
      'dashboard' => ('Dashboard', 'Visão geral do negócio'),
      'pdv_express' => ('Frente de Caixa', 'Modo Express — Delivery e Retirada'),
      'pdv_balcao' => ('Frente de Caixa', 'Modo Mesa / Balcão'),
      'pedidos' => ('Central de Pedidos', 'Gestão de pedidos em andamento'),
      'clientes' => ('Clientes', 'Cadastro e histórico de clientes'),
      'produtos' => ('Produtos', 'Cardápio e política de preços'),
      'financeiro' => ('Financeiro', 'Caixa, receitas e relatórios'),
      'configuracoes' => ('Configurações', 'Parametrização do sistema'),
      _ => (id, ''),
    };
  }
}

// ─── Helper: Dialog de Confirmação Global ──────────────────────────────────

Future<bool> _confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        titulo,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Text(
        mensagem,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDestructive ? const Color(0xFFEF4444) : const Color(0xFFFF6B2B),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Função global para reutilizar em qualquer tela do app
Future<bool> confirmarAcaoFincore(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) {
  return _confirmarAcao(
    context,
    titulo: titulo,
    mensagem: mensagem,
    confirmLabel: confirmLabel,
    isDestructive: isDestructive,
  );
}
