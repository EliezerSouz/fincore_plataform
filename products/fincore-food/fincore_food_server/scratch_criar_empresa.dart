import 'dart:convert';
import 'package:postgres/postgres.dart';

void main() async {
  print('Conectando ao banco Supabase PostgreSQL para testar transação de onboarding...');
  final connection = await Connection.open(
    Endpoint(
      host: 'db.nlaxdeqbordmovukyypk.supabase.co',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'GeR9cjvrXrujvL0R',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  print('Conexão ativa. Iniciando transação simulada de criarEmpresa...');

  final tenantId = '11111111-2222-3333-4444-555555555555';
  final usuarioId = '99999999-8888-7777-6666-555555555555';
  final usuarioEmail = 'onboarding_test@fincore.com';
  final now = DateTime.now();

  try {
    await connection.runTx((session) async {
      // 1. Inserir a Empresa
      print('Inserindo na tabela "empresa"...');
      await session.execute(
        r'''
        INSERT INTO public.empresa (
          id, "razaoSocial", "nomeFantasia", "documentoFiscal", email, telefone,
          status, plano, timezone, locale, currency, country, "createdFrom",
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion", "tipoPessoa"
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
        )
        ''',
        parameters: [
          tenantId, 'Razao Social Teste', 'Fantasia Teste', '12345678909', usuarioEmail, '11999999999',
          'PENDENTE_ATIVACAO', 'bronze', 'America/Sao_Paulo', 'pt_BR', 'BRL', 'BR', 'Web',
          now, now, usuarioId, usuarioId, 1, 'FISICA'
        ],
      );
      print('Empresa inserida com sucesso.');

      // 2. Inserir o Usuário
      print('Inserindo na tabela "usuarios"...');
      await session.execute(
        r'''
        INSERT INTO public.usuarios (
          id, "activeTenantId", "authUserId", username, email, nome, ativo, "criadoEm", "atualizadoEm"
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9
        )
        ''',
        parameters: [
          usuarioId, tenantId, usuarioId, 'testuser', usuarioEmail, 'Teste User', true, now, now
        ],
      );
      print('Usuário inserido com sucesso.');

      // 3. Inserir EventoEmpresa
      print('Inserindo na tabela "eventos_empresa"...');
      await session.execute(
        r'''
        INSERT INTO public.eventos_empresa (
          id, "tenantId", tipo, payload, "geradoPor", "ocorridoEm"
        ) VALUES (
          gen_random_uuid(), $1, $2, $3, $4, $5
        )
        ''',
        parameters: [
          tenantId, 'CRIADA', jsonEncode({'test': true}), usuarioId, now
        ],
      );
      print('EventoEmpresa inserido com sucesso.');

      // 4. Inserir EmpresaConfiguracao
      print('Inserindo na tabela "empresa_configuracao"...');
      await session.execute(
        r'''
        INSERT INTO public.empresa_configuracao (
          id, "tenantId", "taxaServico", "usarWhatsApp", tema, "mensagemRodape",
          "autoPrintCaixa", "autoPrintCozinha", "autoPrintBalcao", "autoPrintExpedicao",
          "viasCliente", "viasCozinha", "viasBalcao", "viasExpedicao",
          "larguraPapel", "cortarPapel", "abrirGaveta", "imprimirQRCode", "imprimirCopiaCola",
          "imprimirLogo", "imprimirRodape", "pixTipo", "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26
        )
        ''',
        parameters: [
          tenantId, 0.10, true, 'escuro', 'Obrigado!',
          true, true, false, false,
          1, 1, 0, 0,
          80, true, false, true, true,
          false, true, 'CPF', now, now, usuarioId, usuarioId, 1
        ],
      );
      print('EmpresaConfiguracao inserida com sucesso.');

      // 5. Inserir Cliente padrão
      print('Inserindo na tabela "cliente"...');
      await session.execute(
        r'''
        INSERT INTO public.cliente (
          id, "tenantId", nome, telefone, observacoes, ativo, "aceitaMarketing", "aceitaWhatsapp",
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
        )
        ''',
        parameters: [
          tenantId, 'Consumidor Final', '00000000000', 'Cliente padrão', true, false, false,
          now, now, usuarioId, usuarioId, 1
        ],
      );
      print('Cliente padrão inserido com sucesso.');

      // 6. Inserir MembroEmpresa
      print('Inserindo na tabela "membro_empresa"...');
      await session.execute(
        r'''
        INSERT INTO public.membro_empresa (
          id, "tenantId", "usuarioId", role, ativo, "convidadoEm", "aceitoEm",
          "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (
          gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
        )
        ''',
        parameters: [
          tenantId, usuarioId, 'OWNER', true, now, now,
          now, now, usuarioId, usuarioId, 1
        ],
      );
      print('MembroEmpresa inserido com sucesso.');
    });

    print('\n🎉 SUCESSO! Toda a transação de onboarding executou sem erros!');
  } catch (e, st) {
    print('\n❌ FALHA NA TRANSAÇÃO:');
    print(e);
    print(st);
  } finally {
    await connection.close();
  }
}
