import '../common/domain_primitives.dart';

class ConfiguracaoIdentidade {
  final String? cnpj;
  final String? nomeFantasia;
  final String? telefoneContato;
  final String? enderecoBase;

  const ConfiguracaoIdentidade({
    this.cnpj,
    this.nomeFantasia,
    this.telefoneContato,
    this.enderecoBase,
  });
}

class ConfiguracaoOperacao {
  final String? horarioFuncionamento;
  final int tempoPreparoPadraoMinutos;

  const ConfiguracaoOperacao({
    this.horarioFuncionamento,
    this.tempoPreparoPadraoMinutos = 30,
  });
}

class ConfiguracaoDelivery {
  final double taxaEntregaFixa;
  final List<String> bairrosAtivos;

  const ConfiguracaoDelivery({
    this.taxaEntregaFixa = 0.0,
    this.bairrosAtivos = const [],
  });
}

class ConfiguracaoFinanceira {
  final String? chavePix;
  final String? dadosBancarios;

  const ConfiguracaoFinanceira({
    this.chavePix,
    this.dadosBancarios,
  });
}

class ConfiguracaoImpressao {
  final String? impressoraCaixa;
  final String? impressoraCozinha;

  const ConfiguracaoImpressao({
    this.impressoraCaixa,
    this.impressoraCozinha,
  });
}

class CentroDeConfiguracao {
  final String tenantId;
  final ConfiguracaoIdentidade identidade;
  final ConfiguracaoOperacao operacao;
  final ConfiguracaoDelivery delivery;
  final ConfiguracaoFinanceira financeira;
  final ConfiguracaoImpressao impressao;
  final SyncMetadata metadata;

  const CentroDeConfiguracao({
    required this.tenantId,
    required this.identidade,
    required this.operacao,
    required this.delivery,
    required this.financeira,
    required this.impressao,
    required this.metadata,
  });

  /// Resolve o valor final de uma propriedade aplicando o Modelo de Herança:
  /// (Valor Terminal/Usuário -> Valor Empresa -> Valor Padrão Global)
  static T resolveInherited<T>({
    T? userOrTerminalValue,
    T? empresaValue,
    required T defaultValue,
  }) {
    if (userOrTerminalValue != null) return userOrTerminalValue;
    if (empresaValue != null) return empresaValue;
    return defaultValue;
  }
}
