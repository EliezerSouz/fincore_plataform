import 'dart:io';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

final Expando<Map<String, dynamic>> _sessionContext = Expando<Map<String, dynamic>>();

extension SessionContextExtension on Session {
  Map<String, dynamic> get context {
    return _sessionContext[this] ??= <String, dynamic>{};
  }
}

class AuthMiddleware {
  static const String jwtSecretEnv = 'SUPABASE_JWT_SECRET';
  
  /// Obtém o segredo JWT do ambiente ou senha de desenvolvimento
  static String get _jwtSecret {
    return Platform.environment[jwtSecretEnv] ?? '7y9IvWpX04q7xcVGpYPW+2l0SDhnN37AZdb9Axz3rQz4YF/gaPwU3E0GNYmAwGzvjMZkg2xCZOkBnkAqMVh92Q==';
  }

  static Future<AuthenticationInfo?> handleAuth(Session session, String token) async {
    try {
      // Validação do token diretamente no Supabase API para suportar chaves ECC e rotação de chaves sem falhas locais
      final url = Uri.parse('https://nlaxdeqbordmovukyypk.supabase.co/auth/v1/user');
      final response = await HttpClient().getUrl(url).then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        req.headers.add('apikey', 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy');
        return req.close();
      });

      if (response.statusCode != 200) {
        session.log('Falha na validação do JWT via Supabase API. Status: ${response.statusCode}', level: LogLevel.warning);
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final userData = jsonDecode(responseBody);
      
      final sub = userData['id'] as String?;
      final email = userData['email'] as String?;
      
      if (sub == null) return null;

      final userUuid = UuidValue.fromString(sub);

      // 2. Resolver o tenantId e papel na base de dados
      String tenantHeader = '';
      if (session is MethodCallSession) {
        tenantHeader = session.httpRequest.headers.value('x-tenant-id') ?? '';
      }
      
      if (tenantHeader.isEmpty) {
        // Tentar resolver a empresa a partir do vínculo existente no banco
        final resolveMembro = await MembroEmpresa.db.findFirstRow(
          session,
          where: (t) => t.usuarioId.equals(userUuid),
        );
        if (resolveMembro != null) {
          tenantHeader = resolveMembro.tenantId.toString();
          session.context['role'] = resolveMembro.role;
        }
      }

      if (tenantHeader.isNotEmpty) {
        final tenantUuid = UuidValue.fromString(tenantHeader);
        final empresa = await Empresa.db.findById(session, tenantUuid);
        if (empresa != null) {
          session.context['vencimento'] = empresa.vencimento;
        }
      }
      
      final scopes = <Scope>{};
      
      // Adicionar metadados à sessão para acesso nos endpoints
      session.context['usuarioId'] = sub;
      session.context['email'] = email;
      session.context['tenantId'] = tenantHeader;

      // Gerar um ID numérico estável para o Serverpod a partir do UUID
      final userIdInt = sub.hashCode.abs();

      // Se o cabeçalho do tenant for especificado, validamos o vínculo na tabela membros_empresa
      if (tenantHeader.isNotEmpty) {
        final tenantUuid = UuidValue.fromString(tenantHeader);
        final membro = await MembroEmpresa.db.findFirstRow(
          session,
          where: (t) => t.tenantId.equals(tenantUuid) & t.usuarioId.equals(userUuid),
        );

        if (membro == null) {
          session.log('Acesso negado: Usuário $sub não é membro do tenant $tenantHeader', level: LogLevel.warning);
          return null; 
        }

        if (!membro.ativo) {
          session.log('Acesso negado: Vínculo inativo para usuário $sub no tenant $tenantHeader', level: LogLevel.warning);
          return null;
        }

        // Configurar escopo baseado na role
        scopes.add(Scope(membro.role.toLowerCase()));
        session.context['role'] = membro.role;
      }

      return AuthenticationInfo(userIdInt, scopes);
    } catch (e) {
      session.log('Falha na validação do JWT Supabase: $e', level: LogLevel.warning);
      return null;
    }
  }
}
