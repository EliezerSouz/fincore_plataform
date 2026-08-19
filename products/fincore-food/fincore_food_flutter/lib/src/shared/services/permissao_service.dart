/// Serviço centralizado de permissões para o FINCORE FOOD.
///
/// Regra: a role vem de [TenantContext.usuario.role] (string proveniente
/// do backend via MembroEmpresa.role). Nunca usar e-mail para determinar
/// privilégios — vetor de escalada de privilégio [SEC-002].
///
/// Uso:
/// ```dart
/// final role = TenantContext().usuario.role;
/// if (PermissaoService.podeEditarPedido(role)) { ... }
/// ```
class PermissaoService {
  PermissaoService._();

  // ── Helpers internos ────────────────────────────────────────────────

  static bool _isAdmin(String? role) {
    final r = role?.toUpperCase();
    return r == 'ADMIN' || r == 'SUPERADMIN' || r == 'ADMINISTRADOR';
  }

  static bool _isOperador(String? role) {
    final r = role?.toUpperCase();
    return r == 'OPERADOR' || r == 'OPERADOR_CAIXA';
  }

  static bool _isCozinha(String? role) =>
      role?.toUpperCase() == 'COZINHA';

  static bool _isEntregador(String? role) =>
      role?.toUpperCase() == 'ENTREGADOR';

  // ── Permissões de Pedidos ────────────────────────────────────────────

  /// Pode visualizar a lista de pedidos e o drawer de detalhes.
  static bool podeVerPedidos(String? role) => true; // todos os perfis

  /// Pode criar um novo pedido (via PDV).
  static bool podeCriarPedido(String? role) =>
      _isAdmin(role) || _isOperador(role);

  /// Pode editar os dados comerciais de um pedido.
  static bool podeEditarPedido(String? role) =>
      _isAdmin(role) || _isOperador(role);

  /// Pode cancelar um pedido permanentemente.
  static bool podeCancelarPedido(String? role) => _isAdmin(role);

  /// Pode reverter o status de um pedido para uma etapa anterior.
  static bool podeRevertarStatus(String? role) =>
      _isAdmin(role) || _isOperador(role);

  // ── Permissões de Produção ───────────────────────────────────────────

  /// Pode avançar o status de pendente → emPreparo.
  static bool podeIniciarPreparo(String? role) =>
      _isAdmin(role) || _isOperador(role) || _isCozinha(role);

  /// Pode avançar o status de emPreparo → pronto.
  static bool podeConcluirPreparo(String? role) =>
      _isAdmin(role) || _isOperador(role) || _isCozinha(role);

  /// Pode marcar o pedido como entregue (pronto → entregue).
  static bool podeEntregar(String? role) =>
      _isAdmin(role) || _isOperador(role) || _isEntregador(role);

  /// Pode visualizar o bloco de "Produção Necessária".
  static bool podeVerProducao(String? role) =>
      _isAdmin(role) || _isOperador(role) || _isCozinha(role);

  // ── Permissões Financeiras ────────────────────────────────────────────

  /// Pode ver valores financeiros nos cards e no drawer.
  static bool podeVerFinanceiro(String? role) =>
      _isAdmin(role) || _isOperador(role);

  // ── Permissões de Impressão ───────────────────────────────────────────

  /// Pode imprimir cupons do pedido.
  static bool podeImprimir(String? role) =>
      _isAdmin(role) || _isOperador(role) || _isCozinha(role);

  // ── Permissões de Navegação ───────────────────────────────────────────

  /// Pode ver o Dashboard.
  static bool podeVerDashboard(String? role) =>
      _isAdmin(role) || _isOperador(role);

  /// Pode acessar a Frente de Caixa (PDV).
  static bool podeAcessarPdv(String? role) =>
      _isAdmin(role) || _isOperador(role);

  /// Pode acessar módulos de Cadastros (Produtos, Clientes).
  static bool podeAcessarCadastros(String? role) =>
      _isAdmin(role) || _isOperador(role);

  /// Pode acessar o módulo Financeiro.
  static bool podeAcessarFinanceiro(String? role) => _isAdmin(role);

  /// Pode acessar módulos de Sistema (Usuários, Configurações).
  static bool podeAcessarSistema(String? role) => _isAdmin(role);

  /// Pode ver o KDS (cozinha) no menu.
  static bool podeVerKds(String? role) =>
      _isAdmin(role) || _isCozinha(role);

  /// Pode visualizar o histórico/linha do tempo de auditoria.
  static bool podeVerTimeline(String? role) => _isAdmin(role);
}
