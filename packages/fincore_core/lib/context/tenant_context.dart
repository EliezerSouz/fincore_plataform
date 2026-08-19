import '../common/app_constants.dart';
import '../common/core_models.dart';
import '../src/logging/log_service.dart';

class ContextStateError extends StateError {
  ContextStateError(super.message);
}

class TenantContext {
  static final TenantContext _instance = TenantContext._internal();
  factory TenantContext() => _instance;
  TenantContext._internal();

  CoreEmpresa? _empresa;
  CoreUsuario? _usuario;

  // P2-02: TTL de role — após 8h offline o role é degradado para OPERADOR
  DateTime? _roleVerifiedAt;
  static const _roleTtl = Duration(hours: 8);

  bool get hasContext => _empresa != null && _usuario != null;

  CoreEmpresa get empresa {
    final e = _empresa;
    if (e == null) {
      throw ContextStateError('Operação rejeitada: Nenhum contexto de Empresa (Tenant) ativo.');
    }
    return e;
  }

  String get tenantId => empresa.id;

  CoreUsuario get usuario {
    final u = _usuario;
    if (u == null) {
      throw ContextStateError('Operação rejeitada: Nenhum contexto de Usuário autenticado ativo.');
    }
    return u;
  }

  /// Retorna o role efetivo — degradado para 'OPERADOR' se o TTL expirou (P2-02).
  /// Use este getter sempre que for verificar permissões em vez de `usuario.role`.
  String get roleEfetivo {
    if (!isRoleFresh()) {
      LogService.instance.warning(
        LogModule.startup,
        'P2-02: TTL de role expirado (${_roleTtl.inHours}h). '
        'Degradando para OPERADOR até próxima verificação online.',
        tenantId: _empresa?.id,
        userId: _usuario?.id,
      );
      return 'OPERADOR';
    }
    return _usuario?.role ?? 'OPERADOR';
  }

  /// Verifica se o role ainda está dentro do TTL configurado.
  bool isRoleFresh() {
    final verifiedAt = _roleVerifiedAt;
    if (verifiedAt == null) return false;
    return DateTime.now().difference(verifiedAt) < _roleTtl;
  }

  /// Marca o timestamp de verificação de role.
  /// Deve ser chamado após autenticação online bem-sucedida ou refresh de sessão.
  void markRoleVerified() {
    _roleVerifiedAt = DateTime.now();
  }

  void setContext({required CoreEmpresa empresa, required CoreUsuario usuario}) {
    _empresa = empresa;
    _usuario = usuario;
    _roleVerifiedAt = DateTime.now(); // P2-02: role verificado na sessão

    LogService.instance.info(
      LogModule.startup,
      '''
--------------------------------------
FINCORE WORKSPACE LOADED
Tenant: ${empresa.nomeFantasia}
Usuario: ${usuario.nome} (${usuario.email})
Empresa ID: ${empresa.id}
Role: ${usuario.role ?? 'OPERADOR'}
Versao: ${AppConstants.version}
--------------------------------------''',
      tenantId: empresa.id,
      userId: usuario.id,
    );
  }

  void clear() {
    _empresa = null;
    _usuario = null;
    _roleVerifiedAt = null;
  }
}
