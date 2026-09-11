import 'package:fincore_core/common/kds_models.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'permissao_service.dart';

class DadosOrdemKanban {
  final String cliente;
  final String telefone;
  final String tipoLogistica; // 'Entrega' | 'Retirada' | 'Mesa'
  final String pagamento;
  final int totalCentavos;
  final double totalUnidades;
  final DateTime? dataAgendada;
  final String observacoesLimpa;
  final String? endereco;
  final String? bairro;

  const DadosOrdemKanban({
    required this.cliente,
    required this.telefone,
    required this.tipoLogistica,
    required this.pagamento,
    required this.totalCentavos,
    required this.totalUnidades,
    this.dataAgendada,
    required this.observacoesLimpa,
    this.endereco,
    this.bairro,
  });

  factory DadosOrdemKanban.fromOrdem(OrdemPreparo o) {
    final obs = o.observacoes ?? '';
    
    String cliente = 'Consumidor';
    String telefone = '';
    String tipoLogistica = 'Retirada';
    String pagamento = 'Pendente';
    int totalCentavos = 0;
    double totalUnidades = 0;
    DateTime? dataAgendada;
    List<String> obsRestantes = [];
    String? endereco;
    String? bairro;

    // Remove as tags estruturadas para facilitar o processamento uniforme
    final textoParaProcessar = obs
        .replaceAll('[DADOS_PEDIDO]', '')
        .replaceAll('[/DADOS_PEDIDO]', '')
        .trim();

    final linhas = textoParaProcessar.split('\n');
    for (final linha in linhas) {
      if (linha.trim().isEmpty) continue;
      
      final parts = linha.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim().toLowerCase();
        final val = parts.sublist(1).join(':').trim();

        if (key == 'cliente') {
          cliente = val;
          continue;
        } else if (key == 'telefone') {
          telefone = val;
          continue;
        } else if (key == 'tipo') {
          tipoLogistica = val;
          continue;
        } else if (key == 'pagamento') {
          pagamento = val;
          continue;
        } else if (key == 'endereco' || key == 'endereço') {
          endereco = val;
          continue;
        } else if (key == 'bairro') {
          bairro = val;
          continue;
        } else if (key == 'total') {
          totalCentavos = int.tryParse(val) ?? 0;
          continue;
        } else if (key == 'unidades') {
          totalUnidades = double.tryParse(val) ?? 0;
          continue;
        } else if (key == 'observacao' || key == 'observação' || key == 'obs') {
          obsRestantes.add(val);
          continue;
        } else if (key == 'agendado' && val.isNotEmpty) {
          try {
            dataAgendada = DateFormat('dd/MM/yyyy HH:mm').parse(val);
          } catch (_) {}
          continue;
        } else if (key == 'obs' || key == 'observações') {
          obsRestantes.add(val);
          continue;
        }
      }
      obsRestantes.add(linha.trim());
    }

    // Fallback de cálculo de unidades se vier zerado
    if (totalUnidades == 0) {
      for (final i in o.itens) {
        totalUnidades += i.quantidade.toDouble();
      }
    }

    // Se o processamento acima não identificou o cliente/total (formato legado)
    if (cliente == 'Consumidor' && !obs.contains('[DADOS_PEDIDO]')) {
      final isDelivery = obs.toLowerCase().contains('delivery') || obs.toLowerCase().contains('entrega');
      final isMesa = obs.toLowerCase().contains('mesa');
      tipoLogistica = isDelivery ? 'Entrega' : (isMesa ? 'Mesa' : 'Retirada');

      DateTime? agendada;
      if (obs.contains('[AGENDADA PARA:')) {
        try {
          final start = obs.indexOf('[AGENDADA PARA:') + '[AGENDADA PARA:'.length;
          final end = obs.indexOf(']', start);
          final dateStr = obs.substring(start, end).trim();
          agendada = DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
        } catch (_) {}
      }

      String limpa = obs;
      if (obs.contains(']')) {
        final idx = obs.lastIndexOf(']');
        if (idx != -1 && idx < obs.length - 1) {
          limpa = obs.substring(idx + 1).trim();
        } else if (idx != -1) {
          limpa = '';
        }
      }
      obsRestantes = [limpa];
      dataAgendada = agendada;
    }

    // Filtro de segurança baseado nas permissões do papel do usuário
    String? role;
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext) {
        role = tenantCtx.usuario.role;
      }
    } catch (_) {}

    if (!PermissaoService.podeVerFinanceiro(role)) {
      pagamento = '';
      totalCentavos = 0;
    }

    return DadosOrdemKanban(
      cliente: cliente,
      telefone: telefone,
      tipoLogistica: tipoLogistica,
      pagamento: pagamento,
      totalCentavos: totalCentavos,
      totalUnidades: totalUnidades,
      dataAgendada: dataAgendada,
      observacoesLimpa: obsRestantes.join(', ').trim(),
      endereco: endereco,
      bairro: bairro,
    );
  }
}
