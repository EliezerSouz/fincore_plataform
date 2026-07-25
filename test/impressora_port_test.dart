import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/domain/ports/impressora_port.dart';
import 'package:salgaderia/models/domain_models.dart';
import 'package:salgaderia/services/settings_service.dart';

class FakeImpressoraPort implements IImpressoraPort {
  final List<PedidoCompleto> impressoes = [];
  bool conexaoDisponivel = true;

  @override
  Future<void> imprimirPedido(PedidoCompleto pedido, AppSettings settings) async {
    impressoes.add(pedido);
  }

  @override
  Future<bool> testarConexao(String destino) async {
    return conexaoDisponivel;
  }
}

void main() {
  late FakeImpressoraPort impressora;

  setUp(() {
    impressora = FakeImpressoraPort();
  });

  test('registra pedidos impressos sem erros de I/O', () async {
    final pedido = Pedido(
      id: 1,
      numero: 1,
      clienteId: 1,
      clienteNome: 'João Silva',
      clienteTelefone: '11999999999',
      dataEntrega: DateTime.now(),
      tipoEntrega: 'Entrega',
      formaPagamento: 'Pix',
      subtotalCentavos: 5000,
      taxaEntregaCentavos: 500,
      totalCentavos: 5500,
      observacoes: '',
      status: 'Pendente',
      statusFinanceiro: 'Pendente',
      versao: 1,
      prioridade: 'Normal',
      pixConfirmado: false,
      pixConfirmadoEm: null,
      comprovantePix: null,
      criadoEm: DateTime.now(),
    );

    final cliente = Cliente(
      id: 1,
      nome: 'João Silva',
      telefone: '11999999999',
      logradouro: 'Rua A',
      numero: '10',
      bairro: 'Bairro B',
      cidade: 'Cidade C',
      cep: '',
      referencia: '',
      observacoes: '',
      ativo: true,
    );

    final pedidoCompleto = PedidoCompleto(pedido, cliente, []);
    await impressora.imprimirPedido(pedidoCompleto, const AppSettings());

    expect(impressora.impressoes.length, 1);
    expect(impressora.impressoes.first.cliente.nome, 'João Silva');
  });

  test('testa conexao com sucesso', () async {
    impressora.conexaoDisponivel = true;
    final resultado = await impressora.testarConexao('192.168.1.100');
    expect(resultado, isTrue);
  });
}
