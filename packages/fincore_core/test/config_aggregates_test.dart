import 'package:test/test.dart';
import 'package:fincore_core/config/config_aggregates.dart';
import 'package:fincore_core/common/domain_primitives.dart';

void main() {
  group('CentroDeConfiguracao & Inheritance Tests', () {
    final mockMetadata = SyncMetadata(
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
      updatedBy: 'admin',
    );

    test('should resolve parameter inheritance correctly (User > Empresa > Global)', () {
      const defaultPrinter = 'EPSON_GLOBAL_DEFAULT';
      const empresaPrinter = 'TM_T20_EMPRESA';
      const userPrinter = 'POS_58_USER_TERMINAL';

      // 1. Quando o terminal/usuário especifica um valor, ele prevalece
      final resolvedUser = CentroDeConfiguracao.resolveInherited<String>(
        userOrTerminalValue: userPrinter,
        empresaValue: empresaPrinter,
        defaultValue: defaultPrinter,
      );
      expect(resolvedUser, equals(userPrinter));

      // 2. Quando o usuário não especifica, herda da Empresa
      final resolvedEmpresa = CentroDeConfiguracao.resolveInherited<String>(
        userOrTerminalValue: null,
        empresaValue: empresaPrinter,
        defaultValue: defaultPrinter,
      );
      expect(resolvedEmpresa, equals(empresaPrinter));

      // 3. Quando nem usuário nem empresa especificam, cai no Default Global da FINCORE
      final resolvedDefault = CentroDeConfiguracao.resolveInherited<String>(
        userOrTerminalValue: null,
        empresaValue: null,
        defaultValue: defaultPrinter,
      );
      expect(resolvedDefault, equals(defaultPrinter));
    });

    test('should instantiate modular configuration aggregates correctly', () {
      final config = CentroDeConfiguracao(
        tenantId: 'tenant-123',
        identidade: const ConfiguracaoIdentidade(
          cnpj: '12.345.678/0001-90',
          nomeFantasia: 'Salgaderia Express',
          telefoneContato: '11977776666',
          enderecoBase: 'Rua Central, 100',
        ),
        operacao: const ConfiguracaoOperacao(
          horarioFuncionamento: '08:00 - 22:00',
          tempoPreparoPadraoMinutos: 25,
        ),
        delivery: const ConfiguracaoDelivery(
          taxaEntregaFixa: 7.50,
          bairrosAtivos: ['Centro', 'Jardins'],
        ),
        financeira: const ConfiguracaoFinanceira(
          chavePix: 'pix@salgaderia.com',
          dadosBancarios: 'Banco 001, Ag 1234, Conta 5678-9',
        ),
        impressao: const ConfiguracaoImpressao(
          impressoraCaixa: 'EPSON_TM_T20',
          impressoraCozinha: 'BEMATECH_MP4200',
        ),
        metadata: mockMetadata,
      );

      expect(config.tenantId, equals('tenant-123'));
      expect(config.identidade.nomeFantasia, equals('Salgaderia Express'));
      expect(config.operacao.tempoPreparoPadraoMinutos, equals(25));
      expect(config.delivery.taxaEntregaFixa, equals(7.50));
      expect(config.financeira.chavePix, equals('pix@salgaderia.com'));
      expect(config.impressao.impressoraCozinha, equals('BEMATECH_MP4200'));
    });
  });
}
