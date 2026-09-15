import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/repository/membro_empresa_repository.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_page_header.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/validators/fincore_validators.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/audit_timeline_panel.dart';

/// Tela de Gestão de Usuários & Acessos (Módulo 4 ERP)
/// Padrão comercial de alta densidade informacional (RBAC)
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late final UsuarioRepository _usuarioRepo;
  late final AuditLogRepository _auditLogRepo;
  late final EmpresaRepository _empresaRepo;
  late final MembroEmpresaRepository _membroRepo;
  bool _isLoading = true;
  List<CoreUsuario> _usuarios = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'Todos';
  int _selectedSubTab = 0;

  // Controle de edição/criação embutido no painel direito
  CoreUsuario? _selectedUsuario;
  bool _isCreating = false;
  bool _isInspectorOpen = false;
  bool _isEditing = false;
  final _usuariosFormKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String _roleSelected = 'Administrador';
  bool _ativo = true;
  bool _isSaving = false;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _usuarioRepo = DependencyInjection().get<UsuarioRepository>();
    _auditLogRepo = DependencyInjection().get<AuditLogRepository>();
    _empresaRepo = DependencyInjection().get<EmpresaRepository>();
    _membroRepo = DependencyInjection().get<MembroEmpresaRepository>();
    _loadUsuarios();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsuarios() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await _usuarioRepo.findAll();
      if (mounted) {
        setState(() {
          _usuarios = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuarios: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectUsuario(CoreUsuario? user) {
    if (user == null) {
      setState(() {
        _selectedUsuario = null;
        _isCreating = true;
        _isInspectorOpen = true;
        _isEditing = true;
        _activeTab = 0;
        _nomeCtrl.clear();
        _usernameCtrl.clear();
        _emailCtrl.clear();
        _senhaCtrl.clear();
        _roleSelected = 'Administrador';
        _ativo = true;
      });
      return;
    }

    setState(() {
      _selectedUsuario = user;
      _isCreating = false;
      _isInspectorOpen = true;
      _isEditing = false;
      _activeTab = 0;
      _nomeCtrl.text = user.nome;
      _usernameCtrl.text = user.username;
      _emailCtrl.text = user.email ?? '';
      _senhaCtrl.clear();
      _roleSelected = _mapRoleLabelBack(user.role);
      _ativo = user.ativo;
    });
  }

  String _mapRoleLabelBack(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
      case 'OWNER':
        return 'Administrador';
      case 'OPERADOR':
      case 'OPERADOR_CAIXA':
        return 'Operador de Caixa';
      case 'COZINHA':
        return 'Cozinha / KDS';
      case 'GERENTE':
        return 'Gerente Operacional';
      default:
        return 'Operador de Caixa';
    }
  }

  List<CoreUsuario> get _filteredUsuarios {
    return _usuarios.where((u) {
      final emailStr = u.email ?? '';
      final matchesSearch = u.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emailStr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_selectedRoleFilter == 'Todos') return matchesSearch;
      
      // Mapeia o filtro de cargo correspondente
      final userFriendlyRole = _mapRoleLabelBack(u.role);
      return matchesSearch && userFriendlyRole == _selectedRoleFilter;
    }).toList();
  }

  void _openEditorUsuario(CoreUsuario? user) {
    if (user == null) {
      _selectUsuario(null);
    } else {
      _selectUsuario(user);
    }
  }

  Future<void> _salvarUsuario() async {
    if (!_usuariosFormKey.currentState!.validate()) return;

    if (_selectedUsuario != null &&
        (_selectedUsuario!.role == 'OWNER' ||
            _selectedUsuario!.role == 'PROPRIETARIO' ||
            _selectedUsuario!.role.contains('Propriet'))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O usuário Proprietário é a conta mestre do sistema e não pode ser alterado.',
                  ),
                ),
              ],
            ),
            backgroundColor: FincoreColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final tenantId = tenantCtx.hasContext ? tenantCtx.tenantId : 'system';

      // Converter a Role amigável do dropdown de volta para a role do banco
      String dbRole = 'OPERADOR';
      switch (_roleSelected) {
        case 'Administrador':
          dbRole = 'ADMIN';
          break;
        case 'Gerente Operacional':
          dbRole = 'GERENTE';
          break;
        case 'Cozinha / KDS':
          dbRole = 'COZINHA';
          break;
        default:
          dbRole = 'OPERADOR';
          break;
      }

      final isEdit = _selectedUsuario != null;
      String? authUserId = _selectedUsuario?.authUserId;

      // ─── RESOLUÇÃO DE TENANT ID DA EMPRESA CADASTRADA ─────────────────────────
      String activeTenantId = tenantCtx.hasContext ? tenantCtx.tenantId : 'system';
      if (activeTenantId == 'system') {
        try {
          final empresas = await _empresaRepo.findAll();
          if (empresas.isNotEmpty) {
            activeTenantId = empresas.first.id;
          }
        } catch (_) {}
      }

      final username = _usernameCtrl.text.trim();
      final emailInput = _emailCtrl.text.trim();
      final emailToSave = emailInput.isNotEmpty ? emailInput : '$username@fincore.local';

      // Se for novo usuário, gera um UUID local temporário para a coluna authUserId
      if (!isEdit) {
        authUserId = const Uuid().v4();
      }

      // ─── CRIPTOGRAFIA DE SENHA E ROLE NO AVATARURL (JSON ENCODADO) ────────────
      String? passwordHash;
      if (_senhaCtrl.text.isNotEmpty) {
        passwordHash = _hashPassword(_senhaCtrl.text.trim());
      } else if (isEdit && _selectedUsuario?.avatarUrl != null) {
        // Preserva o hash anterior
        try {
          final oldMap = jsonDecode(_selectedUsuario!.avatarUrl!);
          passwordHash = oldMap['password_hash'] as String?;
        } catch (_) {}
      }

      final encoddedAvatarUrl = jsonEncode({
        'role': dbRole,
        'password_hash': passwordHash,
      });

      final user = CoreUsuario(
        id: _selectedUsuario?.id ?? const Uuid().v4(), // Garante UUID local no ID também!
        tenantId: activeTenantId,
        authUserId: authUserId,
        username: username,
        email: emailToSave,
        nome: _nomeCtrl.text.trim(),
        avatarUrl: encoddedAvatarUrl,
        ativo: _ativo,
        role: dbRole,
        criadoEm: _selectedUsuario?.criadoEm ?? DateTime.now(),
        atualizadoEm: DateTime.now(),
        metadata: _selectedUsuario?.metadata ?? SyncMetadata(
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          syncStatus: SyncStatus.pending,
        ),
      );

      await _usuarioRepo.saveWithSync(user);

      // Salva membro correspondente para vincular o usuário à empresa com o papel (role) correto
      final existingMembros = await _membroRepo.findByUsuarioGlobal(user.id);
      final membroId = existingMembros.isNotEmpty ? existingMembros.first.id : const Uuid().v4();
      final convidadoEm = existingMembros.isNotEmpty ? existingMembros.first.convidadoEm : DateTime.now();

      final membro = CoreMembroEmpresa(
        id: membroId,
        tenantId: activeTenantId,
        usuarioId: user.id,
        role: dbRole,
        ativo: _ativo,
        convidadoEm: convidadoEm,
        aceitoEm: DateTime.now(),
        metadata: SyncMetadata(
          version: existingMembros.isNotEmpty ? existingMembros.first.metadata.version + 1 : 1,
          createdAt: existingMembros.isNotEmpty ? existingMembros.first.metadata.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          updatedBy: tenantCtx.hasContext ? tenantCtx.usuario.id : 'system',
          syncStatus: SyncStatus.pending,
        ),
      );
      await _membroRepo.save(membro);

      // Registra o log de auditoria no sistema local
      try {
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await _auditLogRepo.log(
          entityName: 'usuarios',
          entityId: user.id,
          userId: currentUserId,
          action: isEdit ? 'UPDATE' : 'CREATE',
          entityDisplayName: user.nome,
          entityModule: 'Sistema',
          diff: {
            'nome': user.nome,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'ativo': user.ativo,
          },
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria: $logErr');
      }
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isCreating = false;
          if (!isEdit) {
            _isInspectorOpen = false;
            _selectedUsuario = null;
          } else {
            _selectedUsuario = user;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Usuário editado com sucesso!' : 'Novo usuário cadastrado!'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
      await _loadUsuarios();
    } catch (e) {
      debugPrint('Erro ao salvar usuário: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _hashPassword(String password) {
    var hash = BigInt.parse('14695981039346656037'); // 0xcbf29ce484222325
    final prime = BigInt.parse('1099511628211'); // 0x100000001b3
    final mask64 = (BigInt.one << 64) - BigInt.one;

    for (var i = 0; i < password.length; i++) {
      hash = hash ^ BigInt.from(password.codeUnitAt(i));
      hash = (hash * prime) & mask64;
    }
    return hash.toRadixString(16);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Sub-Abas Superiores no TOPO Absoluto (Idêntico a ProdutosPage) ──
        Row(
          children: [
            _buildSubTab('Colaboradores', Icons.people_alt_outlined, 0),
            const SizedBox(width: 16),
            _buildSubTab('Permissões (RBAC)', Icons.admin_panel_settings_outlined, 1),
            const SizedBox(width: 16),
            _buildSubTab('Auditoria de Acesso', Icons.history_outlined, 2),
          ],
        ),
        const SizedBox(height: 14),

        // ── 2. Conteúdo da Aba Ativa ──────────────────────────────────────────
        Expanded(
          child: _selectedSubTab == 0
              ? _buildColaboradoresTabContent()
              : _selectedSubTab == 1
                  ? _buildRbacExplanationPanel()
                  : Container(
                      decoration: BoxDecoration(
                        color: FincoreColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const AuditTimelinePanel(entityName: 'usuarios', entityId: ''),
                    ),
        ),
      ],
    );
  }

  Widget _discreteMetricText(String label, {bool isWarning = false}) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isWarning ? FincoreColors.danger : FincoreColors.textSecondary,
      ),
    );
  }

  Widget _buildColaboradoresTabContent() {
    final totalColaboradores = _usuarios.length;
    final totalAtivos = _usuarios.where((u) => u.ativo).length;
    final inspectorTitle = _selectedUsuario == null ? 'Novo Usuário' : _selectedUsuario!.nome;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Resumo Contextual discreto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _discreteMetricText('$totalColaboradores colaboradores'),
                  const SizedBox(width: 8),
                  const Text('·', style: TextStyle(color: FincoreColors.textMuted, fontSize: 14)),
                  const SizedBox(width: 8),
                  _discreteMetricText('$totalAtivos ativos'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Linha ÚNICA de Ações (Busca + Filtro de Cargo + Botão "+ Novo usuário")
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FincoreColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FincoreColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: FincoreColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Pesquisar por nome, usuário ou email...',
                              hintStyle: TextStyle(fontSize: 13, color: FincoreColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
                      dropdownColor: FincoreColors.surface,
                      icon: const Icon(Icons.arrow_drop_down, size: 18, color: FincoreColors.textMuted),
                      items: ['Todos', 'Administrador', 'Gerente Operacional', 'Operador de Caixa', 'Cozinha / KDS']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f == 'Todos' ? 'Cargo: Todos' : f)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openEditorUsuario(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FincoreColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.person_add_outlined, size: 16, color: Colors.white),
                  label: const Text('Novo usuário', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Tabela Master de Colaboradores
            Expanded(
              child: _buildTablePanel(),
            ),
          ],
        ),

        // 4. Drawer / Inspector Panel na Direita
        if (_isInspectorOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isInspectorOpen = false),
              child: Container(color: Colors.black26),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 460,
            child: Container(
              decoration: const BoxDecoration(
                color: FincoreColors.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(-4, 0)),
                ],
              ),
              child: FincoreInspectorPanel(
                isOpen: _isInspectorOpen,
                isEditing: _isEditing,
                title: _isEditing ? (_selectedUsuario == null ? 'Novo Usuário' : 'Editar Usuário') : inspectorTitle,
                subtitle: _selectedUsuario?.email,
                onEdit: _selectedUsuario != null ? () => setState(() => _isEditing = true) : null,
                onClose: () {
                  setState(() {
                    _isInspectorOpen = false;
                    _isEditing = false;
                    _selectedUsuario = null;
                  });
                },
                child: _buildRightPanelContent(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubTab(String label, IconData icon, int index) {
    final isSelected = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? FincoreColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? FincoreColors.primary : FincoreColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRbacExplanationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: FincoreColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Matriz de Permissões e Perfis (RBAC)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Controle estruturado de acessos comerciais e operacionais por perfis de responsabilidade.',
              style: TextStyle(fontSize: 12, color: FincoreColors.textMuted),
            ),
            const SizedBox(height: 20),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),
            _buildRoleItem('ADMINISTRADOR', 'Acesso Irrestrito', 'Controle total de configurações, tributação, financeiro, relatórios, usuários e estoque.', FincoreColors.primary),
            _buildRoleItem('GERENTE OPERACIONAL', 'Gestão Operacional', 'Acesso a produtos, preços, estoque, caixa, cancelamentos e estornos de vendas.', const Color(0xFF06B6D4)),
            _buildRoleItem('OPERADOR DE CAIXA', 'Frente de Caixa (PDV)', 'Abertura/fechamento de caixa, registro de pedidos, emissão de comprovantes e recebimentos.', const Color(0xFF10B981)),
            _buildRoleItem('COZINHA / KDS', 'Display de Preparo (KDS)', 'Visualização e alteração de status de ordens de produção no display de cozinha.', const Color(0xFFF97316)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleItem(String title, String subtitle, String desc, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: badgeColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanelContent() {
    if (!_isEditing) {
      final u = _selectedUsuario;
      if (u == null) return const SizedBox.shrink();

      final initials = u.nome.trim().isNotEmpty ? u.nome.trim().substring(0, 1).toUpperCase() : '?';
      final avatarColor = u.ativo ? FincoreColors.primary : FincoreColors.textMuted;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: avatarColor,
                    child: Text(initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Text(u.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FincoreColors.textPrimary)),
                  Text('@${u.username}', style: const TextStyle(fontSize: 12, color: FincoreColors.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FincoreColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _mapRoleLabelBack(u.role).toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FincoreColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: FincoreColors.border),
            const SizedBox(height: 16),

            _buildInspectorSectionTitle('Informações de Acesso'),
            _buildInspectorDetailRow('Nome de Usuário', u.username),
            _buildInspectorDetailRow('E-mail', u.email ?? 'Não informado'),
            _buildInspectorDetailRow('Perfil RBAC', _mapRoleLabelBack(u.role)),
            _buildInspectorDetailRow('Status', u.ativo ? 'CADASTRO ATIVO' : 'BLOQUEADO'),
            _buildInspectorDetailRow('Data de Cadastro', '${u.criadoEm.day.toString().padLeft(2, "0")}/${u.criadoEm.month.toString().padLeft(2, "0")}/${u.criadoEm.year}'),

            const SizedBox(height: 24),
            if (u.role == 'OWNER' || u.role == 'PROPRIETARIO' || u.role.contains('Propriet')) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FincoreColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FincoreColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: FincoreColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Conta Mestre Proprietário\nEste usuário é o titular do sistema e não pode ser editado nem desativado.',
                        style: TextStyle(fontSize: 11.5, color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  label: const Text('Editar Usuário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: AuditTimelinePanel(entityName: 'usuarios', entityId: u.id),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FincoreColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.history, size: 16, color: FincoreColors.textSecondary),
                label: const Text('Ver Histórico de Auditoria', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    // MODO EDITOR
    return _buildDetailsPanel();
  }

  Widget _buildInspectorSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: FincoreColors.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInspectorDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: FincoreColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LADO ESQUERDO: LISTAGEM MASTER ─────────
  Widget _buildTablePanel() {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Lista de Colaboradores
          Expanded(
            child: _filteredUsuarios.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum colaborador encontrado.',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredUsuarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final u = _filteredUsuarios[idx];
                      final isSelected = _selectedUsuario?.id == u.id;

                      // Cores dinâmicas para avatares
                      final colors = [
                        const Color(0xFF7C3AED), // Roxo
                        const Color(0xFFF97316), // Laranja
                        const Color(0xFF10B981), // Verde
                        const Color(0xFF06B6D4), // Ciano
                      ];
                      final avatarColor = colors[idx % colors.length];
                      final initials = u.nome.trim().isNotEmpty ? u.nome.trim().substring(0, 1).toUpperCase() : '?';

                      return GestureDetector(
                        onTap: () => _selectUsuario(u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? FincoreColors.primary.withValues(alpha: 0.08) : FincoreColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? FincoreColors.primary.withValues(alpha: 0.5) : FincoreColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) ...[
                                Container(
                                  width: 4,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: FincoreColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Avatar
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Informações
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            u.nome,
                                            style: const TextStyle(
                                              color: FincoreColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Badge de Status
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: u.ativo
                                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            u.ativo ? 'ATIVO' : 'BLOQUEADO',
                                            style: TextStyle(
                                              color: u.ativo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '@${u.username} • ${u.email ?? "sem e-mail"}',
                                      style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    // Badge de Perfil RBAC
                                    Text(
                                      _mapRoleLabelBack(u.role).toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF06B6D4),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── LADO DIREITO: FORMULÁRIO DE DADOS DE ACESSO ────────────────────────────
  // Perfis dinâmicos no RBAC
  final List<String> _roles = [
    'Administrador',
    'Gerente Operacional',
    'Operador de Caixa',
    'Cozinha / KDS',
    'Garçom / Salão',
  ];

  final Map<String, bool> _userPermissions = {
    'pdv_caixa': true,
    'comandas_mesas': true,
    'produtos_cardapio': false,
    'config_fiscal': false,
    'relatorios_dre': false,
    'gestao_equipe': false,
  };

  Widget _buildDetailsPanel() {
    if (_selectedUsuario == null && !_isCreating) {
      return Container(
        decoration: BoxDecoration(
          color: FincoreColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FincoreColors.border),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text(
            'Selecione ou cadastre um colaborador para editar.',
            style: TextStyle(color: FincoreColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _usuariosFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabsHeader(),
            if (_activeTab == 0) _buildTabDados(),
            if (_activeTab == 1) _buildTabPermissoes(),
            if (_activeTab == 2) _buildTabDispositivos(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsHeader() {
    final tabs = ['Dados', 'Permissões', 'Dispositivos'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FincoreColors.border, width: 1)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = _activeTab == idx;
            final isNew = _isCreating;
            final isEnabled = !isNew || idx == 0;

            return GestureDetector(
              onTap: isEnabled ? () => setState(() => _activeTab = idx) : null,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[idx],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabDados() {
    final isNew = _isCreating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FincoreFieldLabel(label: 'Nome Completo', isRequired: true),
        FincoreTextField(
          controller: _nomeCtrl,
          hintText: 'Ex: Carlos Oliveira',
          onChanged: (_) => setState(() {}),
          validator: FincoreValidators.required,
        ),
        const SizedBox(height: 12),

        const FincoreFieldLabel(label: 'Nome de Usuário (Login)', isRequired: true),
        FincoreTextField(
          controller: _usernameCtrl,
          hintText: 'Ex: coliveira',
          onChanged: (_) => setState(() {}),
          validator: FincoreValidators.compose([
            FincoreValidators.required,
            FincoreValidators.username,
          ]),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FincoreFieldLabel(label: 'E-mail de Acesso'),
            FincoreTextField(
              controller: _emailCtrl,
              hintText: 'carlos@empresa.com.br (Opcional)',
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                return FincoreValidators.email(val);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FincoreFieldLabel(label: 'Senha de Acesso'),
            FincoreTextField(
              controller: _senhaCtrl,
              hintText: isNew ? 'Defina a senha do colaborador...' : 'Deixe em branco para manter a senha atual...',
              obscureText: true,
              validator: isNew ? FincoreValidators.required : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Liberar Acesso?', style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
            Switch(
              value: _ativo,
              activeColor: const Color(0xFFF97316),
              onChanged: (v) => setState(() => _ativo = v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildTabPermissoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FincoreFieldLabel(label: 'Cargo / Perfil de Acesso'),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: FincoreColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: FincoreColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roles.contains(_roleSelected) ? _roleSelected : _roles.first,
                    isExpanded: true,
                    dropdownColor: FincoreColors.surface,
                    style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _roleSelected = val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Criar Novo Perfil Customizado (RBAC)',
              icon: Icon(Icons.add_circle_outline, color: FincoreColors.primary),
              onPressed: () => _mostrarModalNovoPerfil(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('MATRIZ DE PERMISSÕES DO PERFIL (RBAC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
        const SizedBox(height: 10),
        _buildPermissionToggle('Acesso ao PDV / Operação de Caixa', 'pdv_caixa'),
        _buildPermissionToggle('Lançamento de Comandas & Mesas', 'comandas_mesas'),
        _buildPermissionToggle('Gestão de Cardápio & Produtos', 'produtos_cardapio'),
        _buildPermissionToggle('Configurações Fiscais & Empresa', 'config_fiscal'),
        _buildPermissionToggle('Relatórios Fiscais & DRE Financeiro', 'relatorios_dre'),
        _buildPermissionToggle('Gestão de Usuários & Equipe', 'gestao_equipe'),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildPermissionToggle(String title, String key) {
    final isChecked = _userPermissions[key] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: FincoreColors.textPrimary)),
          Switch(
            value: isChecked,
            activeColor: FincoreColors.primary,
            onChanged: (val) => setState(() => _userPermissions[key] = val),
          ),
        ],
      ),
    );
  }

  void _mostrarModalNovoPerfil() {
    final nomePerfilCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        title: const Text('Novo Perfil de Acesso (RBAC)', style: TextStyle(color: FincoreColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FincoreFieldLabel(label: 'NOME DO PERFIL', isRequired: true),
            FincoreTextField(
              controller: nomePerfilCtrl,
              hintText: 'Ex: Supervisor de Entregas',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newRole = nomePerfilCtrl.text.trim();
              if (newRole.isNotEmpty) {
                setState(() {
                  if (!_roles.contains(newRole)) _roles.add(newRole);
                  _roleSelected = newRole;
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: FincoreColors.primary),
            child: const Text('Criar Perfil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabDispositivos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DISPOSITIVOS AUTORIZADOS VINCULADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FincoreColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.important_devices, size: 20, color: FincoreColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUsuario != null ? 'Terminal Principal (${_selectedUsuario!.nome})' : 'Terminal Atual',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text('Desktop Windows • IP Local Ativo', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const Text('VINCULADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildRoleExplanation(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: FincoreColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTabAuditoria() {
    return FutureBuilder<List<AuditLogEntry>>(
      future: _auditLogRepo.findAllGlobal(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: FincoreColors.primary));
        }
        final logs = snapshot.data ?? [];
        final userLogs = logs.where((x) => x.userId == _selectedUsuario?.id).toList();

        if (userLogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum log de auditoria registrado para este usuário.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 13)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userLogs.length > 5 ? 5 : userLogs.length, // Limita aos 5 mais recentes
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final log = userLogs[index];
            final Color actionColor = log.action == 'CREATE' ? Colors.green : log.action == 'DELETE' ? Colors.red : Colors.orange;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FincoreColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        log.timestamp.toString().substring(11, 16),
                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Entidade: ${log.targetEntity}",
                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (log.diff != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      log.diff!,
                      style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isCreating || _selectedUsuario != null) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _isCreating = false;
                if (_usuarios.isNotEmpty) {
                  _selectUsuario(_usuarios.first);
                } else {
                  _selectedUsuario = null;
                }
              });
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: FincoreColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          decoration: BoxDecoration(
            gradient: FincoreColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: FincoreShadows.glow(FincoreColors.primary, intensity: 0.2),
          ),
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    await _salvarUsuario();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _isSaving ? 'Salvando...' : 'Salvar',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
