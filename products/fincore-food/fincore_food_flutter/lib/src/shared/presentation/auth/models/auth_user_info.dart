/// Informações de autenticação do usuário logado.
///
/// Usado pelo FincoreRootRouter e SupabaseSessionService para transmitir
/// o estado da sessão após login via Supabase Auth.
///
/// Substituiu o tipo [AuthUserInfo] do Serverpod na arquitetura local-first.
class AuthUserInfo {
  /// ID interno do usuário no banco de dados de domínio (tabela `usuarios`).
  final String usuarioId;

  /// E-mail do usuário.
  final String email;

  /// Role do usuário dentro da empresa (ex: 'ADMIN', 'OPERADOR', 'SUPERADMIN').
  final String? role;

  /// ID da empresa/tenant ativa do usuário.
  final String? tenantId;

  /// Data de vencimento da assinatura da empresa.
  final DateTime? vencimento;

  const AuthUserInfo({
    required this.usuarioId,
    required this.email,
    this.role,
    this.tenantId,
    this.vencimento,
  });

  @override
  String toString() =>
      'AuthUserInfo(usuarioId: $usuarioId, email: $email, role: $role, tenantId: $tenantId, vencimento: $vencimento)';
}
