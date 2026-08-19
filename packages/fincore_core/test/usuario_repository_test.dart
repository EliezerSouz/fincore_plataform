import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/usuario_repository.dart';
import 'package:fincore_core/src/logging/log_service.dart';

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  group('UsuarioRepository Unit Tests', () {
    late FincoreDatabase db;
    late TenantContext context;
    late UsuarioRepository repository;

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-123',
      razaoSocial: 'Empresa Teste',
      nomeFantasia: 'Teste',
      documentoFiscal: '123',
      email: 'a@a.com',
      telefone: '123',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.bronze,
      timezone: 'GMT',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Web',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-caixa-1',
      username: 'caixa1',
      nome: 'Operador de Caixa 1',
      email: 'caixa1@empresa.com',
      avatarUrl: null,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      repository = UsuarioRepository(db: db, context: context);
    });

    tearDown(() async {
      await db.close();
    });

    test('should save and retrieve Usuario from local Drift SQLite', () async {
      await repository.save(mockUsuario);

      final found = await repository.findById('user-caixa-1');
      expect(found, isNotNull);
      expect(found!.nome, equals('Operador de Caixa 1'));
      expect(found.email, equals('caixa1@empresa.com'));
    });

    test('should retrieve Usuario regardless of active tenant (global table)', () async {
      await repository.save(mockUsuario);

      final mockOtherEmpresa = CoreEmpresa(
        id: 'tenant-other',
        razaoSocial: 'Outra Empresa',
        nomeFantasia: 'Outra',
        documentoFiscal: '00000000000',
        email: 'other@empresa.com',
        telefone: '1100000000',
        status: StatusEmpresa.ativo,
        plano: PlanoEmpresa.bronze,
        timezone: 'America/Sao_Paulo',
        locale: 'pt_BR',
        currency: 'BRL',
        country: 'BR',
        createdFrom: 'Web',
        version: 1,
        tipoPessoa: 'JURIDICA',
        metadata: mockMetadata,
      );

      final mockOtherUsuario = CoreUsuario(
        id: 'user-other',
        username: 'otheruser',
        nome: 'Other User',
        email: 'other@user.com',
        avatarUrl: null,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Troca o contexto para o outro tenant
      context.setContext(empresa: mockOtherEmpresa, usuario: mockOtherUsuario);

      // O usuário ainda deve ser encontrado porque a tabela é global
      final found = await repository.findById('user-caixa-1');
      expect(found, isNotNull);
      expect(found!.nome, equals('Operador de Caixa 1'));

      final all = await repository.findAll();
      expect(all.length, equals(1));
    });
  });
}
