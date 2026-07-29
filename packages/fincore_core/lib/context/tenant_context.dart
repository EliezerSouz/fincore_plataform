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

  void setContext({required CoreEmpresa empresa, required CoreUsuario usuario}) {
    _empresa = empresa;
    _usuario = usuario;

    LogService.instance.info(
      LogModule.startup,
      '''
══════════════════════════════════════
FINCORE WORKSPACE LOADED
Tenant: ${empresa.nomeFantasia}
Usuario: ${usuario.nome} (${usuario.email})
Empresa ID: ${empresa.id}
Versão: 1.2.0
══════════════════════════════════════''',
      tenantId: empresa.id,
      userId: usuario.id,
    );
  }

  void clear() {
    _empresa = null;
    _usuario = null;
  }
}
