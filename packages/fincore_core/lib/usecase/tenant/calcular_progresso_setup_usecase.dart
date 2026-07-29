import 'package:drift/drift.dart';
import '../../database/fincore_database.dart';

class WorkspaceSetupProgress {
  final int passos;
  final int concluidos;
  final double percentual;
  final Map<String, bool> checklist;

  WorkspaceSetupProgress({
    required this.passos,
    required this.concluidos,
    required this.percentual,
    required this.checklist,
  });
}

class CalcularProgressoSetupUseCase {
  final FincoreDatabase db;

  CalcularProgressoSetupUseCase({required this.db});

  Future<WorkspaceSetupProgress> execute(String tenantId) async {
    // 1. Checar Empresa
    final empresaQuery = db.select(db.empresasTable)..where((t) => t.id.equals(tenantId));
    final empresa = await empresaQuery.getSingleOrNull();
    final bool empresaCriada = empresa != null;
    final bool contaAtiva = empresa?.status == 'ativo';

    // 2. Checar Primeiro Login (usuarios locais)
    final usuariosQuery = db.select(db.usuariosTable);
    final usuarios = await usuariosQuery.get();
    final bool loginRealizado = usuarios.isNotEmpty;

    // 3. Checar Categorias
    final categoriasQuery = db.select(db.categoriasTable)..where((t) => t.tenantId.equals(tenantId));
    final categorias = await categoriasQuery.get();
    final bool categoriasCadastradas = categorias.isNotEmpty;

    // 4. Checar Produtos
    final produtosQuery = db.select(db.produtosTable)..where((t) => t.tenantId.equals(tenantId));
    final produtos = await produtosQuery.get();
    final bool produtosCadastrados = produtos.isNotEmpty;

    // 5. Checar Clientes
    final clientesQuery = db.select(db.clientesTable)..where((t) => t.tenantId.equals(tenantId));
    final clientes = await clientesQuery.get();
    final bool clientesCadastrados = clientes.isNotEmpty;

    // 6. Checar Vendas (Ordens de Preparo)
    final ordensQuery = db.select(db.ordensPreparoTable)..where((t) => t.tenantId.equals(tenantId));
    final ordens = await ordensQuery.get();
    final bool vendaRealizada = ordens.isNotEmpty;

    final checklist = {
      'empresa_criada': empresaCriada,
      'conta_ativa': contaAtiva,
      'login_realizado': loginRealizado,
      'categorias_cadastradas': categoriasCadastradas,
      'produtos_cadastrados': produtosCadastrados,
      'clientes_cadastrados': clientesCadastrados,
      'venda_realizada': vendaRealizada,
    };

    final concluidos = checklist.values.where((v) => v).length;
    final passos = checklist.length;
    final percentual = (concluidos / passos) * 100;

    return WorkspaceSetupProgress(
      passos: passos,
      concluidos: concluidos,
      percentual: percentual,
      checklist: checklist,
    );
  }
}
