import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/empresa_repository.dart';
import 'package:fincore_core/src/logging/log_service.dart';

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  group('EmpresaRepository Unit Tests', () {
    late FincoreDatabase db;
    late TenantContext context;
    late EmpresaRepository repository;

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-999',
      razaoSocial: 'Salgaderia e Alimentos LTDA',
      nomeFantasia: 'Salgaderia Central',
      documentoFiscal: '99.888.777/0001-11',
      email: 'contato@salgaderia.com',
      telefone: '11988887777',
      status: StatusEmpresa.ativo,
      plano: PlanoEmpresa.ouro,
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      currency: 'BRL',
      country: 'BR',
      createdFrom: 'Web',
      version: 1,
      tipoPessoa: 'JURIDICA',
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-admin',
      nome: 'Administrador',
      email: 'admin@salgaderia.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    setUp(() {
      db = FincoreDatabase(NativeDatabase.memory());
      context = TenantContext();
      context.clear();
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      repository = EmpresaRepository(db: db, context: context);
    });

    tearDown(() async {
      await db.close();
    });

    test('should save and retrieve active Empresa from local Drift SQLite', () async {
      await repository.save(mockEmpresa);

      final found = await repository.findById('tenant-999');
      expect(found, isNotNull);
      expect(found!.nomeFantasia, equals('Salgaderia Central'));
      expect(found.plano, equals(PlanoEmpresa.ouro));
      expect(found.timezone, equals('America/Sao_Paulo'));
    });

    test('should return empty list when querying all empresas for non-matching tenant', () async {
      await repository.save(mockEmpresa);

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
        nome: 'Other',
        email: 'other@user.com',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Troca o contexto para o outro tenant
      context.setContext(empresa: mockOtherEmpresa, usuario: mockOtherUsuario);

      final found = await repository.findById('tenant-999');
      expect(found, isNull);

      final all = await repository.findAll();
      expect(all.isEmpty, isTrue);
    });
  });
}
