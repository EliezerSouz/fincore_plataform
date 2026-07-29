import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';

class AuthEndpoint extends Endpoint {
  /// Faz a validação da sessão autenticada por JWT e retorna as informações do usuário logado.
  Future<AuthUserInfo?> login(Session session) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) {
      return null;
    }

    final usuarioId = session.context['usuarioId'] as String;
    final email = session.context['email'] as String? ?? '';
    final tenantId = session.context['tenantId'] as String?;
    final role = session.context['role'] as String?;
    final vencimento = session.context['vencimento'] as DateTime?;

    return AuthUserInfo(
      usuarioId: usuarioId,
      email: email,
      tenantId: tenantId.toString().isEmpty ? null : tenantId,
      role: role.toString().isEmpty ? null : role,
      vencimento: vencimento,
    );
  }

  Future<void> logout(Session session) async {
    // Session logout
  }
}
