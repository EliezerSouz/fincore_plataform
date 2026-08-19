import 'package:test/test.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/src/logging/log_service.dart';

void main() {
  setUpAll(() {
    LogService.init('.');
  });

  group('TenantContext Tests', () {
    final context = TenantContext();

    setUp(() {
      context.clear();
    });

    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'user-admin',
      updatedBy: 'user-admin',
    );

    final mockEmpresa = CoreEmpresa(
      id: 'tenant-123',
      razaoSocial: 'Empresa Teste LTDA',
      nomeFantasia: 'Empresa Teste',
      documentoFiscal: '12.345.678/0001-90',
      email: 'teste@empresa.com',
      telefone: '11999999999',
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

    final mockUsuario = CoreUsuario(
      id: 'user-abc',
      nome: 'Eliezer Souza',
      email: 'eliezer@fincore.com',
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    test('should throw ContextStateError when accessing context without initialization', () {
      expect(() => context.tenantId, throwsA(isA<ContextStateError>()));
      expect(() => context.empresa, throwsA(isA<ContextStateError>()));
      expect(() => context.usuario, throwsA(isA<ContextStateError>()));
      expect(context.hasContext, isFalse);
    });

    test('should successfully set and retrieve active context when consistent', () {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);

      expect(context.hasContext, isTrue);
      expect(context.tenantId, equals('tenant-123'));
      expect(context.empresa.nomeFantasia, equals('Empresa Teste'));
      expect(context.usuario.nome, equals('Eliezer Souza'));
    });

    test('should successfully clear context', () {
      context.setContext(empresa: mockEmpresa, usuario: mockUsuario);
      expect(context.hasContext, isTrue);

      context.clear();
      expect(context.hasContext, isFalse);
      expect(() => context.tenantId, throwsA(isA<ContextStateError>()));
    });
  });
}
