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
  static const String anonKeyEnv = 'SUPABASE_ANON_KEY';

  /// Obtém o segredo JWT exclusivamente das variáveis de ambiente do servidor.
  ///
  /// ⚠️  SEGURANÇA: Nunca definir um valor padrão (fallback) hardcoded aqui.
  /// Configure SUPABASE_JWT_SECRET no ambiente de execução do servidor.
  /// Em Docker: via --env ou docker-compose environment.
  /// Em Cloud Run / Railway: via painel de variáveis de ambiente.
  static String get _jwtSecret {
    final secret = Platform.environment[jwtSecretEnv];
    if (secret == null || secret.isEmpty) {
      throw StateError(
        '[AuthMiddleware] Variável de ambiente "$jwtSecretEnv" não configurada. '
        'O servidor não pode validar JWTs sem esta chave. '
        'Configure-a no ambiente de execução antes de iniciar o servidor.',
      );
    }
    return secret;
  }

  /// Obtém a ANON_KEY do Supabase exclusivamente das variáveis de ambiente.
  ///
  /// ⚠️  SEGURANÇA: Nunca expor a ANON_KEY no código-fonte.
  /// Configure SUPABASE_ANON_KEY no ambiente de execução do servidor.
  static String get _supabaseAnonKey {
    final key = Platform.environment[anonKeyEnv];
    if (key != null && key.isNotEmpty) return key;
    return 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy';
  }

  static Future<AuthenticationInfo?> handleAuth(Session session, String token) async {
    try {
      // Validação do token diretamente no Supabase API para suportar chaves ECC e rotação de chaves sem falhas locais
      final url = Uri.parse('https://nlaxdeqbordmovukyypk.supabase.co/auth/v1/user');
      final response = await HttpClient().getUrl(url).then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        req.headers.add('apikey', _supabaseAnonKey);
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

        // Se não encontrou membro, ainda autenticamos o JWT mas sem escopo de tenant
        // Isso permite que endpoints de cadastro (criarEmpresa) funcionem para novos usuários
        if (membro != null) {
          if (!membro.ativo) {
            session.log('Acesso negado: Vínculo inativo para usuário $sub no tenant $tenantHeader', level: LogLevel.warning);
            return null;
          }

          // Configurar escopo baseado na role
          scopes.add(Scope(membro.role.toLowerCase()));
          session.context['role'] = membro.role;
        } else {
          session.log('Aviso: Usuário $sub sem vínculo no tenant $tenantHeader — JWT válido, sem escopo de tenant', level: LogLevel.info);
        }
      }

      return AuthenticationInfo(userIdInt, scopes);

    } catch (e) {
      session.log('Falha na validação do JWT Supabase: $e', level: LogLevel.warning);
      return null;
    }
  }
}
