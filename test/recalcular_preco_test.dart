import 'package:flutter_test/flutter_test.dart';
import 'package:salgaderia/database/app_database.dart';
import 'package:salgaderia/domain/ports/grupo_preco_repository_port.dart';
import 'package:salgaderia/domain/usecases/recalcular_preco_usecase.dart';
import 'package:salgaderia/models/domain_models.dart';

class FakeGrupoPrecoRepository implements IGrupoPrecoRepository {
  final Map<int, List<FaixaInput>> faixasPorGrupo = {};

  @override
  Future<int?> preco(int grupoId, int quantidade) async {
    final faixas = faixasPorGrupo[grupoId] ?? [];
    for (final f in faixas) {
      if (f.atende(quantidade)) return f.valorCentavos;
    }
    return null;
  }

  @override
  Stream<List<GruposPrecoData>> observar() => throw UnimplementedError();

  @override
  Future<List<FaixasPrecoData>> faixas(int grupoId) => throw UnimplementedError();

  @override
  Future<int> salvar(
      {int? id,
      required String nome,
      String descricao = '',
      required List<FaixaInput> faixas}) =>
      throw UnimplementedError();
}

void main() {
  late FakeGrupoPrecoRepository repo;
  late RecalcularPrecoUseCase useCase;

  setUp(() {
    repo = FakeGrupoPrecoRepository();
    useCase = RecalcularPrecoUseCase(repo);

    repo.faixasPorGrupo[1] = const [
      FaixaInput(1, 49, 150),
      FaixaInput(50, null, 100),
    ];
  });

  test('calcula preço correto quando quantidade atinge faixa com desconto', () async {
    const grupo = GruposPrecoData(id: 1, nome: 'Salgados', descricao: '', ativo: true);
    const produto1 = Produto(id: 1, nome: 'Coxinha', categoria: 'Salgados', grupoPrecoId: 1, tempoMedioMinutos: 10, controlaEstoque: true, ordemProducao: 0, ativo: true);
    const produto2 = Produto(id: 2, nome: 'Kibe', categoria: 'Salgados', grupoPrecoId: 1, tempoMedioMinutos: 10, controlaEstoque: true, ordemProducao: 0, ativo: true);

    final itens = [
      ItemCarrinho(produto: produto1, grupo: grupo, quantidade: 30),
      ItemCarrinho(produto: produto2, grupo: grupo, quantidade: 25),
    ];

    final resumos = await useCase(itens);

    expect(resumos.length, 1);
    expect(resumos.first.quantidade, 55);
    expect(resumos.first.valorUnitarioCentavos, 100);
    expect(itens[0].valorUnitarioCentavos, 100);
    expect(itens[1].valorUnitarioCentavos, 100);
  });
}
