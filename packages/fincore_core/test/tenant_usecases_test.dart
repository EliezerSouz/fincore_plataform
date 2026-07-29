import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/fincore_core.dart';

void main() {
  group('Tenant UseCases Unit Tests', () {
    late FincoreDatabase db;
    late CriarEmpresaUseCase criarUseCase;
    late AtivarEmpresaUseCase ativarUseCase;
    late CalcularProgressoSetupUseCase progressoUseCase;

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      criarUseCase = CriarEmpresaUseCase(db: db);
      ativarUseCase = AtivarEmpresaUseCase(db: db);
      progressoUseCase = CalcularProgressoSetupUseCase(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('CriarEmpresaUseCase [CU-J0-002] deve criar empresa, usuario, membro admin e logar evento', () async {
      await criarUseCase.execute(
        tenantId: 'tenant-123',
        razaoSocial: 'Salgadinho Teste LTDA',
        nomeFantasia: 'Salgadinho Teste',
        documentoFiscal: '12.345.678/0001-99',
        emailEmpresa: 'salgados@teste.com',
        telefoneEmpresa: '11999999999',
        usuarioId: 'user-admin-123',
        usuarioNome: 'Admin Teste',
        usuarioEmail: 'admin@teste.com',
      );

      // Verificar se Empresa foi criada
      final empresa = await (db.select(db.empresasTable)..where((t) => t.id.equals('tenant-123'))).getSingleOrNull();
      expect(empresa, isNotNull);
      expect(empresa!.nomeFantasia, equals('Salgadinho Teste'));
      expect(empresa.status, equals('PENDENTE_ATIVACAO'));

      // Verificar se Usuário foi criado
      final usuario = await (db.select(db.usuariosTable)..where((t) => t.id.equals('user-admin-123'))).getSingleOrNull();
      expect(usuario, isNotNull);
      expect(usuario!.nome, equals('Admin Teste'));

      // Verificar se Membro foi criado
      final membro = await (db.select(db.membrosEmpresaTable)
          ..where((t) => t.tenantId.equals('tenant-123') & t.usuarioId.equals('user-admin-123')))
          .getSingleOrNull();
      expect(membro, isNotNull);
      expect(membro!.role, equals('ADMIN'));
      expect(membro.ativo, isTrue);

      // Verificar se Evento foi criado
      final evento = await (db.select(db.eventosEmpresaTable)..where((t) => t.tenantId.equals('tenant-123'))).getSingleOrNull();
      expect(evento, isNotNull);
      expect(evento!.tipo, equals('CRIADA'));
    });

    test('AtivarEmpresaUseCase [CU-J0-006] deve mudar status para ativo e logar evento', () async {
      // 1. Criar empresa pendente
      await criarUseCase.execute(
        tenantId: 'tenant-123',
        razaoSocial: 'Salgadinho Teste LTDA',
        nomeFantasia: 'Salgadinho Teste',
        documentoFiscal: '12.345.678/0001-99',
        emailEmpresa: 'salgados@teste.com',
        telefoneEmpresa: '11999999999',
        usuarioId: 'user-admin-123',
        usuarioNome: 'Admin Teste',
        usuarioEmail: 'admin@teste.com',
      );

      // 2. Ativar a empresa
      await ativarUseCase.execute(tenantId: 'tenant-123', ativadoPor: 'superadmin-user');

      // 3. Verificar status ativo
      final empresa = await (db.select(db.empresasTable)..where((t) => t.id.equals('tenant-123'))).getSingleOrNull();
      expect(empresa, isNotNull);
      expect(empresa!.status, equals('ativo'));

      // 4. Verificar evento ativada
      final eventos = await (db.select(db.eventosEmpresaTable)..where((t) => t.tenantId.equals('tenant-123') & t.tipo.equals('ATIVADA'))).get();
      expect(eventos.length, equals(1));
      expect(eventos.first.geradoPor, equals('superadmin-user'));
    });

    test('CalcularProgressoSetupUseCase [CU-J0-007] deve calcular corretamente o progresso do Setup', () async {
      final tenantId = 'tenant-123';
      
      // 1. Criar empresa (estará PENDENTE_ATIVACAO)
      await criarUseCase.execute(
        tenantId: tenantId,
        razaoSocial: 'Salgadinho Teste LTDA',
        nomeFantasia: 'Salgadinho Teste',
        documentoFiscal: '12.345.678/0001-99',
        emailEmpresa: 'salgados@teste.com',
        telefoneEmpresa: '11999999999',
        usuarioId: 'user-admin-123',
        usuarioNome: 'Admin Teste',
        usuarioEmail: 'admin@teste.com',
      );

      // Progresso 1: Criada = true, Ativa = false, Login = true (tem membro admin), outros false.
      // Total concluídos: 2 de 7 (empresa_criada, login_realizado)
      var progress = await progressoUseCase.execute(tenantId);
      expect(progress.checklist['empresa_criada'], isTrue);
      expect(progress.checklist['conta_ativa'], isFalse);
      expect(progress.checklist['login_realizado'], isTrue);
      expect(progress.concluidos, equals(2));
      expect(progress.percentual, closeTo(28.57, 0.05));

      // 2. Ativar empresa
      await ativarUseCase.execute(tenantId: tenantId, ativadoPor: 'system');

      // Progresso 2: Criada = true, Ativa = true, Login = true.
      // Total concluídos: 3 de 7
      progress = await progressoUseCase.execute(tenantId);
      expect(progress.checklist['conta_ativa'], isTrue);
      expect(progress.concluidos, equals(3));
      expect(progress.percentual, closeTo(42.85, 0.05));
    });
  });
}
