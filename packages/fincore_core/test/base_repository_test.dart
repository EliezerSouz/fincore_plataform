import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/repository/base_repository.dart';
import 'package:fincore_core/src/logging/log_service.dart';

class MockEntity {
  final String id;
  final String tenantId;
  final String value;

  MockEntity({required this.id, required this.tenantId, required this.value});
}

class MockRepository extends BaseRepository<MockEntity, String> {
  final List<MockEntity> _db = [];

  MockRepository(super.context);

  @override
  Future<MockEntity?> findById(String id) async {
    for (final entity in _db) {
      if (entity.id == id && entity.tenantId == activeTenantId) {
        return entity;
      }
    }
    return null;
  }

  @override
  Future<List<MockEntity>> findAll() async {
    // Filtro dinâmico implícito por tenantId
    return _db.where((e) => e.tenantId == activeTenantId).toList();
  }

  @override
  Future<void> save(MockEntity entity) async {
    if (entity.tenantId != activeTenantId) {
      throw SecurityError('Tentativa de gravação de dados em tenant diferente do ativo.');
    }
    _db.add(entity);
  }

  @override
  Future<void> delete(String id) async {
    _db.removeWhere((e) => e.id == id && e.tenantId == activeTenantId);
  }
}

class SecurityError extends Error {
  final String message;
  SecurityError(this.message);
  @override
  String toString() => message;
}

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  group('BaseRepository Tenant Isolation Tests', () {
    final context = TenantContext();
    late MockRepository repo;

    setUp(() {
      context.clear();
      repo = MockRepository(context);
    });

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-123',
      tipoPessoa: 'JURIDICA',
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
      metadata: mockMetadata,
    );

    final mockUsuario = CoreUsuario(
      id: 'user-1',
      nome: 'User',
      email: 'user@user.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    test('should throw ContextStateError when activeTenantId accessed without context', () {
      expect(() => repo.activeTenantId, throwsA(isA<ContextStateError>()));
    });

    test('should successfully access activeTenantId when context is initialized', () {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);
      expect(repo.activeTenantId, equals('tenant-123'));
    });

    test('should successfully save and find entities belonging to active tenant', () async {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      final entity = MockEntity(id: 'entity-1', tenantId: 'tenant-123', value: 'Hello');
      await repo.save(entity);

      final found = await repo.findById('entity-1');
      expect(found, isNotNull);
      expect(found!.value, equals('Hello'));
    });

    test('should throw SecurityError when saving entity belonging to another tenant', () async {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      final leakedEntity = MockEntity(id: 'entity-2', tenantId: 'tenant-leaked', value: 'Evil');
      expect(() => repo.save(leakedEntity), throwsA(isA<SecurityError>()));
    });

    test('should not find entities belonging to another tenant', () async {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      final entity = MockEntity(id: 'entity-1', tenantId: 'tenant-123', value: 'Hello');
      await repo.save(entity);

      // Alterar context para outro tenant
      final otherEmpresa = CoreEmpresa(
        id: 'tenant-other',
        tipoPessoa: 'JURIDICA',
        razaoSocial: 'Other',
        nomeFantasia: 'Other',
        documentoFiscal: '123',
        email: 'b@b.com',
        telefone: '123',
        status: StatusEmpresa.ativo,
        plano: PlanoEmpresa.bronze,
        timezone: 'GMT',
        locale: 'pt_BR',
        currency: 'BRL',
        country: 'BR',
        createdFrom: 'Web',
        version: 1,
        metadata: mockMetadata,
      );
      final otherUsuario = CoreUsuario(
        id: 'user-2',
        nome: 'Other User',
        email: 'other@other.com',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      context.setContext(empresa: otherEmpresa, usuario: otherUsuario);

      final found = await repo.findById('entity-1');
      expect(found, isNull);

      final list = await repo.findAll();
      expect(list.isEmpty, isTrue);
    });
  });
}
